{ lib, pkgs, vars, ... }:
let
  jellyfinDataDir = "${vars.mediaRoot}/config/jellyfin";
  jellyfinCacheDir = "${jellyfinDataDir}/cache";
  baseUrl = "http://127.0.0.1:8096/jellyfin";
  jellarrConfig = pkgs.lib.generators.toYAML {} {
    version = 1;
    base_url = baseUrl;
    system = {
      enableMetrics = true;
      pluginRepositories = [
        {
          name = "Jellyfin Official";
          url = "https://repo.jellyfin.org/releases/plugin/manifest.json";
          enabled = true;
        }
        {
          name = "Moonfin";
          url = "https://raw.githubusercontent.com/Moonfin-Client/Plugin/refs/heads/master/manifest.json";
          enabled = true;
        }
        {
          name = "IAmParadox";
          url = "https://www.iamparadox.dev/jellyfin/plugins/manifest.json";
          enabled = true;
        }
      ];
    };
    library = {
      virtualFolders = [
        {
          name = "Movies";
          collectionType = "movies";
          libraryOptions = {
            pathInfos = [
              {
                path = "${vars.hddMediaPath}/movies";
              }
            ];
          };
        }
        {
          name = "TV Shows";
          collectionType = "tvshows";
          libraryOptions = {
            pathInfos = [
              {
                path = "${vars.hddMediaPath}/tv";
              }
            ];
          };
        }
        {
          name = "Music";
          collectionType = "music";
          libraryOptions = {
            pathInfos = [
              {
                path = "${vars.hddMediaPath}/music";
              }
            ];
          };
        }
      ];
    };
    startup = {
      completeStartupWizard = true;
    };
    users = [
      {
        name = "admin";
        password = "admin";
        policy = {
          isAdministrator = true;
        };
      }
    ];
    plugins = [
      { name = "File Transformation"; }
      {
        name = "Moonfin";
        configuration = {
          EnableSettingsSync = true;
          JellyseerrEnabled = true;
          JellyseerrUrl = "http://127.0.0.1:5055";
          JellyseerrDisplayName = "Seerr";
        };
      }
    ];
  };

  jellarrConfigFile = pkgs.writeText "jellarr-config.yml" jellarrConfig;
  waitForJellyfin = pkgs.writeShellScript "wait-for-jellyfin" ''
    #!${pkgs.runtimeShell}
    set -eu

    for _ in $(seq 1 120); do
      # If Jellyfin is already at /jellyfin, we are good
      CODE=$(${pkgs.curl}/bin/curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8096/jellyfin/System/Info/Public || echo "000")
      if [ "$CODE" = "200" ]; then
        exit 0
      fi

      # If Jellyfin is at / (fresh wipe), configure BaseUrl and restart
      CODE=$(${pkgs.curl}/bin/curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8096/System/Info/Public || echo "000")
      if [ "$CODE" = "200" ]; then
        if [ -n "''${JELLARR_API_KEY:-}" ]; then
          CONFIG=$(${pkgs.curl}/bin/curl -s "http://127.0.0.1:8096/System/Configuration/network" -H "X-Emby-Token: ''${JELLARR_API_KEY}")
          if [ -n "$CONFIG" ]; then
            NEW_CONFIG=$(echo "$CONFIG" | ${pkgs.jq}/bin/jq '.BaseUrl = "/jellyfin"' || true)
            if [ -n "$NEW_CONFIG" ]; then
              ${pkgs.curl}/bin/curl -s -X POST "http://127.0.0.1:8096/System/Configuration/network" \
                -H "X-Emby-Token: ''${JELLARR_API_KEY}" \
                -H "Content-Type: application/json" \
                -d "$NEW_CONFIG" >/dev/null || true
              systemctl --user restart jellyfin || true
            fi
          fi
        fi
      fi
      sleep 1
    done

    echo "Jellyfin not running at ${baseUrl}"
    exit 1
  '';
  runJellarr = pkgs.writeShellScript "run-jellarr" ''
    #!${pkgs.runtimeShell}
    set -e

    if [ -z "$JELLARR_API_KEY" ]; then
      echo "JELLARR_API_KEY is missing in ${vars.mediaRoot}/.env; skipping one-shot Jellarr run."
      exit 0
    fi

    exec ${vars.pkgs.jellarr}/bin/jellarr --configFile ${jellarrConfigFile}
  '';
in {
  home.packages = [
    vars.pkgs.jellarr
    pkgs.jellyfin
  ];

  home.activation.seedJellyfinConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${jellyfinDataDir}" "${jellyfinCacheDir}"
  '';

  systemd.user.services.jellyfin = {
    Unit = {
      Description = "Jellyfin media server";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      ExecStartPre = "${pkgs.util-linux}/bin/mountpoint -q ${vars.hddMountPath}";
      ExecStart = "${pkgs.jellyfin}/bin/jellyfin --datadir ${jellyfinDataDir} --cachedir ${jellyfinCacheDir}";
      Restart = "always";
      RestartSec = "5s";
      Environment = [
        "TZ=${vars.tz}"
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.jellarr = {
    Unit = {
      Description = "Apply Jellyfin config via Jellarr";
      After = [ "jellyfin.service" ];
      Wants = [ "jellyfin.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStartPre = "${waitForJellyfin}";
      ExecStart = "${runJellarr}";
      Environment = [
        "TZ=${vars.tz}"
      ];
      EnvironmentFile = "${vars.mediaRoot}/.env";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
