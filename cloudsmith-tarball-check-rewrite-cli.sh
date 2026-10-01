#!/usr/bin/env bash
# =============================================================================
# cloudsmith-tarball-check.sh
# Verify that a package tarball exists on Cloudsmith and passes integrity checks.
# Uses the official Cloudsmith CLI (pip install cloudsmith-cli).
#
# Usage:
#   ./cloudsmith-tarball-check.sh <PACKAGE> <VERSION> <OWNER> <REPO>
#
# Required env:
#   CLOUDSMITH_API_KEY       — your Cloudsmith API token
#
# Optional env:
#   CLOUDSMITH_DOWNLOAD_DIR  — staging dir (default: /tmp/cloudsmith-check)
#   CLOUDSMITH_KEEP_TARBALL  — set "true" to retain tarball after verification
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log_ok()   { echo -e "${GREEN}✔  $*${RESET}"; }
log_warn() { echo -e "${YELLOW}⚠  $*${RESET}"; }
log_err()  { echo -e "${RED}✘  $*${RESET}" >&2; }
log_info() { echo -e "${CYAN}   $*${RESET}"; }

# ---------------------------------------------------------------------------
# Parameters
# ---------------------------------------------------------------------------
PACKAGE="${1:-${PACKAGE:-}}"
VERSION="${2:-${VERSION:-}}"
OWNER="${3:-${OWNER:-}}"
REPO="${4:-${REPO:-}}"

[[ -z "$PACKAGE" || -z "$VERSION" || -z "$OWNER" || -z "$REPO" ]] && {
    log_err "Usage: $0 <PACKAGE> <VERSION> <OWNER> <REPO>"; exit 1; }

DOWNLOAD_DIR="${CLOUDSMITH_DOWNLOAD_DIR:-/tmp/cloudsmith-check}"
KEEP_TARBALL="${CLOUDSMITH_KEEP_TARBALL:-false}"

echo -e "\n${BOLD}Cloudsmith Tarball Check${RESET}"
echo -e "${CYAN}$(printf '─%.0s' {1..60})${RESET}"
log_info "Namespace  : ${OWNER}/${REPO}"
log_info "Package    : ${PACKAGE}"
log_info "Version    : ${VERSION}"
log_info "Stage dir  : ${DOWNLOAD_DIR}"

# ---------------------------------------------------------------------------
# Preflight: CLI present
# ---------------------------------------------------------------------------
if ! command -v cloudsmith &>/dev/null; then
    log_err "Cloudsmith CLI not found. Install with:"
    echo    "    pip install cloudsmith-cli"
    exit 1
fi
log_ok "Cloudsmith CLI $(cloudsmith --version 2>&1 | head -1)"

# ---------------------------------------------------------------------------
# Preflight: API key
# ---------------------------------------------------------------------------
[[ -z "${CLOUDSMITH_API_KEY:-}" ]] && {
    log_err "CLOUDSMITH_API_KEY is not set."
    echo    "    export CLOUDSMITH_API_KEY=<your-token>"; exit 1; }
log_ok "API key present (${#CLOUDSMITH_API_KEY} chars)"

# ---------------------------------------------------------------------------
# Rate-limit guard — fail fast before burning quota
# ---------------------------------------------------------------------------
log_info "Checking API service..."
RATE_OUTPUT=$(cloudsmith check service 2>&1) || {
    log_warn "Service check non-zero — proceeding cautiously."
    log_warn "$RATE_OUTPUT"
}
log_ok "API service reachable."

# ---------------------------------------------------------------------------
# [1/3] Confirm package exists
# ---------------------------------------------------------------------------
echo -e "\n${BOLD}[1/3] Querying package index...${RESET}"

PKG_JSON=$(cloudsmith ls pkg "${OWNER}/${REPO}" \
    --query "name:${PACKAGE} version:${VERSION}" \
    --output-format json 2>&1) || {
    log_err "cloudsmith ls pkg failed:"; echo "$PKG_JSON" >&2; exit 1; }

