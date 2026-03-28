"""
Tests for core/sync_engine.py

Run: python3 -m pytest calendar_sync/tests/test_sync_engine.py -v
     (from projects/beehive_os/)
"""
from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

sys.path.insert(0, str(Path(__file__).parents[2]))

from calendar_sync.config.schema import (
    BeeEventsConfig,
    BeeHiveConfig,
    CalendarSourceConfig,
    LiveSyncConfig,
)
from calendar_sync.core.sync_engine import SyncEngine


# ── Helpers ───────────────────────────────────────────────────────────────────

def _make_config(sources: list[dict]) -> BeeHiveConfig:
    calendars = []
    for s in sources:
        try:
            calendars.append(CalendarSourceConfig(**s))
        except ValueError:
            pass
    return BeeHiveConfig(
        schema_version="1.2",
        calendars=calendars,
        bee_events=BeeEventsConfig(),
        live_sync=LiveSyncConfig(interval_seconds=900),
    )


def _make_event(ev_id: str, title: str, ts: float = 1e9) -> dict:
    return {
        "id": ev_id, "source_id": "test",
        "icon": "📅", "title": title,
        "time": "10h00", "date": "2099-01-01",
        "timestamp": ts, "sub": "Test",
        "location": "", "urgent": False,
        "all_day": False, "color": "#FFB81C",
    }


# ── Deduplication ─────────────────────────────────────────────────────────────

class TestDeduplication:
    def test_duplicate_ids_collapsed(self, tmp_path):
        cfg    = _make_config([{"id": "a", "type": "ics", "url": "http://x"}])
        engine = SyncEngine(cfg, data_dir=tmp_path, state_path=tmp_path / "state.json")

        ev1 = _make_event("a_123", "Meeting", ts=1000.0)
        ev2 = _make_event("a_123", "Meeting duplicate", ts=1001.0)

        with patch.object(engine._ics_loaders["a"], "fetch", new=AsyncMock(return_value=[ev1, ev2])):
            import asyncio
            result = asyncio.run(engine.sync())

        events = result.get("events", [])
        ids    = [e["id"] for e in events]
        assert ids.count("a_123") == 1, "Duplicate id should appear only once"

    def test_chronological_order(self, tmp_path):
        cfg    = _make_config([{"id": "a", "type": "ics", "url": "http://x"}])
        engine = SyncEngine(cfg, data_dir=tmp_path, state_path=tmp_path / "state.json")

        events_in = [
            _make_event("a_003", "C", ts=3000.0),
            _make_event("a_001", "A", ts=1000.0),
            _make_event("a_002", "B", ts=2000.0),
        ]

        with patch.object(engine._ics_loaders["a"], "fetch", new=AsyncMock(return_value=events_in)):
            import asyncio
            result = asyncio.run(engine.sync())

        timestamps = [e["timestamp"] for e in result["events"]]
        assert timestamps == sorted(timestamps), "Events should be in chronological order"


# ── Atomic write ──────────────────────────────────────────────────────────────

class TestAtomicWrite:
    def test_output_file_written(self, tmp_path):
        cfg    = _make_config([{"id": "a", "type": "ics", "url": "http://x"}])
        engine = SyncEngine(cfg, data_dir=tmp_path, state_path=tmp_path / "state.json")

        ev = _make_event("a_001", "Test event", ts=1000.0)
        with patch.object(engine._ics_loaders["a"], "fetch", new=AsyncMock(return_value=[ev])):
            import asyncio
            asyncio.run(engine.sync())

        out = tmp_path / "events_live.json"
        assert out.exists(), "events_live.json should be created"

        data = json.loads(out.read_text())
        assert "_meta" in data
        assert "events" in data
        assert data["_meta"]["version"] == "2.1"

    def test_no_tmp_file_left(self, tmp_path):
        cfg    = _make_config([{"id": "a", "type": "ics", "url": "http://x"}])
        engine = SyncEngine(cfg, data_dir=tmp_path, state_path=tmp_path / "state.json")

        with patch.object(engine._ics_loaders["a"], "fetch", new=AsyncMock(return_value=[])):
            import asyncio
            asyncio.run(engine.sync())

        tmp_files = list(tmp_path.glob("*.tmp"))
        assert not tmp_files, "No .tmp files should remain after sync"

    def test_backup_created(self, tmp_path):
        cfg    = _make_config([{"id": "a", "type": "ics", "url": "http://x"}])
        engine = SyncEngine(cfg, data_dir=tmp_path, state_path=tmp_path / "state.json")

        # Pre-create an existing events_live.json
        (tmp_path / "events_live.json").write_text('{"events":[]}')

        with patch.object(engine._ics_loaders["a"], "fetch", new=AsyncMock(return_value=[])):
            import asyncio
            asyncio.run(engine.sync())

        assert (tmp_path / "events_live.bak").exists(), "Backup should be created before overwriting"


# ── State persistence ─────────────────────────────────────────────────────────

class TestStatePersistence:
    def test_state_file_written(self, tmp_path):
        cfg    = _make_config([{"id": "a", "type": "ics", "url": "http://x"}])
        state  = tmp_path / "sync_state.json"
        engine = SyncEngine(cfg, data_dir=tmp_path, state_path=state)

        with patch.object(engine._ics_loaders["a"], "fetch", new=AsyncMock(return_value=[])):
            import asyncio
            asyncio.run(engine.sync())

        assert state.exists(), "sync_state.json should be created"
        data = json.loads(state.read_text())
        assert "last_sync" in data
        assert "sources" in data


# ── Config hot-reload ─────────────────────────────────────────────────────────

class TestConfigHotReload:
    def test_new_source_added(self, tmp_path):
        cfg1 = _make_config([{"id": "a", "type": "ics", "url": "http://x"}])
        engine = SyncEngine(cfg1, data_dir=tmp_path, state_path=tmp_path / "state.json")
        assert "a" in engine._ics_loaders
        assert "b" not in engine._ics_loaders

        cfg2 = _make_config([
            {"id": "a", "type": "ics", "url": "http://x"},
            {"id": "b", "type": "ics", "url": "http://y"},
        ])
        engine.update_config(cfg2)
        assert "b" in engine._ics_loaders

    def test_removed_source_gone(self, tmp_path):
        cfg1 = _make_config([
            {"id": "a", "type": "ics", "url": "http://x"},
            {"id": "b", "type": "ics", "url": "http://y"},
        ])
        engine = SyncEngine(cfg1, data_dir=tmp_path, state_path=tmp_path / "state.json")

        cfg2 = _make_config([{"id": "a", "type": "ics", "url": "http://x"}])
        engine.update_config(cfg2)
        assert "b" not in engine._ics_loaders

    def test_etag_preserved_on_reload(self, tmp_path):
        cfg1 = _make_config([{"id": "a", "type": "ics", "url": "http://x"}])
        engine = SyncEngine(cfg1, data_dir=tmp_path, state_path=tmp_path / "state.json")
        engine._ics_loaders["a"]._etag = "abc123"

        engine.update_config(cfg1)  # same config
        assert engine._ics_loaders["a"]._etag == "abc123", "ETag should be preserved on reload"
