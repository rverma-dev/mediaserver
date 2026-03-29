#!/usr/bin/env bash
# One-time system hardening: dirs, sysctl, hosts, firewall, apt.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env || true

PUID="${PUID:-1000}"
PGID="${PGID:-1000}"
USER="${USER:-pi}"

# when the user is not logged in (e.g. after SSH disconnect or on headless boot).
if ! loginctl show-user "${USER}" 2>/dev/null | grep -q 'Linger=yes'; then
    info "Enabling linger for ${USER} (user services persist without login)..."
    sudo loginctl enable-linger "${USER}"
fi

info "Creating config directories..."
sudo mkdir -p "${MEDIASERVER_ROOT}/config"/{warp,angie,qbittorrent,sonarr,radarr,prowlarr,bazarr,seerr,immich}
sudo mount -a 2>/dev/null || true
# Only fix ownership on first run (marker file avoids slow chown -R on re-runs)
if [[ ! -f "${MEDIASERVER_ROOT}/.init-done" ]]; then
    sudo chown -R "${PUID}:${PGID}" "${MEDIASERVER_ROOT}"
fi

SYSCTL_CONF="/etc/sysctl.d/99-mediaserver-nvme.conf"
sysctl_desired=$(cat <<'EOF'
vm.dirty_ratio=10
vm.dirty_background_ratio=5
vm.overcommit_memory=1
EOF
)
if write_if_changed "$SYSCTL_CONF" "$sysctl_desired"; then
    info "Sysctl tuning: no changes"
else
    grep -q 'vm.overcommit_memory' "$SYSCTL_CONF" 2>/dev/null || echo 'vm.overcommit_memory=1' | sudo tee -a "$SYSCTL_CONF" >/dev/null
    sudo sysctl -p "$SYSCTL_CONF" 2>/dev/null || true
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

# Optional: static LAN IP (e.g. to match DuckDNS mapping 192.168.68.60)
if [[ -n "${PI_LAN_IP:-}" && -n "${PI_LAN_GW:-}" ]]; then
    if command -v dhcpcd &>/dev/null; then
        IFACE=$(ip -o -4 route show to default 2>/dev/null | awk '{print $5}' | head -1)
        if [[ -n "$IFACE" ]]; then
            sudo mkdir -p /etc/dhcpcd.conf.d
            DEST="/etc/dhcpcd.conf.d/99-mediaserver-static.conf"
            DESIRED="interface $IFACE
static ip_address=${PI_LAN_IP}/24
static routers=${PI_LAN_GW}
static domain_name_servers=${PI_LAN_GW}"
            if [[ ! -f "$DEST" ]] || ! diff -q <(echo "$DESIRED") "$DEST" &>/dev/null; then
                info "Configuring static IP ${PI_LAN_IP} on $IFACE (gateway ${PI_LAN_GW})..."
                sudo mkdir -p "$(dirname "$DEST")"
                echo "$DESIRED" | sudo tee "$DEST" >/dev/null
                info "Static IP configured. Reboot or restart dhcpcd to apply."
            else
                info "Static IP ${PI_LAN_IP} already configured"
            fi
        else
            warn "Could not detect default interface — skipping static IP"
        fi
    else
        warn "dhcpcd not found — set static IP manually (router DHCP reservation recommended)"
    fi
elif [[ -n "${PI_LAN_IP:-}" ]]; then
    warn "PI_LAN_IP set but PI_LAN_GW missing — skipping static IP (router DHCP reservation is an alternative)"
fi

if command -v ufw &>/dev/null; then
    ufw_status=$(sudo ufw status 2>/dev/null)
    ufw_active=$(echo "$ufw_status" | grep -q "^Status: active" && echo yes || echo no)
    ufw_ports="22/tcp 80/tcp 443/tcp 9443/tcp 6881/tcp 6881/udp 8554/tcp"
    ufw_missing=()
    for port in $ufw_ports; do
        echo "$ufw_status" | grep -q "^${port%/*}.*${port##*/}" || ufw_missing+=("$port")
    done
    if [[ "$ufw_active" == yes && ${#ufw_missing[@]} -eq 0 ]]; then
        info "UFW: no changes"
    else
        info "UFW: applying rules..."
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        for port in $ufw_ports; do sudo ufw allow "$port"; done
        sudo ufw --force enable 2>/dev/null || warn "UFW enable failed"
    fi
else
    warn "UFW not installed. Consider: sudo apt install ufw"
fi

if command -v fail2ban-client &>/dev/null; then
    if systemctl is-enabled fail2ban &>/dev/null && systemctl is-active fail2ban &>/dev/null; then
        info "Fail2ban: already enabled and running"
    else
        info "Fail2ban: enabling..."
        sudo systemctl enable fail2ban
        sudo systemctl start fail2ban 2>/dev/null || true
    fi
else
    sudo apt install -y fail2ban 2>/dev/null || warn "Fail2ban install skipped"
fi

AUTO_UPGRADES_CONF="/etc/apt/apt.conf.d/20auto-upgrades"
auto_upgrades_desired=$(cat <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::AutoremoveInterval "7";
EOF
)
if command -v apt-get &>/dev/null; then
    if ! dpkg -s unattended-upgrades &>/dev/null; then
        info "APT: installing unattended-upgrades..."
        apt_updated_recently 3600 || sudo apt-get update -qq
        sudo apt-get install -y unattended-upgrades 2>/dev/null || warn "Could not install unattended-upgrades"
        sudo dpkg-reconfigure -plow unattended-upgrades 2>/dev/null || true
    fi
    if write_if_changed "$AUTO_UPGRADES_CONF" "$auto_upgrades_desired"; then
        info "APT maintenance config: no changes"
    else
        info "APT maintenance config: applied"
        for timer in apt-daily.timer apt-daily-upgrade.timer; do
            systemctl list-unit-files "$timer" &>/dev/null && sudo systemctl enable "$timer" 2>/dev/null || true
        done
    fi
else
    info "APT not available — skipping"
fi

info "System setup complete."
