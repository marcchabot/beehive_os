#!/usr/bin/env python3
"""
bee_sync_simple.py — Bee-Live Sync v2.1 (Simple)
=================================================
Script one-shot de synchronisation calendrier pour Bee-Hive OS.
Lit user_config.json, récupère les événements de chaque source,
et écrit data/events_live.json.

Usage:
    python3 bee_sync_simple.py            # sync normale
    python3 bee_sync_simple.py --dry-run  # affiche sans écrire
    python3 bee_sync_simple.py --auth     # flow OAuth2 Google interactif
    python3 bee_sync_simple.py --verbose  # logging DEBUG

Dépendances:
    pip install requests icalendar
    pip install google-api-python-client google-auth google-auth-oauthlib  # pour google_api
"""

import json
import logging
import sys
import subprocess
from datetime import datetime, timezone, timedelta, time as dtime
from pathlib import Path
from typing import List, Dict, Any, Optional

try:
    import requests
except ImportError:
    print("ERREUR : 'requests' manquant. Installez-le : pip install requests")
    sys.exit(1)

try:
    from icalendar import Calendar
except ImportError:
    print("ERREUR : 'icalendar' manquant. Installez-le : pip install icalendar")
    sys.exit(1)

# ─── Chemins ────────────────────────────────────────────────────────────────

SCRIPT_DIR   = Path(__file__).resolve().parent
PROJECT_DIR  = SCRIPT_DIR.parent                        # beehive_os/
DATA_DIR     = PROJECT_DIR / "data"
OUTPUT_FILE  = DATA_DIR / "events_live.json"
CONFIG_FILE  = PROJECT_DIR / "user_config.json"

# Chemin alternatif si Bee-Hive OS est installé dans ~/beehive_os/
HOME_ROOT    = Path.home() / "beehive_os"
TOKEN_PATH   = HOME_ROOT / "config" / "google_calendar_token.json"
CREDS_PATH   = HOME_ROOT / "config" / "google_credentials.json"
GOOGLE_ACCESS_FALLBACK = Path(__file__).resolve().parents[3] / "google_access.json"

LOG_FILE     = Path.home() / ".cache" / "beehive" / "bee_sync.log"

# ─── Icônes automatiques ─────────────────────────────────────────────────────

ICON_MAP: Dict[str, str] = {
    # Sport
    "soccer":        "⚽",
    "football":      "⚽",
    "karate":        "🥋",
    "karaté":        "🥋",
    "gym":           "💪",
    "yoga":          "🧘",
    "ski":           "🏂",
    "noah":          "🏂",
    "natation":      "🏊",
    "tennis":        "🎾",
    "hockey":        "🏒",
    # Santé
    "pharmacie":     "💊",
    "pharmacy":      "💊",
    "médecin":       "🏥",
    "doctor":        "🏥",
    "dentiste":      "🦷",
    "dentist":       "🦷",
    "rendez-vous":   "🩺",
    "appointment":   "🩺",
    # Social
    "anniversaire":  "🎂",
    "birthday":      "🎂",
    "famille":       "👨‍👩‍👦",
    "family":        "👨‍👩‍👦",
    "amis":          "👥",
    "friends":       "👥",
    "dîner":         "🍽️",
    "dinner":        "🍽️",
    "fête":          "🎉",
    "party":         "🎉",
    # Travail / école
    "réunion":       "📋",
    "meeting":       "📋",
    "cours":         "📚",
    "class":         "📚",
    "work":          "💼",
    "travail":       "💼",
    # Voyage
    "vacances":      "✈️",
    "vacation":      "✈️",
    "voyage":        "✈️",
    "trip":          "✈️",
    "tremblant":     "🏔️",
    # Divers
    "ménage":        "🧹",
    "cleaning":      "🧹",
    "épicerie":      "🛒",
    "grocery":       "🛒",
}


def get_icon(title: str, default: str = "📅") -> str:
    """Retourne l'icône correspondant au titre de l'événement."""
    title_lower = title.lower()
    for keyword, icon in ICON_MAP.items():
        if keyword in title_lower:
            return icon
    return default


# ─── Chargement config ────────────────────────────────────────────────────────

