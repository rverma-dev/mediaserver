{
  pkgs,
  ...
}: {
  home.packages = [pkgs.qbittorrent-nox];

  systemd.user.services.qbittorrent = {
    Unit = {
      Description = "qBittorrent-nox torrent client";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --webui-port=8080 --profile=/opt/mediaserver/config/qbittorrent";
      Restart = "always";
      RestartSec = "5s";
    };
    Install.WantedBy = ["default.target"];
  };
}
