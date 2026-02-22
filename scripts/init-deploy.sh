#!/usr/bin/env bash
# Docker compose pull/up and verify

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env || true

info "Pulling images..."
cd "${MEDIASERVER_ROOT}"
sudo docker compose pull

info "Starting services..."
sudo docker compose up -d

echo ""
info "Waiting for containers to start..."
sleep 10
info "Container status:"
sudo docker compose ps --format "table {{.Name}}\t{{.Status}}"
echo ""

UNHEALTHY=$(sudo docker compose ps --format json 2>/dev/null | jq -r 'select(.Health == "unhealthy") | .Name' 2>/dev/null || true)
if [[ -n "$UNHEALTHY" ]]; then
    warn "Some containers may be unhealthy: $UNHEALTHY"
fi

PI_IP=$(hostname -I | awk '{print $1}')
info "Access URLs:"
echo "  HTTP (LAN):     http://${PI_IP}"
[[ -n "${DUCKDNS_SUBDOMAIN:-}" ]] && echo "  HTTPS (DuckDNS): https://${DUCKDNS_SUBDOMAIN}.duckdns.org"
echo ""
echo "  /jellyfin   - Media streaming"
echo "  /qbit       - Torrent client"
echo "  /sonarr     - TV automation"
echo "  /radarr     - Movie automation"
echo "  /prowlarr   - Indexer management"
echo "  /bazarr     - Subtitles"
echo "  Seerr       - Landing page (HTTP)"
echo "  OpenClaw    - HTTPS catch-all (WhatsApp, etc.)"
echo ""
info "Setup complete."
