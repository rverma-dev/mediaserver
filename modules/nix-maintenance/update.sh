#!/usr/bin/env bash
# WorkingDirectory is set by the systemd unit; run in repo root
set -euo pipefail
nix flake update
nix run home-manager -- switch --flake '.#pi' -b backup
