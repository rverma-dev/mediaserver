#!/usr/bin/env bash
# Static IP via NetworkManager

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

CURRENT_IP=$(hostname -I | awk '{print $1}')
ACTIVE_CON=$(nmcli -t -f NAME,DEVICE con show --active 2>/dev/null | grep -v "docker\|br-\|lo" | head -1 | cut -d: -f1)
if [[ -n "$ACTIVE_CON" ]]; then
    CURRENT_METHOD=$(nmcli -g ipv4.method con show "$ACTIVE_CON" 2>/dev/null || echo "auto")
    if [[ "$CURRENT_METHOD" = "auto" ]]; then
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
