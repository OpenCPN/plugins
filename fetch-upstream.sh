#!/bin/bash
set -e

echo "=== OpenCPN Plugin Sync Automation ==="

# Ensure we are on master
git checkout master

MASTER_STASH_NAME="master-auto-stash-$(date +%s)"
PLUGIN_STASH_NAME="plugin-auto-stash-$(date +%s)"

echo ""
echo "Step 0: Stashing local changes on master (if any)..."
if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    git stash push -u -m "$MASTER_STASH_NAME"
    echo "  - Master changes stashed as: $MASTER_STASH_NAME"
else
    echo "  - No changes to stash on master."
fi

echo ""
echo "Step 1: Fetching upstream..."
git fetch upstream

echo ""
echo "Step 2: Updating metadata/ and ocpn-plugins.xml from upstream/master..."
git checkout upstream/master -- metadata
git checkout upstream/master -- ocpn-plugins.xml

echo "Staging metadata and catalog update..."
git add metadata ocpn-plugins.xml

echo "Committing metadata and catalog update..."
git commit -m "Update metadata and ocpn-plugins.xml from upstream"

echo ""
echo "Step 3: Stashing local plugin patches (if any)..."
# Switch to each plugin branch, stash changes if present
for b in $(git branch | grep source/plugins || true); do
    echo "  - Checking branch: $b"
    git checkout "$b"
    if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
        git stash push -u -m "$PLUGIN_STASH_NAME-$b"
        echo "    * Plugin changes stashed as: $PLUGIN_STASH_NAME-$b"
    else
        echo "    * No changes to stash on $b"
    fi
done

echo ""
echo "Step 4: Deleting all local plugin branches..."
git checkout master
for b in $(git branch | grep source/plugins || true); do
    echo "  - Deleting: $b"
    git branch -D "$b"
done

echo ""
echo "Step 5: Recreating plugin branches from upstream..."
for rb in $(git branch -r | grep upstream/source/plugins | sed 's/upstream\///'); do
    echo "  - Creating: $rb"
    git checkout -b "$rb" "upstream/$rb"
done

echo ""
echo "Step 6: Restoring plugin patches (if any stashes exist)..."
for b in $(git branch | grep source/plugins || true); do
    echo "  - Restoring patches for: $b"
    git checkout "$b"
    # Try to find a stash matching this branch
    STASH_REF=$(git stash list | grep "$PLUGIN_STASH_NAME-$b" | head -n1 | cut -d: -f1 || true)
    if [ -n "$STASH_REF" ]; then
        echo "    * Applying stash: $STASH_REF"
        git stash apply "$STASH_REF" || echo "    ! Failed to apply stash for $b (manual check needed)"
    else
        echo "    * No stash found for $b"
    fi
done

echo ""
echo "Step 7: Verifying plugin branches match upstream (before patches)..."
for b in $(git branch | grep source/plugins || true); do
    echo "  - Checking: $b"
    if git diff --quiet "upstream/$b" "$b"; then
        echo "    ✓ $b matches upstream (before any local patches)"
    else
        echo "    ✗ $b differs from upstream (local patches or changes present)"
    fi
done

echo ""
echo "Step 8: Returning to master and restoring master stash (if any)..."
git checkout master
MASTER_STASH_REF=$(git stash list | grep "$MASTER_STASH_NAME" | head -n1 | cut -d: -f1 || true)
if [ -n "$MASTER_STASH_REF" ]; then
    echo "  - Applying master stash: $MASTER_STASH_REF"
    git stash apply "$MASTER_STASH_REF" || echo "  ! Failed to apply master stash (manual check needed)"
else
    echo "  - No master stash to restore."
fi

echo ""
echo "=== Sync Complete ==="
echo "Master updated (metadata + ocpn-plugins.xml)."
echo "Plugin branches regenerated from upstream."
echo "Local plugin patches restored where stashes existed."
echo "Master work restored where stashed."

echo ""
read -p "Push master to origin? (y/n): " answer
if [ "$answer" = "y" ]; then
    echo "Pushing master to origin..."
    git push origin master
    echo "Push complete."
else
    echo "Push skipped."
fi

echo ""
echo "=== All Done ==="
