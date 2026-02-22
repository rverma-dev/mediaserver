#!/usr/bin/env bash
# Generate service configs from templates using .env values

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env || true

command -v envsubst &>/dev/null || {
    info "Installing gettext-base (envsubst)..."
    sudo apt-get install -y gettext-base
}

TEMPLATES=(
    "config/sonarr/config.xml.template:config/sonarr/config.xml"
    "config/radarr/config.xml.template:config/radarr/config.xml"
    "config/prowlarr/config.xml.template:config/prowlarr/config.xml"
    "config/bazarr/config/config.yaml.template:config/bazarr/config/config.yaml"
)

for entry in "${TEMPLATES[@]}"; do
    tmpl="${MEDIASERVER_ROOT}/${entry%%:*}"
    dest="${MEDIASERVER_ROOT}/${entry##*:}"

    [[ ! -f "$tmpl" ]] && { warn "Template not found: $tmpl — skipping."; continue; }

    if [[ -f "$dest" ]]; then
        info "Config exists: $dest — updating API keys in place."
        case "$dest" in
            *.xml)
                [[ -n "${SONARR_API_KEY:-}" ]]  && sed -i "s|<ApiKey>.*</ApiKey>|<ApiKey>${SONARR_API_KEY}</ApiKey>|" "$dest" 2>/dev/null
                [[ -n "${RADARR_API_KEY:-}" ]]   && sed -i "s|<ApiKey>.*</ApiKey>|<ApiKey>${RADARR_API_KEY}</ApiKey>|" "$dest" 2>/dev/null
                [[ -n "${PROWLARR_API_KEY:-}" ]] && sed -i "s|<ApiKey>.*</ApiKey>|<ApiKey>${PROWLARR_API_KEY}</ApiKey>|" "$dest" 2>/dev/null
                ;;
            *.yaml)
                [[ -n "${BAZARR_API_KEY:-}" ]]  && sed -i "s|^\(  apikey:\).*|\1 ${BAZARR_API_KEY}|" "$dest" 2>/dev/null
                [[ -n "${SONARR_API_KEY:-}" ]]  && python3 -c "
import yaml, sys
with open('$dest') as f: cfg = yaml.safe_load(f)
cfg['sonarr']['apikey'] = '${SONARR_API_KEY}'
cfg['radarr']['apikey'] = '${RADARR_API_KEY}'
cfg['auth']['apikey'] = '${BAZARR_API_KEY}'
with open('$dest', 'w') as f: yaml.dump(cfg, f, default_flow_style=False, allow_unicode=True)
" 2>/dev/null || warn "Python yaml update failed for $dest, falling back to sed."
                ;;
        esac
    else
        info "Generating: $dest from template."
        envsubst < "$tmpl" > "$dest"
    fi
done

info "Config generation complete."
