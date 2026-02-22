{
  pkgs,
  vars,
  ...
}: {
  systemd.user.services.caddy = {
    Unit = {
      Description = "Caddy reverse proxy (DuckDNS)";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${vars.pkgs.caddy-duckdns}/bin/caddy run --config /opt/mediaserver/caddy/Caddyfile --adapter caddyfile";
      ExecReload = "${vars.pkgs.caddy-duckdns}/bin/caddy reload --config /opt/mediaserver/caddy/Caddyfile --adapter caddyfile";
      Restart = "always";
      RestartSec = "5s";
      EnvironmentFile = "/opt/mediaserver/.env";
    };
    Install.WantedBy = ["default.target"];
  };
}
