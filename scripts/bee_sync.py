#!/usr/bin/env python3
"""
bee_sync.py — Bee-Hive OS Calendar Sync (Gog Wrapper Edition)
Utilise 'gog' pour Google et parsing manuel pour ICS.
Écrit 'events_live.json' pour Bee-Hive OS.
"""
import json
import datetime
import os
import subprocess
import zoneinfo
from pathlib import Path

# Paths relative to the project root (one level up from scripts/)
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
WORKSPACE_DIR = PROJECT_ROOT.parent

# On Marc's real machine, these might need to be absolute or configured.
# We'll try to detect if we're in the OpenClaw workspace or local.
if "/home/node/.openclaw/workspace" in str(PROJECT_ROOT):
    # Workspace mode
    CONFIG_FILE = PROJECT_ROOT / "user_config.json"
    OUTPUT_FILE = PROJECT_ROOT / "data/events_live.json"
    GOG_CONFIG = "/home/node/.openclaw/config/gogcli/"
else:
    # Marc's local machine mode (~/beehive_os)
    CONFIG_FILE = PROJECT_ROOT / "user_config.json"
    OUTPUT_FILE = PROJECT_ROOT / "data/events_live.json"
    GOG_CONFIG = os.path.expanduser("~/.config/gogcli/")

# Gog Config
GOG_CMD = "gog"
GOG_ENV = {
    "GOG_KEYRING_PASSWORD": "maya",
    "XDG_CONFIG_HOME": GOG_CONFIG,
    "PATH": os.environ.get("PATH", "")
}

LOCAL_TZ   = zoneinfo.ZoneInfo("America/Toronto")
DAYS_AHEAD = 7
MAX_EVENTS = 10

def get_icon(title: str, label: str = "") -> str:
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

def fetch_google_gog(cal_cfg):
    label  = cal_cfg.get("label", "Google")
    cal_id = cal_cfg["calendar_id"]
    
    cmd = [GOG_CMD, "calendar", "list", cal_id, "--days", str(DAYS_AHEAD), "--json", "--results-only"]
    events = []
    
    try:
        res = subprocess.run(cmd, env=GOG_ENV, capture_output=True, text=True, check=True)
        data = json.loads(res.stdout)
        
        # 'gog' returns a list of events directly with --results-only
        for item in data:
            summary = item.get("summary", "Sans titre")
            start = item.get("start", {})
            
            # Google API format via gog
            dt_str = start.get("dateTime") or start.get("date")
            if not dt_str: continue
            
            all_day = "dateTime" not in start
            
            if all_day:
                dt = datetime.datetime.strptime(dt_str, "%Y-%m-%d").replace(tzinfo=LOCAL_TZ)
                time_str = "Toute la journée"
            else:
                # Handle Z or offset
                dt = datetime.datetime.fromisoformat(dt_str.replace("Z", "+00:00")).astimezone(LOCAL_TZ)
                time_str = dt.strftime("%Hh%M")
            
            events.append({
                "icon":      get_icon(summary, label),
                "title":     summary,
                "time":      time_str,
                "sub":       label,
                "urgent":    "urgent" in summary.lower(),
                "timestamp": dt.timestamp(),
            })
    except Exception as exc:
        print(f"[bee_sync] Gog '{label}' error: {exc}")
        
    return events

def fetch_ics_calendar(cal_cfg):
    from urllib import request
    label = cal_cfg.get("label", "ICS")
    url   = cal_cfg["url"]
    events = []
    
    # Simple logic to avoid heavy deps, just looking for VEVENTs
    try:
        req = request.Request(url, headers={"User-Agent": "Bee-Hive OS bee_sync/1.0"})
        with request.urlopen(req, timeout=10) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            
        # Very crude parsing but sufficient for O365 ics
        lines = raw.splitlines()
        current = {}
        in_event = False
        
        for line in lines:
            if line.startswith("BEGIN:VEVENT"):
                in_event = True
                current = {}
            elif line.startswith("END:VEVENT"):
                in_event = False
                if "SUMMARY" in current and "DTSTART" in current:
                    summary = current["SUMMARY"]
                    dtstart = current["DTSTART"]
                    
                    try:
                        if "T" in dtstart:
                            # 20260328T150000Z
                            clean_dt = dtstart.split(":")[1] if ":" in dtstart else dtstart
                            dt = datetime.datetime.strptime(clean_dt.rstrip("Z"), "%Y%m%dT%H%M%S")
                            if dtstart.endswith("Z"):
                                dt = dt.replace(tzinfo=datetime.timezone.utc).astimezone(LOCAL_TZ)
                            else:
                                dt = dt.replace(tzinfo=LOCAL_TZ)
                            time_str = dt.strftime("%Hh%M")
                        else:
                            clean_dt = dtstart.split(":")[1] if ":" in dtstart else dtstart
                            dt = datetime.datetime.strptime(clean_dt, "%Y%m%d").replace(tzinfo=LOCAL_TZ)
                            time_str = "Toute la journée"
                            
                        # Window check
                        now = datetime.datetime.now(LOCAL_TZ)
                        if dt.timestamp() >= (now - datetime.timedelta(hours=2)).timestamp() and dt.timestamp() <= (now + datetime.timedelta(days=DAYS_AHEAD)).timestamp():
                            events.append({
                                "icon":      get_icon(summary, label),
                                "title":     summary,
                                "time":      time_str,
                                "sub":       label,
                                "urgent":    "urgent" in summary.lower(),
                                "timestamp": dt.timestamp(),
                            })
                    except Exception:
                        continue
            elif in_event:
                if ":" in line:
                    key, val = line.split(":", 1)
                    current[key.split(";")[0]] = val
                    
    except Exception as exc:
        print(f"[bee_sync] ICS '{label}' error: {exc}")
        
    return events

def main():
    try:
        with open(CONFIG_FILE) as f:
            config = json.load(f)
    except Exception as exc:
        print(f"Config error: {exc}")
        return

    calendars = config.get("calendars", [])
    all_events = []
    
    for cal in calendars:
        if cal.get("type") == "google_api":
            all_events.extend(fetch_google_gog(cal))
        elif cal.get("type") == "ics":
            all_events.extend(fetch_ics_calendar(cal))

    # Sort & Dedup
    all_events.sort(key=lambda x: x["timestamp"])
    
    seen = set()
    final_events = []
    for ev in all_events:
        key = f"{ev['title']}_{ev['timestamp']}"
        if key not in seen:
            seen.add(key)
            final_events.append(ev)

    final_events = final_events[:MAX_EVENTS]

    # Write
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, "w") as f:
        json.dump(final_events, f, indent=2, ensure_ascii=False)
        
    print(f"Sync complete: {len(final_events)} events written to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
