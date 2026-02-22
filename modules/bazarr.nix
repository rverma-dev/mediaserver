{
  vars,
  ...
}: {
  systemd.user.services.bazarr = {
    Unit = {
      Description = "Bazarr - Subtitle manager";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${vars.pkgs.bazarr}/bin/bazarr --config /opt/mediaserver/config/bazarr";
      Restart = "always";
      RestartSec = "5s";
    };
    Install.WantedBy = ["default.target"];
  };
}
