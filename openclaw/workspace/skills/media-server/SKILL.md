# Media Server Skill

Teaches the agent how to manage the Arr stack and media services.

## API Keys

Keys are in config XML/YAML. Read them before making API calls:

- **Sonarr**: `config/sonarr/config.xml` → `<ApiKey>`
- **Radarr**: `config/radarr/config.xml` → `<ApiKey>`
- **Prowlarr**: `config/prowlarr/config.xml` → `<ApiKey>`
- **Bazarr**: `config/bazarr/config/config.yaml` → `auth.password`

## Endpoints

| Service   | Base URL                 | Key header |
|-----------|--------------------------|------------|
| Sonarr    | http://sonarr:8989/api/v3 | X-Api-Key  |
| Radarr    | http://radarr:7878/api/v3 | X-Api-Key  |
| Prowlarr  | http://warp:9696/api/v1   | X-Api-Key  |
| Bazarr    | http://bazarr:6767/api    | X-Api-Key  |

## Common Operations

### Search & Add

- **Sonarr**: `GET /series/lookup?term=<query>` → `POST /series` with tvdbId
- **Radarr**: `GET /movie/lookup?term=<query>` → `POST /movie` with tmdbId

### Check Download Status

- **Sonarr**: `GET /queue` — pending downloads
- **Radarr**: `GET /queue` — pending downloads

### Jellyfin Library Scan

Trigger via API or UI:
- API: `POST http://jellyfin:8096/Library/Refresh` (if API key configured)
- Or instruct user: Jellyfin → System → Scan Library

### qBittorrent

- **Pause all**: `POST /api/v2/torrents/pause` (with auth)
- **Resume**: `POST /api/v2/torrents/resume`
- **Remove**: `POST /api/v2/torrents/delete` (with deleteFiles flag)

Web UI: http://qbittorrent:8080 (or /qbit via Caddy)
