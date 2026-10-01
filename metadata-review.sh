#!/bin/bash

# Usage:
#   ./metadata-review.sh PACKAGE VERSION
#
# Example:
#   ./metadata-review.sh celestial_navigation 2.8.14
#
# This script reviews metadata XML files for a given plugin and version.
# It highlights differences, validates structure, checks tarball URLs,
# and summarizes architectures.

PACKAGE="$1"
VERSION="$2"

if [ -z "$PACKAGE" ] || [ -z "$VERSION" ]; then
    echo "ERROR: Missing required arguments."
    echo "Usage: ./metadata-review.sh PACKAGE VERSION"
    exit 1
fi

echo "------------------------------------------------------------"
echo "Metadata Review Helper"
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
echo "Validating XML structure"

for f in "${FILES[@]}"; do
    echo "Checking: $f"

    # Basic well-formedness check
    if ! xmllint --noout "$f" 2>/dev/null; then
        echo "  ERROR: XML is not well-formed"
        continue
    else
        echo "  XML well-formed"
    fi

    # Version check
    if grep -q "<version>${VERSION}</version>" "$f"; then
        echo "  Version tag OK"
    else
        echo "  WARNING: Version tag mismatch"
    fi

    # Extract tarball URL
    TARBALL=$(grep -oP '(?<=<tarball>).*?(?=</tarball>)' "$f")
    if [ -n "$TARBALL" ]; then
        echo "  Tarball: $TARBALL"

        # Check tarball existence
        if curl -s --head "$TARBALL" | grep -q "200 OK"; then
            echo "  Tarball exists"
        else
            echo "  WARNING: Tarball not reachable"
        fi
    else
        echo "  WARNING: No tarball URL found"
    fi

    # Extract architecture
    ARCH=$(grep -oP '(?<=<platform>).*?(?=</platform>)' "$f")
    if [ -n "$ARCH" ]; then
        echo "  Architecture: $ARCH"
    else
        echo "  WARNING: No architecture tag found"
    fi

    echo ""
done

echo "------------------------------------------------------------"
echo "Metadata review complete."
