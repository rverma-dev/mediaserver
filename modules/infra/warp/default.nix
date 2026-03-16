{pkgs, vars, ...}: {
  systemd.user.services.wireproxy = {
    Unit = {
      Description = "wireproxy - Cloudflare WARP via WireGuard (SOCKS5 proxy)";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${pkgs.wireproxy}/bin/wireproxy -c ${vars.mediaRoot}/config/warp/wireproxy.conf";
      Restart = "always";
      RestartSec = "5s";
    };
    Install.WantedBy = ["default.target"];
  };
}
