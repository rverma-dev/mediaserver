{
  lib,
  pkgs,
  vars,
  ...
}: let
  configDir = "${vars.mediaRoot}/config/immich";
  pgDataDir = "${configDir}/postgres";
  pgSocketDir = "/run/user/1000/immich-postgres";
  valkeySocket = "/run/user/1000/immich-valkey.sock";

  # PostgreSQL 17 + VectorChord (pgvecto.rs is broken on pg17; VectorChord is its successor)
  postgres = pkgs.postgresql.withPackages (ps: [ps.vectorchord ps.pgvector]);

  pgLogDir = "${pgDataDir}/pg_log";

  pgStartScript = pkgs.writeShellScript "immich-db-start" ''
    mkdir -p "${pgSocketDir}" "${pgLogDir}"
    exec ${postgres}/bin/postgres \
      -D "${pgDataDir}" \
      -k "${pgSocketDir}" \
      -c listen_addresses=127.0.0.1 \
      -c port=5432 \
      -c ssl=on \
      -c ssl_cert_file="${pgDataDir}/server.crt" \
      -c ssl_key_file="${pgDataDir}/server.key" \
      -c shared_preload_libraries=vchord.so \
      -c shared_buffers=512MB \
      -c work_mem=32MB \
      -c effective_cache_size=2GB \
      -c synchronous_commit=off \
      -c wal_compression=on \
      -c logging_collector=on \
      -c log_directory="${pgLogDir}" \
      -c log_filename=postgresql.log \
      -c log_rotation_age=1d \
      -c log_rotation_size=100MB \
      -c log_min_duration_statement=1000
  '';

  pgSetupScript = pkgs.writeShellScript "immich-db-setup" ''
    set -euo pipefail

    echo "Waiting for postgres..."
    for i in $(seq 1 30); do
      ${postgres}/bin/pg_isready -h "${pgSocketDir}" && break
      sleep 1
    done
    ${postgres}/bin/pg_isready -h "${pgSocketDir}" || { echo "Postgres not ready"; exit 1; }

    psql="${postgres}/bin/psql"

    $psql -h "${pgSocketDir}" -d postgres -c "
      DO \$\$ BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'immich') THEN
          CREATE USER immich;
        END IF;
      END \$\$;"

    $psql -h "${pgSocketDir}" -tc "SELECT 1 FROM pg_database WHERE datname='immich'" \
      | grep -q 1 || \
      $psql -h "${pgSocketDir}" -c "CREATE DATABASE immich OWNER immich"

    $psql -h "${pgSocketDir}" -d immich -U immich <<'SQL'
      CREATE EXTENSION IF NOT EXISTS unaccent;
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
      CREATE EXTENSION IF NOT EXISTS vchord;
      CREATE EXTENSION IF NOT EXISTS cube;
      CREATE EXTENSION IF NOT EXISTS earthdistance;
      CREATE EXTENSION IF NOT EXISTS pg_trgm;
    SQL

    # Monitoring role for Alloy (runs as root OS user)
    $psql -h "${pgSocketDir}" -d postgres -c "
      DO \$\$ BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'root') THEN
          CREATE ROLE root WITH LOGIN;
          GRANT pg_monitor TO root;
        END IF;
      END \$\$;"

    touch "${configDir}/.db-initialized"
    echo "Immich database initialized"
  '';
in {
  home.packages = [pkgs.immich];

  home.activation.initImmich = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ ! -d "${pgDataDir}" ]]; then
      mkdir -p "${pgDataDir}"
      chmod 700 "${pgDataDir}"
      ${postgres}/bin/initdb \
        --pgdata="${pgDataDir}" \
        --locale=C.UTF-8 \
        --encoding=UTF-8
      echo "Initialized Immich postgres data dir"
    fi

    # Self-signed TLS cert for postgres (required by Alloy's sslmode=require default)
    if [[ ! -f "${pgDataDir}/server.crt" ]]; then
      ${pkgs.openssl}/bin/openssl req -new -x509 -days 3650 -nodes \
        -out "${pgDataDir}/server.crt" \
        -keyout "${pgDataDir}/server.key" \
        -subj "/CN=localhost"
      chmod 600 "${pgDataDir}/server.key"
      echo "Generated postgres SSL certificate"
    fi

    set -a
    [[ -f ${vars.mediaRoot}/.env ]] && source ${vars.mediaRoot}/.env
    set +a
    if mountpoint -q "${vars.hddMountPath}" 2>/dev/null; then
      mkdir -p "${vars.hddImmichLibrary}"
    fi
  '';

  # PostgreSQL with VectorChord
  systemd.user.services.immich-db = {
    Unit = {
      Description = "Immich - PostgreSQL";
      After = ["network.target"];
    };
    Service = {
      ExecStart = "${pgStartScript}";
      Restart = "on-failure";
      RestartSec = "5s";
    };
    Install.WantedBy = ["default.target"];
  };

  # One-time DB + extension setup (skipped once .db-initialized exists)
  systemd.user.services.immich-db-setup = {
    Unit = {
      Description = "Immich - DB init (one-time)";
      After = ["immich-db.service"];
      Requires = ["immich-db.service"];
      ConditionPathExists = "!${configDir}/.db-initialized";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pgSetupScript}";
      RemainAfterExit = true;
    };
    Install.WantedBy = ["default.target"];
  };

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

  # Immich server (no machine-learning — too heavy for Pi)
  systemd.user.services.immich = {
    Unit = {
      Description = "Immich - Photo management server";
      After = ["network-online.target" "immich-db.service" "immich-db-setup.service" "immich-redis.service"];
      Requires = ["immich-db.service" "immich-redis.service"];
    };
    Service = {
      ExecStart = "${pkgs.immich}/bin/server";
      Restart = "always";
      RestartSec = "10s";
      IOSchedulingClass = "best-effort";
      IOSchedulingPriority = 7;
      EnvironmentFile = "${vars.mediaRoot}/.env";
      Environment = [
        "IMMICH_HOST=0.0.0.0"
        "IMMICH_PORT=3001"
        "DB_URL=postgresql:///immich?host=${pgSocketDir}"
        "REDIS_SOCKET=${valkeySocket}"
        "IMMICH_MACHINE_LEARNING_ENABLED=false"
        "IMMICH_LOG_LEVEL=warn"
        "IMMICH_MEDIA_LOCATION=${vars.hddImmichLibrary}"
      ];
    };
    Install.WantedBy = ["default.target"];
  };
}
