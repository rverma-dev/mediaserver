#!/usr/bin/env bash
# Run once: generates WireGuard profile from Cloudflare WARP registration
# Usage: nix shell nixpkgs#wgcf && bash scripts/init-warp.sh

set -euo pipefail
CONF_DIR="${MEDIASERVER_ROOT:-/home/pi/mediaserver}/config/warp"
mkdir -p "$CONF_DIR"
cd "$CONF_DIR"

if [ -f wireproxy.conf ]; then
  echo "wireproxy.conf already exists. Delete it to re-register."
  exit 0
fi

wgcf register --accept-tos
wgcf generate

# Convert wgcf-profile.conf → wireproxy.conf
# wireproxy needs the WireGuard config + a [Socks5] section
cat wgcf-profile.conf > wireproxy.conf
cat >> wireproxy.conf <<'EOF'

[Socks5]
BindAddress = 127.0.0.1:1080
EOF

echo "Done. wireproxy.conf created at $CONF_DIR/wireproxy.conf"
echo "Start with: systemctl --user restart wireproxy"
