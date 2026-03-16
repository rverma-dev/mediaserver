#!/usr/bin/env bash
# Shared vars and helpers for init scripts. Source from init.sh or individual scripts.

set -euo pipefail

MEDIASERVER_ROOT="${MEDIASERVER_ROOT:-/home/pi/mediaserver}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# write_if_changed <path> <content>
# Writes content to path only if it differs from current content (or file doesn't exist).
# Returns 0 if no change was needed, 1 if the file was written.
write_if_changed() {
    local path="$1"
    local content="$2"
    if [[ -f "$path" ]] && diff -q <(echo "$content") "$path" &>/dev/null; then
        return 0
    fi
    echo "$content" | sudo tee "$path" >/dev/null
    return 1
}

# apt_updated_recently <seconds>
# Returns 0 if apt package lists were updated within <seconds> ago.
apt_updated_recently() {
    local max_age="${1:-3600}"
    local stamp
    stamp=$(find /var/lib/apt/lists -maxdepth 1 -name "*.InRelease" -printf '%T@\n' 2>/dev/null | sort -n | tail -1)
    [[ -n "$stamp" ]] && (( $(date +%s) - ${stamp%.*} < max_age ))
}

load_env() {
    [[ -f "${MEDIASERVER_ROOT}/.env" ]] || return 1
    set -a
    source "${MEDIASERVER_ROOT}/.env" 2>/dev/null || true
    set +a
    PUID=$(grep -E '^PUID=' "${MEDIASERVER_ROOT}/.env" 2>/dev/null | cut -d= -f2) || PUID=1000
    PGID=$(grep -E '^PGID=' "${MEDIASERVER_ROOT}/.env" 2>/dev/null | cut -d= -f2) || PGID=1000
    DUCKDNS_SUBDOMAIN=$(grep -E '^DUCKDNS_SUBDOMAIN=' "${MEDIASERVER_ROOT}/.env" 2>/dev/null | cut -d= -f2-)
    return 0
}
