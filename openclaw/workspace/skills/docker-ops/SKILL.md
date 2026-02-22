# Docker Operations Skill

Teaches the agent how to manage Docker and the media server stack.

## Context

- Compose file: `/opt/mediaserver/docker-compose.yml`
- Root: `/opt/mediaserver` (MEDIASERVER_ROOT)

## Commands

### Status & Logs

```bash
cd /opt/mediaserver
docker compose ps
docker compose logs -f <service>
docker compose logs --tail=50 <service>
```

### Restart & Update

```bash
docker compose restart <service>
docker compose pull
docker compose up -d
```

### Health Check

```bash
docker compose ps --format "table {{.Name}}\t{{.Status}}"
docker inspect --format '{{.State.Health.Status}}' <container>
```

### Image Update Workflow

1. `docker compose pull`
2. `docker compose up -d`
3. Verify: `docker compose ps`
4. Check logs for errors: `docker compose logs -f <service>`

### Log Inspection

- Journal (if daemon.json uses journald): `journalctl -u docker CONTAINER_NAME=<name>`
- Docker logs: `docker logs <container>`
- Compose: `docker compose logs <service>`
