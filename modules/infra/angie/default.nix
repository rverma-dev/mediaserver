{
  lib,
  pkgs,
  vars,
  ...
}: let
  configDir = "${vars.mediaRoot}/config/angie";
  legoPath = "${configDir}/lego";
  certDir = "${legoPath}/certificates";
  template = ./angie.conf.template;
  # Angie uses nginx generic; mime.types is in conf/mime.types.
  mimeTypes = "${pkgs.angie}/conf/mime.types";
  configFile = "${configDir}/angie.conf";

  startScript = pkgs.writeShellScript "angie-start" ''
    set -euo pipefail
    export PATH="${lib.makeBinPath [pkgs.angie pkgs.lego pkgs.envsubst pkgs.coreutils]}:$PATH"

    [[ -f "${vars.mediaRoot}/.env" ]] && set -a && source "${vars.mediaRoot}/.env" && set +a

    if [[ -z "''${DUCKDNS_SUBDOMAIN:-}" ]] || [[ -z "''${DUCKDNS_TOKEN:-}" ]]; then
      echo "DUCKDNS_SUBDOMAIN and DUCKDNS_TOKEN must be set in .env"
      exit 1
    fi

    DOMAIN="''${DUCKDNS_SUBDOMAIN}.duckdns.org"
    CERT_CRT="${certDir}/''${DOMAIN}.crt"
    CERT_KEY="${certDir}/''${DOMAIN}.key"

    mkdir -p "${configDir}" "${legoPath}"

    if [[ ! -f "$CERT_CRT" ]]; then
      echo "Obtaining certificate for $DOMAIN..."
      lego --path "${legoPath}" --dns duckdns --dns.resolvers 1.1.1.1 \
        -d "$DOMAIN" --email "''${ACME_EMAIL:-admin@$DOMAIN}" run
    fi

    export DUCKDNS_SUBDOMAIN
    export CERT_CRT
    export CERT_KEY

  sed \
    -e "s|__DUCKDNS_SUBDOMAIN__|${"$"}DUCKDNS_SUBDOMAIN|g" \
    -e "s|__CERT_CRT__|${"$"}CERT_CRT|g" \
    -e "s|__CERT_KEY__|${"$"}CERT_KEY|g" \
    "${template}" \
    | sed "s|__MIME_TYPES_PATH__|${mimeTypes}|g" > "${configFile}"

    exec nginx -c "${configFile}" -g 'daemon off;'
  '';

  renewScript = pkgs.writeShellScript "angie-cert-renew" ''
    set -euo pipefail
    [[ -f "${vars.mediaRoot}/.env" ]] && set -a && source "${vars.mediaRoot}/.env" && set +a
    DOMAIN="''${DUCKDNS_SUBDOMAIN:-}.duckdns.org"
    [[ -z "''${DUCKDNS_SUBDOMAIN:-}" ]] && exit 0
    ${pkgs.lego}/bin/lego --path "${legoPath}" --dns duckdns -d "$DOMAIN" renew --reuse-key
    systemctl --user reload angie
  '';
in {
  home.activation.angieSetcap = lib.hm.dag.entryAfter ["writeBoundary"] ''
    angie_real=$(readlink -f "${pkgs.angie}/bin/nginx" 2>/dev/null || true)
    if [[ -n "$angie_real" ]]; then
      /usr/bin/sudo setcap 'cap_net_bind_service=+ep' "$angie_real" 2>/dev/null || true
    fi
  '';

  systemd.user.services.angie = {
    Unit = {
      Description = "Angie reverse proxy (DuckDNS)";
      After = [
        "network-online.target"
        "sonarr.service"
        "radarr.service"
        "prowlarr.service"
        "bazarr.service"
        "qbittorrent.service"
        "immich.service"
        "seerr.service"
        "jellyfin.service"
        "wireproxy.service"
      ];
      Wants = [
        "sonarr.service"
        "radarr.service"
        "prowlarr.service"
        "bazarr.service"
        "qbittorrent.service"
        "immich.service"
        "seerr.service"
        "jellyfin.service"
        "wireproxy.service"
      ];
    };
    Service = {
      ExecStart = "${startScript}";
      ExecReload = "${pkgs.angie}/bin/nginx -s reload -c ${configFile}";
      Restart = "always";
      RestartSec = "5s";
      EnvironmentFile = "${vars.mediaRoot}/.env";
    };
    Install.WantedBy = ["default.target"];
  };

  systemd.user.timers.angie-cert-renew = {
    Unit = { Description = "Angie TLS cert renewal"; };
    Timer = {
      OnCalendar = "daily";
      RandomizedDelaySec = "1h";
    };
    Install.WantedBy = ["timers.target"];
  };

  systemd.user.services.angie-cert-renew = {
    Unit = { Description = "Angie TLS cert renewal"; };
    Service = {
      Type = "oneshot";
      ExecStart = "${renewScript}";
    };
  };
}
