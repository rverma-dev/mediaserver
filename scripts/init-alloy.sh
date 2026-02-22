#!/usr/bin/env bash
# Grafana Alloy (optional, requires GCLOUD_RW_API_KEY)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env || true

[[ -z "${GCLOUD_RW_API_KEY:-}" ]] && { warn "GCLOUD_RW_API_KEY not set — skipping Alloy."; exit 0; }

info "Installing Grafana Alloy via Grafana Cloud script..."
export GCLOUD_HOSTED_METRICS_ID="${GCLOUD_HOSTED_METRICS_ID:-2992798}"
export GCLOUD_HOSTED_METRICS_URL="${GCLOUD_HOSTED_METRICS_URL:-https://prometheus-prod-43-prod-ap-south-1.grafana.net/api/prom/push}"
export GCLOUD_HOSTED_LOGS_ID="${GCLOUD_HOSTED_LOGS_ID:-1492074}"
export GCLOUD_HOSTED_LOGS_URL="${GCLOUD_HOSTED_LOGS_URL:-https://logs-prod-028.grafana.net/loki/api/v1/push}"
export GCLOUD_FM_URL="${GCLOUD_FM_URL:-https://fleet-management-prod-018.grafana.net}"
export GCLOUD_FM_POLL_FREQUENCY="${GCLOUD_FM_POLL_FREQUENCY:-60s}"
export GCLOUD_FM_HOSTED_ID="${GCLOUD_FM_HOSTED_ID:-1534285}"
export ARCH="${ARCH:-arm64}"
export GCLOUD_RW_API_KEY

sudo -E env GCLOUD_HOSTED_METRICS_ID="$GCLOUD_HOSTED_METRICS_ID" \
    GCLOUD_HOSTED_METRICS_URL="$GCLOUD_HOSTED_METRICS_URL" \
    GCLOUD_HOSTED_LOGS_ID="$GCLOUD_HOSTED_LOGS_ID" \
    GCLOUD_HOSTED_LOGS_URL="$GCLOUD_HOSTED_LOGS_URL" \
    GCLOUD_FM_URL="$GCLOUD_FM_URL" \
    GCLOUD_FM_POLL_FREQUENCY="$GCLOUD_FM_POLL_FREQUENCY" \
    GCLOUD_FM_HOSTED_ID="$GCLOUD_FM_HOSTED_ID" \
    ARCH="$ARCH" \
    GCLOUD_RW_API_KEY="$GCLOUD_RW_API_KEY" \
    /bin/sh -c "$(curl -fsSL https://storage.googleapis.com/cloud-onboarding/alloy/scripts/install-linux.sh)"
info "Alloy installed."
