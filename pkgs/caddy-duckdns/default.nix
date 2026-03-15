# Build Caddy with DuckDNS plugin via nixpkgs caddy.withPlugins.
# Previously fetched pre-built binaries from GitHub releases (404).
{pkgs, lib}:
  pkgs.caddy.withPlugins {
    plugins = ["github.com/caddy-dns/duckdns@v0.5.0"];
    hash = "sha256-uMYFZJ+dOoahO9+nAU+bGiuFQRmPbPWFwH1uH8xBcFQ=";
  }
