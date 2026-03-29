# NVMe disk alerts + Grafana Alloy (optional, needs GCLOUD_RW_API_KEY).
{
  lib,
  pkgs,
  vars,
  ...
}: let
  alloyConfig = ./alloy-config.alloy;
  envFile = "${vars.mediaRoot}/.env";

  nvmeCheckScript = pkgs.writeShellScript "nvme-disk-check" ''
    set -euo pipefail
    THRESHOLD_PCT=85
    MOUNT="/"
    pct=$(${pkgs.coreutils}/bin/df -P "$MOUNT" | ${pkgs.gawk}/bin/awk 'NR==2 {gsub(/%/,""); print $5}')
    if [[ -n "$pct" ]] && [[ "$pct" -ge "$THRESHOLD_PCT" ]]; then
      echo "NVMe alert: $MOUNT at ''${pct}% (threshold ''${THRESHOLD_PCT}%)"
      ${pkgs.coreutils}/bin/df -h "$MOUNT"
      exit 1
    fi
  '';

  alloyStart = pkgs.writeShellScript "alloy-start" ''
    set -euo pipefail
    set -a; source "${envFile}" 2>/dev/null; set +a
    if [[ -z "''${GCLOUD_RW_API_KEY:-}" ]]; then
      echo "GCLOUD_RW_API_KEY not set — Alloy disabled."
      exit 0
    fi
    export GCLOUD_HOSTED_METRICS_ID="''${GCLOUD_HOSTED_METRICS_ID:-2992798}"
    export GCLOUD_HOSTED_METRICS_URL="''${GCLOUD_HOSTED_METRICS_URL:-https://prometheus-prod-43-prod-ap-south-1.grafana.net/api/prom/push}"
    export GCLOUD_HOSTED_LOGS_ID="''${GCLOUD_HOSTED_LOGS_ID:-1492074}"
    export GCLOUD_HOSTED_LOGS_URL="''${GCLOUD_HOSTED_LOGS_URL:-https://logs-prod-028.grafana.net/loki/api/v1/push}"
    exec ${pkgs.grafana-alloy}/bin/alloy run "${alloyConfig}" \
      --storage.path="''${XDG_STATE_HOME:-$HOME/.local/state}/alloy" \
      --server.http.listen-addr=127.0.0.1:12345
  '';
in {
  home.packages = [pkgs.grafana-alloy];

  home.activation.enableNvmeAlertTimer = lib.hm.dag.entryAfter ["writeBoundary"] ''
    systemctl --user enable nvme-disk-alert.timer 2>/dev/null || true
    systemctl --user start nvme-disk-alert.timer 2>/dev/null || true
  '';

  systemd.user.services.nvme-disk-alert = {
    Unit.Description = "NVMe disk space check (alert at 85%)";
    Service = {
      Type = "oneshot";
      ExecStart = "${nvmeCheckScript}";
    };
    Install.WantedBy = ["default.target"];
  };

  systemd.user.timers.nvme-disk-alert = {
    Unit = {
      Description = "NVMe disk space alert (every 15 min)";
    };
    Timer = {
      OnCalendar = "*:0/15";
      Persistent = true;
    };
    Install.WantedBy = ["timers.target"];
  };

  systemd.user.services.grafana-alloy = {
    Unit = {
      Description = "Grafana Alloy — metrics & logs to Grafana Cloud";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${alloyStart}";
      Restart = "on-failure";
      RestartSec = "30s";
      EnvironmentFile = envFile;
    };
    Install.WantedBy = ["default.target"];
  };
}
