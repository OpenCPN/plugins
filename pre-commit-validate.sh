#!/bin/bash

# Usage:
#   ./pre-commit-validate.sh PACKAGE VERSION
#
# Example:
#   ./pre-commit-validate.sh celestial_navigation 2.8.14
#
# This script validates metadata XML files before committing.
# It ensures well-formed XML, correct version tags, valid tarball URLs,
# presence of SHA256, and correct plugin naming.

PACKAGE="$1"
VERSION="$2"

if [ -z "$PACKAGE" ] || [ -z "$VERSION" ]; then
    echo "ERROR: Missing required arguments."
    echo "Usage: ./pre-commit-validate.sh PACKAGE VERSION"
    exit 1
fi

echo "------------------------------------------------------------"
echo "Pre-Commit Metadata Validator"
echo "Package:   $PACKAGE"
echo "Version:   $VERSION"
echo "------------------------------------------------------------"

FILES=(metadata/${PACKAGE}*-*${VERSION}*xml)

if [ ${#FILES[@]} -eq 0 ]; then
    echo "ERROR: No metadata files found for ${PACKAGE} ${VERSION}"
    exit 1
fi

echo "Validating ${#FILES[@]} metadata XML file(s):"
for f in "${FILES[@]}"; do
    echo "------------------------------------------------------------"
    echo "Checking: $f"

    # 1. XML well-formedness
    if ! xmllint --noout "$f" 2>/dev/null; then
        echo "  ERROR: XML is not well-formed"
        exit 1
    else
        echo "  XML well-formed"
    fi

    # 2. Version tag
    if grep -q "<version>${VERSION}</version>" "$f"; then
        echo "  Version tag OK"
    else
        echo "  ERROR: Version tag mismatch"
        exit 1
    fi

    # 3. Plugin name tag
    NAME=$(grep -oP '(?<=<name>).*?(?=</name>)' "$f")
    if [ -n "$NAME" ]; then
        echo "  Name tag: $NAME"
    else
        echo "  ERROR: Missing <name> tag"
        exit 1
    fi

    # 4. Tarball URL
    TARBALL=$(grep -oP '(?<=<tarball>).*?(?=</tarball>)' "$f")
    if [ -n "$TARBALL" ]; then
        echo "  Tarball: $TARBALL"
        if curl -s --head "$TARBALL" | grep -q "200 OK"; then
            echo "  Tarball exists"
        else
            echo "  ERROR: Tarball not reachable"
            exit 1
        fi
    else
        echo "  ERROR: Missing tarball URL"
        exit 1
    fi

    # 5. SHA256
    SHA=$(grep -oP '(?<=<sha256>).*?(?=</sha256>)' "$f")
    if [ -n "$SHA" ]; then
        echo "  SHA256 present"
    else
        echo "  ERROR: Missing SHA256"
        exit 1
    fi

    # 6. Architecture/platform
    ARCH=$(grep -oP '(?<=<platform>).*?(?=</platform>)' "$f")
    if [ -n "$ARCH" ]; then
        echo "  Architecture: $ARCH"
    else
        echo "  WARNING: No <platform> tag found"
    fi

done

echo "------------------------------------------------------------"
echo "All metadata files passed validation."
echo "Safe to commit."
