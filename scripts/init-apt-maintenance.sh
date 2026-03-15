#!/usr/bin/env bash
# Configure automatic APT updates and periodic cleanup on Raspberry Pi OS (Debian).
# - unattended-upgrades: installs security & recommended updates daily
# - APT periodic: update lists, upgrade, autoremove, autoclean on schedule

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

[[ $(uname -s) == "Linux" ]] || { warn "Skipping apt maintenance (non-Linux)"; exit 0; }
command -v apt-get &>/dev/null || { warn "apt-get not found; skipping apt maintenance"; exit 0; }

info "Configuring unattended-upgrades..."
sudo apt-get update -qq
sudo apt-get install -y unattended-upgrades 2>/dev/null || { warn "Could not install unattended-upgrades"; exit 1; }

# Enable automatic updates (security + recommended)
sudo dpkg-reconfigure -plow unattended-upgrades 2>/dev/null || true

# APT periodic: daily update/upgrade, weekly autoremove & autoclean
sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::AutoremoveInterval "7";
EOF

# Ensure unattended-upgrades timer is active
if systemctl list-unit-files apt-daily.timer &>/dev/null; then
    sudo systemctl enable apt-daily.timer 2>/dev/null || true
    sudo systemctl enable apt-daily-upgrade.timer 2>/dev/null || true
fi

info "APT maintenance configured: daily updates, weekly autoremove/autoclean"
