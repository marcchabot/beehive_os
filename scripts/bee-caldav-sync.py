#!/usr/bin/env python3
"""
bee-caldav-sync.py — CalDAV Bi-Directional Sync for Bee-Hive OS 🐝☁️
v0.8.25

Syncs Google Calendar events bi-directionally using the gog CLI tool.
Reads/writes events data from/to ~/.config/bee-hive-os/data/events_live.json
(the same file bee_sync.py uses).

Usage:
  python3 bee-caldav-sync.py --sync          # Full bidirectional sync
  python3 bee-caldav-sync.py --pull          # Pull only from remote
  python3 bee-caldav-sync.py --sync --force-full  # Force full resync

Output: JSON status on stdout for BeeCalendar.qml to parse.
"""

import json
import os
import sys
import subprocess
import datetime
import zoneinfo
from pathlib import Path

# ═══════════════════════════════════════════════════════════════
# CONFIGURATION ET CHEMINS 🐝
# ═══════════════════════════════════════════════════════════════

SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent

# Déterminer les chemins selon l'environnement
if "/home/node/.openclaw/workspace" in str(PROJECT_ROOT):
    CONFIG_FILE = PROJECT_ROOT / "user_config.json"
    DATA_DIR = PROJECT_ROOT / "data"
    GOG_CONFIG = "/home/node/.openclaw/config/gogcli/"
else:
    CONFIG_FILE = PROJECT_ROOT / "user_config.json"
    DATA_DIR = Path(os.path.expanduser("~/.config/bee-hive-os/data"))
    GOG_CONFIG = os.path.expanduser("~/.config")

EVENTS_FILE = DATA_DIR / "events_live.json"
LOCAL_TZ = zoneinfo.ZoneInfo("America/Toronto")
DAYS_AHEAD = 14
DAYS_BEHIND = 1  # Combien de jours dans le passé pour les événements récents

# Calendriers Google par défaut (identifiants bien connus)
WELL_KNOWN_IDS = {
    "famille":   "family01761025763253819175@group.calendar.google.com",
    "personnel": "powerland@gmail.com",
    "perso":     "powerland@gmail.com",
    "pharmacie": "e2vcp5c26oqp0aobdfpoceg687mr8h4h@import.calendar.google.com",
    "xps":       "641157bb2b2c0a399e538051e15f77aea90c5b1ab8a8bfa31dea87586bc6e486@group.calendar.google.com"
}

# Gog Config — PATH complet incluant ~/.local/bin et linuxbrew
_home = os.path.expanduser("~")
_base_path = os.environ.get("PATH", "/usr/local/bin:/usr/bin:/bin")
_local_bin = os.path.join(_home, ".local", "bin")
_linuxbrew_bin = "/home/linuxbrew/.linuxbrew/bin"
for p in [_local_bin, _linuxbrew_bin]:
    if p not in _base_path:
        _base_path = f"{p}:{_base_path}"

GOG_ENV = {
    "GOG_KEYRING_PASSWORD": "maya",
    "GOG_ACCOUNT": "powerland@gmail.com",
    "XDG_CONFIG_HOME": GOG_CONFIG,
    "HOME": _home,
    "PATH": _base_path,
}

# ═══════════════════════════════════════════════════════════════
# UTILITAIRES 🐝
# ═══════════════════════════════════════════════════════════════

def get_icon(title: str, label: str = "") -> str:
    """Détermine l'icône emoji selon le titre et le label du calendrier."""
    text = (title + " " + label).lower()
    if any(k in text for k in ("soccer", "match", "football", "cdc")):       return "⚽"
    if any(k in text for k in ("karaté", "karate", "judo", "aikido")):      return "🥋"
    if any(k in text for k in ("pharmacie", "médicament", "rx", "pilule")): return "💊"
    if any(k in text for k in ("dentiste", "paro", "orthodont", "dentaire")): return "🦷"
    if any(k in text for k in ("médecin", "docteur", "clinique", "dr ")):   return "🩺"
    if any(k in text for k in ("école", "étude", "devoir", "classe")):      return "📚"
    if any(k in text for k in ("livraison", "lufa", "colis", "commande")):  return "📦"
    if any(k in text for k in ("ménage", "nettoyage", "rangement")):        return "🧹"
    if any(k in text for k in ("poubelle", "recyclage", "compost")):        return "🗑️"
    if any(k in text for k in ("coupe", "haircut", "coiffeur")):            return "✂️"
    if any(k in text for k in ("appel", "telus", "réunion", "meeting")):    return "📞"
    if any(k in text for k in ("anniversaire", "birthday", "fête")):        return "🎂"
    if any(k in text for k in ("ski", "tremblant", "chalet")):              return "🏔️"
    if any(k in text for k in ("voyage", "avion", "vol ", "trip")):         return "✈️"
    if any(k in text for k in ("sport", "gym", "entraîne")):                return "🏃"
    return "📅"


