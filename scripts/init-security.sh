#!/usr/bin/env bash
# UFW and Fail2ban

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

info "Configuring UFW..."
if command -v ufw &>/dev/null; then
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 22/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 9443/tcp
    sudo ufw allow 6881/tcp
    sudo ufw allow 6881/udp
    sudo ufw allow 8554/tcp  # camera-mock RTSP
    sudo ufw --force enable 2>/dev/null || warn "UFW enable failed (may need manual setup)."
else
    warn "UFW not installed. Consider: sudo apt install ufw"
fi

info "Configuring Fail2ban..."
if command -v fail2ban-client &>/dev/null; then
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban 2>/dev/null || true
else
    sudo apt install -y fail2ban 2>/dev/null || warn "Fail2ban install skipped."
fi
