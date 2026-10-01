#!/bin/bash

# Usage:
#   ./pr-create.sh PACKAGE VERSION
#
# Example:
#   ./pr-create.sh celestial_navigation 2.8.14
#
# This script creates a pull request from your fork (origin/master)
# to the upstream OpenCPN/plugins repository. It uses the GitHub CLI (gh).
# The PR title and body are automatically generated.

PACKAGE="$1"
VERSION="$2"

if [ -z "$PACKAGE" ] || [ -z "$VERSION" ]; then
    echo "ERROR: Missing required arguments."
    echo "Usage: ./pr-create.sh PACKAGE VERSION"
    exit 1
fi

PR_TITLE="${PACKAGE}-${VERSION}"
PR_BODY="Metadata update for ${PACKAGE} version ${VERSION}."

echo "------------------------------------------------------------"
echo "PR Automation Script"
echo "Package:   $PACKAGE"
echo "Version:   $VERSION"
echo "Title:     $PR_TITLE"
echo "------------------------------------------------------------"

echo "Checking current branch"
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $BRANCH"

if [ "$BRANCH" != "master" ]; then
    echo "ERROR: You must be on master to create this PR."
    exit 1
fi

echo "------------------------------------------------------------"
echo "Pushing master to origin"
git push origin master

echo "------------------------------------------------------------"
echo "Creating pull request to OpenCPN/plugins"

gh pr create \
    --title "$PR_TITLE" \
    --body "$PR_BODY" \
    --base master \
    --head "rgleason:master" \
    --repo "OpenCPN/plugins"

echo "------------------------------------------------------------"
echo "Pull request created."
echo "OpenCPN/plugins will now show your PR titled:"
echo "  $PR_TITLE"
