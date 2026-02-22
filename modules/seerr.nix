{
  vars,
  ...
}: {
  systemd.user.services.seerr = {
    Unit = {
      Description = "Seerr - Media request manager";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${vars.pkgs.seerr}/bin/seerr";
      Restart = "always";
      RestartSec = "5s";
      Environment = [
        "CONFIG_DIRECTORY=/opt/mediaserver/config/seerr"
        "LOG_LEVEL=warn"
        "TZ=Asia/Kolkata"
        "PORT=5055"
      ];
    };
    Install.WantedBy = ["default.target"];
  };
}
