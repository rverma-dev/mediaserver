#!/usr/bin/env bash
# Nix: install Determinate Nix (if missing), apply home-manager config

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env || true

if ! command -v nix &>/dev/null; then
    info "Installing Determinate Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
    info "Nix installed. Source the daemon script or open a new shell."
    if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        # shellcheck disable=SC1091
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
fi

nix --version || error "Nix not available in PATH. Open a new shell and re-run."

info "Building home-manager config..."
cd "${MEDIASERVER_ROOT}"
nix run home-manager -- switch --flake '.#pi' -b backup

# Grant Caddy binary the ability to bind to privileged ports
CADDY_BIN=$(readlink -f "$(command -v caddy 2>/dev/null)" || true)
if [[ -n "$CADDY_BIN" ]]; then
    info "Setting CAP_NET_BIND_SERVICE on Caddy binary..."
    sudo setcap 'cap_net_bind_service=+ep' "$CADDY_BIN" 2>/dev/null || warn "Could not set cap on Caddy."
fi

info "Nix setup complete. Services: systemctl --user status caddy sonarr radarr jellyfin"
