#!/usr/bin/env bash
# Apply Nix home-manager config and verify services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env || true

PI_IP=$(hostname -I | awk '{print $1}')

info "Service status:"
systemctl --user list-units --type=service --state=running | grep -E '(caddy|openclaw|sonarr|radarr|prowlarr|bazarr|jellyfin|seerr|qbittorrent)' || true
echo ""

info "Access URLs:"
[[ -n "${DUCKDNS_SUBDOMAIN:-}" ]] && echo "  HTTPS (DuckDNS): https://${DUCKDNS_SUBDOMAIN}.duckdns.org"
echo "  LAN:            http://${PI_IP}"
echo ""
echo "  /jellyfin   - Media streaming"
echo "  /qbit       - Torrent client"
echo "  /sonarr     - TV automation"
echo "  /radarr     - Movie automation"
echo "  /prowlarr   - Indexer management"
echo "  /bazarr     - Subtitles"
echo "  /seerr      - Media requests"
echo "  /           - OpenClaw (catch-all)"
echo ""
info "Setup complete."
