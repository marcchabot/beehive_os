#!/usr/bin/env python3
"""
Bee-Hive Calendar Sync — Version simple et robuste
Synchronisation ponctuelle des calendriers (ICS ou Google API).
Pas de daemon, pas d'asyncio — une sync, un exit. Facile à cron.
"""

import json
import logging
import os
import sys
from datetime import datetime, timezone, time as dtime, timedelta
from pathlib import Path
from typing import List, Dict, Optional
import urllib.request
import urllib.error

# ─── Chemins ────────────────────────────────────────────────────────────────
BEEHIVE_ROOT = Path.home() / "beehive_os"
USER_CONFIG  = BEEHIVE_ROOT / "user_config.json"
LIVE_JSON    = BEEHIVE_ROOT / "data" / "events_live.json"
LOG_FILE     = Path.home() / ".cache" / "beehive" / "calendar_sync.log"

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

# ─── Sources ────────────────────────────────────────────────────────────────
class CalendarSource:
    """Source calendrier de type ICS (URL ou fichier local)."""
    def __init__(self, source_cfg: dict):
        self.id     = source_cfg["id"]
        self.url    = source_cfg.get("url", "")
        self.label  = source_cfg.get("label", self.id)
        self.color  = source_cfg.get("color", "#FFB81C")

    def fetch_events(self) -> List[dict]:
        """Télécharge et parse les événements ICS."""
        if not self.url:
            logging.warning(f"[{self.id}] URL vide, skip.")
            return []

        try:
            # Support fichier local (file://) ou HTTP(S)
            if self.url.startswith("file://"):
                path = Path(self.url[7:])
                ics_data = path.read_text(encoding="utf-8")
            else:
                req = urllib.request.Request(
                    self.url,
                    headers={'User-Agent': 'Bee-Hive Calendar Sync'}
                )
                with urllib.request.urlopen(req, timeout=10) as resp:
                    ics_data = resp.read().decode("utf-8")

            return self._parse_ics(ics_data)

        except Exception as exc:
            logging.error(f"[{self.id}] Erreur fetch: {exc}")
            return []

    def _parse_ics(self, ics_data: str) -> List[dict]:
        """Parse le contenu ICS en Liste d'événements."""
        try:
            from icalendar import Calendar
        except ImportError:
            logging.error("Module 'icalendar' manquant. Installez: pip install icalendar")
            return []

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
                # All-day event → date object
                dt_full = datetime.combine(dt, dtime(0, 0), tzinfo=timezone.utc)
                ts = dt_full.timestamp()

            # Ignorer les événements passés de plus de 30 min
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

# ─── Google API (optionnel) ─────────────────────────────────────────────────
class GoogleAPISource:
    """Source Google Calendar — nécessite OAuth2 credentials."""
    SCOPES     = ["https://www.googleapis.com/auth/calendar.readonly"]
    TOKEN_PATH = BEEHIVE_ROOT / "config" / "google_calendar_token.json"
    CREDS_PATH = BEEHIVE_ROOT / "config" / "google_credentials.json"

    def __init__(self, source_cfg: dict):
        self.id          = source_cfg["id"]
        self.calendar_id = source_cfg.get("calendar_id", "primary")
        self.label       = source_cfg.get("label", self.id)
        self.color       = source_cfg.get("color", "#FFB81C")

    def fetch_events(self) -> List[dict]:
        """Récupère événements via Google Calendar API."""
        try:
            from google.oauth2.credentials import Credentials
            from google.auth.transport.requests import Request
            from googleapiclient.discovery import build
        except ImportError as e:
            logging.error(f"Modules Google manquants: {e}. Installez: pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client")
            return []

        creds = self._get_credentials()
        if not creds:
            logging.error(f"[{self.id}] Credentials Google invalides ou absents.")
            return []

        try:
            service  = build("calendar", "v3", credentials=creds, cache_discovery=False)
            now_utc  = datetime.now(timezone.utc)
            time_min = now_utc.strftime("%Y-%m-%dT%H:%M:%SZ")
            time_max = (now_utc + timedelta(days=60)).strftime("%Y-%m-%dT%H:%M:%SZ")

            result = service.events().list(
                calendarId=self.calendar_id,
                timeMin=time_min,
                timeMax=time_max,
                maxResults=200,
                singleEvents=True,
                orderBy="startTime",
            ).execute()

            items = result.get("items", [])
            events = []
            for item in items:
                ev = self._parse_google_event(item)
                if ev:
                    events.append(ev)
            return events

        except Exception as exc:
            logging.error(f"[{self.id}] Erreur Google API: {exc}")
            return []

    def _get_credentials(self):
        """Charge et rafraîchit les credentials OAuth2."""
        from google.oauth2.credentials import Credentials
        from google.auth.transport.requests import Request

        creds = None
        if self.TOKEN_PATH.exists():
            creds = Credentials.from_authorized_user_file(
                str(self.TOKEN_PATH), self.SCOPES
            )

        if creds and creds.expired and creds.refresh_token:
            logging.info(f"[{self.id}] Rafraîchissement token Google...")
            creds.refresh(Request())
            self._save_token(creds)

        return creds if (creds and creds.valid) else None

    def _save_token(self, creds):
        self.TOKEN_PATH.parent.mkdir(parents=True, exist_ok=True)
        with open(self.TOKEN_PATH, "w") as f:
            f.write(creds.to_json())

    def _parse_google_event(self, item: dict) -> Optional[dict]:
        start = item.get("start", {})
        dt_str = start.get("dateTime") or start.get("date")
        if not dt_str:
            return None

        all_day = "date" in start and "dateTime" not in start

        if all_day:
            dt_local = datetime.strptime(dt_str, "%Y-%m-%d")
            ts = dt_local.replace(tzinfo=timezone.utc).timestamp()
        else:
            dt_aware = datetime.fromisoformat(dt_str)
            ts = dt_aware.timestamp()
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