def load_config() -> Dict[str, Any]:
    """
    Charge user_config.json depuis PROJECT_DIR.
    Supporte schema v1.x (events_ics_url) et v2.0 (calendars[]).
    """
    if not CONFIG_FILE.exists():
        logging.warning(f"user_config.json introuvable à {CONFIG_FILE}")
        return {}

    with open(CONFIG_FILE, "r", encoding="utf-8") as f:
        cfg = json.load(f)

    logging.info(f"Config chargée : schema={cfg.get('schema_version', '?')} "
                 f"version={cfg.get('version', '?')}")

    # Compatibilité v1 : events_ics_url → calendars[]
    if not cfg.get("calendars") and cfg.get("events_ics_url"):
        logging.info("Compatibilité v1 : conversion events_ics_url → calendars[]")
        cfg["calendars"] = [{
            "id":    "default",
            "type":  "ics",
            "url":   cfg["events_ics_url"],
            "label": "Calendrier",
            "color": "#FFB81C",
        }]

    return cfg


# ─── Sync ICS ────────────────────────────────────────────────────────────────

def sync_ics(source: Dict[str, Any], lookahead_days: int = 14) -> List[Dict[str, Any]]:
    """
    Récupère et parse un calendrier .ICS depuis une URL HTTP(S).
    Retourne les événements futurs triés chronologiquement.
    Gère les événements récurrents (RRULE) via la lib icalendar.
    """
    src_id  = source["id"]
    url     = source.get("url", "").strip()
    label   = source.get("label", src_id)
    color   = source.get("color", "#FFB81C")

    if not url:
        logging.warning(f"[{src_id}] URL ICS vide, source ignorée.")
        return []

    logging.info(f"[{src_id}] Récupération ICS : {url[:60]}…")

    try:
        resp = requests.get(url, timeout=15)
        resp.raise_for_status()
    except requests.RequestException as exc:
        logging.error(f"[{src_id}] Erreur HTTP : {exc}")
        return []

    try:
        cal = Calendar.from_ical(resp.content)
    except Exception as exc:
        logging.error(f"[{src_id}] Erreur parsing ICS : {exc}")
        return []

    now_utc     = datetime.now(timezone.utc)
    cutoff_past = (now_utc - timedelta(minutes=30)).timestamp()
    cutoff_fut  = (now_utc + timedelta(days=lookahead_days)).timestamp()
    events      = []

    for component in cal.walk():
        if component.name != "VEVENT":
            continue

        dtstart = component.get("DTSTART")
        if dtstart is None:
            continue

        dt      = dtstart.dt
        all_day = not hasattr(dt, "hour")

        if all_day:
            ts = datetime.combine(dt, dtime(0, 0), tzinfo=timezone.utc).timestamp()
        else:
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            ts = dt.timestamp()

        # Filtre temporel
        if ts < cutoff_past or ts > cutoff_fut:
            continue

        summary  = str(component.get("SUMMARY", "")).strip()
        location = str(component.get("LOCATION", "")).strip()
        uid      = str(component.get("UID", f"{src_id}_{ts}"))
        dt_local = datetime.fromtimestamp(ts)

        events.append({
            "id":        f"{src_id}_{uid[:24]}",
            "source_id": src_id,
            "icon":      get_icon(summary),
            "title":     summary,
            "time":      "" if all_day else dt_local.strftime("%Hh%M"),
            "date":      dt_local.strftime("%Y-%m-%d"),
            "timestamp": int(ts),
            "sub":       label,
            "location":  location,
            "urgent":    False,
            "all_day":   all_day,
            "color":     color,
        })

    events.sort(key=lambda e: e["timestamp"])
    logging.info(f"[{src_id}] {len(events)} événement(s) ICS trouvé(s).")
    return events


# ─── Sync Google API ──────────────────────────────────────────────────────────

def _load_google_credentials():
    """
    Charge les credentials Google OAuth2.
    Cherche d'abord le token standard (google-auth), puis le fallback google_access.json.
    Retourne un objet google.oauth2.credentials.Credentials ou None.
    """
    try:
        from google.oauth2.credentials import Credentials
        from google.auth.transport.requests import Request
    except ImportError:
        logging.error("google-auth manquant : pip install google-auth google-api-python-client")
        return None

    SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"]

    # 1. Token standard (généré par --auth ou le daemon)
    if TOKEN_PATH.exists():
        logging.info(f"Chargement token : {TOKEN_PATH}")
        creds = Credentials.from_authorized_user_file(str(TOKEN_PATH), SCOPES)
        if creds.expired and creds.refresh_token:
            logging.info("Rafraîchissement du token Google…")
            creds.refresh(Request())
            TOKEN_PATH.parent.mkdir(parents=True, exist_ok=True)
            TOKEN_PATH.write_text(creds.to_json())
        if creds.valid:
            return creds

    # 2. Fallback : google_access.json (format custom du workspace)
    if GOOGLE_ACCESS_FALLBACK.exists():
        logging.info(f"Fallback token : {GOOGLE_ACCESS_FALLBACK}")
        try:
            with open(GOOGLE_ACCESS_FALLBACK) as f:
                ga = json.load(f)
            creds = Credentials(
                token         = ga.get("last_access_token"),
                refresh_token = ga.get("refresh_token"),
                client_id     = ga.get("client_id"),
                client_secret = ga.get("client_secret"),
                token_uri     = "https://oauth2.googleapis.com/token",
                scopes        = SCOPES,
            )
            if creds.expired and creds.refresh_token:
                creds.refresh(Request())
            if creds.valid:
                return creds
        except Exception as exc:
            logging.warning(f"Fallback google_access.json inutilisable : {exc}")

    logging.error(
        "Aucun credentials Google valide trouvé. "
        f"Lancez : python3 {__file__} --auth"
    )
    return None


