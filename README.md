# Raspberry Pi 5 — Nix Media Stack

Single Nix flake for the Pi: **arr stack** (Prowlarr → Sonarr/Radarr → qBittorrent → Jellyfin), **Immich** (photos), **Seerr** (requests). Public exposure via **DuckDNS** at `rverma-pi.duckdns.org`. **OpenClaw** (AI assistant with Cursor backend) runs separately in `~/openclaw` — Caddy proxies `/` to it.

## Architecture

```
Prowlarr (indexers) --> Sonarr (TV) --> qBittorrent (downloads) --> Jellyfin (streaming)
                    --> Radarr (Movies) ↗                       ↗
                    --> Bazarr (subtitles) ----------------------
Seerr (discovery UI) — HTTPS :9443
OpenClaw (CursorClaw) — HTTPS catch-all, runs in ~/openclaw, Cursor as AI brain
Immich — Photo management (PostgreSQL + Valkey)
```

- **Caddy**: Reverse proxy, HTTPS via DuckDNS DNS challenge
- **Wireproxy**: Cloudflare WARP SOCKS5 for Prowlarr/Seerr (bypass ISP blocking)
- **Alloy**: Grafana Cloud logs/metrics (optional)

## Public URLs (rverma-pi.duckdns.org)

| Path | Service |
|------|---------|
| `https://rverma-pi.duckdns.org/` | OpenClaw (catch-all, see ~/openclaw) |
| `https://rverma-pi.duckdns.org/jellyfin/` | Jellyfin |
| `https://rverma-pi.duckdns.org/qbit/` | qBittorrent |
| `https://rverma-pi.duckdns.org/sonarr/` | Sonarr |
| `https://rverma-pi.duckdns.org/radarr/` | Radarr |
| `https://rverma-pi.duckdns.org/prowlarr/` | Prowlarr |
| `https://rverma-pi.duckdns.org/bazarr/` | Bazarr |
| `https://rverma-pi.duckdns.org/photos/` | Immich |
| `https://rverma-pi.duckdns.org:9443` | Seerr |

## Quick Start

```bash
git clone git@github.com:rverma-dev/mediaserver.git /home/pi/mediaserver
cd /home/pi/mediaserver
cp .env.example .env
# Edit .env: DUCKDNS_TOKEN, DUCKDNS_SUBDOMAIN=rverma-pi, *arr API keys, etc.
./init.sh
```

`init.sh` runs: `init-dirs` → `init-alloy` → `init-nix` (home-manager) → `init-network` → `init-security` → `init-deploy`.

---

## OpenClaw (CursorClaw)

