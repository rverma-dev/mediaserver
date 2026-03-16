{
  lib,
  pkgs,
  vars,
  ...
}: {
  home.activation.seedSonarrConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    config_file="${vars.mediaRoot}/config/sonarr/config.xml"
    if [[ ! -f "$config_file" ]]; then
      mkdir -p "$(dirname "$config_file")"
      set -a; [[ -f ${vars.mediaRoot}/.env ]] && source ${vars.mediaRoot}/.env; set +a
      ${pkgs.gettext}/bin/envsubst < ${./config.xml.template} > "$config_file"
      echo "Seeded sonarr config.xml"
    fi
  '';

  systemd.user.services.sonarr = {
    Unit = {
      Description = "Sonarr - TV automation";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${vars.pkgs.sonarr}/bin/sonarr --nobrowser --data=${vars.mediaRoot}/config/sonarr";
      Restart = "always";
      RestartSec = "5s";
      Environment = ["TZ=${vars.tz}"];
      IOSchedulingClass = "best-effort";
      IOSchedulingPriority = 7;
    };
    Install.WantedBy = ["default.target"];
  };
}