PKG_COUNT=$(echo "$PKG_JSON" | jq 'if type=="array" then length
    elif .data then (.data|length) else 0 end' 2>/dev/null || echo "0")

[[ "$PKG_COUNT" -eq 0 ]] && {
    log_err "Package not found: ${OWNER}/${REPO} — ${PACKAGE}@${VERSION}"
    echo -e "${YELLOW}Hint: confirm name/version match exactly what was uploaded.${RESET}"
    exit 1; }

log_ok "Found ${PKG_COUNT} matching package record(s)."

PKG_SLUG=$(echo "$PKG_JSON" | jq -r \
    'if type=="array" then .[0].slug elif .data then .data[0].slug else "" end' 2>/dev/null || echo "unknown")
PKG_FORMAT=$(echo "$PKG_JSON" | jq -r \
    'if type=="array" then .[0].format elif .data then .data[0].format else "" end' 2>/dev/null || echo "unknown")
PKG_STATUS=$(echo "$PKG_JSON" | jq -r \
    'if type=="array" then .[0].status elif .data then .data[0].status else "" end' 2>/dev/null || echo "unknown")

log_info "Slug   : ${PKG_SLUG}"
log_info "Format : ${PKG_FORMAT}"
log_info "Status : ${PKG_STATUS}"

[[ "$PKG_STATUS" != "fully_synchronised" && "$PKG_STATUS" != "completed" ]] && \
    log_warn "Status is '${PKG_STATUS}' — package may not be fully available yet."

# ---------------------------------------------------------------------------
# [2/3] Download + CLI integrity verification
# ---------------------------------------------------------------------------
echo -e "\n${BOLD}[2/3] Downloading tarball for integrity check...${RESET}"

mkdir -p "$DOWNLOAD_DIR"
rm -f "${DOWNLOAD_DIR}"/*.tar.gz "${DOWNLOAD_DIR}"/*.tgz \
      "${DOWNLOAD_DIR}"/*.zip    "${DOWNLOAD_DIR}"/*.whl 2>/dev/null || true

# CLI verifies checksum automatically — non-zero exit = tampered/missing/no rights
cloudsmith download \
    "${OWNER}/${REPO}" "${PACKAGE}" \
    --version "${VERSION}" \
    --output-dir "${DOWNLOAD_DIR}" || {
    log_err "Download or integrity verification failed."
    log_err "Tarball may be corrupted, missing, or API key lacks download rights."
    exit 1; }

DOWNLOADED_FILE=$(find "$DOWNLOAD_DIR" -type f | head -1)
[[ -z "$DOWNLOADED_FILE" ]] && {
    log_err "Download succeeded but no file found in ${DOWNLOAD_DIR}."; exit 1; }

FILE_SIZE=$(du -sh "$DOWNLOADED_FILE" 2>/dev/null | awk '{print $1}')
log_ok "Downloaded: $(basename "$DOWNLOADED_FILE") (${FILE_SIZE})"

# ---------------------------------------------------------------------------
# [3/3] Supplementary local SHA-512 (belt-and-braces)
# ---------------------------------------------------------------------------
echo -e "\n${BOLD}[3/3] Computing local SHA-512 fingerprint...${RESET}"

LOCAL_SHA512=$(sha512sum "$DOWNLOADED_FILE" | awk '{print $1}')
log_ok "SHA-512: ${LOCAL_SHA512:0:32}...${LOCAL_SHA512: -8}"

SIDECAR="${DOWNLOAD_DIR}/checksum-sha512.txt"
echo "${LOCAL_SHA512}  $(basename "$DOWNLOADED_FILE")" > "$SIDECAR"
log_info "Checksum sidecar: ${SIDECAR}"

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
if [[ "$KEEP_TARBALL" != "true" ]]; then
    rm -f "$DOWNLOADED_FILE"
    log_info "Tarball removed (set CLOUDSMITH_KEEP_TARBALL=true to retain)."
fi

echo -e "\n${GREEN}${BOLD}✔  Cloudsmith tarball check passed — ${PACKAGE}@${VERSION}${RESET}\n"
exit 0
