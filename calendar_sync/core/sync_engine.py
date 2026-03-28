"""
core/sync_engine.py — Orchestrates sync across all configured calendar sources.

Responsibilities:
  - Build ICSLoader / GoogleAPISource instances from config
  - Run all fetches concurrently (asyncio.gather)
  - Deduplicate events by id
  - Write events_live.json atomically (tmp → rename)
  - Persist sync state to sync_state.json
  - Hot-reload sources when config changes (preserves ETag cache)

Google API support mirrors the original daemon (optional deps).
"""
from __future__ import annotations

import asyncio
import json
import logging
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

import aiohttp

from ..config.schema import BeeHiveConfig, CalendarSourceConfig
from .ics_loader import ICSLoader

logger = logging.getLogger(__name__)


# ── Google API source (optional deps, mirrors bee_sync_daemon v2.0) ──────────

class GoogleAPISource:
    """Wraps Google Calendar API; requires google-auth + google-api-python-client."""

    SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"]

    def __init__(self, cfg: CalendarSourceConfig, token_path: Path, creds_path: Path):
        self.source_id   = cfg.id
        self.calendar_id = cfg.calendar_id
        self.label       = cfg.label
        self.color       = cfg.color
        self.token_path  = token_path
        self.creds_path  = creds_path
        self.last_ok:    str | None = None
        self.last_error: str | None = None

    async def fetch(self, session: aiohttp.ClientSession) -> list[dict]:
        """Run blocking Google API call in a thread pool."""
        try:
            creds = self._get_credentials()
            if creds is None:
                self.last_error = (
                    f"Google credentials missing or invalid. "
                    f"Run: python3 bee_sync_daemon.py --auth"
                )
                logger.error("[%s] %s", self.source_id, self.last_error)
                return []

            loop   = asyncio.get_event_loop()
            events = await loop.run_in_executor(None, self._fetch_sync, creds)
            self.last_ok    = datetime.now(timezone.utc).isoformat()
            self.last_error = None
            logger.info("[%s] Loaded %d event(s) via Google API", self.source_id, len(events))
            return events

        except Exception as exc:
            self.last_error = str(exc)
            logger.warning("[%s] Google API error: %s", self.source_id, exc)
            return []

    def _get_credentials(self):
        try:
            from google.auth.transport.requests import Request
            from google.oauth2.credentials import Credentials
        except ImportError:
            logger.error("google-auth not installed. pip install google-auth google-auth-oauthlib")
            return None

        if not self.token_path.exists():
            return None

        creds = Credentials.from_authorized_user_file(str(self.token_path), self.SCOPES)
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
            self.token_path.write_text(creds.to_json())
        return creds if (creds and creds.valid) else None

    def _fetch_sync(self, creds) -> list[dict]:
        from datetime import timedelta

        from googleapiclient.discovery import build

        service   = build("calendar", "v3", credentials=creds, cache_discovery=False)
        now_utc   = datetime.now(timezone.utc)
        time_min  = now_utc.strftime("%Y-%m-%dT%H:%M:%SZ")
        time_max  = (now_utc + timedelta(days=60)).strftime("%Y-%m-%dT%H:%M:%SZ")

        result = service.events().list(
            calendarId=self.calendar_id,
            timeMin=time_min, timeMax=time_max,
            maxResults=200,
            singleEvents=True,   # expands recurrences server-side
            orderBy="startTime",
        ).execute()

        events = []
        for item in result.get("items", []):
            ev = self._parse_item(item)
            if ev:
                events.append(ev)
        return events

    def _parse_item(self, item: dict) -> Optional[dict]:
        from datetime import timedelta

        start   = item.get("start", {})
        dt_str  = start.get("dateTime") or start.get("date")
        if not dt_str:
            return None

        all_day = "dateTime" not in start

        if all_day:
            dt_local = datetime.strptime(dt_str, "%Y-%m-%d")
            ts       = dt_local.replace(tzinfo=timezone.utc).timestamp()
        else:
            dt_aware = datetime.fromisoformat(dt_str)
            ts       = dt_aware.timestamp()
            dt_local = datetime.fromtimestamp(ts)

        now_ts = datetime.now(timezone.utc).timestamp()
        if ts < now_ts - 1800:
            return None

        from .ics_loader import get_icon
        summary  = item.get("summary", "")
        location = item.get("location", "")
        uid      = item.get("id", f"{self.source_id}_{ts:.0f}")

        return {
            "id":        f"{self.source_id}_{uid[:24]}",
            "source_id": self.source_id,
            "icon":      get_icon(summary),
            "title":     summary,
            "time":      "" if all_day else dt_local.strftime("%Hh%M"),
            "date":      dt_local.strftime("%Y-%m-%d"),
            "timestamp": ts,
            "sub":       self.label,
            "location":  location[:60] if location else "",
            "urgent":    "urgent" in summary.lower(),
            "all_day":   all_day,
            "color":     self.color,
        }


# ── SyncEngine ────────────────────────────────────────────────────────────────

