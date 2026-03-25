#!/usr/bin/env python3
"""
Bee-Live Sync Daemon v2.0
Synchronisation découplée du flux Git pour Bee-Hive OS.
Fonctionne en service systemd utilisateur avec polling asyncio.
"""

import asyncio
import json
import logging
import os
import signal
import subprocess
import sys
from datetime import datetime, timezone, time as dtime, timedelta
from pathlib import Path
from typing import Optional, List, Dict, Any

import aiohttp
from icalendar import Calendar

# ─── Chemins ────────────────────────────────────────────────────────────────
BEEHIVE_ROOT = Path.home() / "beehive_os"
LIVE_JSON    = BEEHIVE_ROOT / "data" / "events_live.json"
USER_CONFIG  = BEEHIVE_ROOT / "user_config.json"
LOG_FILE     = Path.home() / ".cache" / "beehive" / "bee_sync.log"

# ─── Icônes auto-détectées ───────────────────────────────────────────────────
ICON_MAP = {
    "soccer": "⚽", "football": "⚽", "karate": "🥋", "pharmacie": "💊",
    "pharmacy": "💊", "médecin": "🏥", "doctor": "🏥", "anniversaire": "🎂",
    "birthday": "🎂", "réunion": "📋", "meeting": "📋", "vacances": "✈️",
    "vacation": "✈️", "cours": "📚", "class": "📚", "dentiste": "🦷",
    "dentist": "🦷", "gym": "💪", "yoga": "🧘", "noah": "🏂", "ski": "🏂",
    "work": "💼", "rendez-vous": "🩺", "famille": "👨‍👩‍👦", "amis": "👥",
}

def get_event_icon(title: str, default: str = "📅") -> str:
    title_lower = title.lower()
    for keyword, icon in ICON_MAP.items():
        if keyword in title_lower:
            return icon
    return default

class CalendarSource:
    def __init__(self, source_cfg: dict):
        self.id       = source_cfg["id"]
        self.type     = source_cfg.get("type", "ics")
        self.url      = source_cfg.get("url", "")
        self.label    = source_cfg.get("label", self.id)
        self.color    = source_cfg.get("color", "#FFB81C")
        self.last_ok  = None
        self.error    = None

    async def fetch_events(self, session: aiohttp.ClientSession) -> List[dict]:
        """Récupère et parse les événements depuis l'URL ICS."""
        if not self.url:
            return []
        try:
            async with session.get(self.url, timeout=aiohttp.ClientTimeout(total=10)) as resp:
                resp.raise_for_status()
                ics_data = await resp.text()

            events = self._parse_ics(ics_data)
            self.last_ok = datetime.now(timezone.utc).isoformat()
            self.error   = None
            return events

        except Exception as exc:
            self.error = str(exc)
            logging.warning(f"[{self.id}] Erreur fetch: {exc}")
            return []

    def _parse_ics(self, ics_data: str) -> List[dict]:
        cal    = Calendar.from_ical(ics_data)
        now_ts = datetime.now(timezone.utc).timestamp()
        events = []

        for component in cal.walk():
            if component.name != "VEVENT":
                continue

            dtstart = component.get("DTSTART")
            if dtstart is None:
                continue

            dt = dtstart.dt
            if hasattr(dt, "timestamp"):
                ts = dt.timestamp()
            else:
                # all-day event → date object
                dt_full = datetime.combine(dt, dtime(0, 0), tzinfo=timezone.utc)
                ts = dt_full.timestamp()

            # Ignorer les événements passés depuis plus de 30 min
            if ts < now_ts - 1800:
                continue

            summary  = str(component.get("SUMMARY", ""))
            location = str(component.get("LOCATION", ""))
            uid      = str(component.get("UID", f"{self.id}_{ts}"))

            dt_local = datetime.fromtimestamp(ts)
            all_day  = not hasattr(dtstart.dt, "hour")

            events.append({
                "id":        f"{self.id}_{uid[:16]}",
                "source_id": self.id,
                "icon":      get_event_icon(summary),
                "title":     summary,
                "time":      "" if all_day else dt_local.strftime("%Hh%M"),
                "date":      dt_local.strftime("%Y-%m-%d"),
                "timestamp": ts,
                "sub":       self.label,
                "location":  location,
                "urgent":    False,
                "all_day":   all_day,
                "color":     self.color,
            })

        return sorted(events, key=lambda e: e["timestamp"])

