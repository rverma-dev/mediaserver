{
  lib,
  pkgs,
  vars,
  ...
}: {
  home.activation.seedRadarrConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    config_file="${vars.mediaRoot}/config/radarr/config.xml"
    if [[ ! -f "$config_file" ]]; then
      mkdir -p "$(dirname "$config_file")"
      set -a; [[ -f ${vars.mediaRoot}/.env ]] && source ${vars.mediaRoot}/.env; set +a
      ${pkgs.gettext}/bin/envsubst < ${./config.xml.template} > "$config_file"
      echo "Seeded radarr config.xml"
    fi
  '';

  systemd.user.services.radarr = {
    Unit = {
      Description = "Radarr - Movie automation";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${vars.pkgs.radarr}/bin/radarr --nobrowser --data=${vars.mediaRoot}/config/radarr";
      Restart = "always";
      RestartSec = "5s";
      Environment = ["TZ=${vars.tz}"];
      IOSchedulingClass = "best-effort";
      IOSchedulingPriority = 7;
    };
    Install.WantedBy = ["default.target"];
  };
}
