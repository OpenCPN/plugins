#!/usr/bin/bash

# Merge another branch, possibly a pull request.

set -x

old_date=$(sed -n '/<date>/s/<[^>]*>//gp'  ocpn-plugins.xml | sed -ne 'l')
tools/ocpn-metadata generate \
    --userdir metadata \
    --destfile ocpn-plugins.xml\
    --date "$old_date"  \
    --force
if ! git diff -b --quiet ocpn-plugins.xml; then
    echo "Re-generating ocpn-plugins.xml to match metadata."
    git config --local user.email "action@github.com"
    git config --local user.name "$GITHUB_ACTOR"
    git add ocpn-plugins.xml
    git commit -m "Updating the repository GitHub ocpn-plugins.xml" -a
    git push
fi
