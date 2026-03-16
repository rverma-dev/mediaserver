{
  lib,
  vars,
  ...
}: let
  cfg = vars.cameraMock;
in {
  home.activation.seedCameraMockConfig = lib.mkIf cfg.enable (lib.hm.dag.entryAfter ["writeBoundary"] ''
    cm_config="${vars.mediaRoot}/config/camera-mock"
    if [[ ! -f "$cm_config/config.yaml" ]]; then
      mkdir -p "$cm_config"
      cp ${./seed/config.yaml} "$cm_config/config.yaml"
      chmod 600 "$cm_config/config.yaml"
      echo "Seeded camera-mock config"
    fi
  '');

  systemd.user.services.camera-mock = lib.mkIf cfg.enable {
    Unit = {
      Description = "camera-mock RTSP simulator";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${vars.pkgs.camera-mock}/bin/camera-mock --config ${vars.mediaRoot}/config/camera-mock/config.yaml";
      Restart = "on-failure";
      RestartSec = "5s";
      EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
    };
    Install.WantedBy = ["default.target"];
  };
}
