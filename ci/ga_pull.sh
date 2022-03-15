#!/bin/bash
#
# Validate all metadata which differs from upstream metadata at
# https://github.com/OpenCPN/plugins.git. Requires a pull request
# context where GITHUB_BASE_REF is defined.

set -e

sudo apt-get update
sudo apt-get install libxml2-utils

base_branch=$GITHUB_BASE_REF
git remote add upstream https://github.com/OpenCPN/plugins.git
git fetch upstream $base_branch

if git diff --quiet upstream/$base_branch -- metadata; then
    echo "No metadata changes, nothing to check."
    exit 0
fi

exit_rc=0
for f in $(git diff --name-only --diff-filter=ACMR upstream/$base_branch HEAD)
do
    if [[ "$f" == metadata*.xml ]]; then
        echo "Processing file: $f"
        xmllint --schema ocpn-plugins.xsd $f --noout || exit_rc=$((exit_rc | 1))
        tools/check-metadata-urls $f || exit_rc=$((exit_rc | 2))
    fi
done

if [ $exit_rc = 0 ];          then echo "All files pass checks" fi; fi
if [ $((exit_rc & 1 )) = 1 ]; then echo "xmllint error(s)"; fi
if [ $((exit_rc & 2 )) = 2 ]; then echo "Url access or checksum error(s)"; fi
exit $exit_rc