class GoogleAPISource:
    """Source calendrier via Google Calendar API — supporte les événements récurrents."""

    SCOPES     = ["https://www.googleapis.com/auth/calendar.readonly"]
    TOKEN_PATH = BEEHIVE_ROOT / "config" / "google_calendar_token.json"
    CREDS_PATH = BEEHIVE_ROOT / "config" / "google_credentials.json"

    def __init__(self, source_cfg: dict):
        self.id          = source_cfg["id"]
        self.type        = "google_api"
        self.calendar_id = source_cfg.get("calendar_id", "primary")
        self.label       = source_cfg.get("label", self.id)
        self.color       = source_cfg.get("color", "#FFB81C")
        self.url         = ""   # champ vide pour compatibilité meta
        self.last_ok     = None
        self.error       = None

    async def fetch_events(self, session: aiohttp.ClientSession) -> List[dict]:
        """Récupère les événements via Google Calendar API (récurrences incluses)."""
        try:
            creds = self._get_credentials()
            if creds is None:
                self.error = (
                    "Credentials Google absents ou invalides. "
                    f"Lancez: python3 {__file__} --auth"
                )
                logging.error(f"[{self.id}] {self.error}")
                return []

            loop   = asyncio.get_event_loop()
            events = await loop.run_in_executor(None, self._fetch_events_sync, creds)
            self.last_ok = datetime.now(timezone.utc).isoformat()
            self.error   = None
            return events

        except Exception as exc:
            self.error = str(exc)
            logging.warning(f"[{self.id}] Erreur Google API: {exc}")
            return []

    def _get_credentials(self):
        """Charge les credentials OAuth2 et les rafraîchit si nécessaire."""
        from google.oauth2.credentials import Credentials
        from google.auth.transport.requests import Request

        creds = None
        if self.TOKEN_PATH.exists():
            creds = Credentials.from_authorized_user_file(
                str(self.TOKEN_PATH), self.SCOPES
            )

        if creds and creds.expired and creds.refresh_token:
            logging.info(f"[{self.id}] Rafraîchissement du token Google…")
            creds.refresh(Request())
            self._save_token(creds)

        return creds if (creds and creds.valid) else None

    def _save_token(self, creds):
        self.TOKEN_PATH.parent.mkdir(parents=True, exist_ok=True)
        with open(self.TOKEN_PATH, "w") as f:
            f.write(creds.to_json())

    def _fetch_events_sync(self, creds) -> List[dict]:
        """Appel synchrone à l'API (exécuté dans un thread via run_in_executor)."""
        from googleapiclient.discovery import build

        service  = build("calendar", "v3", credentials=creds, cache_discovery=False)
        now_utc  = datetime.now(timezone.utc)
        time_min = now_utc.strftime("%Y-%m-%dT%H:%M:%SZ")
        time_max = (now_utc + timedelta(days=60)).strftime("%Y-%m-%dT%H:%M:%SZ")

        result = service.events().list(
            calendarId=self.calendar_id,
            timeMin=time_min,
            timeMax=time_max,
            maxResults=200,
            singleEvents=True,   # développe les récurrences en occurrences individuelles
            orderBy="startTime",
        ).execute()

        items  = result.get("items", [])
        events = []
        for item in items:
            ev = self._parse_google_event(item)
            if ev:
                events.append(ev)
        return events

    def _parse_google_event(self, item: dict) -> Optional[dict]:
        start = item.get("start", {})
        dt_str = start.get("dateTime") or start.get("date")
        if not dt_str:
            return None

        all_day = "date" in start and "dateTime" not in start

        if all_day:
            dt_local = datetime.strptime(dt_str, "%Y-%m-%d")
            ts       = dt_local.replace(tzinfo=timezone.utc).timestamp()
        else:
            # dateTime inclut le fuseau horaire
            from datetime import timezone as _tz
            dt_aware = datetime.fromisoformat(dt_str)
            ts       = dt_aware.timestamp()
            dt_local = datetime.fromtimestamp(ts)

        now_ts = datetime.now(timezone.utc).timestamp()
        if ts < now_ts - 1800:
            return None

        summary  = item.get("summary", "")
        location = item.get("location", "")
        uid      = item.get("id", f"{self.id}_{ts}")

        return {
            "id":        f"{self.id}_{uid[:24]}",
            "source_id": self.id,
            "icon":      get_event_icon(summary),
            "title":     summary,
            "time":      "" if all_day else dt_local.strftime("%Hh%M"),
            "date":      dt_local.strftime("%Y-%m-%d"),
            "timestamp": ts,
            "sub":       self.label,
            "location":  location,
            "urgent":    False,
            "all_day":   all_day,
            "color":     self.color,
        }


def _build_source(cfg: dict):
    """Instancie la bonne classe de source selon le champ 'type'."""
    src_type = cfg.get("type", "ics")
    if src_type == "google_api":
        return GoogleAPISource(cfg)
    return CalendarSource(cfg)


