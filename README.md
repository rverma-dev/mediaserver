# Raspberry Pi 5 Media Server

Self-hosted media server on Pi 5 (NVMe boot, Raspberry Pi OS Lite Trixie).

## Architecture

```
Prowlarr (indexers) --> Sonarr (TV) --> qBittorrent (downloads) --> Jellyfin (streaming)
                    --> Radarr (Movies) ↗                       ↗
                    --> Bazarr (subtitles) ----------------------
```

All traffic from Prowlarr routes through Cloudflare WARP to bypass ISP SNI blocking.
Caddy reverse proxy serves everything on port 80.

## Quick Start (Fresh Pi)

```bash
# Clone to /opt/mediaserver
sudo git clone git@github.com:rverma-dev/mediaserver.git /opt/mediaserver
sudo chown -R 1000:1000 /opt/mediaserver

# Run setup
/opt/mediaserver/init.sh
```

This handles: system update, Docker install, directory creation, static IP, container deployment.

## URLs

All services at `http://<pi-ip>`:

| Path | Service | Purpose |
|------|---------|---------|
| `/jellyfin/` | Jellyfin | Media streaming |
| `/qbit/` | qBittorrent | Torrent client |
| `/sonarr/` | Sonarr | TV show automation |
| `/radarr/` | Radarr | Movie automation |
| `/prowlarr/` | Prowlarr | Indexer management |
| `/bazarr/` | Bazarr | Subtitle management |

## Credentials

All services: **admin / abcdef**

Change after setup if needed.

## Stack

| Container | Image | Notes |
|-----------|-------|-------|
| caddy | `caddy:2` | Reverse proxy, port 80 |
| warp | `caomingjun/warp` | Cloudflare WARP SOCKS5 proxy |
| jellyfin | `jellyfin/jellyfin` | HEVC HW decode via `/dev/video19` |
| qbittorrent | `linuxserver/qbittorrent` | Peer port 6881 exposed |
| sonarr | `linuxserver/sonarr` | Root: `/data/media/tv` |
| radarr | `linuxserver/radarr` | Root: `/data/media/movies` |
| prowlarr | `linuxserver/prowlarr` | Routes through WARP network |
| bazarr | `linuxserver/bazarr` | Connected to Sonarr + Radarr |

## Directory Layout

```
/opt/mediaserver/
├── docker-compose.yml    # Stack definition
├── Caddyfile             # Reverse proxy routes
├── .env                  # TZ, PUID, PGID
├── init.sh               # Fresh install script
├── config/               # Persistent service configs (in git)
│   ├── jellyfin/
│   ├── qbittorrent/
│   ├── sonarr/
│   ├── radarr/
│   ├── prowlarr/
│   └── bazarr/
└── data/                 # NOT in git
    ├── torrents/
    │   ├── complete/
    │   └── incomplete/
    └── media/
        ├── movies/
        └── tv/
```

Hardlinks work because all containers mount `data/` at `/data`.

## Managing

```bash
cd /opt/mediaserver

# Status
docker compose ps

# Logs
docker compose logs -f jellyfin

# Restart one service
docker compose restart sonarr

# Update all
docker compose pull && docker compose up -d

# Stop everything
docker compose down
```

## API Keys

Pre-configured, used for inter-service communication:

| Service | API Key |
|---------|---------|
| Sonarr | `fe844a2835e64defa363291763992806` |
| Radarr | `84c66fa0cdbf412fa97bb68f210fa902` |
| Prowlarr | `7aa5e13a824c4c19bae6420bbf4f0921` |
| Bazarr | `b6b3bbacc78345bbb63b4b9de3565bc5` |

## Pi 5 Notes

- **HEVC HW decode**: `/dev/video19` (rpi-hevc-dec) passed to Jellyfin
- **No HW encode**: Software transcode only (Cortex-A76 handles 1-2x 1080p)
- **NVMe**: Plenty of I/O for concurrent downloads + streaming
- **Thermals**: Use active cooler for sustained load
- **Static IP**: Set via NetworkManager, persists across reboots
