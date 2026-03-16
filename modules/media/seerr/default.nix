{
  pkgs,
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
        "CONFIG_DIRECTORY=${vars.mediaRoot}/config/seerr"
        "LOG_LEVEL=warn"
        "TZ=${vars.tz}"
        "PORT=5055"
      ];
    };
    Install.WantedBy = ["default.target"];
  };
}
