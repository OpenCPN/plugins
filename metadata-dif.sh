#!/bin/bash

# Usage:
#   ./metadata-diff.sh PACKAGE VERSION
#
# Example:
#   ./metadata-diff.sh celestial_navigation 2.8.14
#
# This script compares old and new metadata XML files for a given plugin
# and version. It highlights differences in version, tarball, SHA256,
# description, architecture, and other fields.

PACKAGE="$1"
VERSION="$2"

if [ -z "$PACKAGE" ] || [ -z "$VERSION" ]; then
    echo "ERROR: Missing required arguments."
    echo "Usage: ./metadata-diff.sh PACKAGE VERSION"
    exit 1
fi

echo "------------------------------------------------------------"
echo "Metadata Diff Tool"
echo "Package:   $PACKAGE"
echo "Version:   $VERSION"
echo "------------------------------------------------------------"

# Find new metadata files
NEW_FILES=(metadata/${PACKAGE}*-*${VERSION}*xml)

if [ ${#NEW_FILES[@]} -eq 0 ]; then
    echo "ERROR: No new metadata files found for ${PACKAGE} ${VERSION}"
    exit 1
fi

echo "New metadata files:"
for f in "${NEW_FILES[@]}"; do
    echo "  - $f"
done

echo "------------------------------------------------------------"
echo "Searching for older metadata files"

# Find older versions of the same package
OLD_FILES=(metadata/${PACKAGE}*xml)

# Filter out the new version
OLD_FILES=("${OLD_FILES[@]/${NEW_FILES[@]}}")

if [ ${#OLD_FILES[@]} -eq 0 ]; then
    echo "No older metadata files found."
    echo "Nothing to diff."
    exit 0
fi

echo "Older metadata files:"
for f in "${OLD_FILES[@]}"; do
    echo "  - $f"
done

echo "------------------------------------------------------------"
echo "Comparing old vs new metadata"

for NEW in "${NEW_FILES[@]}"; do
    echo "------------------------------------------------------------"
    echo "New file: $NEW"

    for OLD in "${OLD_FILES[@]}"; do
        echo "Old file: $OLD"
        echo ""

        echo "Differences:"
        diff -u "$OLD" "$NEW" || true

        echo ""
        echo "------------------------------------------------------------"
    done
done

echo "Metadata diff complete."