def format_relative_date(dt):
    """Formate une date en format relatif français (même logique que bee_sync.py)."""
    now = datetime.datetime.now(LOCAL_TZ)
    today = now.date()
    target = dt.date()

    time_str = dt.strftime("%Hh%M") if (dt.hour or dt.minute) else ""

    if target == today:
        prefix = "Auj."
    elif target == today + datetime.timedelta(days=1):
        prefix = "Dem."
    else:
        days = ["Lun.", "Mar.", "Mer.", "Jeu.", "Ven.", "Sam.", "Dim."]
        prefix = days[dt.weekday()]

    if not time_str:
        return f"{prefix} (Journée)"
    return f"{prefix} {time_str}"


def _run_gog(args: list, timeout: int = 30) -> tuple:
    """Exécute une commande gog et retourne (returncode, stdout, stderr)."""
    cmd = ["gog"] + args
    try:
        result = subprocess.run(
            cmd, env=GOG_ENV, capture_output=True, text=True,
            timeout=timeout, check=False
        )
        return result.returncode, result.stdout, result.stderr
    except FileNotFoundError:
        return -1, "", "gog command not found in PATH"
    except subprocess.TimeoutExpired:
        return -2, "", "gog command timed out"
    except Exception as e:
        return -3, "", str(e)


# ═══════════════════════════════════════════════════════════════
# PULL — Récupérer les événements depuis Google Calendar 🐝📥
# ═══════════════════════════════════════════════════════════════

def pull_events_from_google(calendars_config: list) -> list:
    """
    Récupère les événements Google Calendar via gog CLI.
    Retourne une liste d'événements au format events_live.json.
    """
    all_events = []
    errors = []

    for cal_cfg in calendars_config:
        cal_type = cal_cfg.get("type", "google_api")
        if cal_type not in ("google_api", "google"):
            continue  # Les calendriers ICS sont gérés par bee_sync.py

        label = cal_cfg.get("label", "Google")
        cal_id = cal_cfg.get("calendar_id") or cal_cfg.get("id", "")

        # Résolution des alias bien connus
        if cal_id.lower() in WELL_KNOWN_IDS:
            cal_id = WELL_KNOWN_IDS[cal_id.lower()]

        if not cal_id:
            errors.append(f"No calendar ID for '{label}'")
            continue

        # Construire la plage de dates
        now = datetime.datetime.now(LOCAL_TZ)
        from_date = (now - datetime.timedelta(days=DAYS_BEHIND)).strftime("%Y-%m-%d")
        to_date = (now + datetime.timedelta(days=DAYS_AHEAD)).strftime("%Y-%m-%d")

        # Exécuter gog calendar list
        rc, stdout, stderr = _run_gog([
            "calendar", "list", cal_id,
            "--from", from_date,
            "--to", to_date,
            "--max", "50",
            "--json",
            "--results-only",
            "--account", "powerland@gmail.com"
        ])

        if rc != 0:
            err_msg = stderr[:200] if stderr else f"exit code {rc}"
            errors.append(f"Gog '{label}': {err_msg}")
            continue

        try:
            data = json.loads(stdout)
            items = data if isinstance(data, list) else data.get("events", [])
        except json.JSONDecodeError as e:
            errors.append(f"Gog '{label}': JSON parse error: {e}")
            continue

        for item in items:
            summary = item.get("summary", "Sans titre")
            start = item.get("start", {})
            end = item.get("end", {})
            event_id = item.get("id", "")
            dt_str = start.get("dateTime") or start.get("date")
            end_dt_str = end.get("dateTime") or end.get("date")

            if not dt_str:
                continue

            all_day = "dateTime" not in start

            try:
                if all_day:
                    dt = datetime.datetime.strptime(dt_str, "%Y-%m-%d").replace(tzinfo=LOCAL_TZ)
                else:
                    dt = datetime.datetime.fromisoformat(dt_str.replace("Z", "+00:00")).astimezone(LOCAL_TZ)
            except Exception as e:
                errors.append(f"Parse error for '{summary}': {e}")
                continue

            event = {
                "id": event_id,
                "calendarId": cal_id,
                "icon": get_icon(summary, label),
                "title": summary,
                "time": format_relative_date(dt),
                "sub": label,
                "urgent": "urgent" in summary.lower(),
                "timestamp": dt.timestamp(),
                "canDelete": bool(event_id and cal_id),
                "source": "caldav",
            }
            all_events.append(event)

    return all_events, errors


