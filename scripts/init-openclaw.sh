#!/usr/bin/env bash
# OpenClaw: migrate from openclaw-data or copy template

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env || true
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

if [[ -d /opt/openclaw-data/config ]] && [[ ! -f "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json" ]]; then
    info "Migrating OpenClaw config from /opt/openclaw-data..."
    sudo cp -a /opt/openclaw-data/config/* "${MEDIASERVER_ROOT}/config/openclaw/"
    for key in OPENCLAW_GATEWAY_TOKEN GOOGLE_API_KEY GEMINI_API_KEY; do
        val=$(grep -E "^${key}=" /opt/openclaw-data/.env 2>/dev/null | cut -d= -f2-)
        if [[ -n "$val" ]]; then
            cur=$(grep -E "^${key}=" "${MEDIASERVER_ROOT}/.env" 2>/dev/null | cut -d= -f2-)
            if [[ -z "$cur" ]]; then
                grep -v "^${key}=" "${MEDIASERVER_ROOT}/.env" 2>/dev/null > "${MEDIASERVER_ROOT}/.env.tmp" || true
                echo "${key}=${val}" >> "${MEDIASERVER_ROOT}/.env.tmp"
                mv "${MEDIASERVER_ROOT}/.env.tmp" "${MEDIASERVER_ROOT}/.env"
            fi
        fi
    done
    token=$(grep -E '^OPENCLAW_GATEWAY_TOKEN=' "${MEDIASERVER_ROOT}/.env" 2>/dev/null | cut -d= -f2-)
    [[ -z "$token" ]] && token=$(grep -E '^OPENCLAW_GATEWAY_TOKEN=' /opt/openclaw-data/.env 2>/dev/null | cut -d= -f2-)
    if [[ -n "$token" ]]; then
        sudo cat "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json" | \
            jq --arg t "$token" '.gateway.auth.token = $t' | \
            sudo tee "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json.tmp" >/dev/null
        sudo mv "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json.tmp" "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json"
    fi
    if ! sudo grep -q "172.20.0" "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json" 2>/dev/null; then
        sudo cat "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json" | \
            jq '.gateway.trustedProxies = (.gateway.trustedProxies + ["172.20.0.0/24"]) | unique' | \
            sudo tee "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json.tmp" >/dev/null
        sudo mv "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json.tmp" "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json"
    fi
    gemini_key=$(grep -E '^GEMINI_API_KEY=' "${MEDIASERVER_ROOT}/.env" 2>/dev/null | cut -d= -f2-)
    [[ -z "$gemini_key" ]] && gemini_key=$(grep -E '^GEMINI_API_KEY=' /opt/openclaw-data/.env 2>/dev/null | cut -d= -f2-)
    if [[ -n "$gemini_key" ]] && ! sudo grep -q "GEMINI_API_KEY" "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json" 2>/dev/null; then
        sudo cat "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json" | \
            jq --arg k "$gemini_key" '.env.GEMINI_API_KEY = $k' | \
            sudo tee "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json.tmp" >/dev/null
        sudo mv "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json.tmp" "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json"
    fi
    sudo chown -R "${PUID}:${PGID}" "${MEDIASERVER_ROOT}/config/openclaw"
    info "OpenClaw migrated: Codex OAuth, WhatsApp, GEMINI_API_KEY preserved."
elif [[ ! -f "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json" ]]; then
    info "Copying OpenClaw template (fresh install)..."
    sudo cp "${MEDIASERVER_ROOT}/openclaw/openclaw.json" "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json"
    token=$(grep -E '^OPENCLAW_GATEWAY_TOKEN=' "${MEDIASERVER_ROOT}/.env" 2>/dev/null | cut -d= -f2-)
    if [[ -n "$token" ]]; then
        sudo sed -i "s|REPLACE_WITH_OPENCLAW_GATEWAY_TOKEN|${token}|" "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json"
    fi
    sudo chown "${PUID}:${PGID}" "${MEDIASERVER_ROOT}/config/openclaw/openclaw.json"
fi
