"""
config/schema.py — Typed dataclass schema for user_config.json.

All fields mirror the JSON structure; defaults allow partial configs.
"""
from __future__ import annotations
from dataclasses import dataclass, field
from typing import Literal


@dataclass
class CalendarSourceConfig:
    id: str
    type: Literal["ics", "google_api"] = "ics"
    label: str = ""
    color: str = "#FFB81C"
    # ICS source
    url: str = ""
    # Google API source
    calendar_id: str = "primary"

    def __post_init__(self):
        if not self.label:
            self.label = self.id
        if self.type == "ics" and not self.url:
            raise ValueError(f"Calendar '{self.id}' has type=ics but no url")
        if self.type == "google_api" and not self.calendar_id:
            raise ValueError(f"Calendar '{self.id}' has type=google_api but no calendar_id")


@dataclass
class BeeEventsConfig:
    enabled: bool = True
    max_events: int = 3


@dataclass
class LiveSyncConfig:
    enabled: bool = True
    interval_seconds: int = 900  # 15 min


@dataclass
class BeeHiveConfig:
    schema_version: str = "1.2"
    calendars: list[CalendarSourceConfig] = field(default_factory=list)
    bee_events: BeeEventsConfig = field(default_factory=BeeEventsConfig)
    live_sync: LiveSyncConfig = field(default_factory=LiveSyncConfig)

    @property
    def ics_sources(self) -> list[CalendarSourceConfig]:
        return [c for c in self.calendars if c.type == "ics"]

    @property
    def google_sources(self) -> list[CalendarSourceConfig]:
        return [c for c in self.calendars if c.type == "google_api"]
