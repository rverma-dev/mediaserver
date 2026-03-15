#!/usr/bin/env bash
# Create config directories (NVMe). Data dirs (torrents, media, immich) live on HDD at /mnt/hdd.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env || true
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

info "Creating config directories (NVMe)..."
sudo mkdir -p "${MEDIASERVER_ROOT}/config"/{warp,caddy/{data,config},jellyfin,qbittorrent,sonarr,radarr,prowlarr,bazarr,seerr}

# Mount HDD if in fstab; init-hdd creates downloads/media/immich layout
sudo mount -a 2>/dev/null || true

info "Fixing ownership..."
sudo chown -R "${PUID}:${PGID}" "${MEDIASERVER_ROOT}"
