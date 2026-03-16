#!/usr/bin/env bash
# One-time system hardening: dirs, sysctl, hosts, firewall, apt.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env || true

PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

info "Creating config directories..."
sudo mkdir -p "${MEDIASERVER_ROOT}/config"/{warp,caddy/{data,config},jellyfin,qbittorrent,sonarr,radarr,prowlarr,bazarr,seerr}
sudo mount -a 2>/dev/null || true
# Only fix ownership on first run (marker file avoids slow chown -R on re-runs)
if [[ ! -f "${MEDIASERVER_ROOT}/.init-done" ]]; then
    sudo chown -R "${PUID}:${PGID}" "${MEDIASERVER_ROOT}"
fi

SYSCTL_CONF="/etc/sysctl.d/99-mediaserver-nvme.conf"
if [[ ! -f "$SYSCTL_CONF" ]]; then
    info "Writing sysctl tuning ($SYSCTL_CONF)..."
    cat <<'EOF' | sudo tee "$SYSCTL_CONF" >/dev/null
vm.dirty_ratio=10
vm.dirty_background_ratio=5
EOF
    sudo sysctl -p "$SYSCTL_CONF"
else
    info "Sysctl tuning already in place"
fi

if [[ -n "${DUCKDNS_SUBDOMAIN:-}" ]]; then
    HOSTNAME="${DUCKDNS_SUBDOMAIN}.duckdns.org"
    HOSTS_LINE="127.0.0.1 ${HOSTNAME}"
    if grep -qF "${HOSTS_LINE}" /etc/hosts 2>/dev/null; then
        info "Hosts entry for ${HOSTNAME} already present"
    else
        info "Adding ${HOSTNAME} -> 127.0.0.1 to /etc/hosts"
        echo "${HOSTS_LINE}" | sudo tee -a /etc/hosts >/dev/null
    fi
else
    warn "DUCKDNS_SUBDOMAIN not set — skipping hosts entry"
fi

if command -v ufw &>/dev/null; then
    info "Configuring UFW..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 22/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 9443/tcp
    sudo ufw allow 6881/tcp
    sudo ufw allow 6881/udp
    sudo ufw allow 8554/tcp
    sudo ufw --force enable 2>/dev/null || warn "UFW enable failed"
else
    warn "UFW not installed. Consider: sudo apt install ufw"
fi

if command -v fail2ban-client &>/dev/null; then
    info "Enabling Fail2ban..."
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban 2>/dev/null || true
else
    sudo apt install -y fail2ban 2>/dev/null || warn "Fail2ban install skipped"
fi

if command -v apt-get &>/dev/null; then
    info "Configuring unattended-upgrades..."
    sudo apt-get update -qq
    sudo apt-get install -y unattended-upgrades 2>/dev/null || warn "Could not install unattended-upgrades"
    sudo dpkg-reconfigure -plow unattended-upgrades 2>/dev/null || true

    sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::AutoremoveInterval "7";
EOF

    if systemctl list-unit-files apt-daily.timer &>/dev/null; then
        sudo systemctl enable apt-daily.timer 2>/dev/null || true
        sudo systemctl enable apt-daily-upgrade.timer 2>/dev/null || true
    fi
    info "APT maintenance configured"
else
    info "APT not available — skipping"
fi

info "System setup complete."
