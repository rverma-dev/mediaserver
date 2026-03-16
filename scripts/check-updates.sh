#!/usr/bin/env bash
# Check upstream GitHub releases for new package versions.
# Called by the weekly-update workflow.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

check_github_release() {
  local name="$1" owner="$2" repo="$3" nix_file="$4" include_prerelease="${5:-false}" strip_build_suffix="${6:-false}"

  current=$(grep 'version = ' "$nix_file" | head -1 | sed 's/.*"\(.*\)".*/\1/')
  [[ "$strip_build_suffix" == "true" ]] && current=$(echo "$current" | sed 's/-[0-9]*$//')

  if [[ "$include_prerelease" == "true" ]]; then
    latest=$(curl -sf "https://api.github.com/repos/${owner}/${repo}/releases" \
      | jq -r 'first | .tag_name' | sed 's/^v//')
  else
    latest=$(curl -sf "https://api.github.com/repos/${owner}/${repo}/releases/latest" \
      | jq -r '.tag_name' | sed 's/^v//')
  fi

  if [[ -z "$latest" || "$latest" == "null" ]]; then
    echo "  ${name}: failed to fetch latest version"
    return
  fi

  if [[ "$current" == "$latest" ]]; then
    echo "  ${name}: ${current} (up to date)"
  else
    echo "  ${name}: ${current} → ${latest} ⬆"
  fi
}

echo "=== Package version check ==="
echo ""

check_github_release "Caddy"    "caddyserver"    "caddy"    "${REPO_ROOT}/pkgs/caddy-duckdns/default.nix" "true"
check_github_release "Sonarr"   "Sonarr"         "Sonarr"   "${REPO_ROOT}/pkgs/sonarr/default.nix"
check_github_release "Radarr"   "Radarr"         "Radarr"   "${REPO_ROOT}/pkgs/radarr/default.nix"
check_github_release "Prowlarr" "Prowlarr"       "Prowlarr" "${REPO_ROOT}/pkgs/prowlarr/default.nix"
check_github_release "Bazarr"   "morpheus65535"   "bazarr"   "${REPO_ROOT}/pkgs/bazarr/default.nix"
check_github_release "Jellyfin" "jellyfin"       "jellyfin" "${REPO_ROOT}/pkgs/jellyfin/default.nix"
# Seerr: strip build suffix (3.0.1-11 → 3.0.1) for comparison; write new version for workflow when update needed
check_seerr() {
  local nix_file="${REPO_ROOT}/pkgs/seerr/default.nix"
  current=$(grep 'version = ' "$nix_file" | head -1 | sed 's/.*"\(.*\)".*/\1/' | sed 's/-[0-9]*$//')
  latest=$(curl -sf "https://api.github.com/repos/seerr-team/seerr/releases/latest" | jq -r '.tag_name' | sed 's/^v//')
  if [[ -z "$latest" || "$latest" == "null" ]]; then
    echo "  Seerr: failed to fetch latest version"
    return
  fi
  if [[ "$current" == "$latest" ]]; then
    echo "  Seerr: ${current} (up to date)"
    rm -f "${REPO_ROOT}/.seerr-new-version"
  else
    echo "  Seerr: ${current} → ${latest} ⬆"
    echo "$latest" > "${REPO_ROOT}/.seerr-new-version"
  fi
}
check_seerr

echo ""
echo "=== Flake inputs ==="
nix flake update --commit-lock-file 2>&1 | grep -E '(Updated|Added)' || echo "  (all up to date)"

exit 0
