#!/usr/bin/env bash
# Apply sysctl tuning to prevent large writeback bursts that can stall the system.
# Run once (or after kernel update): sudo ./scripts/init-sysctl.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

[[ $EUID -eq 0 ]] || error "Run as root: sudo ./scripts/init-sysctl.sh"

CONF="/etc/sysctl.d/99-mediaserver-nvme.conf"
info "Writing $CONF..."
cat <<'EOF' | tee "$CONF"
# Mediaserver: prevent large writeback bursts that can stall system
vm.dirty_ratio=10
vm.dirty_background_ratio=5
EOF
sudo sysctl -p "$CONF"
info "Sysctl applied."
