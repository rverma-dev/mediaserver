{
  vars,
  ...
}: {
  systemd.user.services.sonarr = {
    Unit = {
      Description = "Sonarr - TV automation";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${vars.pkgs.sonarr}/bin/sonarr --nobrowser --data=/opt/mediaserver/config/sonarr";
      Restart = "always";
      RestartSec = "5s";
    };
    Install.WantedBy = ["default.target"];
  };
}
