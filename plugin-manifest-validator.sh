#!/bin/bash

# Usage:
#   ./plugin-manifest-validator.sh PACKAGE VERSION
#
# Example:
#   ./plugin-manifest-validator.sh celestial_navigation 2.8.14
#
# This script validates the <plugin> manifest block inside metadata XML.
# It checks required fields, structure, and correctness.

PACKAGE="$1"
VERSION="$2"

if [ -z "$PACKAGE" ] || [ -z "$VERSION" ]; then
    echo "ERROR: Missing required arguments."
    echo "Usage: ./plugin-manifest-validator.sh PACKAGE VERSION"
    exit 1
fi

echo "------------------------------------------------------------"
echo "Plugin Manifest Validator"
echo "Package:   $PACKAGE"
echo "Version:   $VERSION"
echo "------------------------------------------------------------"

FILES=(metadata/${PACKAGE}*-*${VERSION}*xml)

if [ ${#FILES[@]} -eq 0 ]; then
    echo "ERROR: No metadata files found."
    exit 1
fi

for f in "${FILES[@]}"; do
    echo "Validating manifest in: $f"

    # Check manifest block
    if ! grep -q "<plugin>" "$f"; then
        echo "  ERROR: No <plugin> block found"
        continue
    fi

    # Required fields
    REQUIRED_FIELDS=(
        "<name>"
        "<version>"
        "<description>"
        "<author>"
        "<license>"
        "<icon>"
        "<platform>"
        "<minopencpn>"
        "<maxopencpn>"
    )

    for field in "${REQUIRED_FIELDS[@]}"; do
        if grep -q "$field" "$f"; then
            echo "  OK: $field present"
        else
            echo "  WARNING: Missing $field"
        fi
    done

    # Check icon URL
    ICON=$(grep -oP '(?<=<icon>).*?(?=</icon>)' "$f")
    if [ -n "$ICON" ]; then
        echo "  Icon: $ICON"
        if curl -s --head "$ICON" | grep -q "200 OK"; then
            echo "  Icon reachable"
        else
            echo "  WARNING: Icon not reachable"
        fi
    fi

    echo ""
done

echo "------------------------------------------------------------"
echo "Manifest validation complete."
