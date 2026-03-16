{
  lib,
  pkgs,
  vars,
  ...
}: {
  home.activation.seedBazarrConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    config_file="${vars.mediaRoot}/config/bazarr/config/config.yaml"
    if [[ ! -f "$config_file" ]]; then
      mkdir -p "$(dirname "$config_file")"
      set -a; [[ -f ${vars.mediaRoot}/.env ]] && source ${vars.mediaRoot}/.env; set +a
      ${pkgs.gettext}/bin/envsubst < ${./config.yaml.template} > "$config_file"
      echo "Seeded bazarr config.yaml"
    fi
  '';

  systemd.user.services.bazarr = {
    Unit = {
      Description = "Bazarr - Subtitle manager";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${vars.pkgs.bazarr}/bin/bazarr --config ${vars.mediaRoot}/config/bazarr";
      Restart = "always";
      RestartSec = "5s";
      Environment = [
        "TZ=${vars.tz}"
        "PATH=${pkgs.ffmpeg}/bin:/run/current-system/sw/bin:/usr/bin:/bin"
      ];
    };
    Install.WantedBy = ["default.target"];
  };
}
