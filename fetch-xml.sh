#!/bin/bash
#
# fetch-xml.sh
#
# Usage:
#   ./fetch-xml.sh PACKAGE SHORT_VERSION OWNER "CHANNEL1 CHANNEL2 CHANNEL3"
#
# Example:
#   ./fetch-xml.sh celestial_navigation 2.8.14 opencpn "prod beta alpha"
#
# Description:
#   Cloudsmith no longer exposes metadata XML files via raw endpoints or HTML.
#   All metadata must now be fetched via the Cloudsmith CLI using the API.
#
#   This script:
#     • Accepts OWNER and CHANNELS (prod/beta/alpha) as variables
#     • Automatically constructs full Cloudsmith repo names:
#           PACKAGE → hyphenated (celestial-navigation)
#           CHANNEL → appended (celestial-navigation-prod)
#     • Searches all constructed repos
#     • Auto-detects the full Cloudsmith version (e.g., 2.8.14.0+8611.1b53a71)
#     • Finds ALL metadata packages (one per architecture)
#     • Downloads ALL metadata.xml files
#     • Saves them as PACKAGE_pi-SHORT_VERSION-ARCH.xml
#
# Requirements:
#     • Cloudsmith CLI installed
#     • CLOUDSMITH_API_KEY exported in environment
#     • jq installed
#

PACKAGE="$1"
SHORT_VERSION="$2"
OWNER="$3"
CHANNELS_STRING="$4"

if [ -z "$PACKAGE" ] || [ -z "$SHORT_VERSION" ] || [ -z "$OWNER" ] || [ -z "$CHANNELS_STRING" ]; then
    echo "ERROR: Missing required arguments."
    echo "Usage: ./fetch-xml.sh PACKAGE SHORT_VERSION OWNER \"prod beta alpha\""
    exit 1
fi

# Convert "prod beta alpha" → array
IFS=' ' read -r -a CHANNELS <<< "$CHANNELS_STRING"

# Cloudsmith repo names require hyphens, not underscores
HY_PACKAGE="${PACKAGE//_/-}"

# Build full repo names: e.g., celestial-navigation-prod
REPOS=()
for CH in "${CHANNELS[@]}"; do
    REPOS+=( "${HY_PACKAGE}-${CH}" )
done

echo "------------------------------------------------------------"
echo "Metadata XML Fetcher (Cloudsmith CLI)"
echo "Package:   $PACKAGE"
echo "Version:   $SHORT_VERSION"
echo "Owner:     $OWNER"
echo "Channels:  $CHANNELS_STRING"
echo "Repos:     ${REPOS[*]}"
echo "------------------------------------------------------------"

mkdir -p metadata

FOUND_REPO=""
FOUND_JSON=""

echo "Searching Cloudsmith repos for metadata XML..."

#
# Search each repo until we find metadata packages
#
for REPO in "${REPOS[@]}"; do

    echo "Checking repo: $OWNER/$REPO"

    JSON=$(cloudsmith list packages "$OWNER/$REPO" --query "$PACKAGE" --output-format json)

    # Check if this repo contains metadata packages for this version
    HAS_METADATA=$(echo "$JSON" | jq -r \
        ".data[]
         | select(.identifiers.name | startswith(\"${PACKAGE}_pi-${SHORT_VERSION}\"))
         | select(.identifiers.name | endswith(\"-metadata\"))"
    )

    if [ -n "$HAS_METADATA" ]; then
        FOUND_REPO="$REPO"
        FOUND_JSON="$JSON"
        break
    fi
done

if [ -z "$FOUND_REPO" ]; then
    echo "ERROR: No metadata XML found for ${PACKAGE} version ${SHORT_VERSION}"
    exit 1
fi

#
# Extract full Cloudsmith version (same for all architectures)
#
FOUND_FULL_VERSION=$(echo "$FOUND_JSON" | jq -r \
    ".data[]
     | select(.identifiers.name | startswith(\"${PACKAGE}_pi-${SHORT_VERSION}\"))
     | select(.identifiers.name | endswith(\"-metadata\"))
     | .version" | head -n 1)

echo "------------------------------------------------------------"
echo "Metadata found!"
echo "Repo:          $FOUND_REPO"
echo "Full Version:  $FOUND_FULL_VERSION"
echo "------------------------------------------------------------"

#
# Download each metadata.xml file separately
#
echo "$FOUND_JSON" | jq -c \
    ".data[]
     | select(.identifiers.name | startswith(\"${PACKAGE}_pi-${SHORT_VERSION}\"))
     | select(.identifiers.name | endswith(\"-metadata\"))" \
| while IFS= read -r ENTRY; do

    ARCH=$(echo "$ENTRY" | jq -r ".identifiers.name")
    URL=$(echo "$ENTRY" | jq -r ".files[0].cdn_url")

    # Strip CRLF and trailing whitespace
    URL=$(echo "$URL" | tr -d '\r' | sed 's/[[:space:]]*$//')

    SAFE_ARCH=$(echo "$ARCH" | sed 's/[^a-zA-Z0-9._-]/_/g')
    OUTFILE="metadata/${PACKAGE}_pi-${SHORT_VERSION}-${SAFE_ARCH}.xml"

    echo "Downloading:"
    echo "  Architecture: $ARCH"
    echo "  URL:          $URL"
    echo "  Output:       $OUTFILE"

    wget -c "$URL" -O "$OUTFILE" || {
        echo "ERROR: download failed for $ARCH"
        continue
    }

    echo "Validating $OUTFILE..."
    if grep -q "<version>" "$OUTFILE"; then
        echo "OK: Version tag found"
    else
        echo "WARNING: Version tag missing in $OUTFILE"
    fi

    echo "------------------------------------------------------------"
done

echo "All metadata XML files downloaded."
echo "------------------------------------------------------------"
echo "Metadata XML fetch complete."
