#!/usr/bin/env bash
# Install Determinate Nix (if missing) and apply home-manager config.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env || true

if ! command -v nix &>/dev/null; then
    info "Installing Determinate Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
    if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        # shellcheck disable=SC1091
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
fi

nix --version || error "Nix not available in PATH. Open a new shell and re-run."

info "Building home-manager config..."
cd "${MEDIASERVER_ROOT}"
nix run home-manager -- switch --flake '.#pi' -b backup

info "Nix setup complete. Services: systemctl --user status angie sonarr radarr jellyfin"
