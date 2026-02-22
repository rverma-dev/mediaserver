# MEMORY.md - Persistent Knowledge

_Curated long-term memory. Update when you learn something worth keeping._

## Media Server Architecture

- **Stack**: Jellyfin, Sonarr, Radarr, Prowlarr, Bazarr, qBittorrent, Seerr
- **Network**: 172.20.0.0/24, Caddy at .2, WARP at .3, OpenClaw at .10
- **Prowlarr/Seerr**: Run inside WARP container (network_mode: service:warp) for indexer access
- **Data**: `/opt/mediaserver/data` — torrents (complete/incomplete), media (movies/tv)
- **Config**: `/opt/mediaserver/config/<service>` — persistent state per service

## Service Endpoints

| Service   | Internal URL           | API Key location              |
|-----------|------------------------|--------------------------------|
| Sonarr    | http://sonarr:8989     | config/sonarr/config.xml      |
| Radarr    | http://radarr:7878     | config/radarr/config.xml      |
| Prowlarr  | http://warp:9696       | config/prowlarr/config.xml    |
| Bazarr    | http://bazarr:6767     | config/bazarr/config/config.yaml |
| qBittorrent | http://qbittorrent:8080 | config/qbittorrent/...        |
| Jellyfin  | http://jellyfin:8096   | No API key for library scan   |

## Known Issues & Fixes

- _Add as you encounter them_

## Common Maintenance

- **Library scan**: Jellyfin → System → Scan Library
- **Update stack**: `docker compose pull && docker compose up -d`
- **Check WARP**: `curl -x socks5h://172.20.0.3:1080 -s https://cloudflare.com/cdn-cgi/trace`