def build_source(cfg: dict):
    """Factory pour créer la bonne source selon 'type'."""
    src_type = cfg.get("type", "ics")
    if src_type == "google_api":
        return GoogleAPISource(cfg)
    return CalendarSource(cfg)

# ─── Core ───────────────────────────────────────────────────────────────────
def load_config() -> Dict:
    """Charge user_config.json et retourne la config."""
    if not USER_CONFIG.exists():
        raise FileNotFoundError(f"Config introuvable: {USER_CONFIG}")

    with open(USER_CONFIG, "r", encoding="utf-8") as f:
        return json.load(f)

def setup_logging():
    """Configure le logging vers fichier + stdout."""
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[
            logging.FileHandler(LOG_FILE, encoding="utf-8"),
            logging.StreamHandler(sys.stdout),
        ],
    )

def sync_all(sources_cfg: List[dict]) -> List[dict]:
    """Synchronise toutes les sources et retourne la liste d'événements unifiée."""
    sources = [build_source(cfg) for cfg in sources_cfg]
    all_events = []
    sources_meta = []

    for src in sources:
        events = src.fetch_events()
        sources_meta.append({
            "id":       src.id,
            "type":     getattr(src, "type", "ics"),
            "url":      getattr(src, "url", ""),
            "label":    src.label,
            "color":    src.color,
            "last_ok":  datetime.now(timezone.utc).isoformat() if events else None,
            "error":    None if events else "Aucun événement ou erreur",
        })
        all_events.extend(events)

    # Déduplication par ID + tri chronologique
    seen = set()
    deduped = []
    for ev in sorted(all_events, key=lambda e: e["timestamp"]):
        if ev["id"] not in seen:
            seen.add(ev["id"])
            deduped.append(ev)

    return deduped, sources_meta

def atomic_write_json(data: dict, target_path: Path):
    """Écriture atomique via fichier temporaire."""
    target_path.parent.mkdir(parents=True, exist_ok=True)
    tmp = target_path.with_suffix(".tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    tmp.replace(target_path)
    logging.info(f"✅ Sync écrite: {target_path} ({len(data.get('events', []))} événements)")

def notify_quickshell():
    """Envoie un signal IPC à Quickshell pour rafraîchir les widgets."""
    try:
        import subprocess
        subprocess.run(
            ["quickshell", "ipc", "call", "root", "refreshEvents"],
            timeout=2,
            capture_output=True
        )
        logging.info("📡 IPC envoyé à Quickshell")
    except Exception as exc:
        logging.debug(f"IPC ignoré (shell non actif?): {exc}")

def main():
    setup_logging()
    logging.info("🐝 Bee-Hive Calendar Sync démarré")

    try:
        config = load_config()
    except Exception as exc:
        logging.error(f"❌ Impossible de charger la config: {exc}")
        sys.exit(1)

    # Récupérer les sources (multi-calendars ou legacy)
    calendars_cfg = config.get("calendars", [])
    if not calendars_cfg:
        legacy_url = config.get("events_ics_url", "")
        if legacy_url:
            calendars_cfg = [{
                "id": "default",
                "type": "ics",
                "url": legacy_url,
                "label": "Calendrier",
                "color": "#FFB81C"
            }]

    if not calendars_cfg:
        logging.warning("⚠️ Aucune source calendrier configurée. Sync ignorée.")
        sys.exit(0)

    # Synchronisation
    try:
        events, sources_meta = sync_all(calendars_cfg)

        payload = {
            "_meta": {
                "version":   "2.0",
                "last_sync": datetime.now(timezone.utc).isoformat(),
                "sources":   sources_meta,
            },
            "events": events,
        }

        atomic_write_json(payload, LIVE_JSON)
        notify_quickshell()

        logging.info(f"🎉 Synchronisation terminée avec succès ({len(events)} événements)")

    except Exception as exc:
        logging.error(f"❌ Erreur pendant la sync: {exc}", exc_info=True)
        sys.exit(1)

if __name__ == "__main__":
    main()
