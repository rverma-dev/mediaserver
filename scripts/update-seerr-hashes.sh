#!/usr/bin/env bash
# Fetch Seerr release hashes and update pkgs/seerr/default.nix.
# Run after .github/workflows/build-seerr.yml creates a release.
#
# Usage: ./scripts/update-seerr-hashes.sh [version]
#   version: optional, defaults to value in pkgs/seerr/default.nix

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
NIX_FILE="${REPO_ROOT}/pkgs/seerr/default.nix"
REPO="rverma-dev/mediaserver"

version="${1:-}"
if [[ -z "$version" ]]; then
  version=$(grep -E '^\s+version\s*=' "$NIX_FILE" | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
fi

tag="seerr-v${version}"
base_url="https://github.com/${REPO}/releases/download/${tag}"
arm64_url="${base_url}/seerr-linux-arm64.tar.gz"
amd64_url="${base_url}/seerr-linux-amd64.tar.gz"

echo "Fetching hashes for Seerr ${version}..."
arm64_hash=$(nix-prefetch-url "$arm64_url" 2>/dev/null || {
  echo "Failed to fetch $arm64_url — is release $tag published?" >&2
  exit 1
})
amd64_hash=$(nix-prefetch-url "$amd64_url" 2>/dev/null || {
  echo "Failed to fetch $amd64_url — is release $tag published?" >&2
  exit 1
})

# Convert to SRI format
arm64_sri="sha256-$(echo -n "$arm64_hash" | xxd -r -p | base64 -w0)"
amd64_sri="sha256-$(echo -n "$amd64_hash" | xxd -r -p | base64 -w0)"

echo "  linux_arm64: $arm64_sri"
echo "  linux_amd64: $amd64_sri"

# Update the nix file (match any existing hash)
sed -i "s|hash = \"[^\"]*\";  # arm64|hash = \"${arm64_sri}\";  # arm64|" "$NIX_FILE"
sed -i "s|hash = \"[^\"]*\";  # amd64|hash = \"${amd64_sri}\";  # amd64|" "$NIX_FILE"

echo "Updated $NIX_FILE"
