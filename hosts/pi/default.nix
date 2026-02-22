{
  pkgs,
  vars,
  ...
}: {
  imports = import ../../modules;

  home.username = "pi";
  home.homeDirectory = "/home/pi";
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    vars.pkgs.caddy-duckdns
    vars.pkgs.sonarr
    vars.pkgs.radarr
    vars.pkgs.prowlarr
    vars.pkgs.bazarr
    vars.pkgs.jellyfin
    vars.pkgs.seerr
    git
    curl
    jq
    ripgrep
    python3
    nodejs
    pnpm
    uv
  ];
}
