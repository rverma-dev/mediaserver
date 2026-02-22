#!/usr/bin/env bash
# Create data and config directories, fix ownership

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env || true
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

info "Creating data directories..."
sudo mkdir -p "${MEDIASERVER_ROOT}/data"/{torrents/{complete,incomplete},media/{movies,tv}}

info "Creating config directories..."
sudo mkdir -p "${MEDIASERVER_ROOT}/config"/{warp,caddy/{data,config},jellyfin,qbittorrent,sonarr,radarr,prowlarr,bazarr,seerr,openclaw}

info "Fixing ownership..."
sudo chown -R "${PUID}:${PGID}" "${MEDIASERVER_ROOT}"
