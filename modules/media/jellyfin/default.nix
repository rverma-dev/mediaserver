{
  lib,
  pkgs,
  vars,
  ...
}: {
  home.activation.seedJellyfinConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    jf_config="${vars.mediaRoot}/config/jellyfin/config"
    jf_plugins="${vars.mediaRoot}/config/jellyfin/plugins/configurations"
    seed_config_dir="${./seed/config}"
    seed_plugin_dir="${./seed/plugins/configurations}"

    if [[ ! -f "$jf_config/network.xml" || ! -f "$jf_config/system.xml" || ! -f "$jf_plugins/Jellyfin.Plugin.Tmdb.xml" ]]; then
      mkdir -p "$jf_config" "$jf_plugins"

      for seed_file in "$seed_config_dir"/*.xml "$seed_config_dir"/*.json; do
        target_file="$jf_config/$(basename "$seed_file")"
        [[ -f "$target_file" ]] || cp "$seed_file" "$target_file"
      done

      for seed_plugin_file in "$seed_plugin_dir"/*; do
        target_plugin_file="$jf_plugins/$(basename "$seed_plugin_file")"
        [[ -f "$target_plugin_file" ]] || cp "$seed_plugin_file" "$target_plugin_file"
      done

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
