#!/usr/bin/env python3
"""
Bee-Live Sync Daemon v3.0 — Réécriture complète (2026-03-27)
=============================================================
Corrections par rapport à v2.0 :
  - Instance unique via fcntl.flock (plus de spawn runaway)
  - Arrêt propre en < 1s : asyncio.Event interrompt le sleep
  - SIGHUP pour rechargement de config à chaud
  - Logs rotatifs (10 × 1 Mo)
  - Timezones correctes via ICSLoader (normalisation UTC)
  - RRULE ignorées en v1 (pas d'expansion locale)
  - Backup automatique avant chaque sync (events_live.bak)

Architecture :
  calendar_sync/config/manager.py   → lecture user_config.json
  calendar_sync/core/sync_engine.py → orchestration (ICS + Google API)
  calendar_sync/core/ics_loader.py  → parsing ICS, timezones

Usage :
  python3 bee_sync_daemon.py          # démarrage normal
  python3 bee_sync_daemon.py --auth   # flow OAuth2 Google (première fois)
  python3 bee_sync_daemon.py --once   # sync unique puis exit (debug / cron)
  kill -HUP  $(cat ~/.cache/beehive/bee_sync.pid)   # rechargement config
  kill -TERM $(cat ~/.cache/beehive/bee_sync.pid)   # arrêt propre
"""

from __future__ import annotations

import asyncio
import fcntl
import logging
import logging.handlers
import os
import signal
import subprocess
import sys
from pathlib import Path

# ── Chemins ──────────────────────────────────────────────────────────────────

BEEHIVE_ROOT = Path.home() / "beehive_os"
SCRIPT_DIR   = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent        # .../projects/beehive_os/

# Rendre calendar_sync importable depuis scripts/
sys.path.insert(0, str(PROJECT_ROOT))

from calendar_sync.config.manager import ConfigError, ConfigManager
from calendar_sync.core.sync_engine import SyncEngine

# ── Chemins runtime ───────────────────────────────────────────────────────────

DATA_DIR    = BEEHIVE_ROOT / "data"
STATE_PATH  = BEEHIVE_ROOT / "data" / "sync_state.json"
USER_CONFIG = BEEHIVE_ROOT / "user_config.json"
LOG_FILE    = Path.home() / ".cache" / "beehive" / "bee_sync.log"
LOCK_FILE   = Path.home() / ".cache" / "beehive" / "bee_sync.lock"
PID_FILE    = Path.home() / ".cache" / "beehive" / "bee_sync.pid"


# ── Single-instance guard ─────────────────────────────────────────────────────

class SingleInstanceError(RuntimeError):
    pass


class _SingleInstance:
    """File-based exclusive lock using fcntl.flock (survives process crash)."""

    def __init__(self) -> None:
        self._fd = None

    def acquire(self) -> None:
        LOCK_FILE.parent.mkdir(parents=True, exist_ok=True)
        self._fd = open(LOCK_FILE, "w")
        try:
            fcntl.flock(self._fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            self._fd.close()
            self._fd = None
            raise SingleInstanceError(
                f"Another bee_sync_daemon is already running "
                f"(lock: {LOCK_FILE}). Aborting."
            )
        self._fd.write(str(os.getpid()))
        self._fd.flush()
        PID_FILE.write_text(str(os.getpid()))

    def release(self) -> None:
        if self._fd is not None:
            try:
                fcntl.flock(self._fd, fcntl.LOCK_UN)
                self._fd.close()
            except OSError:
                pass
            self._fd = None
        for path in (LOCK_FILE, PID_FILE):
            path.unlink(missing_ok=True)


# ── Logging setup ─────────────────────────────────────────────────────────────

def setup_logging() -> None:
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)

    root = logging.getLogger()
    root.setLevel(logging.INFO)

    # Rotating file handler: 10 × 1 MB
    fh = logging.handlers.RotatingFileHandler(
        LOG_FILE, maxBytes=1_048_576, backupCount=10, encoding="utf-8"
    )
    fh.setFormatter(logging.Formatter(
        "%(asctime)s [%(levelname)s] %(name)s — %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S",
    ))

    sh = logging.StreamHandler(sys.stdout)
    sh.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s",
                                      datefmt="%H:%M:%S"))

    root.addHandler(fh)
    root.addHandler(sh)


# ── IPC → Quickshell ─────────────────────────────────────────────────────────

def _notify_shell() -> None:
    """Signal Quickshell to refresh BeeEvents (best-effort, never raises)."""
    try:
        subprocess.run(
            ["quickshell", "ipc", "call", "root", "refreshEvents"],
            timeout=2, capture_output=True,
        )
    except Exception:
        pass  # Quickshell may not be running; that's fine


# ── Daemon ────────────────────────────────────────────────────────────────────

log = logging.getLogger("bee_sync_daemon")