AI assistant with **Cursor Agent CLI as the brain** — runs in `~/openclaw` (separate from mediaserver). Uses [openclaw-cursor-bridge](https://github.com/andeya/openclaw-cursor-bridge) to delegate all reasoning to Cursor. Accessible via WhatsApp, Telegram, and HTTPS at `/`.

**Setup**: See `~/openclaw/README.md` after cloning. Caddy proxies `/` to `127.0.0.1:18789` (OpenClaw gateway port).

---

## ARR Stack

Automated media acquisition and streaming pipeline. Prowlarr manages indexers; Sonarr/Radarr request content; qBittorrent downloads; Bazarr fetches subtitles; Jellyfin streams. Seerr provides the request UI.

### Prowlarr

**Function**: Indexer manager. Syncs indexers to Sonarr/Radarr, handles Jackett/NZB indexers, proxy for torrent sites.

**Usage**: Add indexers in UI; sync to apps; Sonarr/Radarr pull indexers from Prowlarr API.

**Configuration**: `config/prowlarr/config.xml` (seeded from template with `PROWLARR_API_KEY`). Runs through **proxychains + WARP** (SOCKS5 127.0.0.1:1080) to bypass ISP blocking. Port 9696.

### Sonarr

**Function**: TV automation. Monitors for new episodes, sends to qBittorrent, imports to library, renames/organizes.

**Usage**: Add series (search or TVDB ID); set quality profile; Sonarr grabs and imports automatically.

**Configuration**: `config/sonarr/config.xml` (seeded with `SONARR_API_KEY`). Port 8989. Root folder: `/mnt/hdd/media/tv`.

### Radarr

**Function**: Movie automation. Same flow as Sonarr but for movies (TMDB).

**Usage**: Add movies; set quality profile; Radarr grabs and imports.

**Configuration**: `config/radarr/config.xml` (seeded with `RADARR_API_KEY`). Port 7878. Root folder: `/mnt/hdd/media/movies`.

### Bazarr

**Function**: Subtitle manager. Fetches subtitles for Sonarr/Radarr media, supports multiple providers.

**Usage**: Configure providers; Bazarr runs alongside Sonarr/Radarr, matches and downloads subs.

**Configuration**: `config/bazarr/config/config.yaml` (seeded with `BAZARR_API_KEY`). Port 6767. Needs ffmpeg in PATH.

### qBittorrent

**Function**: Torrent client. Receives torrents from Sonarr/Radarr, downloads to `data/torrents/incomplete`, moves completed to `data/torrents/complete`. Sonarr/Radarr import from there.

**Usage**: Web UI at `/qbit/`; default user `admin`; whitelist `192.168.68.0/22` for LAN auth bypass.

**Configuration**: `config/qbittorrent/qBittorrent/config/qBittorrent.conf`. Port 8080. Paths: `/mnt/hdd/downloads/{complete,incomplete}` (HDD; same FS as media for Arr hardlinks).

### Jellyfin

**Function**: Media server. Streams movies/TV to clients. Transcodes when needed (ffmpeg). No account required for LAN.

**Usage**: Add library (movies → `data/media/movies`, TV → `data/media/tv`); scan; stream via web/Android/iOS.

**Configuration**: `config/jellyfin/`. Port 8096. Datadir/cache/transcodes on NVMe; media libraries at `/mnt/hdd/media`. Prefer H.264/HEVC; AV1/VP9 cause slow transcoding on Pi.

### Seerr

**Function**: Request manager. Users browse/request movies/TV; Seerr forwards to Sonarr/Radarr. Integrates with Plex/Jellyfin for user sync.

**Usage**: Configure Jellyfin/Sonarr/Radarr in settings; users request via UI; approvals go to arr stack.

**Configuration**: `config/seerr/settings.json`. Port 5055. Runs through **proxychains + WARP** for TMDB/API access. HTTPS at `:9443`.

---

## Immich

Self-hosted photo management. Upload, organize, backup, and share photos. Supports face detection, albums, tags, map view.

### What it does

- **Upload**: Web, mobile app, CLI; sync from device
- **Library**: Albums, timeline, map, people (with ML disabled; face detection off on Pi)
- **Sharing**: Shared links, albums

### Usage

- **Web**: `https://rverma-pi.duckdns.org/photos/`
- **Mobile**: Immich app, point to server URL
- **CLI**: `immich` CLI for uploads

### Configuration

| Location | Purpose |
|----------|---------|
| `config/immich/` | PostgreSQL data, config (NVMe) |
| `/mnt/hdd/immich/library` | Original images (HDD) |

**Services**: `immich-db` (PostgreSQL 17 + VectorChord), `immich-redis` (Valkey), `immich` (server)

**Environment**: `IMMICH_MACHINE_LEARNING_ENABLED=false` (no ML on Pi), `IMMICH_LOG_LEVEL=warn`

---

## External HDD (NVMe/HDD Split)

**Layout**: NVMe = control plane (OS, DBs, caches, metadata). HDD = data plane (media, torrents, Immich originals).

Format and auto-mount at `/mnt/hdd`:

```bash
lsblk                    # identify device (e.g. /dev/sda)
./scripts/init-hdd.sh format /dev/sda   # DESTROYS data; type YES to confirm
./scripts/init-hdd.sh fstab             # add fstab entry (noatime, commit=60)
./scripts/init-hdd.sh mount             # mount + create downloads/media/immich layout
```

**HDD layout** (Arr hardlinks require downloads + media on same FS):

| Path | Purpose |
|------|---------|
| `/mnt/hdd/downloads/{complete,incomplete}` | qBittorrent |
| `/mnt/hdd/media/{movies,tv}` | Sonarr/Radarr/Jellyfin |
| `/mnt/hdd/immich/library` | Immich originals |

**Migration** from old layout:
- Arr + qBittorrent: `./scripts/migrate-arr-paths.sh`. Then update Sonarr/Radarr root folders in UI → `/mnt/hdd/media/tv` and `/mnt/hdd/media/movies`; enable hardlinks.
- Immich: if you have existing photos in `data/immich`, move to `/mnt/hdd/immich/library` and update library path in Immich admin.

**Optional tuning:**
- `./scripts/init-hdd.sh uas` — check USB HDD uses UAS (not usb-storage)
- `./scripts/init-hdd.sh spindown` — disable aggressive spin-down (0=never)
- `./scripts/init-hdd.sh spindown-service 0` — persist spin-down setting across reboots
- `make verify` — performance verification (throughput, NVMe headroom)

## Infrastructure

| Component | Function |
|-----------|----------|
| **Caddy** | Reverse proxy, TLS via DuckDNS, routes `/jellyfin`, `/qbit`, etc. |
| **Wireproxy** | Cloudflare WARP SOCKS5 on 127.0.0.1:1080; Prowlarr/Seerr use proxychains |
| **Alloy** | Grafana Cloud agent; optional, set `GCLOUD_RW_API_KEY` in `.env` |

---

## Nix Flake Layout

```
flake.nix
├── hosts/pi/default.nix     # home-manager entry, imports modules
├── modules/
│   ├── shell               # zsh, starship, atuin, lazygit, aliases
│   ├── caddy               # Caddy + DuckDNS, OpenClaw proxy at /
│   ├── sonarr, radarr, prowlarr, bazarr, jellyfin, seerr, qbittorrent
│   ├── immich              # PostgreSQL 17 + VectorChord, Valkey, server
│   └── warp                # wireproxy (WARP SOCKS5)
└── pkgs/                   # Custom packages (caddy-duckdns, *arr, jellyfin, seerr)
```

Apply config: `make build` or `nix run home-manager -- switch --flake '.#pi' -b backup`

**nix-direnv**: `.envrc` loads the dev shell and `.env` when you `cd` into the repo. Requires [nix-direnv](https://github.com/nix-community/nix-direnv) in your direnv config. Run `direnv allow` once.

## .env Variables

| Variable | Purpose |
|----------|---------|
| `DUCKDNS_TOKEN`, `DUCKDNS_SUBDOMAIN` | Caddy TLS (set `rverma-pi` for subdomain) |
| `SONARR_API_KEY`, `RADARR_API_KEY`, `PROWLARR_API_KEY`, `BAZARR_API_KEY` | Injected into *arr configs via templates |
| `CURSOR_API_KEY` | Cursor Agent CLI (auto-exported in zsh; used by OpenClaw cursor-bridge) |
| `HDD_MOUNT_PATH` | Optional; HDD mount point (default: `/mnt/hdd`) |
| `GCLOUD_RW_API_KEY` | Grafana Cloud Alloy (optional) |

Fresh install: leave API keys empty, let services generate on first run, copy from each UI (Settings → General) into `.env`, then `home-manager switch` to re-seed configs.

## Shell Aliases

- `ms` → cd mediaserver
- `msl` → journalctl --user -f
- `mss` → status all services
- `msr` → systemctl --user restart
- `mslog <unit>` → journalctl --user -u
- `immich` → status immich stack
- `warp-status`, `warp-ip` → WARP connectivity check

## Managing

```bash
make status                    # all service statuses
make logs                      # follow all logs
systemctl --user restart sonarr  # restart one service
make build                     # home-manager switch
make gc                        # Nix garbage collection
make disk                      # disk usage
make warp-status               # WARP check
make temps                     # Pi temperature

systemctl --user status caddy sonarr radarr prowlarr bazarr jellyfin seerr qbittorrent wireproxy immich immich-db immich-redis
journalctl --user -u jellyfin -f
```
