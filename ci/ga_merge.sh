#!/usr/bin/bash

# Merge another branch, possibly a pull request. Ensure that ocpn-plugins.xml
# reflects actual metadata, re-generating it if required.
#
# 'actual metadata' refers to upstream, by default
# https://github.com/OpenCPN/plugins.git. For test purposes, the environment
# variable UPSTREAM can be used to override this value.

set -e

if [ -z "$GITHUB_REF" ]; then
    echo 'Cannot determine upstream base ref using $GITHUB_REF - exiting'
    exit 0;
fi
upstream=${UPSTREAM:-https://github.com/OpenCPN/plugins.git}
echo "Using upstream: ... ${upstream##https:}"
git remote add upstream $upstream
git fetch upstream $GITHUB_REF:base_branch

tools/ocpn-metadata generate --userdir metadata --frozendir frozen-metadata \
    --destfile ocpn-plugins.new
sed  -ie  '/<date>/d' ocpn-plugins.new ocpn-plugins.xml
if git diff -b --quiet --no-index ocpn-plugins.xml ocpn-plugins.new; then
    echo "ocpn-plugins.xml is already  up do date -- exiting"
    exit 0
fi

echo "Re-generating ocpn-plugins.xml to match metadata."
tools/ocpn-metadata generate --userdir metadata --frozendir frozen-metadata \
    --destfile ocpn-plugins.xmlö --force
git config --local user.email "action@github.com"
git config --local user.name "$GITHUB_ACTOR"
git add ocpn-plugins.xml
git commit -m "Automatic update of ocpn-plugins.xml" -a
git push
