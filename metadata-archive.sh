#!/bin/bash

# Usage:
#   ./metadata-archive.sh PACKAGE VERSION
#
# Example:
#   ./metadata-archive.sh celestial_navigation 2.8.14
#
# This script moves older metadata XML files for a plugin into the beta/
# directory, keeping only the newest version in metadata/.

PACKAGE="$1"
VERSION="$2"

if [ -z "$PACKAGE" ] || [ -z "$VERSION" ]; then
    echo "ERROR: Missing required arguments."
    echo "Usage: ./metadata-archive.sh PACKAGE VERSION"
    exit 1
fi

echo "------------------------------------------------------------"
echo "Metadata Archive Manager"
echo "Package:   $PACKAGE"
echo "Version:   $VERSION"
echo "------------------------------------------------------------"

mkdir -p beta

NEW_FILES=(metadata/${PACKAGE}*-*${VERSION}*xml)
OLD_FILES=(metadata/${PACKAGE}*xml)

# Remove new files from old list
for nf in "${NEW_FILES[@]}"; do
    OLD_FILES=("${OLD_FILES[@]/$nf}")
done

if [ ${#OLD_FILES[@]} -eq 0 ]; then
    echo "No older metadata files to archive."
    exit 0
fi

echo "Archiving older metadata files:"
for f in "${OLD_FILES[@]}"; do
    echo "  Moving $f -> beta/"
    mv "$f" beta/
done

echo "Archive complete."
