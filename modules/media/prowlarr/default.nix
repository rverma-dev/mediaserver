{
  lib,
  pkgs,
  vars,
  ...
}: let
  proxychainsConf = ../warp/proxychains.conf;
in {
  home.activation.seedProwlarrConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    config_file="${vars.mediaRoot}/config/prowlarr/config.xml"
    if [[ ! -f "$config_file" ]]; then
      mkdir -p "$(dirname "$config_file")"
      set -a; [[ -f ${vars.mediaRoot}/.env ]] && source ${vars.mediaRoot}/.env; set +a
      ${pkgs.gettext}/bin/envsubst < ${./config.xml.template} > "$config_file"
      echo "Seeded prowlarr config.xml"
    fi
  '';

  systemd.user.services.prowlarr = {
    Unit = {
      Description = "Prowlarr - Indexer manager";
      After = ["network-online.target" "wireproxy.service"];
      Requires = ["wireproxy.service"];
    };
    Service = {
      ExecStart = "${pkgs.proxychains-ng}/bin/proxychains4 -f ${proxychainsConf} ${vars.pkgs.prowlarr}/bin/prowlarr --nobrowser --data=${vars.mediaRoot}/config/prowlarr";
      Restart = "always";
      RestartSec = "5s";
      Environment = ["TZ=${vars.tz}"];
    };
    Install.WantedBy = ["default.target"];
  };
}