def sync_google(source: Dict[str, Any], lookahead_days: int = 14) -> List[Dict[str, Any]]:
    """
    Récupère les événements depuis Google Calendar API.
    Utilise singleEvents=True pour développer automatiquement les récurrences
    (soccer hebdomadaire, karaté, etc.) en occurrences individuelles.
    """
    src_id      = source["id"]
    calendar_id = source.get("calendar_id", "primary")
    label       = source.get("label", src_id)
    color       = source.get("color", "#FFB81C")

    logging.info(f"[{src_id}] Sync Google Calendar (calendarId={calendar_id})…")

    try:
        from googleapiclient.discovery import build
    except ImportError:
        logging.error("google-api-python-client manquant : pip install google-api-python-client")
        return []

    creds = _load_google_credentials()
    if creds is None:
        return []

    try:
        service = build("calendar", "v3", credentials=creds, cache_discovery=False)
    except Exception as exc:
        logging.error(f"[{src_id}] Impossible de créer le service Google : {exc}")
        return []

    now_utc  = datetime.now(timezone.utc)
    time_min = now_utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    time_max = (now_utc + timedelta(days=lookahead_days)).strftime("%Y-%m-%dT%H:%M:%SZ")

    try:
        result = service.events().list(
            calendarId   = calendar_id,
            timeMin      = time_min,
            timeMax      = time_max,
            maxResults   = 250,
            singleEvents = True,   # développe les RRULE en occurrences individuelles
            orderBy      = "startTime",
        ).execute()
    except Exception as exc:
        logging.error(f"[{src_id}] Erreur API Google : {exc}")
        return []

    items  = result.get("items", [])
    events = []

    for item in items:
        start   = item.get("start", {})
        dt_str  = start.get("dateTime") or start.get("date")
        if not dt_str:
            continue

        all_day = "dateTime" not in start

        if all_day:
            dt_local = datetime.strptime(dt_str, "%Y-%m-%d")
            ts       = int(datetime.combine(dt_local.date(), dtime(0, 0),
                                            tzinfo=timezone.utc).timestamp())
        else:
            dt_aware = datetime.fromisoformat(dt_str)
            ts       = int(dt_aware.timestamp())
            dt_local = datetime.fromtimestamp(ts)

        summary  = item.get("summary", "").strip()
        location = item.get("location", "").strip()
        uid      = item.get("id", f"{src_id}_{ts}")

        events.append({
            "id":        f"{src_id}_{uid[:24]}",
            "source_id": src_id,
            "icon":      get_icon(summary),
            "title":     summary,
            "time":      "" if all_day else dt_local.strftime("%Hh%M"),
            "date":      dt_local.strftime("%Y-%m-%d"),
            "timestamp": ts,
            "sub":       label,
            "location":  location,
            "urgent":    False,
            "all_day":   all_day,
            "color":     color,
        })

    logging.info(f"[{src_id}] {len(events)} événement(s) Google trouvé(s) "
                 f"(récurrences incluses).")
    return events


# ─── Écriture output ──────────────────────────────────────────────────────────

