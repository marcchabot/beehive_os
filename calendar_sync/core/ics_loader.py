"""
core/ics_loader.py — ICS calendar loader with correct timezone handling.

Key design decisions:
  - All internal timestamps normalized to UTC (aware datetime)
  - RRULE events skipped in v1 (server-side expansion not guaranteed)
  - ETag caching to avoid redundant downloads
  - Uses `icalendar` library for RFC 5545-compliant parsing
  - Graceful degradation: errors per-source, never crash the daemon

Timezone normalization rules:
  - datetime with tzinfo  → astimezone(UTC)
  - naive datetime        → assumed UTC (icalendar emits naive for UTC-encoded)
  - date (all-day)        → midnight UTC, flagged as all_day=True
"""
from __future__ import annotations

import logging
from datetime import date, datetime, timedelta, timezone
from typing import Iterator

import aiohttp
from icalendar import Calendar

logger = logging.getLogger(__name__)

# ── Icon mapping ─────────────────────────────────────────────────────────────

ICON_MAP: dict[str, str] = {
    "soccer": "⚽",    "football": "⚽",  "karate": "🥋",   "karaté": "🥋",
    "pharmacie": "💊", "pharmacy": "💊", "médecin": "🏥",  "doctor": "🏥",
    "anniversaire": "🎂", "birthday": "🎂",
    "réunion": "📋",   "meeting": "📋",
    "vacances": "✈️",  "vacation": "✈️",
    "cours": "📚",     "class": "📚",    "école": "📚",
    "dentiste": "🦷",  "dentist": "🦷",
    "gym": "💪",       "yoga": "🧘",
    "noah": "🏂",      "ski": "🏂",
    "work": "💼",      "travail": "💼",
    "rendez-vous": "🩺",
    "famille": "👨‍👩‍👦",  "amis": "👥",
    "livraison": "📦", "lufa": "📦",
    "poubelle": "🗑️",  "recyclage": "🗑️",
    "appel": "📞",     "telus": "📞",
    "ménage": "🧹",
}


def get_icon(title: str) -> str:
    t = title.lower()
    for keyword, icon in ICON_MAP.items():
        if keyword in t:
            return icon
    return "📅"


# ── Timezone normalization ────────────────────────────────────────────────────

def normalize_to_utc(dt_value: datetime | date) -> tuple[datetime, bool]:
    """Convert any icalendar datetime/date value to (utc_aware_datetime, is_all_day).

    Cases handled:
      1. timezone-aware datetime  → astimezone(UTC)
      2. naive datetime           → treated as UTC (icalendar convention for 'Z' suffix)
      3. date (all-day VEVENT)    → midnight UTC, is_all_day=True
    """
    if isinstance(dt_value, datetime):
        if dt_value.tzinfo is None:
            # Naive = originally stored as UTC (or TZID stripped by icalendar)
            return dt_value.replace(tzinfo=timezone.utc), False
        return dt_value.astimezone(timezone.utc), False

    # Pure date → all-day event
    return (
        datetime(dt_value.year, dt_value.month, dt_value.day, tzinfo=timezone.utc),
        True,
    )


# ── ICSLoader ────────────────────────────────────────────────────────────────

