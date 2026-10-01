#!/usr/bin/env bash
# =============================================================================
# run-metadata-pipeline.sh
# OpenCPN Full Metadata Pipeline Orchestrator
#
# Usage:
#   ./run-metadata-pipeline.sh <PACKAGE> <VERSION> <OWNER> <REPO>
#
# Or via environment variables:
#   PACKAGE=opencpn-plugin-foo VERSION=1.2.3 OWNER=myorg REPO=my-plugin \
#     ./run-metadata-pipeline.sh
#
# Override the scripts directory if it differs from this file's location:
#   SCRIPTS_DIR=/path/to/scripts ./run-metadata-pipeline.sh ...
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPTS_DIR:-$SCRIPT_DIR}"

PACKAGE="${1:-${PACKAGE:-}}"
VERSION="${2:-${VERSION:-}}"
OWNER="${3:-${OWNER:-}}"
REPO="${4:-${REPO:-}}"

TOTAL_STEPS=12
STEP=0
FAILED_STEPS=()

log_step() { echo -e "\n${CYAN}${BOLD}[STEP $1/$TOTAL_STEPS] $2${RESET}\n${CYAN}$(printf '─%.0s' {1..70})${RESET}"; }
log_ok()   { echo -e "${GREEN}✔  $*${RESET}"; }
log_warn() { echo -e "${YELLOW}⚠  $*${RESET}"; }
log_err()  { echo -e "${RED}✘  $*${RESET}" >&2; }

run_script() {
    local script="$SCRIPTS_DIR/$1"; shift
    [[ -f "$script" ]] || { log_err "Script not found: $script"; exit 1; }
    [[ -x "$script" ]] || { log_warn "chmod +x $script"; chmod +x "$script"; }
    bash "$script" "$@"
}

safe_run() {
    local label="$1"; shift
    if run_script "$@"; then
        log_ok "$label completed."
    else
        log_err "$label FAILED."
        FAILED_STEPS+=("$label")
        [[ "${PIPELINE_ABORT_ON_ERROR:-false}" == "true" ]] && exit 1
    fi
}


# ── Preflight ────────────────────────────────────────────────────────────────
[[ -z "$PACKAGE" || -z "$VERSION" || -z "$OWNER" || -z "$REPO" ]] && {
    log_err "Missing required parameters."
    echo "Usage: $0 <PACKAGE> <VERSION> <OWNER> <REPO>"
    exit 1
}
export PACKAGE VERSION OWNER REPO



# ── Banner ──────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}╔══════════════════════════════════════════════════════════════════════╗"
echo -e "║         OpenCPN Metadata Pipeline — Full Orchestrator                ║"
echo -e "╚══════════════════════════════════════════════════════════════════════╝${RESET}"
printf "  %-10s : %s\n" "PACKAGE"  "$PACKAGE"
printf "  %-10s : %s\n" "VERSION"  "$VERSION"
printf "  %-10s : %s\n" "OWNER"    "$OWNER"
printf "  %-10s : %s\n" "REPO"     "$REPO"
printf "  %-10s : %s\n" "SCRIPTS"  "$SCRIPTS_DIR"
printf "  %-10s : %s\n" "START"    "$(date '+%Y-%m-%d %H:%M:%S %Z')"


git rev-parse --git-dir &>/dev/null || { log_err "Not inside a git repository."; exit 1; }
GIT_ROOT="$(git rev-parse --show-toplevel)"
log_ok "Git root: $GIT_ROOT"

# ---------------------------------------------------------------------------
# Preflight: Cloudsmith CLI
# ---------------------------------------------------------------------------
if ! command -v cloudsmith &>/dev/null; then
    log_err "Cloudsmith CLI not found — required for Step 6 (tarball check)."
    echo -e "    Install with: ${BOLD}pip install cloudsmith-cli${RESET}"
    echo -e "    Standalone binary: https://cloudsmith.io/~cloudsmith/repos/cli/"
    exit 1
fi
log_ok "Cloudsmith CLI: $(cloudsmith --version 2>&1 | head -1)"

if [[ -z "${CLOUDSMITH_API_KEY:-}" ]]; then
    log_err "CLOUDSMITH_API_KEY is not set — required for Step 6 (tarball check)."
    echo -e "    export CLOUDSMITH_API_KEY=<your-token>"
    exit 1
fi
log_ok "CLOUDSMITH_API_KEY present (${#CLOUDSMITH_API_KEY} chars)"


