#!/usr/bin/env bash
set -euo pipefail

# Raspberry Pi 5 Media Server - Fresh Install Script
# Run on a fresh Pi OS Lite (Trixie) with NVMe boot
# Usage: git clone git@github.com:rverma-dev/mediaserver.git /opt/mediaserver && /opt/mediaserver/init.sh

MEDIASERVER_ROOT="/opt/mediaserver"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

[[ $EUID -eq 0 ]] && error "Do not run as root. Script uses sudo where needed."

info "=== Raspberry Pi 5 Media Server Setup ==="
echo ""

# --- System update ---
info "Updating system packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git

# --- Verify NVMe ---
ROOT_DEV=$(df -h / | awk 'NR==2 {print $1}')
info "Root: ${ROOT_DEV}"
echo "$ROOT_DEV" | grep -q "nvme" && info "NVMe boot confirmed." || warn "Not on NVMe."

# --- Docker ---
if command -v docker &>/dev/null; then
    info "Docker: $(docker --version)"
else
    info "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
    warn "Added to docker group. Log out/in if docker commands fail."
fi
docker compose version &>/dev/null || error "Docker Compose not found."
sudo systemctl enable docker

# --- Create data directories (not in git) ---
info "Creating data directories..."
sudo mkdir -p "${MEDIASERVER_ROOT}/data"/{torrents/{complete,incomplete},media/{movies,tv}}

# --- Create config dirs for services that need them (not in git) ---
sudo mkdir -p "${MEDIASERVER_ROOT}/config"/{warp,caddy/{data,config}}

# --- Fix ownership ---
sudo chown -R 1000:1000 "${MEDIASERVER_ROOT}"

# --- Static IP ---
CURRENT_IP=$(hostname -I | awk '{print $1}')
ACTIVE_CON=$(nmcli -t -f NAME,DEVICE con show --active | grep -v "docker\|br-\|lo" | head -1 | cut -d: -f1)
if [ -n "$ACTIVE_CON" ]; then
    CURRENT_METHOD=$(nmcli -g ipv4.method con show "$ACTIVE_CON")
    if [ "$CURRENT_METHOD" = "auto" ]; then
        info "Setting static IP: ${CURRENT_IP}..."
        GATEWAY=$(ip route | awk '/default/ {print $3; exit}')
        SUBNET=$(ip -o -f inet addr show | grep "$CURRENT_IP" | awk '{print $4}')
        sudo nmcli con mod "$ACTIVE_CON" ipv4.method manual \
            ipv4.addresses "$SUBNET" \
            ipv4.gateway "$GATEWAY" \
            ipv4.dns "1.1.1.1,8.8.8.8"
        sudo nmcli con down "$ACTIVE_CON" && sudo nmcli con up "$ACTIVE_CON"
        info "Static IP set: $SUBNET, gateway: $GATEWAY"
    else
        info "IP already static: $CURRENT_IP"
    fi
fi

# --- Deploy ---
info "Pulling images..."
cd "${MEDIASERVER_ROOT}"
docker compose pull

info "Starting services..."
docker compose up -d

# --- Verify ---
echo ""
info "All services:"
docker compose ps --format "table {{.Name}}\t{{.Status}}"
echo ""
PI_IP=$(hostname -I | awk '{print $1}')
info "Access everything at: http://${PI_IP}"
echo "  /jellyfin   - Media streaming"
echo "  /qbit       - Torrent client"
echo "  /sonarr     - TV automation"
echo "  /radarr     - Movie automation"
echo "  /prowlarr   - Indexer management"
echo "  /bazarr     - Subtitles"
echo ""
info "Credentials: admin / abcdef (all services)"
info "Setup complete."
