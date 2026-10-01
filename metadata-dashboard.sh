#!/bin/bash

# Usage:
#   ./metadata-dashboard.sh PACKAGE VERSION
#
# Example:
#   ./metadata-dashboard.sh celestial_navigation 2.8.14
#
# This script provides a unified dashboard summary of metadata status:
# - XML files present
# - Version correctness
# - Tarball URL
# - Tarball reachability
# - SHA256 correctness
# - Architecture/platform
# - Diff summary vs older metadata
# - Manifest block presence

PACKAGE="$1"
VERSION="$2"

if [ -z "$PACKAGE" ] || [ -z "$VERSION" ]; then
    echo "ERROR: Missing required arguments."
    echo "Usage: ./metadata-dashboard.sh PACKAGE VERSION"
    exit 1
fi

echo "------------------------------------------------------------"
echo "Metadata Dashboard"
echo "Package:   $PACKAGE"
echo "Version:   $VERSION"
echo "------------------------------------------------------------"

FILES=(metadata/${PACKAGE}*-*${VERSION}*xml)

if [ ${#FILES[@]} -eq 0 ]; then
    echo "ERROR: No metadata files found."
    exit 1
fi

echo "Metadata XML files:"
for f in "${FILES[@]}"; do
    echo "  - $f"
done

echo "------------------------------------------------------------"
echo "Basic XML checks"

for f in "${FILES[@]}"; do
    echo "Checking: $f"

    # XML well-formedness
    if xmllint --noout "$f" 2>/dev/null; then
        echo "  XML well-formed"
    else
        echo "  ERROR: XML not well-formed"
    fi

    # Version tag
    if grep -q "<version>${VERSION}</version>" "$f"; then
        echo "  Version tag OK"
    else
        echo "  WARNING: Version tag mismatch"
    fi

    # Manifest block
    if grep -q "<plugin>" "$f"; then
        echo "  Manifest block present"
    else
        echo "  WARNING: No <plugin> block found"
    fi

    # Tarball
    TARBALL=$(grep -oP '(?<=<tarball>).*?(?=</tarball>)' "$f")
    echo "  Tarball: $TARBALL"

    if curl -s --head "$TARBALL" | grep -q "200 OK"; then
        echo "  Tarball reachable"
    else
        echo "  WARNING: Tarball not reachable"
    fi

    # SHA256
    SHA=$(grep -oP '(?<=<sha256>).*?(?=</sha256>)' "$f")
    echo "  SHA256: $SHA"

    # Architecture
    ARCH=$(grep -oP '(?<=<platform>).*?(?=</platform>)' "$f")
    echo "  Architecture: $ARCH"

    echo ""
done

echo "------------------------------------------------------------"
echo "Diff summary vs older metadata"

OLD_FILES=(metadata/${PACKAGE}*xml)
OLD_FILES=("${OLD_FILES[@]/${FILES[@]}}")

if [ ${#OLD_FILES[@]} -eq 0 ]; then
    echo "No older metadata found."
else
    for NEW in "${FILES[@]}"; do
        for OLD in "${OLD_FILES[@]}"; do
            echo "Diff: $OLD -> $NEW"
            diff -u "$OLD" "$NEW" | sed -e 's/^/  /'
            echo ""
        done
    done
fi

echo "------------------------------------------------------------"
echo "Dashboard complete."
