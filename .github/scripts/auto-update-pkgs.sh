#!/usr/bin/env bash
# Auto-update packages from upstream GitHub releases.
# Usage:
#   ./auto-update-pkgs.sh            # report only (safe for local use)
#   ./auto-update-pkgs.sh --update   # check + prefetch hashes + update nix files (CI)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UPDATE=false
[[ "${1:-}" == "--update" ]] && UPDATE=true
CHANGED=()

# GitHub API auth (avoids 60 req/hr anonymous limit)
AUTH=()
[[ -n "${GH_TOKEN:-${GITHUB_TOKEN:-}}" ]] && AUTH=(-H "Authorization: token ${GH_TOKEN:-$GITHUB_TOKEN}")

current_version() { grep -m1 'version = ' "$1" | sed 's/.*"\([^"]*\)".*/\1/'; }

github_latest() {
  curl -sf "${AUTH[@]}" \
    "https://api.github.com/repos/$1/$2/releases/latest" \
    | jq -r '.tag_name' | sed 's/^v//'
}

prefetch_sri() {
  local b32
  b32=$(nix-prefetch-url --type sha256 "$1" 2>/dev/null) || return 1
  nix hash convert --to sri "sha256:$b32"
}

# Replace version and hashes in a nix file.
# Args: file old_ver new_ver [old_hash new_hash]...
apply() {
  local f="$1" old_v="$2" new_v="$3"; shift 3
  sed -i "s|version = \"${old_v}\"|version = \"${new_v}\"|" "$f"
  while (( $# >= 2 )); do
    sed -i "s|hash = \"$1\"|hash = \"$2\"|" "$f"
    shift 2
  done
}

# Dual-arch package (arm64 + amd64 hashes)
update_dual() {
  local name="$1" owner="$2" repo="$3" nix="${REPO_ROOT}/$4"
  local arm64_tpl="$5" amd64_tpl="$6"

  local cur; cur=$(current_version "$nix")
  local lat; lat=$(github_latest "$owner" "$repo")
  [[ -z "$lat" || "$lat" == "null" ]] && { echo "  $name: ✗ fetch failed"; return; }
  [[ "$cur" == "$lat" ]] && { echo "  $name: $cur ✓"; return; }

  echo -n "  $name: $cur → $lat"
  if ! $UPDATE; then echo " ⬆"; return; fi

  echo " — prefetching..."
  local h1 h2
  h1=$(prefetch_sri "${arm64_tpl//VERSION/$lat}") || { echo "    ✗ arm64 prefetch failed"; return; }
  h2=$(prefetch_sri "${amd64_tpl//VERSION/$lat}") || { echo "    ✗ amd64 prefetch failed"; return; }

  mapfile -t old < <(grep -oP 'hash = "\K[^"]+' "$nix")
  apply "$nix" "$cur" "$lat" "${old[0]}" "$h1" "${old[1]}" "$h2"
  CHANGED+=("$name: $cur → $lat")
  echo "    ✓ updated"
}

# Single-arch package (one hash)
update_single() {
  local name="$1" owner="$2" repo="$3" nix="${REPO_ROOT}/$4" url_tpl="$5"

  local cur; cur=$(current_version "$nix")
  local lat; lat=$(github_latest "$owner" "$repo")
  [[ -z "$lat" || "$lat" == "null" ]] && { echo "  $name: ✗ fetch failed"; return; }
  [[ "$cur" == "$lat" ]] && { echo "  $name: $cur ✓"; return; }

  echo -n "  $name: $cur → $lat"
  if ! $UPDATE; then echo " ⬆"; return; fi

  echo " — prefetching..."
  local h
  h=$(prefetch_sri "${url_tpl//VERSION/$lat}") || { echo "    ✗ prefetch failed"; return; }

  local old; old=$(grep -oP 'hash = "\K[^"]+' "$nix" | head -1)
  apply "$nix" "$cur" "$lat" "$old" "$h"
  CHANGED+=("$name: $cur → $lat")
  echo "    ✓ updated"
}

# Seerr: version check only — build handled separately by workflow
check_seerr() {
  local nix="${REPO_ROOT}/pkgs/seerr/default.nix"
  local cur; cur=$(current_version "$nix" | sed 's/-[0-9]*$//')
  local lat; lat=$(github_latest "seerr-team" "seerr")
  [[ -z "$lat" || "$lat" == "null" ]] && { echo "  Seerr: ✗ fetch failed"; return; }

  if [[ "$cur" == "$lat" ]]; then
    echo "  Seerr: $cur ✓"
    rm -f "${REPO_ROOT}/.seerr-new-version"
  else
    echo "  Seerr: $cur → $lat ⬆ (build required)"
    echo "$lat" > "${REPO_ROOT}/.seerr-new-version"
  fi
}

echo "=== Package update check ==="

update_dual "Sonarr" "Sonarr" "Sonarr" "pkgs/sonarr/default.nix" \
  "https://github.com/Sonarr/Sonarr/releases/download/vVERSION/Sonarr.main.VERSION.linux-arm64.tar.gz" \
  "https://github.com/Sonarr/Sonarr/releases/download/vVERSION/Sonarr.main.VERSION.linux-x64.tar.gz"

update_dual "Radarr" "Radarr" "Radarr" "pkgs/radarr/default.nix" \
  "https://github.com/Radarr/Radarr/releases/download/vVERSION/Radarr.master.VERSION.linux-core-arm64.tar.gz" \
  "https://github.com/Radarr/Radarr/releases/download/vVERSION/Radarr.master.VERSION.linux-core-x64.tar.gz"

update_dual "Prowlarr" "Prowlarr" "Prowlarr" "pkgs/prowlarr/default.nix" \
  "https://github.com/Prowlarr/Prowlarr/releases/download/vVERSION/Prowlarr.master.VERSION.linux-core-arm64.tar.gz" \
  "https://github.com/Prowlarr/Prowlarr/releases/download/vVERSION/Prowlarr.master.VERSION.linux-core-x64.tar.gz"

update_single "Bazarr" "morpheus65535" "bazarr" "pkgs/bazarr/default.nix" \
  "https://github.com/morpheus65535/bazarr/releases/download/vVERSION/bazarr.zip"

update_dual "Jellyfin" "jellyfin" "jellyfin" "pkgs/jellyfin/default.nix" \
  "https://repo.jellyfin.org/files/server/linux/latest-stable/arm64/jellyfin_VERSION-arm64.tar.gz" \
  "https://repo.jellyfin.org/files/server/linux/latest-stable/amd64/jellyfin_VERSION-amd64.tar.gz"

check_seerr

# Claw packages: check npm registry, build handled by workflow
check_npm() {
  local name="$1" npm_pkg="$2" nix="${REPO_ROOT}/$3" marker="$4"
  local cur; cur=$(current_version "$nix")
  local lat; lat=$(curl -sf "https://registry.npmjs.org/${npm_pkg}/latest" | jq -r '.version')
  [[ -z "$lat" || "$lat" == "null" ]] && { echo "  $name: ✗ npm fetch failed"; return; }

  if [[ "$cur" == "$lat" ]]; then
    echo "  $name: $cur ✓"
    rm -f "${REPO_ROOT}/.${marker}-new-version"
  else
    echo "  $name: $cur → $lat ⬆ (build required)"
    echo "$lat" > "${REPO_ROOT}/.${marker}-new-version"
  fi
}

check_npm "Claw"        "openclaw"                "pkgs/claw/default.nix"                "claw"
check_npm "Claw Brain"  "openclaw-cursor-brain"   "pkgs/claw-cursor-brain/default.nix"   "claw-brain"

echo ""
echo "Caddy, Immich: via nix flake update (nixpkgs)"
echo "cursor-cli: manual (no version API)"

if (( ${#CHANGED[@]} )); then
  echo ""
  echo "=== Updated ==="
  printf '  %s\n' "${CHANGED[@]}"
fi

# GitHub Actions outputs
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  if (( ${#CHANGED[@]} )) || [[ -f "${REPO_ROOT}/.seerr-new-version" ]] \
     || [[ -f "${REPO_ROOT}/.claw-new-version" ]] || [[ -f "${REPO_ROOT}/.claw-brain-new-version" ]]; then
    echo "has_updates=true" >> "$GITHUB_OUTPUT"
  else
    echo "has_updates=false" >> "$GITHUB_OUTPUT"
  fi
  {
    echo 'summary<<EOF'
    for c in "${CHANGED[@]}"; do echo "- $c"; done
    if [[ -f "${REPO_ROOT}/.seerr-new-version" ]]; then
      echo "- Seerr: → $(cat "${REPO_ROOT}/.seerr-new-version") (build triggered)"
    fi
    if [[ -f "${REPO_ROOT}/.claw-new-version" ]]; then
      echo "- Claw: → $(cat "${REPO_ROOT}/.claw-new-version") (build triggered)"
    fi
    if [[ -f "${REPO_ROOT}/.claw-brain-new-version" ]]; then
      echo "- Claw Brain: → $(cat "${REPO_ROOT}/.claw-brain-new-version") (build triggered)"
    fi
    echo 'EOF'
  } >> "$GITHUB_OUTPUT"
fi
