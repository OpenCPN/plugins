#!/bin/bash

set -x

sudo apt install libxml2-utils

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
        xmllint --schema ocpn-plugins.xsd $f --noout || exit_rc=1
        tools/check-metadata-urls $f || exit_rc=2
    fi
done

if [ $exit_rc = 0 ];          then echo "All files pass checks" fi; fi
if [ $((exit_rc & 1 )) = 1 ]; then echo "xmllint errors"; fi
if [ $((exit_rc & 2 )) = 2 ]; then echo "inaccessible url(s) errors"; fi
exit $exit_rc
