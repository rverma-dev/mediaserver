#!/usr/bin/env bash
# Bootstrap: cp .env.example .env && ./init.sh

set -euo pipefail

MEDIASERVER_ROOT="${MEDIASERVER_ROOT:-/home/pi/mediaserver}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/common.sh"

[[ $EUID -eq 0 ]] && error "Do not run as root. Script uses sudo where needed."

if [[ ! -f "${MEDIASERVER_ROOT}/.env" ]]; then
    cp "${MEDIASERVER_ROOT}/.env.example" "${MEDIASERVER_ROOT}/.env"
    error ".env created from .env.example. Edit your secrets then re-run init.sh"
fi
load_env
[[ -z "${DUCKDNS_SUBDOMAIN:-}" ]] && warn "DUCKDNS_SUBDOMAIN not set — HTTPS will fail until configured."

"${SCRIPT_DIR}/scripts/init-system.sh"
"${SCRIPT_DIR}/scripts/init-network.sh"
"${SCRIPT_DIR}/scripts/init-hdd.sh" setup
"${SCRIPT_DIR}/scripts/init-nix.sh"

touch "${MEDIASERVER_ROOT}/.init-done"
info "Setup complete. Services: systemctl --user list-units --type=service --state=running"
