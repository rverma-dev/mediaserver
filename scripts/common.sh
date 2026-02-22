#!/usr/bin/env bash
# Shared vars and helpers for init scripts. Source from init.sh or individual scripts.

set -euo pipefail

MEDIASERVER_ROOT="${MEDIASERVER_ROOT:-/opt/mediaserver}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

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
