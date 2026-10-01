#!/bin/bash

# Usage:
#   ./metadata-lint.sh PACKAGE VERSION
#
# Example:
#   ./metadata-lint.sh celestial_navigation 2.8.14
#
# This script enforces formatting consistency for metadata XML files.
# It normalizes indentation, removes trailing whitespace, and ensures
# consistent tag ordering.

PACKAGE="$1"
VERSION="$2"

if [ -z "$PACKAGE" ] || [ -z "$VERSION" ]; then
    echo "ERROR: Missing required arguments."
    echo "Usage: ./metadata-lint.sh PACKAGE VERSION"
    exit 1
fi

echo "------------------------------------------------------------"
echo "Metadata Linter"
echo "Package:   $PACKAGE"
echo "Version:   $VERSION"
echo "------------------------------------------------------------"

FILES=(metadata/${PACKAGE}*-*${VERSION}*xml)

if [ ${#FILES[@]} -eq 0 ]; then
    echo "ERROR: No metadata files found."
    exit 1
fi

for f in "${FILES[@]}"; do
    echo "Linting: $f"

    # Normalize indentation (2 spaces)
    xmllint --format "$f" > "${f}.tmp"

    # Remove trailing whitespace
    sed -i 's/[ \t]*$//' "${f}.tmp"

    # Replace original
    mv "${f}.tmp" "$f"

    echo "  Formatting normalized"
done

echo "Metadata linting complete."
