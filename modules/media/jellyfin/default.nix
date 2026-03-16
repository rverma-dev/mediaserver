{
  lib,
  pkgs,
  vars,
  ...
}: {
  home.activation.seedJellyfinConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    jf_config="${vars.mediaRoot}/config/jellyfin/config"
    jf_plugins="${vars.mediaRoot}/config/jellyfin/plugins/configurations"

    if [[ ! -f "$jf_config/network.xml" ]]; then
      mkdir -p "$jf_config" "$jf_plugins"
      cp ${./seed/config}/* "$jf_config/"
      cp ${./seed/plugins/configurations}/* "$jf_plugins/"
      chmod 600 "$jf_config"/* "$jf_plugins"/*
      echo "Seeded Jellyfin config"
    fi
  '';

  systemd.user.services.jellyfin = {
    Unit = {
      Description = "Jellyfin media server";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${vars.pkgs.jellyfin}/bin/jellyfin --datadir ${vars.mediaRoot}/config/jellyfin --cachedir ${vars.mediaRoot}/config/jellyfin/cache";
      Restart = "always";
      RestartSec = "5s";
      Environment = [
        "TZ=${vars.tz}"
        "JELLYFIN_PublishedServerUrl=http://${vars.lanIp}/jellyfin"
        "PATH=${pkgs.ffmpeg}/bin:/run/current-system/sw/bin:/usr/bin:/bin"
      ];
    };
    Install.WantedBy = ["default.target"];
  };
}
