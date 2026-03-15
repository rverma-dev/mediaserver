#!/usr/bin/env bash
# Add DuckDNS hostname to /etc/hosts so Seerr can reach Radarr/Sonarr locally
# (avoids proxychains hairpin via public IP which often fails on home networks)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env 2>/dev/null || true

[[ -z "${DUCKDNS_SUBDOMAIN:-}" ]] && { warn "DUCKDNS_SUBDOMAIN not set — skipping hosts entry"; exit 0; }

HOSTNAME="${DUCKDNS_SUBDOMAIN}.duckdns.org"
HOSTS_LINE="127.0.0.1 ${HOSTNAME}"

if grep -qF "${HOSTS_LINE}" /etc/hosts 2>/dev/null; then
    info "Hosts entry for ${HOSTNAME} already present"
else
    info "Adding ${HOSTNAME} -> 127.0.0.1 to /etc/hosts"
    echo "${HOSTS_LINE}" | sudo tee -a /etc/hosts > /dev/null
fi
