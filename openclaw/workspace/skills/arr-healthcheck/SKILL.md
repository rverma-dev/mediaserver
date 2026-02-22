---
name: arr-healthcheck
description: Diagnose and maintain Sonarr/Radarr/Prowlarr/qBittorrent/Jellyfin stack health. Use when user asks for arr stack audit, failed downloads, stuck queue, import issues, indexer failures, missing media, or “is everything healthy?”.
---

# Arr Healthcheck

Run a quick, structured health pass and return actionable findings.

## Workflow

1. Check container/service status first.
2. Check Sonarr and Radarr queue + health endpoints.
3. Check Prowlarr indexer status/errors.
4. Check qBittorrent connectivity and stalled torrents.
5. Summarize issues by severity: Critical / Warning / Info.
6. Propose minimal, safe fixes with exact commands or UI path.

## Reporting Template

- **Status:** Healthy / Degraded / Broken
- **Critical:** blockers to new requests or imports
- **Warnings:** quality-of-life problems
- **Next actions:** prioritized fix list

## Guardrails

- Do not run destructive cleanup without user confirmation.
- Prefer reversible actions first (retry, refresh, restart service).
- If unsure, collect logs before suggesting aggressive changes.