class ICSLoader:
    """Fetches and parses one ICS calendar source.

    Args:
        source_id:    Unique identifier (from user_config.json "id")
        url:          HTTPS URL of the .ics feed
        label:        Human-readable label (shown as event "sub")
        color:        Hex colour for the source (passed through to events)
    """

    HTTP_TIMEOUT    = aiohttp.ClientTimeout(total=15)
    LOOKAHEAD_DAYS  = 60
    PAST_CUTOFF_MIN = 30

    def __init__(self, source_id: str, url: str, label: str, color: str = "#FFB81C"):
        self.source_id = source_id
        self.url       = url
        self.label     = label
        self.color     = color

        # State updated after each successful fetch
        self.last_ok:    str | None = None
        self.last_error: str | None = None

        # ETag cache to avoid redundant downloads
        self._etag:          str | None = None
        self._cached_events: list[dict] = []

    # ── Public API ────────────────────────────────────────────────────────────

    async def fetch(self, session: aiohttp.ClientSession) -> list[dict]:
        """Fetch and parse the ICS feed.

        Returns the event list (possibly from cache on HTTP 304).
        Never raises — errors are logged and stored in last_error.
        """
        headers: dict[str, str] = {"User-Agent": "Bee-Hive-OS/2.0 calendar-sync"}
        if self._etag:
            headers["If-None-Match"] = self._etag

        try:
            async with session.get(
                self.url, timeout=self.HTTP_TIMEOUT, headers=headers,
                ssl=True,
            ) as resp:
                if resp.status == 304:
                    logger.debug("[%s] 304 Not Modified — using cache (%d events)",
                                 self.source_id, len(self._cached_events))
                    return self._cached_events

                resp.raise_for_status()
                etag = resp.headers.get("ETag")
                text = await resp.text(encoding="utf-8", errors="replace")

        except aiohttp.ClientResponseError as exc:
            self.last_error = f"HTTP {exc.status}: {exc.message}"
            logger.warning("[%s] %s", self.source_id, self.last_error)
            return self._cached_events  # serve stale cache on error

        except aiohttp.ClientError as exc:
            self.last_error = f"Network error: {exc}"
            logger.warning("[%s] %s", self.source_id, self.last_error)
            return self._cached_events

        except Exception as exc:
            self.last_error = f"Unexpected error: {exc}"
            logger.exception("[%s] Unexpected fetch error", self.source_id)
            return self._cached_events

        # Parse fresh data
        events = list(self._parse(text))
        self._etag          = etag
        self._cached_events = events
        self.last_ok        = datetime.now(timezone.utc).isoformat()
        self.last_error     = None
        logger.info("[%s] Loaded %d event(s)", self.source_id, len(events))
        return events

    # ── Internal parsing ─────────────────────────────────────────────────────

    def _parse(self, ics_text: str) -> Iterator[dict]:
        """Yield normalised event dicts from raw ICS text."""
        try:
            cal = Calendar.from_ical(ics_text)
        except Exception as exc:
            logger.error("[%s] ICS parse error: %s", self.source_id, exc)
            return

        now_utc      = datetime.now(timezone.utc)
        past_cutoff  = now_utc - timedelta(minutes=self.PAST_CUTOFF_MIN)
        future_limit = now_utc + timedelta(days=self.LOOKAHEAD_DAYS)
        skipped_rrule = 0

        for component in cal.walk():
            if component.name != "VEVENT":
                continue

            # ── v1: skip recurring events (RRULE not expanded) ──────────────
            if component.get("RRULE") is not None:
                skipped_rrule += 1
                continue

            dtstart = component.get("DTSTART")
            if dtstart is None:
                continue

            try:
                dt_utc, is_all_day = normalize_to_utc(dtstart.dt)
            except Exception as exc:
                logger.warning("[%s] Cannot parse DTSTART for '%s': %s",
                               self.source_id, component.get("SUMMARY", "?"), exc)
                continue

            # Time-window filter
            if dt_utc < past_cutoff or dt_utc > future_limit:
                continue

            # ── Build event dict ─────────────────────────────────────────────
            uid      = str(component.get("UID", f"{self.source_id}_{dt_utc.timestamp():.0f}"))
            summary  = str(component.get("SUMMARY",  ""))
            location = str(component.get("LOCATION", ""))
            if len(location) > 60:
                location = location[:57] + "…"

            # Convert to local time for display only
            dt_local = dt_utc.astimezone()

            yield {
                "id":        f"{self.source_id}_{uid[:24]}",
                "source_id": self.source_id,
                "icon":      get_icon(summary),
                "title":     summary,
                "time":      "" if is_all_day else dt_local.strftime("%Hh%M"),
                "date":      dt_local.strftime("%Y-%m-%d"),
                "timestamp": dt_utc.timestamp(),
                "sub":       self.label,
                "location":  location,
                "urgent":    "urgent" in summary.lower(),
                "all_day":   is_all_day,
                "color":     self.color,
            }

        if skipped_rrule:
            logger.debug(
                "[%s] Skipped %d RRULE event(s) — recurring events not expanded in v1",
                self.source_id, skipped_rrule,
            )
