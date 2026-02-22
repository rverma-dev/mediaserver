{
  vars,
  ...
}: {
  systemd.user.services.prowlarr = {
    Unit = {
      Description = "Prowlarr - Indexer manager";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${vars.pkgs.prowlarr}/bin/prowlarr --nobrowser --data=/opt/mediaserver/config/prowlarr";
      Restart = "always";
      RestartSec = "5s";
    };
    Install.WantedBy = ["default.target"];
  };
}
