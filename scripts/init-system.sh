#!/usr/bin/env bash
# System: apt, Docker, daemon config

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env || true

[[ $EUID -eq 0 ]] && error "Do not run as root."

info "Updating system packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git jq

ROOT_DEV=$(df -h / | awk 'NR==2 {print $1}')
info "Root: ${ROOT_DEV}"
echo "$ROOT_DEV" | grep -q "nvme" && info "NVMe boot confirmed." || warn "Not on NVMe."

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

info "Configuring Docker daemon..."
sudo mkdir -p /etc/docker
sudo cp "${MEDIASERVER_ROOT}/docker/daemon.json" /etc/docker/daemon.json
sudo systemctl restart docker
info "Docker daemon configured (journald)."