class SyncEngine:
    """Orchestrates a full sync cycle across all configured sources."""

    def __init__(
        self,
        config:     BeeHiveConfig,
        data_dir:   Path,
        state_path: Path,
        token_path: Path | None = None,
        creds_path: Path | None = None,
    ):
        self._config     = config
        self._data_dir   = data_dir
        self._state_path = state_path
        self._token_path = token_path
        self._creds_path = creds_path

        # Source registries; keyed by source_id
        self._ics_loaders:   dict[str, ICSLoader]      = {}
        self._google_sources: dict[str, GoogleAPISource] = {}

        self._build_sources(config)

    # ── Config hot-reload ─────────────────────────────────────────────────────

    def update_config(self, new_config: BeeHiveConfig) -> None:
        """Update source registry without losing ETag / stale-cache state."""
        self._config = new_config

        new_ics_ids    = {s.id for s in new_config.ics_sources}
        new_google_ids = {s.id for s in new_config.google_sources}

        # Remove deleted sources
        for sid in list(self._ics_loaders.keys()):
            if sid not in new_ics_ids:
                del self._ics_loaders[sid]
        for sid in list(self._google_sources.keys()):
            if sid not in new_google_ids:
                del self._google_sources[sid]

        # Add new sources; preserve existing ones (keeps ETag cache)
        for src in new_config.ics_sources:
            if src.id not in self._ics_loaders:
                self._ics_loaders[src.id] = ICSLoader(
                    source_id=src.id, url=src.url,
                    label=src.label, color=src.color,
                )
        for src in new_config.google_sources:
            if src.id not in self._google_sources:
                self._google_sources[src.id] = self._make_google_source(src)

    # ── Sync ──────────────────────────────────────────────────────────────────

    async def sync(self) -> dict:
        """Run one full sync cycle. Returns the written payload."""
        self._backup_previous()

        all_events:   list[dict] = []
        sources_meta: list[dict] = []

        async with aiohttp.ClientSession() as session:
            # Gather all sources concurrently
            sources_list = (
                list(self._ics_loaders.values()) +
                list(self._google_sources.values())
            )
            if not sources_list:
                logger.info("No sources configured — skipping sync")
                return {}

            results = await asyncio.gather(
                *[src.fetch(session) for src in sources_list],
                return_exceptions=True,
            )

        for src, result in zip(sources_list, results):
            if isinstance(result, Exception):
                src.last_error = str(result)
                logger.error("[%s] Unhandled exception: %s", src.source_id, result)
                result = []

            all_events.extend(result)
            sources_meta.append({
                "id":       src.source_id,
                "type":     "google_api" if isinstance(src, GoogleAPISource) else "ics",
                "label":    src.label,
                "last_ok":  src.last_ok,
                "error":    src.last_error,
            })

        # Deduplicate by id + sort chronologically
        seen:   set[str] = set()
        deduped: list[dict] = []
        for ev in sorted(all_events, key=lambda e: e["timestamp"]):
            if ev["id"] not in seen:
                seen.add(ev["id"])
                deduped.append(ev)

        payload = {
            "_meta": {
                "version":   "2.1",
                "last_sync": datetime.now(timezone.utc).isoformat(),
                "sources":   sources_meta,
            },
            "events": deduped,
        }

        self._write_atomic(payload)
        self._persist_state(sources_meta, len(deduped))
        return payload

    # ── Internal helpers ──────────────────────────────────────────────────────

    def _build_sources(self, cfg: BeeHiveConfig) -> None:
        for src in cfg.ics_sources:
            self._ics_loaders[src.id] = ICSLoader(
                source_id=src.id, url=src.url,
                label=src.label, color=src.color,
            )
        for src in cfg.google_sources:
            self._google_sources[src.id] = self._make_google_source(src)

    def _make_google_source(self, src: CalendarSourceConfig) -> GoogleAPISource:
        token = self._token_path or (Path.home() / "beehive_os/config/google_calendar_token.json")
        creds = self._creds_path or (Path.home() / "beehive_os/config/google_credentials.json")
        return GoogleAPISource(src, token_path=token, creds_path=creds)

    def _backup_previous(self) -> None:
        """Copy events_live.json → events_live.bak before overwriting."""
        live = self._data_dir / "events_live.json"
        if live.exists():
            try:
                shutil.copy2(live, live.with_suffix(".bak"))
            except OSError as exc:
                logger.warning("Could not create backup: %s", exc)

    def _write_atomic(self, payload: dict) -> None:
        out = self._data_dir / "events_live.json"
        tmp = out.with_suffix(".tmp")
        self._data_dir.mkdir(parents=True, exist_ok=True)

        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, indent=2)
        tmp.replace(out)
        logger.info(
            "Sync complete: %d event(s) → %s",
            len(payload.get("events", [])), out,
        )

    def _persist_state(self, sources_meta: list[dict], event_count: int) -> None:
        state = {
            "last_sync":   datetime.now(timezone.utc).isoformat(),
            "event_count": event_count,
            "sources":     {s["id"]: s for s in sources_meta},
        }
        self._state_path.parent.mkdir(parents=True, exist_ok=True)
        tmp = self._state_path.with_suffix(".tmp")
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(state, f, indent=2)
        tmp.replace(self._state_path)
