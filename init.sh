#!/usr/bin/env bash
# Raspberry Pi 5 Consolidated Server - Bootstrap
# Usage: git clone ... /opt/mediaserver && cd /opt/mediaserver && cp .env.example .env && ./init.sh
#
# Or run phases individually: ./scripts/init-system.sh, ./scripts/init-deploy.sh, etc.

set -euo pipefail

MEDIASERVER_ROOT="${MEDIASERVER_ROOT:-/opt/mediaserver}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/common.sh"

[[ $EUID -eq 0 ]] && error "Do not run as root. Script uses sudo where needed."

info "=== Raspberry Pi 5 Consolidated Server Setup ==="
echo ""

# --- .env check ---
if [[ ! -f "${MEDIASERVER_ROOT}/.env" ]]; then
    cp "${MEDIASERVER_ROOT}/.env.example" "${MEDIASERVER_ROOT}/.env"
    error ".env created from .env.example. Edit your secrets then re-run init.sh"
fi
load_env
[[ -z "${DUCKDNS_SUBDOMAIN:-}" ]] && warn "DUCKDNS_SUBDOMAIN not set — HTTPS will fail until configured."

# --- Run phases ---
"${SCRIPT_DIR}/scripts/init-dirs.sh"
"${SCRIPT_DIR}/scripts/init-alloy.sh"

# Nix-managed services (all services)
"${SCRIPT_DIR}/scripts/init-nix.sh"

# Final ownership (after nix may have created files)
sudo chown -R "${PUID}:${PGID}" "${MEDIASERVER_ROOT}"

"${SCRIPT_DIR}/scripts/init-network.sh"
"${SCRIPT_DIR}/scripts/init-security.sh"
"${SCRIPT_DIR}/scripts/init-deploy.sh"
