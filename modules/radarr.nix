{
  vars,
  ...
}: {
  systemd.user.services.radarr = {
    Unit = {
      Description = "Radarr - Movie automation";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${vars.pkgs.radarr}/bin/radarr --nobrowser --data=/opt/mediaserver/config/radarr";
      Restart = "always";
      RestartSec = "5s";
    };
    Install.WantedBy = ["default.target"];
  };
}
