---
name: media-ops-autopilot
description: Set up lightweight recurring maintenance for media stack operations (queue hygiene, failed items, subtitle drift, indexer sanity, disk pressure signals). Use when user wants proactive upkeep, automation, reminders, or periodic checks.
---

# Media Ops Autopilot

Design low-noise maintenance routines that prevent backlog and failures.

## Workflow

1. Identify recurring checks with highest payoff.
2. Choose cadence (heartbeat batch vs cron exact-time job).
3. Keep checks lightweight; avoid duplicate polling loops.
4. Send only actionable summaries, not raw noise.
5. Track last-run state to avoid repeated alerts.

## Recommended Checks

- Failed downloads/import failures
- Stalled queue items
- Indexer authentication/outage signals
- Subtitle missing for recently added media
- Disk free-space threshold warnings

## Guardrails

- Never auto-delete media without explicit approval.
- Prefer “detect + notify + suggest fix” over silent mutation.
- Include rollback path for every automated action.
