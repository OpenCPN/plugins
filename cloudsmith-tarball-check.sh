#!/bin/bash

# Usage:
#   ./cloudsmith-tarball-check.sh PACKAGE VERSION
#
# Example:
#   ./cloudsmith-tarball-check.sh celestial_navigation 2.8.14
#
# This script validates Cloudsmith tarballs referenced in metadata XML.
# It checks URL reachability, SHA256 correctness, and tarball contents.

PACKAGE="$1"
VERSION="$2"

if [ -z "$PACKAGE" ] || [ -z "$VERSION" ]; then
    echo "ERROR: Missing required arguments."
    echo "Usage: ./cloudsmith-tarball-check.sh PACKAGE VERSION"
    exit 1
fi

echo "------------------------------------------------------------"
echo "Cloudsmith Tarball Checker"
echo "Package:   $PACKAGE"
echo "Version:   $VERSION"
echo "------------------------------------------------------------"

FILES=(metadata/${PACKAGE}*-*${VERSION}*xml)

if [ ${#FILES[@]} -eq 0 ]; then
    echo "ERROR: No metadata files found for ${PACKAGE} ${VERSION}"
    exit 1
fi

echo "Found ${#FILES[@]} metadata XML file(s):"
for f in "${FILES[@]}"; do
    echo "  - $f"
done

echo "------------------------------------------------------------"

for f in "${FILES[@]}"; do
    echo "Checking metadata: $f"

    # Extract tarball URL
    TARBALL=$(grep -oP '(?<=<tarball>).*?(?=</tarball>)' "$f")
    if [ -z "$TARBALL" ]; then
        echo "  ERROR: No tarball URL found"
        exit 1
    fi

    echo "  Tarball URL: $TARBALL"

    # Extract SHA256
    SHA=$(grep -oP '(?<=<sha256>).*?(?=</sha256>)' "$f")
    if [ -z "$SHA" ]; then
        echo "  ERROR: No SHA256 found"
        exit 1
    fi

    echo "  Expected SHA256: $SHA"

    echo "------------------------------------------------------------"
    echo "Checking tarball reachability"

    if curl -s --head "$TARBALL" | grep -q "200 OK"; then
        echo "  Tarball reachable"
    else
        echo "  ERROR: Tarball not reachable"
        exit 1
    fi

    echo "------------------------------------------------------------"
    echo "Downloading tarball for validation"

    TMPFILE=$(mktemp)
    curl -s -L "$TARBALL" -o "$TMPFILE"

    if [ ! -s "$TMPFILE" ]; then
        echo "  ERROR: Tarball download failed or empty"
        rm -f "$TMPFILE"
        exit 1
    fi

    echo "  Tarball downloaded to $TMPFILE"

    echo "------------------------------------------------------------"
    echo "Validating SHA256"

    ACTUAL_SHA=$(sha256sum "$TMPFILE" | awk '{print $1}')

    echo "  Actual SHA256:   $ACTUAL_SHA"
    echo "  Expected SHA256: $SHA"

    if [ "$ACTUAL_SHA" != "$SHA" ]; then
        echo "  ERROR: SHA256 mismatch"
        rm -f "$TMPFILE"
        exit 1
    else
        echo "  SHA256 OK"
    fi

    echo "------------------------------------------------------------"
    echo "Inspecting tarball contents"

    tar -tzf "$TMPFILE" | grep -E "${PACKAGE}|plugin|dll|so|xml" || echo "  WARNING: No expected plugin files found"

    echo "------------------------------------------------------------"
    echo "Tarball validation complete for $f"
    echo ""

    rm -f "$TMPFILE"
done

echo "------------------------------------------------------------"
echo "All tarballs validated successfully."
