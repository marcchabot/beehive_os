#!/usr/bin/env python3
"""
bee_sync.py — Bee-Hive OS Calendar Sync (Gog Wrapper Edition)
"""
import json
import datetime
import os
import subprocess
import zoneinfo
from pathlib import Path

# Paths relative to the project root
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
WORKSPACE_DIR = PROJECT_ROOT.parent

if "/home/node/.openclaw/workspace" in str(PROJECT_ROOT):
    CONFIG_FILE = PROJECT_ROOT / "user_config.json"
    OUTPUT_FILE = PROJECT_ROOT / "data/events_live.json"
    GOG_CONFIG = "/home/node/.openclaw/config/gogcli/"
else:
    CONFIG_FILE = PROJECT_ROOT / "user_config.json"
    OUTPUT_FILE = PROJECT_ROOT / "data/events_live.json"
    GOG_CONFIG = os.expanduser("~/.config/gogcli/")

# Gog Config
GOG_CMD = "gog"
GOG_ENV = {
    "GOG_KEYRING_PASSWORD": "maya",
    "XDG_CONFIG_HOME": GOG_CONFIG,
    "PATH": os.environ.get("PATH", "")
}

LOCAL_TZ   = zoneinfo.ZoneInfo("America/Toronto")
DAYS_AHEAD = 14
MAX_EVENTS = 12

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

def format_relative_date(dt):
    now = datetime.datetime.now(LOCAL_TZ)
    today = now.date()
    target = dt.date()
    
    time_str = dt.strftime("%Hh%M") if (dt.hour or dt.minute) else ""
    
    if target == today:
        prefix = "Auj."
    elif target == today + datetime.timedelta(days=1):
        prefix = "Dem."
    else:
        # Jour de la semaine abrégé en français
        days = ["Lun.", "Mar.", "Mer.", "Jeu.", "Ven.", "Sam.", "Dim."]
        prefix = days[dt.weekday()]
        
    if not time_str:
        return f"{prefix} (Journée)"
    return f"{prefix} {time_str}"

def fetch_google_gog(cal_cfg):
    label  = cal_cfg.get("label", "Google")
    cal_id = cal_cfg["calendar_id"]
    
    # On force --days 14 pour être sûr d'avoir les récurrences
    cmd = [GOG_CMD, "calendar", "list", cal_id, "--days", str(DAYS_AHEAD), "--json", "--results-only"]
    events = []
    
    try:
        res = subprocess.run(cmd, env=GOG_ENV, capture_output=True, text=True, check=True)
        data = json.loads(res.stdout)
        
        # 'gog' peut renvoyer un tableau direct ou un objet avec une clé 'events'
        items = data if isinstance(data, list) else data.get("events", [])
        
        for item in items:
            summary = item.get("summary", "Sans titre")
            start = item.get("start", {})
            dt_str = start.get("dateTime") or start.get("date")
            if not dt_str: continue
            
            all_day = "dateTime" not in start
            
            try:
                if all_day:
                    dt = datetime.datetime.strptime(dt_str, "%Y-%m-%d").replace(tzinfo=LOCAL_TZ)
                else:
                    dt = datetime.datetime.fromisoformat(dt_str.replace("Z", "+00:00")).astimezone(LOCAL_TZ)
                
                events.append({
                    "icon":      get_icon(summary, label),
                    "title":     summary,
                    "time":      format_relative_date(dt),
                    "sub":       label,
                    "urgent":    "urgent" in summary.lower(),
                    "timestamp": dt.timestamp(),
                })
            except Exception as e:
                print(f"[bee_sync] Error parsing event '{summary}': {e}")
                
    except Exception as exc:
        print(f"[bee_sync] Gog '{label}' error: {exc}")
        
    return events

def fetch_ics_calendar(cal_cfg):
    from urllib import request
    label = cal_cfg.get("label", "ICS")
    url   = cal_cfg["url"]
    events = []
    
    try:
        req = request.Request(url, headers={"User-Agent": "Bee-Hive OS bee_sync/1.0"})
        with request.urlopen(req, timeout=10) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            
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
                        clean_dt = dtstart.split(":")[1] if ":" in dtstart else dtstart
                        if "T" in dtstart:
                            dt = datetime.datetime.strptime(clean_dt.rstrip("Z"), "%Y%m%dT%H%M%S")
                            if dtstart.endswith("Z"):
                                dt = dt.replace(tzinfo=datetime.timezone.utc).astimezone(LOCAL_TZ)
                            else:
                                dt = dt.replace(tzinfo=LOCAL_TZ)
                        else:
                            dt = datetime.datetime.strptime(clean_dt, "%Y%m%d").replace(tzinfo=LOCAL_TZ)
                            
                        now = datetime.datetime.now(LOCAL_TZ)
                        if dt.timestamp() >= (now - datetime.timedelta(hours=2)).timestamp() and dt.timestamp() <= (now + datetime.timedelta(days=DAYS_AHEAD)).timestamp():
                            events.append({
                                "icon":      get_icon(summary, label),
                                "title":     summary,
                                "time":      format_relative_date(dt),
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

    all_events.sort(key=lambda x: x["timestamp"])
    
    seen = set()
    final_events = []
    for ev in all_events:
        key = f"{ev['title']}_{ev['timestamp']}"
        if key not in seen:
            seen.add(key)
            final_events.append(ev)

    # Respect the max_events from config if present
    max_ev = config.get("bee_events", {}).get("max_events", MAX_EVENTS)
    final_events = final_events[:max_ev]

    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, "w") as f:
        json.dump(final_events, f, indent=2, ensure_ascii=False)
        
    # Also write a copy to ~/.config/beehive_os/data/ for redundancy if possible
    try:
        home_fallback = Path.home() / ".config/beehive_os/data/events_live.json"
        home_fallback.parent.mkdir(parents=True, exist_ok=True)
        with open(home_fallback, "w") as f:
            json.dump(final_events, f, indent=2, ensure_ascii=False)
    except Exception:
        pass
        
    print(f"Sync complete: {len(final_events)} events written to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
