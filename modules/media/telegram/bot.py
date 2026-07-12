#!/usr/bin/env python3
"""Small Telegram -> Radarr bridge for private movie requests."""

import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request


BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "")
ALLOWED_CHAT_ID = os.environ.get("TELEGRAM_ALLOWED_CHAT_ID", "")
RADARR_URL = os.environ.get("RADARR_URL", "http://127.0.0.1:7878").rstrip("/")
RADARR_API_KEY = os.environ.get("RADARR_API_KEY", "")


def http_json(url, method="GET", payload=None, headers=None, timeout=60):
    body = None
    request_headers = {"Accept": "application/json"}
    if headers:
        request_headers.update(headers)
    if payload is not None:
        body = json.dumps(payload).encode()
        request_headers["Content-Type"] = "application/json"
    request = urllib.request.Request(
        url, data=body, headers=request_headers, method=method
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        raw = response.read()
        return json.loads(raw) if raw else {}


def telegram(method, payload=None, timeout=70):
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/{method}"
    data = {key: value for key, value in (payload or {}).items() if value is not None}
    return http_json(url, method="POST", payload=data, timeout=timeout).get("result")


def radarr(path, method="GET", payload=None, query=None):
    url = f"{RADARR_URL}{path}"
    if query:
        url += "?" + urllib.parse.urlencode(query)
    return http_json(
        url,
        method=method,
        payload=payload,
        headers={"X-Api-Key": RADARR_API_KEY},
    )


def send(chat_id, text):
    telegram("sendMessage", {"chat_id": chat_id, "text": text})


def allowed(chat_id):
    return bool(ALLOWED_CHAT_ID) and str(chat_id) == ALLOWED_CHAT_ID


def movie_label(movie):
    year = movie.get("year")
    return f"{movie.get('title', 'Unknown')} ({year})" if year else movie.get(
        "title", "Unknown"
    )


def search_movies(chat_id, query):
    movies = radarr("/api/v3/movie/lookup", query={"term": query})
    if not movies:
        send(chat_id, f"No Radarr match found for “{query}”.")
        return

    exact = [
        movie
        for movie in movies
        if movie.get("title", "").casefold() == query.casefold()
    ]
    if len(exact) == 1:
        add_movie(chat_id, exact[0].get("tmdbId"))
        return

    lines = ["Matches (use /add <TMDB ID>):"]
    for movie in movies[:8]:
        tmdb_id = movie.get("tmdbId")
        if tmdb_id:
            lines.append(f"{movie_label(movie)} — {tmdb_id}")
    send(chat_id, "\n".join(lines))


def add_movie(chat_id, tmdb_id):
    if not tmdb_id or not str(tmdb_id).isdigit():
        send(chat_id, "Usage: /add <TMDB ID>")
        return

    lookup = radarr("/api/v3/movie/lookup/tmdb", query={"tmdbId": tmdb_id})
    if not lookup:
        send(chat_id, "Radarr could not find that TMDB ID.")
        return

    existing = radarr("/api/v3/movie")
    if any(str(movie.get("tmdbId")) == str(tmdb_id) for movie in existing):
        send(chat_id, f"{movie_label(lookup)} is already in Radarr.")
        return

    profiles = radarr("/api/v3/qualityprofile")
    roots = radarr("/api/v3/rootfolder")
    if not profiles or not roots:
        send(chat_id, "Radarr has no quality profile or root folder configured.")
        return

    profile = next(
        (item for item in profiles if item.get("name", "").casefold() == "hd-1080p"),
        profiles[0],
    )
    root = next(
        (item for item in roots if item.get("path") == "/mnt/hdd/media/movies"),
        roots[0],
    )
    folder_name = lookup.get("folderName") or lookup.get("title", "movie")
    movie = dict(lookup)
    movie.update(
        {
            "qualityProfileId": profile["id"],
            "rootFolderPath": root["path"],
            "path": root["path"].rstrip("/") + "/" + folder_name,
            "monitored": True,
            "minimumAvailability": "released",
            "addOptions": {"searchForMovie": True, "monitor": "movieOnly"},
        }
    )
    result = radarr("/api/v3/movie", method="POST", payload=movie)
    send(chat_id, f"Added {movie_label(result)} to Radarr; search started.")


def status(chat_id):
    queue = radarr("/api/v3/queue", query={"page": 1, "pageSize": 10})
    records = queue.get("records", [])
    if not records:
        send(chat_id, "Radarr queue is empty.")
        return
    lines = ["Radarr queue:"]
    for item in records:
        lines.append(f"- {item.get('title', 'Unknown')}: {item.get('status', 'unknown')}")
    send(chat_id, "\n".join(lines))


def handle_message(message):
    chat_id = message.get("chat", {}).get("id")
    text = (message.get("text") or "").strip()
    if chat_id is None or not text or not allowed(chat_id):
        return
    try:
        command, _, argument = text.partition(" ")
        command = command.split("@", 1)[0].casefold()
        if command in {"/start", "/help"}:
            send(
                chat_id,
                "Commands:\n/movie <title> — search and add an exact match\n"
                "/add <tmdb id> — add a search result\n/status — show Radarr downloads",
            )
        elif command == "/movie" and argument.strip():
            search_movies(chat_id, argument.strip())
        elif command == "/add":
            add_movie(chat_id, argument.strip())
        elif command == "/status":
            status(chat_id)
        else:
            send(chat_id, "Use /help for available commands.")
    except (urllib.error.URLError, TimeoutError, ValueError, KeyError) as error:
        print(f"request failed: {type(error).__name__}: {error}", flush=True)
        send(chat_id, "The request failed. Check Radarr and try again.")


def main():
    if not BOT_TOKEN or not ALLOWED_CHAT_ID or not RADARR_API_KEY:
        print(
            "Telegram bridge disabled: set TELEGRAM_BOT_TOKEN, "
            "TELEGRAM_ALLOWED_CHAT_ID, and RADARR_API_KEY in .env.",
            flush=True,
        )
        return

    telegram("getMe")
    offset = 0
    print("Telegram bridge is polling.", flush=True)
    while True:
        try:
            updates = telegram(
                "getUpdates",
                {"offset": offset, "timeout": 50, "allowed_updates": ["message"]},
                timeout=65,
            )
            for update in updates or []:
                offset = update["update_id"] + 1
                handle_message(update.get("message", {}))
        except (urllib.error.URLError, TimeoutError, ValueError, KeyError) as error:
            print(f"poll failed: {type(error).__name__}: {error}", flush=True)
            time.sleep(10)


if __name__ == "__main__":
    main()
