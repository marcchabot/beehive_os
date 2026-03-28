"""
config/manager.py — Loads, validates, and hot-reloads user_config.json.

Usage:
    mgr = ConfigManager(Path("~/beehive_os/user_config.json"))
    cfg = mgr.load()          # first load
    cfg = mgr.reload()        # re-read from disk (called on SIGHUP)
"""
from __future__ import annotations

import json
import logging
from pathlib import Path

from .schema import (
    BeeEventsConfig,
    BeeHiveConfig,
    CalendarSourceConfig,
    LiveSyncConfig,
)

logger = logging.getLogger(__name__)

# Fields accepted by each dataclass (used to strip unknown JSON keys safely)
_CAL_FIELDS    = set(CalendarSourceConfig.__dataclass_fields__)
_EVENTS_FIELDS = set(BeeEventsConfig.__dataclass_fields__)
_SYNC_FIELDS   = set(LiveSyncConfig.__dataclass_fields__)


def _pick(d: dict, fields: set[str]) -> dict:
    """Return only the keys in `fields`, ignoring comments / unknown keys."""
    return {k: v for k, v in d.items() if k in fields}


class ConfigError(Exception):
    """Raised when user_config.json is missing or invalid."""


class ConfigManager:
    def __init__(self, config_path: Path):
        self._path = config_path.expanduser()
        self._config: BeeHiveConfig | None = None

    # ── Public API ────────────────────────────────────────────────────────────

    def load(self) -> BeeHiveConfig:
        """Parse config from disk. Raises ConfigError on failure."""
        if not self._path.exists():
            raise ConfigError(f"user_config.json not found: {self._path}")

        try:
            raw = json.loads(self._path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            raise ConfigError(f"Invalid JSON in {self._path}: {exc}") from exc

        self._config = self._parse(raw)
        logger.info(
            "Config loaded: %d calendar(s), interval=%ds",
            len(self._config.calendars),
            self._config.live_sync.interval_seconds,
        )
        return self._config

    def reload(self) -> BeeHiveConfig:
        """Re-read config from disk. Falls back to previous config on error."""
        try:
            return self.load()
        except ConfigError as exc:
            logger.warning("Config reload failed (%s) — keeping previous config", exc)
            if self._config is None:
                raise
            return self._config

    @property
    def config(self) -> BeeHiveConfig:
        if self._config is None:
            return self.load()
        return self._config

    # ── Internal ──────────────────────────────────────────────────────────────

    def _parse(self, raw: dict) -> BeeHiveConfig:
        calendars: list[CalendarSourceConfig] = []
        for cal_raw in raw.get("calendars", []):
            try:
                cal = CalendarSourceConfig(**_pick(cal_raw, _CAL_FIELDS))
                calendars.append(cal)
            except (TypeError, ValueError) as exc:
                logger.warning("Skipping invalid calendar entry %s: %s", cal_raw.get("id"), exc)

        # Fallback: legacy single-URL config (schema < 1.0)
        if not calendars and raw.get("events_ics_url"):
            try:
                calendars.append(CalendarSourceConfig(
                    id="default", type="ics",
                    url=raw["events_ics_url"], label="Calendrier",
                ))
                logger.info("Loaded legacy events_ics_url as calendar source")
            except ValueError as exc:
                logger.warning("Invalid legacy ICS URL: %s", exc)

        bee_events = BeeEventsConfig(**_pick(raw.get("bee_events", {}), _EVENTS_FIELDS))
        live_sync  = LiveSyncConfig(**_pick(raw.get("live_sync",  {}), _SYNC_FIELDS))

        return BeeHiveConfig(
            schema_version=raw.get("schema_version", "1.0"),
            calendars=calendars,
            bee_events=bee_events,
            live_sync=live_sync,
        )