class BeeSyncDaemon:
    def __init__(self):
        self.config   : dict                  = {}
        self.sources  : List[CalendarSource]  = []
        self.interval : int                   = 900  # 15 min par défaut
        self._running : bool                  = True
        LIVE_JSON.parent.mkdir(parents=True, exist_ok=True)  # Créer ~/beehive_os/data/
        LOG_FILE.parent.mkdir(parents=True, exist_ok=True)

    def load_config(self) -> bool:
        """Charge user_config.json et construit la liste des sources."""
        try:
            with open(USER_CONFIG, "r") as f:
                self.config = json.load(f)
        except FileNotFoundError:
            logging.error(f"user_config.json introuvable: {USER_CONFIG}")
            return False

        # Support multi-sources (v2) + fallback mono-source (v1)
        calendars_cfg = self.config.get("calendars", [])
        if not calendars_cfg:
            # Compatibilité v1 : events_ics_url unique
            legacy_url = self.config.get("events_ics_url", "")
            if legacy_url:
                calendars_cfg = [{"id": "default", "type": "ics",
                                  "url": legacy_url, "label": "Calendrier",
                                  "color": "#FFB81C"}]

        self.sources  = [_build_source(c) for c in calendars_cfg]
        self.interval = self.config.get("live_sync", {}).get("interval_seconds", 900)
        logging.info(f"Config chargée: {len(self.sources)} source(s), intervalle {self.interval}s")
        return True

    async def sync_all(self):
        """Effectue une synchronisation complète toutes sources confondues."""
        if not self.sources:
            logging.info("Aucune source configurée, sync ignorée.")
            return

        all_events: List[dict] = []
        sources_meta: List[dict] = []

        async with aiohttp.ClientSession() as session:
            tasks = [src.fetch_events(session) for src in self.sources]
            results = await asyncio.gather(*tasks, return_exceptions=True)

        for src, result in zip(self.sources, results):
            sources_meta.append({
                "id":       src.id,
                "type":     src.type,
                "url":      src.url,
                "label":    src.label,
                "color":    src.color,
                "last_ok":  src.last_ok,
                "error":    src.error if not isinstance(result, list) else src.error,
            })
            if isinstance(result, list):
                all_events.extend(result)

        # Déduplication par id + tri chronologique
        seen = set()
        deduped = []
        for ev in sorted(all_events, key=lambda e: e["timestamp"]):
            if ev["id"] not in seen:
                seen.add(ev["id"])
                deduped.append(ev)

        payload = {
            "_meta": {
                "version":   "2.0",
                "last_sync": datetime.now(timezone.utc).isoformat(),
                "sources":   sources_meta,
            },
            "events": deduped,
        }

        # Écriture atomique (tmp + rename)
        tmp = LIVE_JSON.with_suffix(".tmp")
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, indent=2)
        tmp.replace(LIVE_JSON)
        logging.info(f"Sync OK: {len(deduped)} événement(s) → {LIVE_JSON}")

        # Signal IPC vers Quickshell
        self._notify_shell()

    def _notify_shell(self):
        """Envoie un signal IPC à Quickshell pour rafraîchir BeeEvents."""
        try:
            subprocess.run(
                ["quickshell", "ipc", "call", "root", "refreshEvents"],
                timeout=2, capture_output=True
            )
        except Exception as exc:
            logging.debug(f"IPC signal ignoré (shell non actif?): {exc}")

    async def run(self):
        """Boucle principale du daemon."""
        logging.info("Bee-Live Sync Daemon v2.0 démarré.")
        if not self.load_config():
            logging.error("Impossible de charger la config. Arrêt.")
            return

        # Première sync immédiate au démarrage
        await self.sync_all()

        while self._running:
            await asyncio.sleep(self.interval)
            # Recharger la config pour prendre en compte les changements
            self.load_config()
            await self.sync_all()

    def stop(self):
        self._running = False
        logging.info("Daemon arrêté proprement.")

async def main():
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[
            logging.FileHandler(LOG_FILE),
            logging.StreamHandler(sys.stdout),
        ],
    )
    daemon = BeeSyncDaemon()
    loop   = asyncio.get_running_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, daemon.stop)
    await daemon.run()

def run_oauth_flow():
    """
    Lance le flow OAuth2 interactif (première authentification).
    Nécessite google_credentials.json dans ~/beehive_os/config/.
    Utilisation : python3 bee_sync_daemon.py --auth
    """
    token_path = GoogleAPISource.TOKEN_PATH
    creds_path = GoogleAPISource.CREDS_PATH

    if not creds_path.exists():
        print(f"ERREUR : fichier de credentials introuvable : {creds_path}")
        print("Téléchargez-le depuis Google Cloud Console (OAuth 2.0 Client ID) et placez-le là.")
        sys.exit(1)

    try:
        from google_auth_oauthlib.flow import InstalledAppFlow
    except ImportError:
        print("ERREUR : google-auth-oauthlib manquant. Installez-le avec : pip install google-auth-oauthlib")
        sys.exit(1)

    flow  = InstalledAppFlow.from_client_secrets_file(
        str(creds_path), GoogleAPISource.SCOPES
    )
    creds = flow.run_local_server(port=0)

    token_path.parent.mkdir(parents=True, exist_ok=True)
    with open(token_path, "w") as f:
        f.write(creds.to_json())

    print(f"Authentification réussie. Token sauvegardé : {token_path}")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--auth":
        run_oauth_flow()
    else:
        asyncio.run(main())
