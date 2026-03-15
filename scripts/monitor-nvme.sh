#!/usr/bin/env bash
# NVMe disk space alert — run via systemd timer.
# Alerts when root (NVMe) usage exceeds 85%.
#
# Usage: ./scripts/monitor-nvme.sh
# Or: systemctl --user start nvme-disk-alert.service

set -euo pipefail

THRESHOLD_PCT=85
MOUNT="/"

pct=$(df -P "$MOUNT" | awk 'NR==2 {gsub(/%/,""); print $5}')
if [[ -n "$pct" ]] && [[ "$pct" -ge "$THRESHOLD_PCT" ]]; then
  echo "NVMe alert: ${MOUNT} at ${pct}% (threshold ${THRESHOLD_PCT}%)"
  df -h "$MOUNT"
  # Could add: notify, log to file, send to Grafana, etc.
  exit 1
fi
exit 0
