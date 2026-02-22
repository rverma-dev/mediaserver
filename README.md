# Raspberry Pi 5 Consolidated Server

Single reproducible repo for media stack + OpenClaw + monitoring. Clone, configure `.env`, run `init.sh`, done.

## Architecture

```
Prowlarr (indexers) --> Sonarr (TV) --> qBittorrent (downloads) --> Jellyfin (streaming)
                    --> Radarr (Movies) ↗                       ↗
                    --> Bazarr (subtitles) ----------------------
Seerr (discovery UI) — HTTP landing page
OpenClaw (AI assistant) — HTTPS, WhatsApp
```

- **Caddy**: Reverse proxy, HTTPS via DuckDNS
- **WARP**: Cloudflare SOCKS5 for Prowlarr/Seerr (bypass ISP blocking)
- **Alloy**: Grafana Cloud logs/metrics (optional)

## Quick Start

```bash
# Clone to /opt/mediaserver
sudo git clone git@github.com:rverma-dev/mediaserver.git /opt/mediaserver
sudo chown -R 1000:1000 /opt/mediaserver

# Configure secrets
cd /opt/mediaserver
cp .env.example .env
# Edit .env: DUCKDNS_TOKEN, DUCKDNS_SUBDOMAIN, SONARR_API_KEY, RADARR_API_KEY, PROWLARR_API_KEY, BAZARR_API_KEY, OPENCLAW_*, etc.

# Bootstrap (installs Docker, Alloy, UFW, injects API keys into configs, deploys stack)
./init.sh
```

API keys in `.env` are injected into *arr configs by `init-config.sh`. For fresh install: leave keys empty, let services generate on first run, then copy from each UI (Settings → General) into `.env` and run `./scripts/init-config.sh`.

## GHCR Images (no local build on Pi)

| Image | Workflow | Default |
|-------|----------|---------|
| Caddy (DuckDNS) | `build-caddy.yml` | `ghcr.io/rverma-dev/caddy-duckdns:latest` |
| OpenClaw | `build-openclaw.yml` | `ghcr.io/openclaw/openclaw:latest` (upstream) |

- **Caddy**: Triggers on push when `caddy/` changes. Override: `CADDY_IMAGE`
- **OpenClaw**: Run manually or on workflow change. Builds from `openclaw/openclaw`. Override: `OPENCLAW_IMAGE=ghcr.io/rverma-dev/openclaw:latest`

## URLs

| Path | Service |
|------|---------|
| `/jellyfin/` | Jellyfin |
| `/qbit/` | qBittorrent |
| `/sonarr/` | Sonarr |
| `/radarr/` | Radarr |
| `/prowlarr/` | Prowlarr |
| `/bazarr/` | Bazarr |
| `/` (HTTP) | Seerr (landing) |
| `/` (HTTPS) | OpenClaw |

## Directory Layout

```
/opt/mediaserver/
├── docker-compose.yml    # 11 services
├── Caddyfile
├── .env.example / .env
├── init.sh               # Orchestrates scripts/
├── scripts/              # Modular init phases (run individually for debugging)
│   ├── common.sh
│   ├── init-system.sh    # apt, Docker, daemon
│   ├── init-alloy.sh     # Grafana Alloy
│   ├── init-dirs.sh      # data/config dirs, ownership
│   ├── init-config.sh    # Inject API keys from .env into *arr configs
├── init-openclaw.sh  # OpenClaw migration
│   ├── init-network.sh   # static IP
│   ├── init-security.sh  # UFW, fail2ban
│   └── init-deploy.sh    # compose pull/up
├── caddy/                # Dockerfile (built by CI)
├── openclaw/             # Agent config, workspace, skills
├── docker/               # daemon.json
├── config/               # Persistent state (gitignored for openclaw)
└── data/                 # Torrents + media (gitignored)
```

## OpenClaw Setup

**Migration from /opt/openclaw-data:** If that directory exists, `init.sh` automatically copies `config/` (credentials, WhatsApp, OAuth, sessions) into `config/openclaw/` and merges `OPENCLAW_GATEWAY_TOKEN`, `GOOGLE_API_KEY`, `GEMINI_API_KEY` into `.env`. No re-pairing needed.

**Fresh install:**
1. Set `OPENCLAW_GATEWAY_TOKEN`, `GOOGLE_API_KEY`, `GEMINI_API_KEY` in `.env`
2. Update `config/openclaw/openclaw.json` → `gateway.auth.token` to match `OPENCLAW_GATEWAY_TOKEN`
3. Run wizard for WhatsApp: `docker exec -it openclaw node openclaw.mjs doctor`

## Grafana Cloud

Set `GCLOUD_RW_API_KEY` in `.env` to enable Alloy. `init.sh` runs the [Grafana Cloud install script](https://storage.googleapis.com/cloud-onboarding/alloy/scripts/install-linux.sh) with IDs/URLs from `.env` (see `.env.example`).

## Managing

```bash
cd /opt/mediaserver
sudo docker compose ps
sudo docker compose logs -f jellyfin
sudo docker compose restart sonarr
sudo docker compose pull && sudo docker compose up -d
```
