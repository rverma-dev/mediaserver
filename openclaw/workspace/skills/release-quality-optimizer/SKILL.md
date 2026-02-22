---
name: release-quality-optimizer
description: Optimize movie/TV request quality for user preferences (resolution, codec, audio, subtitles, file size tradeoffs). Use when user asks for better release quality, wrong grabs, profile tuning, or preferred encodes in Sonarr/Radarr.
---

# Release Quality Optimizer

Tune request strategy so grabbed releases match playback and quality goals.

## Workflow

1. Capture target profile (1080p, codec preference, audio/subtitle expectations).
2. Inspect current quality profiles/custom formats in Sonarr/Radarr.
3. Identify why poor grabs happen (profile order, cutoffs, unwanted tags, indexer mix).
4. Suggest profile/custom-format adjustments with rationale.
5. Provide safe test steps using one sample title before broad rollout.

## Defaults (unless user overrides)

- Prefer 1080p WebDL/BluRay.
- Prefer H.264/H.265 for compatibility and size balance.
- Keep remux/high-bitrate only when explicitly requested.

## Guardrails

- Avoid global changes without previewing expected impact.
- Record before/after settings so rollback is easy.