class BeeSyncDaemon:
    def __init__(self) -> None:
        self._stop_event   = asyncio.Event()
        self._reload_flag  = False
        self._config_mgr   = ConfigManager(USER_CONFIG)
        self._engine: SyncEngine | None = None

    # ── Signal handlers ───────────────────────────────────────────────────────

    def _handle_sigterm(self) -> None:
        log.info("SIGTERM received — stopping daemon")
        self._stop_event.set()

    def _handle_sighup(self) -> None:
        log.info("SIGHUP received — scheduling config reload")
        self._reload_flag = True

    # ── Main loop ─────────────────────────────────────────────────────────────

    async def run(self) -> None:
        log.info("Bee-Live Sync Daemon v3.0 starting")

        # Register signal handlers in the running event loop
        loop = asyncio.get_running_loop()
        for sig, handler in (
            (signal.SIGTERM, self._handle_sigterm),
            (signal.SIGINT,  self._handle_sigterm),
            (signal.SIGHUP,  self._handle_sighup),
        ):
            loop.add_signal_handler(sig, handler)

        # Initial config load
        try:
            cfg = self._config_mgr.load()
        except ConfigError as exc:
            log.error("Cannot load config: %s — aborting", exc)
            return

        self._engine = SyncEngine(cfg, data_dir=DATA_DIR, state_path=STATE_PATH)
        interval = cfg.live_sync.interval_seconds
        log.info(
            "Config OK: %d source(s), interval=%ds",
            len(cfg.calendars), interval,
        )

        # First sync immediately at startup
        await self._do_sync()

        # Poll loop: sleep is interruptible via asyncio.Event
        while not self._stop_event.is_set():
            try:
                await asyncio.wait_for(
                    asyncio.shield(self._stop_event.wait()),
                    timeout=float(interval),
                )
            except asyncio.TimeoutError:
                pass  # normal: interval elapsed, time to sync

            if self._stop_event.is_set():
                break

            if self._reload_flag:
                self._reload_flag = False
                try:
                    new_cfg  = self._config_mgr.reload()
                    interval = new_cfg.live_sync.interval_seconds
                    self._engine.update_config(new_cfg)
                    log.info(
                        "Config reloaded: %d source(s), interval=%ds",
                        len(new_cfg.calendars), interval,
                    )
                except ConfigError as exc:
                    log.warning("Config reload failed: %s", exc)

            await self._do_sync()

        log.info("Daemon stopped cleanly")

    async def _do_sync(self) -> None:
        if self._engine is None:
            return
        try:
            await self._engine.sync()
            _notify_shell()
        except Exception as exc:
            log.exception("Sync cycle raised an unexpected exception: %s", exc)


# ── Entry points ──────────────────────────────────────────────────────────────

async def _run_once() -> None:
    """Single sync cycle (--once flag); no daemon loop."""
    log.info("Running one-shot sync")
    mgr = ConfigManager(USER_CONFIG)
    cfg = mgr.load()
    engine = SyncEngine(cfg, data_dir=DATA_DIR, state_path=STATE_PATH)
    await engine.sync()
    _notify_shell()
    log.info("One-shot sync complete")


def run_oauth_flow() -> None:
    """Interactive OAuth2 flow for Google Calendar (--auth flag)."""
    try:
        from google_auth_oauthlib.flow import InstalledAppFlow
    except ImportError:
        print("google-auth-oauthlib not installed. Run: pip install google-auth-oauthlib")
        sys.exit(1)

    creds_path = BEEHIVE_ROOT / "config" / "google_credentials.json"
    token_path = BEEHIVE_ROOT / "config" / "google_calendar_token.json"

    if not creds_path.exists():
        print(f"ERROR: credentials file not found: {creds_path}")
        print("Download it from Google Cloud Console (OAuth 2.0 Client ID).")
        sys.exit(1)

    SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"]
    flow   = InstalledAppFlow.from_client_secrets_file(str(creds_path), SCOPES)
    creds  = flow.run_local_server(port=0)

    token_path.parent.mkdir(parents=True, exist_ok=True)
    token_path.write_text(creds.to_json())
    print(f"Authentication successful. Token saved: {token_path}")


def main() -> None:
    args = sys.argv[1:]

    if "--auth" in args:
        run_oauth_flow()
        return

    setup_logging()

    if "--once" in args:
        asyncio.run(_run_once())
        return

    # ── Full daemon mode ──────────────────────────────────────────────────────
    lock = _SingleInstance()
    try:
        lock.acquire()
    except SingleInstanceError as exc:
        print(f"[bee_sync_daemon] {exc}", file=sys.stderr)
        sys.exit(1)

    try:
        daemon = BeeSyncDaemon()
        asyncio.run(daemon.run())
    finally:
        lock.release()
        log.info("PID file and lock cleaned up")


if __name__ == "__main__":
    main()
