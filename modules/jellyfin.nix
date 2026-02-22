{
  vars,
  ...
}: {
  systemd.user.services.jellyfin = {
    Unit = {
      Description = "Jellyfin media server";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${vars.pkgs.jellyfin}/bin/jellyfin --datadir /opt/mediaserver/config/jellyfin --cachedir /opt/mediaserver/config/jellyfin/cache";
      Restart = "always";
      RestartSec = "5s";
      Environment = [
        "JELLYFIN_PublishedServerUrl=http://192.168.68.60/jellyfin"
      ];
    };
    Install.WantedBy = ["default.target"];
  };
}
