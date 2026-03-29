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
      ExecStartPre = "${pkgs.writeShellScript "jellyfin-db-guard" ''
        #!/usr/bin/env sh
        set -eu

        db_path="${vars.mediaRoot}/config/jellyfin/data/jellyfin.db"
        broken_root="${vars.mediaRoot}/config/jellyfin/data/.repair-backup"
        sqlite_bin="${pkgs.sqlite}/bin/sqlite3"

        if [ -f "$db_path" ]; then
          migration_history=$(
            "$sqlite_bin" "$db_path" \
              "SELECT name FROM sqlite_master WHERE type='table' AND name='__EFMigrationsHistory';" 2>/dev/null
          ) || true
          typed_base_items=$(
            "$sqlite_bin" "$db_path" \
              "SELECT name FROM sqlite_master WHERE type='table' AND name='TypedBaseItems';" 2>/dev/null
          ) || true

          if [ "$migration_history" != "__EFMigrationsHistory" ] || [ "$typed_base_items" != "TypedBaseItems" ]; then
            mkdir -p "$broken_root"
            ts="$(date +%Y%m%d_%H%M%S)"
            mv "$db_path" "$broken_root/jellyfin.db.$ts.broken"
          fi
        fi
      ''}";
      Restart = "on-failure";
      RestartSec = "10s";
      StartLimitIntervalSec = 300;
      StartLimitBurst = 50;
      TimeoutStopSec = 20;
      Environment = [
        "TZ=${vars.tz}"
        "JELLYFIN_PublishedServerUrl=http://${vars.lanIp}/jellyfin"
        "JELLYFIN_DATA_DIR=${vars.mediaRoot}/config/jellyfin"
        "JELLYFIN_CONFIG_DIR=${vars.mediaRoot}/config/jellyfin/config"
        "JELLYFIN_CACHE_DIR=${vars.mediaRoot}/config/jellyfin/cache"
        "JELLYFIN_LOG_DIR=${vars.mediaRoot}/config/jellyfin/log"
        "PATH=${pkgs.ffmpeg}/bin:/run/current-system/sw/bin:/usr/bin:/bin"
      ];
    };
    Install.WantedBy = ["default.target"];
  };
}
