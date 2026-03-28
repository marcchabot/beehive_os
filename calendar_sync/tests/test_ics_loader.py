"""
Tests for core/ics_loader.py

Run: python3 -m pytest calendar_sync/tests/test_ics_loader.py -v
     (from projects/beehive_os/)
"""
from __future__ import annotations

import sys
from datetime import date, datetime, timezone
from pathlib import Path

import pytest

# Ensure the package is importable when running tests directly
sys.path.insert(0, str(Path(__file__).parents[2]))

from calendar_sync.core.ics_loader import ICSLoader, get_icon, normalize_to_utc

FIXTURES = Path(__file__).parent / "fixtures"
SAMPLE_ICS = (FIXTURES / "sample.ics").read_text(encoding="utf-8")


# ── normalize_to_utc ─────────────────────────────────────────────────────────

class TestNormalizeToUTC:
    def test_aware_datetime_converted(self):
        from datetime import timedelta, timezone as tz

        eastern = tz(timedelta(hours=-5))
        dt      = datetime(2026, 3, 27, 10, 0, tzinfo=eastern)
        utc, is_all_day = normalize_to_utc(dt)

        assert utc.tzinfo == timezone.utc
        assert utc.hour == 15    # 10:00 EST → 15:00 UTC
        assert is_all_day is False

    def test_naive_datetime_assumed_utc(self):
        dt = datetime(2026, 3, 27, 14, 30)  # naive
        utc, is_all_day = normalize_to_utc(dt)

        assert utc.tzinfo == timezone.utc
        assert utc == datetime(2026, 3, 27, 14, 30, tzinfo=timezone.utc)
        assert is_all_day is False

    def test_date_becomes_midnight_utc(self):
        d = date(2026, 6, 15)
        utc, is_all_day = normalize_to_utc(d)

        assert utc == datetime(2026, 6, 15, 0, 0, tzinfo=timezone.utc)
        assert is_all_day is True

    def test_utc_datetime_unchanged(self):
        dt = datetime(2026, 1, 1, 12, 0, tzinfo=timezone.utc)
        utc, is_all_day = normalize_to_utc(dt)

        assert utc == dt
        assert is_all_day is False


# ── get_icon ─────────────────────────────────────────────────────────────────

class TestGetIcon:
    def test_known_keywords(self):
        assert get_icon("Karaté Noah") == "🥋"
        assert get_icon("Soccer AS Blainville") == "⚽"
        assert get_icon("Pharmacie Chabot") == "💊"
        assert get_icon("Anniversaire de Julie") == "🎂"
        assert get_icon("Dentiste") == "🦷"

    def test_case_insensitive(self):
        assert get_icon("KARATE") == "🥋"
        assert get_icon("SOCCER") == "⚽"

    def test_unknown_returns_default(self):
        assert get_icon("Mystery event xyz") == "📅"

    def test_empty_string(self):
        assert get_icon("") == "📅"


# ── ICSLoader._parse ─────────────────────────────────────────────────────────

class TestICSLoaderParse:
    def _loader(self) -> ICSLoader:
        return ICSLoader(
            source_id="test",
            url="https://example.com/test.ics",
            label="Test",
            color="#FFB81C",
        )

    def _parse_all(self, ics_text: str) -> list[dict]:
        loader = self._loader()
        # Bypass the time-window filter by using a far-future ICS
        return list(loader._parse(ics_text))

    def test_rrule_events_skipped(self):
        events = self._parse_all(SAMPLE_ICS)
        titles = [e["title"] for e in events]
        assert "Soccer hebdomadaire" not in titles, "RRULE event should be skipped"

    def test_past_events_filtered(self):
        events = self._parse_all(SAMPLE_ICS)
        titles = [e["title"] for e in events]
        assert "Événement passé (doit être filtré)" not in titles

    def test_utc_event_parsed(self):
        events = self._parse_all(SAMPLE_ICS)
        reunion = next((e for e in events if e["title"] == "Réunion équipe"), None)
        assert reunion is not None
        assert reunion["source_id"] == "test"
        assert reunion["all_day"] is False
        assert reunion["icon"] == "📋"  # "réunion" keyword
        assert reunion["time"] != ""   # has a time component

    def test_allday_event_parsed(self):
        events = self._parse_all(SAMPLE_ICS)
        anniversaire = next((e for e in events if "Anniversaire" in e["title"]), None)
        assert anniversaire is not None
        assert anniversaire["all_day"] is True
        assert anniversaire["time"] == ""
        assert anniversaire["icon"] == "🎂"

    def test_tzid_event_parsed(self):
        events = self._parse_all(SAMPLE_ICS)
        karate = next((e for e in events if "Karaté" in e["title"]), None)
        assert karate is not None
        assert karate["all_day"] is False
        # timestamp should be UTC (18:00 Toronto = 23:00 UTC in winter)
        assert karate["timestamp"] > 0

    def test_event_has_required_fields(self):
        events = self._parse_all(SAMPLE_ICS)
        assert len(events) > 0
        required = {"id", "source_id", "icon", "title", "time", "date",
                    "timestamp", "sub", "location", "urgent", "all_day", "color"}
        for ev in events:
            missing = required - ev.keys()
            assert not missing, f"Event '{ev['title']}' missing fields: {missing}"

    def test_event_id_prefixed_with_source_id(self):
        events = self._parse_all(SAMPLE_ICS)
        for ev in events:
            assert ev["id"].startswith("test_")

    def test_location_truncated(self):
        long_loc_ics = SAMPLE_ICS.replace(
            "LOCATION:Pharmacie Chabot, Blainville",
            "LOCATION:" + "x" * 100,
        )
        events = self._parse_all(long_loc_ics)
        pharma = next((e for e in events if "Commande" in e["title"]), None)
        if pharma:
            assert len(pharma["location"]) <= 63  # 60 chars + "…"

    def test_invalid_ics_returns_empty(self):
        events = self._parse_all("NOT VALID ICS DATA 💥")
        assert events == []