# ── STEP 1  Sync with upstream ───────────────────────────────────────────────
STEP=$(( STEP + 1 )); log_step $STEP "Sync with upstream"
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
git fetch --prune upstream 2>/dev/null || git fetch --prune origin
git rebase upstream/master 2>/dev/null || git rebase origin/master \
    || log_warn "Rebase skipped — nothing to rebase or conflicts detected."
log_ok "Branch: $CURRENT_BRANCH"

# ── STEP 2  Fetch XML metadata ───────────────────────────────────────────────
STEP=$(( STEP + 1 )); log_step $STEP "Fetch XML metadata"
safe_run "fetch-xml" "fetch-xml.sh" "$PACKAGE" "$VERSION" "$OWNER" "$REPO"

# ── STEP 3  Metadata review ──────────────────────────────────────────────────
STEP=$(( STEP + 1 )); log_step $STEP "Metadata review"
safe_run "metadata-review" "metadata-review.sh" "$PACKAGE" "$VERSION"

# ── STEP 4  Metadata diff ────────────────────────────────────────────────────
STEP=$(( STEP + 1 )); log_step $STEP "Metadata diff"
safe_run "metadata-diff" "metadata-diff.sh" "$PACKAGE" "$VERSION"

# ── STEP 5  Plugin manifest validation ──────────────────────────────────────
STEP=$(( STEP + 1 )); log_step $STEP "Plugin manifest validation"
safe_run "plugin-manifest-validator" "plugin-manifest-validator.sh" "$PACKAGE" "$VERSION"

# ── STEP 6  Cloudsmith tarball check ────────────────────────────────────────
STEP=$(( STEP + 1 )); log_step $STEP "Cloudsmith tarball check"
safe_run "cloudsmith-tarball-check" "cloudsmith-tarball-check.sh" "$PACKAGE" "$VERSION" "$OWNER" "$REPO"

# ── STEP 7  Metadata XML lint ────────────────────────────────────────────────
STEP=$(( STEP + 1 )); log_step $STEP "Metadata XML lint"
safe_run "metadata-lint" "metadata-lint.sh" "$PACKAGE" "$VERSION"

# ── STEP 8  Archive older metadata to beta ───────────────────────────────────
STEP=$(( STEP + 1 )); log_step $STEP "Archive older metadata → beta"
safe_run "metadata-archive" "metadata-archive.sh" "$PACKAGE" "$VERSION"

# ── STEP 9  Pre-commit validation ────────────────────────────────────────────
STEP=$(( STEP + 1 )); log_step $STEP "Pre-commit validation"
safe_run "pre-commit-validate" "pre-commit-validate.sh"

# ── STEP 10  Commit ──────────────────────────────────────────────────────────
STEP=$(( STEP + 1 )); log_step $STEP "Commit updated metadata"
COMMIT_MSG="${COMMIT_MSG:-"chore: update ${PACKAGE} metadata to ${VERSION}"}"
if git diff --cached --quiet && git diff --quiet; then
    log_warn "No changes to commit."
else
    git add -A
    git commit -m "$COMMIT_MSG"
    log_ok "Committed: $COMMIT_MSG"
fi

# ── STEP 11  Push ────────────────────────────────────────────────────────────
STEP=$(( STEP + 1 )); log_step $STEP "Push to origin"
git push origin "$CURRENT_BRANCH" --set-upstream
log_ok "Pushed $CURRENT_BRANCH → origin."

# ── STEP 12  Create PR ───────────────────────────────────────────────────────
STEP=$(( STEP + 1 )); log_step $STEP "Create pull request → OpenCPN/plugins"
safe_run "pr-create" "pr-create.sh" "$PACKAGE" "$VERSION" "$OWNER" "$REPO"

# ── Summary ──────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}╔══════════════════════════════════════════════════════════════════════╗"
echo -e "║                        Pipeline Complete                             ║"
echo -e "╚══════════════════════════════════════════════════════════════════════╝${RESET}"
echo -e "  FINISH : $(date '+%Y-%m-%d %H:%M:%S %Z')"

if [[ ${#FAILED_STEPS[@]} -eq 0 ]]; then
    echo -e "\n  ${GREEN}${BOLD}All $TOTAL_STEPS steps passed.${RESET}\n"; exit 0
else
    echo -e "\n  ${RED}${BOLD}${#FAILED_STEPS[@]} step(s) failed:${RESET}"
    printf "    ${RED}• %s${RESET}\n" "${FAILED_STEPS[@]}"
    echo -e "\n  ${YELLOW}Review the output above and re-run failing steps individually.${RESET}\n"
    exit 1
fi