# ═══════════════════════════════════════════════════════════════
# PUSH — Envoyer les événements locaux vers Google Calendar 🐝📤
# ═══════════════════════════════════════════════════════════════

def push_events_to_google(local_events: list, calendars_config: list) -> tuple:
    """
    Pousse les événements locaux qui n'existent pas encore sur Google Calendar.
    Conflit: remote wins par défaut (on n'écrase pas un événement distant).
    
    Retourne (pushed_count, errors_list)
    """
    pushed = 0
    errors = []

    # Construire un set des IDs distants existants (pour détecter les nouveaux locaux)
    # On ne pousse que les événements locaux qui n'ont pas de source "caldav"
    events_to_push = [
        e for e in local_events
        if e.get("source", "") != "caldav" and not e.get("calendarId", "")
    ]

    if not events_to_push:
        return 0, []

    # Calendrier par défaut pour les push
    default_cal_id = "powerland@gmail.com"

    for evt in events_to_push:
        title = evt.get("title", "Sans titre")
        timestamp = evt.get("timestamp", 0)
        if not timestamp:
            continue

        dt = datetime.datetime.fromtimestamp(timestamp, tz=LOCAL_TZ)
        date_str = dt.strftime("%Y-%m-%d")
        time_str = dt.strftime("%H:%M")
        all_day = "(Journée)" in evt.get("time", "")

        # Calculer l'heure de fin (1h par défaut)
        end_dt = dt + datetime.timedelta(hours=1)

        # Construire les datetimes RFC3339
        now_offset = datetime.datetime.now(LOCAL_TZ)
        offset = -now_offset.utcoffset().total_seconds() / 60  # minutes
        sign = "+" if offset >= 0 else "-"
        hours_off = int(abs(offset) / 60)
        mins_off = int(abs(offset) % 60)
        tz_str = f"{sign}{hours_off:02d}:{mins_off:02d}"

        if all_day:
            rc, stdout, stderr = _run_gog([
                "calendar", "create", default_cal_id,
                "--summary", title,
                "--from", date_str,
                "--to", date_str,
                "--all-day",
                "--account", "powerland@gmail.com"
            ])
        else:
            iso_start = f"{date_str}T{time_str}:00{tz_str}"
            end_time = end_dt.strftime("%H:%M")
            iso_end = f"{end_dt.strftime('%Y-%m-%d')}T{end_time}:00{tz_str}"

            rc, stdout, stderr = _run_gog([
                "calendar", "create", default_cal_id,
                "--summary", title,
                "--from", iso_start,
                "--to", iso_end,
                "--account", "powerland@gmail.com"
            ])

        if rc == 0:
            pushed += 1
        else:
            err_msg = stderr[:200] if stderr else f"exit code {rc}"
            errors.append(f"Push '{title}': {err_msg}")

    return pushed, errors


# ═══════════════════════════════════════════════════════════════
# MERGE — Fusion intelligente des événements 🐝🔄
# ═══════════════════════════════════════════════════════════════

