# Health Check Skill

Self-healing patterns for the media server.

## Checks to Run

### 1. All Containers Running

```bash
docker compose -f /opt/mediaserver/docker-compose.yml ps
```

Expect: caddy, warp, jellyfin, qbittorrent, sonarr, radarr, prowlarr, seerr, bazarr, openclaw, host-exec — all "Up" or "running".

### 2. WARP Connectivity

```bash
curl -x socks5h://172.20.0.3:1080 -s -o /dev/null -w "%{http_code}" https://cloudflare.com/cdn-cgi/trace
```

Expect: 200. If fails, WARP may need restart.

### 3. Disk Space

```bash
df -h /opt/mediaserver
```

Alert if < 10% free.

### 4. Jellyfin Responding

```bash
curl -s -o /dev/null -w "%{http_code}" http://jellyfin:8096/health
```

Expect: 200.

### 5. Restart Failed Services

```bash
docker compose -f /opt/mediaserver/docker-compose.yml restart <service>
```

### 6. Alert on Issues

- Critical: Use WhatsApp channel if configured
- Keep messages concise: service name, issue, action taken

## Suggested Heartbeat Checks

Add to HEARTBEAT.md (rotate 2–4x/day):

- Containers all up?
- WARP reachable?
- Disk space OK?
- Jellyfin healthy?
