---
name: seerr-curator
description: Build movie/TV recommendations specifically for Seerr with direct request URLs and chat-native visual cards. Use when user asks for recommendations, “what should I watch”, weekend picks, mood-based picks, Hindi/English lists, or asks for Seerr links/posters/buttons.
---

# Seerr Curator

Use this workflow to produce recommendation replies that are instantly actionable.

## Workflow

1. Pick 4–8 relevant titles based on the user’s requested mood/language/genre.
2. Prefer currently popular, well-rated, and broadly accessible picks.
3. For each title, provide:
   - Poster image as real media attachment (not markdown inline image in Telegram)
   - Compact caption: title, year, one-line hook
   - Direct Seerr request URL (`/movie/<tmdbId>` or `/tv/<tmdbId>`)
4. If confidence on ID is low, send search URL fallback and label it clearly.
5. Offer a follow-up pack (Top 3, family-safe, intense, binge, etc.).

## Output Rules

- On Telegram/WhatsApp, send one poster per message with concise caption.
- Keep each caption short and scannable.
- Avoid giant walls of text.
- Prioritize direct links over search links.

## Quality Bar

- No broken poster URLs.
- Correct movie vs TV route in Seerr.
- Keep recommendations varied in tone unless user asks for a specific mood.
