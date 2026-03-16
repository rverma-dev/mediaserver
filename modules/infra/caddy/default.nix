{
  lib,
  pkgs,
  vars,
  ...
}: let
  caddyfile = ./Caddyfile;
  caddyBin = "${vars.pkgs.caddy-duckdns}/bin/caddy";
in {
  home.activation.caddySetcap = lib.hm.dag.entryAfter ["writeBoundary"] ''
    caddy_real=$(readlink -f "${caddyBin}" 2>/dev/null || true)
    if [[ -n "$caddy_real" ]]; then
      /usr/bin/sudo setcap 'cap_net_bind_service=+ep' "$caddy_real" 2>/dev/null || true
    fi
  '';

  systemd.user.services.caddy = {
    Unit = {
      Description = "Caddy reverse proxy (DuckDNS)";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${caddyBin} run --config ${caddyfile} --adapter caddyfile";
      ExecReload = "${caddyBin} reload --config ${caddyfile} --adapter caddyfile";
      Restart = "always";
      RestartSec = "5s";
      EnvironmentFile = "${vars.mediaRoot}/.env";
    };
    Install.WantedBy = ["default.target"];
  };
}