def write_output(events: List[Dict], sources_meta: List[Dict], dry_run: bool = False):
    """
    Écrit events_live.json au format v2.0.
    En dry-run, affiche le JSON sans écrire.
    """
    # Déduplication par id + tri chronologique
    seen, deduped = set(), []
    for ev in sorted(events, key=lambda e: e["timestamp"]):
        if ev["id"] not in seen:
            seen.add(ev["id"])
            deduped.append(ev)

    payload = {
        "_meta": {
            "version":   "2.0",
            "last_sync": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "sources":   sources_meta,
        },
        "events": deduped,
    }

    if dry_run:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
        logging.info(f"[DRY-RUN] {len(deduped)} événement(s) (non écrit).")
        return

    DATA_DIR.mkdir(parents=True, exist_ok=True)
    tmp = OUTPUT_FILE.with_suffix(".tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
    tmp.replace(OUTPUT_FILE)

    logging.info(f"Sync terminée : {len(deduped)} événement(s) → {OUTPUT_FILE}")

    # Signal IPC Quickshell (non-bloquant, ignoré si shell non actif)
    try:
        subprocess.run(
            ["quickshell", "ipc", "call", "root", "refreshEvents"],
            timeout=2, capture_output=True
        )
        logging.debug("Signal IPC refreshEvents envoyé.")
    except Exception:
        pass


# ─── OAuth2 interactif ────────────────────────────────────────────────────────

def run_auth_flow():
    """
    Lance le flow OAuth2 Google interactif (première authentification).
    Requiert google_credentials.json dans ~/beehive_os/config/.
    Sauvegarde le token dans ~/beehive_os/config/google_calendar_token.json.
    """
    if not CREDS_PATH.exists():
        print(f"ERREUR : fichier de credentials introuvable : {CREDS_PATH}")
        print("Téléchargez-le depuis Google Cloud Console → OAuth 2.0 Client IDs.")
        sys.exit(1)

    try:
        from google_auth_oauthlib.flow import InstalledAppFlow
    except ImportError:
        print("ERREUR : google-auth-oauthlib manquant. pip install google-auth-oauthlib")
        sys.exit(1)

    SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"]
    flow   = InstalledAppFlow.from_client_secrets_file(str(CREDS_PATH), SCOPES)
    creds  = flow.run_local_server(port=0)

    TOKEN_PATH.parent.mkdir(parents=True, exist_ok=True)
    TOKEN_PATH.write_text(creds.to_json())
    print(f"Authentification réussie. Token sauvegardé : {TOKEN_PATH}")


# ─── Point d'entrée ───────────────────────────────────────────────────────────

def main():
    dry_run = "--dry-run" in sys.argv
    verbose = "--verbose" in sys.argv or "-v" in sys.argv

    # Logging : fichier + stdout
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    handlers = [
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler(sys.stdout),
    ]
    logging.basicConfig(
        level   = logging.DEBUG if verbose else logging.INFO,
        format  = "%(asctime)s [%(levelname)s] %(message)s",
        datefmt = "%Y-%m-%d %H:%M:%S",
        handlers = handlers,
    )

    logging.info("=== bee_sync_simple.py — démarrage ===")
    if dry_run:
        logging.info("Mode DRY-RUN activé (aucune écriture).")

    cfg = load_config()
    if not cfg:
        logging.error("Impossible de charger user_config.json. Arrêt.")
        sys.exit(1)

    calendars    = cfg.get("calendars", [])
    live_sync    = cfg.get("live_sync", {})
    lookahead    = live_sync.get("lookahead_days", 14)

    if not calendars:
        logging.warning("Aucune source dans 'calendars'. Ajoutez des calendriers dans user_config.json.")
        sys.exit(0)

    logging.info(f"{len(calendars)} source(s) configurée(s). Lookahead : {lookahead} jours.")

    all_events: List[Dict]   = []
    sources_meta: List[Dict] = []

    for source in calendars:
        src_id   = source.get("id", "?")
        src_type = source.get("type", "ics")
        error    = None
        last_ok  = None

        try:
            if src_type == "google_api":
                evts = sync_google(source, lookahead)
            elif src_type == "ics":
                evts = sync_ics(source, lookahead)
            else:
                logging.warning(f"[{src_id}] Type inconnu '{src_type}', ignoré.")
                evts = []

            if evts:
                last_ok = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
            all_events.extend(evts)

        except Exception as exc:
            logging.error(f"[{src_id}] Erreur inattendue : {exc}")
            evts  = []
            error = str(exc)

        sources_meta.append({
            "id":      src_id,
            "type":    src_type,
            "url":     source.get("url", ""),
            "label":   source.get("label", src_id),
            "color":   source.get("color", "#FFB81C"),
            "last_ok": last_ok,
            "error":   error,
        })

    write_output(all_events, sources_meta, dry_run=dry_run)
    logging.info("=== bee_sync_simple.py — terminé ===")


if __name__ == "__main__":
    if "--auth" in sys.argv:
        run_auth_flow()
    else:
        main()
