#!/bin/bash

set -x

sudo apt install libxml2-utils

git checkout $GITHUB_HEAD_REF

base_branch=$GITHUB_BASE_REF
git remote add upstream https://github.com/OpenCPN/plugins.git
git fetch upstream $base_branch


for f in $(git diff --name-only --diff-filter=ACMR upstream/$base_branch HEAD)
do
    if [[ "$f" == metadata*.xml ]]; then
        echo "Processing file: $f"
        xmllint --schema ocpn-plugins.xsd $f --noout || exit_rc=1
    fi
done

tools/ocpn-metadata generate --userdir metadata --destfile metadata.xml
tools/check-metadata-urls metadata.xml || exit_rc=$((exit_rc | 2))

if [ $exit_rc = 0 ];          then echo "All files pass checks" fi; fi
if [ $((exit_rc & 1 )) = 1 ]; then echo "xmllint errors"; fi
if [ $((exit_rc & 2 )) = 2 ]; then echo "inaccessible url(s) errors"; fi
