{
  lib,
  pkgs,
  vars,
  ...
}: let
  configDir = "${vars.mediaRoot}/config/immich";
  valkeySocket = "/run/user/1000/immich-valkey.sock";
in {
  home.packages = [pkgs.immich];

  home.activation.initImmich = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -a
    [[ -f ${vars.mediaRoot}/.env ]] && source ${vars.mediaRoot}/.env
    set +a
    if mountpoint -q "${vars.hddMountPath}" 2>/dev/null; then
      mkdir -p "${vars.hddImmichLibrary}"
    fi
  '';

  # Valkey (Redis-compatible) for job queuing
  systemd.user.services.immich-redis = {
    Unit = {
      Description = "Immich - Valkey cache";
      After = ["network.target"];
    };
    Service = {
      ExecStart = "${pkgs.valkey}/bin/valkey-server --unixsocket ${valkeySocket} --unixsocketperm 700 --save \"\" --appendonly no --loglevel warning";
      Restart = "always";
      RestartSec = "5s";
    };
    Install.WantedBy = ["default.target"];
  };

  # Immich server (no machine-learning — too heavy for Pi). DB from .env (Neon).
  systemd.user.services.immich = {
    Unit = {
      Description = "Immich - Photo management server";
      After = ["network-online.target" "immich-redis.service"];
      Requires = ["immich-redis.service"];
    };
    Service = {
      ExecStart = "${pkgs.immich}/bin/server";
      Restart = "always";
      RestartSec = "10s";
      IOSchedulingClass = "best-effort";
      IOSchedulingPriority = 7;
      EnvironmentFile = "${vars.mediaRoot}/.env";
      Environment = [
        "TZ=${vars.tz}"
        "IMMICH_HOST=0.0.0.0"
        "IMMICH_PORT=3001"
        "REDIS_SOCKET=${valkeySocket}"
        "IMMICH_MACHINE_LEARNING_ENABLED=false"
        "IMMICH_LOG_LEVEL=warn"
        "IMMICH_MEDIA_LOCATION=${vars.hddImmichLibrary}"
      ];
    };
    Install.WantedBy = ["default.target"];
  };
}
