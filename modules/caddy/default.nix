{
  pkgs,
  vars,
  ...
}: let
  caddyfile = ./Caddyfile;
in {
  systemd.user.services.caddy = {
    Unit = {
      Description = "Caddy reverse proxy (DuckDNS)";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${vars.pkgs.caddy-duckdns}/bin/caddy run --config ${caddyfile} --adapter caddyfile";
      ExecReload = "${vars.pkgs.caddy-duckdns}/bin/caddy reload --config ${caddyfile} --adapter caddyfile";
      Restart = "always";
      RestartSec = "5s";
      EnvironmentFile = "${vars.mediaRoot}/.env";
    };
    Install.WantedBy = ["default.target"];
  };
}