def merge_events(local_events: list, remote_events: list) -> list:
    """
    Fusionne les événements locaux et distants.
    Stratégie: remote wins (les événements distants ont priorité).
    Les événements locaux sans source "caldav" sont conservés.
    Les doublons sont détectés par (title, timestamp).
    """
    merged = {}

    # Ajouter tous les événements locaux d'abord
    for evt in local_events:
        key = f"{evt.get('title', '')}_{evt.get('timestamp', 0)}"
        if key not in merged:
            merged[key] = evt

    # Les événements distants écrasent les locaux en cas de conflit (remote wins)
    for evt in remote_events:
        key = f"{evt.get('title', '')}_{evt.get('timestamp', 0)}"
        merged[key] = evt  # Remote écrase local

    # Trier par timestamp
    result = sorted(merged.values(), key=lambda x: x.get("timestamp", 0))
    return result


# ═══════════════════════════════════════════════════════════════
# CHARGEMENT CONFIG 🐝📋
# ═══════════════════════════════════════════════════════════════

def load_config() -> dict:
    """Charge la configuration depuis user_config.json."""
    try:
        with open(CONFIG_FILE) as f:
            return json.load(f)
    except Exception as e:
        print(f"[bee-caldav-sync] Config error: {e}", file=sys.stderr)
        return {}


def load_local_events() -> list:
    """Charge les événements locaux depuis events_live.json."""
    try:
        if EVENTS_FILE.exists():
            with open(EVENTS_FILE) as f:
                data = json.load(f)
            return data if isinstance(data, list) else data.get("events", [])
    except Exception as e:
        print(f"[bee-caldav-sync] Error loading local events: {e}", file=sys.stderr)
    return []


def save_events(events: list) -> bool:
    """Sauvegarde les événements dans events_live.json."""
    try:
        DATA_DIR.mkdir(parents=True, exist_ok=True)
        with open(EVENTS_FILE, "w") as f:
            json.dump(events, f, indent=2, ensure_ascii=False)

        # Aussi écrire dans le fallback home (comme bee_sync.py)
        home_fallback = Path.home() / "beehive_os/data/events_live.json"
        home_fallback.parent.mkdir(parents=True, exist_ok=True)
        with open(home_fallback, "w") as f:
            json.dump(events, f, indent=2, ensure_ascii=False)

        return True
    except Exception as e:
        print(f"[bee-caldav-sync] Error saving events: {e}", file=sys.stderr)
        return False


# ═══════════════════════════════════════════════════════════════
# MAIN 🐝
# ═══════════════════════════════════════════════════════════════

def main():
    # ─── Parse arguments ────────────────────────────────────
    mode = "sync"  # default: bidirectional
    force_full = False

    args = sys.argv[1:]
    if "--pull" in args:
        mode = "pull"
    if "--sync" in args:
        mode = "sync"
    if "--force-full" in args:
        force_full = True

    # ─── Charger la config ──────────────────────────────────
    config = load_config()
    calendars = config.get("calendars", [])
    caldav_cfg = config.get("caldav", {})

    if not caldav_cfg.get("enabled", False) and not calendars:
        result = {
            "status": "disabled",
            "message": "CalDAV sync is disabled or no calendars configured",
            "synced": 0,
            "pushed": 0,
            "errors": []
        }
        print(json.dumps(result, ensure_ascii=False))
        return

    # ─── Charger les événements locaux existants ───────────
    local_events = load_local_events()

    # ─── Pull: récupérer depuis Google Calendar ────────────
    remote_events, pull_errors = pull_events_from_google(calendars)

    # ─── Mode pull-only ─────────────────────────────────────
    if mode == "pull":
        # En mode pull, on fusionne simplement (remote wins)
        merged = merge_events(local_events, remote_events)
        saved = save_events(merged)
        result = {
            "status": "ok" if saved else "error",
            "message": f"Pulled {len(remote_events)} events from Google Calendar",
            "synced": len(remote_events),
            "pushed": 0,
            "total": len(merged),
            "errors": pull_errors
        }
        print(json.dumps(result, ensure_ascii=False))
        return

    # ─── Mode sync (bidirectional) ─────────────────────────
    pushed_count, push_errors = push_events_to_google(local_events, calendars)

    # Fusionner les événements (remote wins)
    merged = merge_events(local_events, remote_events)
    saved = save_events(merged)

    result = {
        "status": "ok" if saved else "partial" if merged else "error",
        "message": f"Synced {len(remote_events)} from Google, pushed {pushed_count} to Google",
        "synced": len(remote_events),
        "pushed": pushed_count,
        "total": len(merged),
        "errors": pull_errors + push_errors
    }
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()