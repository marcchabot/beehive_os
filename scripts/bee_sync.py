#!/usr/bin/env python3
"""
bee_sync.py — Bee-Hive OS Calendar Sync (Robust Edition) 🐝📅
"""
import json
import datetime
import os
import subprocess
import zoneinfo
import sys
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
    GOG_CONFIG = os.path.join(os.path.expanduser("~"), ".config/gogcli/")

# Gog Config
GOG_CMD = "gog"
GOG_ENV = {
    "GOG_KEYRING_PASSWORD": "maya",
    "XDG_CONFIG_HOME": GOG_CONFIG,
    "PATH": os.environ.get("PATH", "/usr/local/bin:/usr/bin:/bin")
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
        days = ["Lun.", "Mar.", "Mer.", "Jeu.", "Ven.", "Sam.", "Dim."]
        prefix = days[dt.weekday()]
        
    if not time_str:
        return f"{prefix} (Journée)"
    return f"{prefix} {time_str}"

def fetch_google_gog(cal_cfg):
    label  = cal_cfg.get("label", "Google")
    # Fallback resilience for ID keys
    cal_id = cal_cfg.get("calendar_id") or cal_cfg.get("id")
    
    if not cal_id:
        print(f"[bee_sync] Warning: No ID found for Google calendar '{label}'")
        return []
        
    cmd = [GOG_CMD, "calendar", "list", cal_id, "--days", str(DAYS_AHEAD), "--json", "--results-only"]
    events = []
    
    try:
        res = subprocess.run(cmd, env=GOG_ENV, capture_output=True, text=True, check=True)
        data = json.loads(res.stdout)
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
                
    except FileNotFoundError:
        print(f"[bee_sync] Error: '{GOG_CMD}' command not found. Please install gog-cli.")
    except Exception as exc:
        print(f"[bee_sync] Gog '{label}' error: {exc}")
        
    return events

_WEEKDAY_MAP = {"MO": 0, "TU": 1, "WE": 2, "TH": 3, "FR": 4, "SA": 5, "SU": 6}

def _parse_ics_dt(raw_val: str, raw_key: str = "") -> datetime.datetime:
    val = raw_val.split(":")[-1] if ":" in raw_val else raw_val
    val = val.strip()
    if "T" in val:
        dt = datetime.datetime.strptime(val.rstrip("Z"), "%Y%m%dT%H%M%S")
        if val.endswith("Z"):
            return dt.replace(tzinfo=datetime.timezone.utc).astimezone(LOCAL_TZ)
        return dt.replace(tzinfo=LOCAL_TZ)
    else:
        return datetime.datetime.strptime(val, "%Y%m%d").replace(tzinfo=LOCAL_TZ)

def _expand_rrule(dtstart: datetime.datetime, rrule_str: str,
                  window_start: datetime.datetime, window_end: datetime.datetime) -> list:
    parts = dict(p.split("=", 1) for p in rrule_str.split(";") if "=" in p)
    freq      = parts.get("FREQ", "")
    interval  = int(parts.get("INTERVAL", 1))
    count_max = int(parts.get("COUNT", 0)) or None

    wend = window_end
    if "UNTIL" in parts:
        try:
            u = parts["UNTIL"].strip()
            fmt = "%Y%m%dT%H%M%S" if "T" in u else "%Y%m%d"
            tz  = datetime.timezone.utc if u.endswith("Z") else LOCAL_TZ
            until = datetime.datetime.strptime(u.rstrip("Z"), fmt).replace(tzinfo=tz).astimezone(LOCAL_TZ)
            wend = min(wend, until)
        except Exception: pass

    byday_wds = []
    if "BYDAY" in parts:
        for d in parts["BYDAY"].split(","):
            code = d.strip()[-2:]
            if code in _WEEKDAY_MAP: byday_wds.append(_WEEKDAY_MAP[code])

    occurrences = []
    count = 0
    if freq == "DAILY":
        dt = dtstart
        while dt <= wend and (count_max is None or count < count_max):
            if dt >= window_start: occurrences.append(dt)
            count += 1
            dt += datetime.timedelta(days=interval)
    elif freq == "WEEKLY":
        if byday_wds:
            week_mon = dtstart - datetime.timedelta(days=dtstart.weekday())
            week_mon = week_mon.replace(hour=dtstart.hour, minute=dtstart.minute, second=0, microsecond=0)
            wk = week_mon
            while wk <= wend and (count_max is None or count < count_max):
                for wd in sorted(byday_wds):
                    dt = wk + datetime.timedelta(days=wd)
                    if dt < dtstart: continue
                    if dt > wend: break
                    if dt >= window_start: occurrences.append(dt)
                    count += 1
                    if count_max and count >= count_max: break
                wk += datetime.timedelta(weeks=interval)
        else:
            dt = dtstart
            while dt <= wend and (count_max is None or count < count_max):
                if dt >= window_start: occurrences.append(dt)
                count += 1
                dt += datetime.timedelta(weeks=interval)
    elif freq == "MONTHLY":
        dt = dtstart
        while dt <= wend and (count_max is None or count < count_max):
            if dt >= window_start: occurrences.append(dt)
            count += 1
            m = dt.month + interval
            y = dt.year + (m - 1) // 12
            m = ((m - 1) % 12) + 1
            try: dt = dt.replace(year=y, month=m)
            except ValueError: break
    elif freq == "YEARLY":
        dt = dtstart
        while dt <= wend and (count_max is None or count < count_max):
            if dt >= window_start: occurrences.append(dt)
            count += 1
            try: dt = dt.replace(year=dt.year + interval)
            except ValueError: break
    return occurrences

def fetch_ics_calendar(cal_cfg):
    from urllib import request
    label = cal_cfg.get("label", "ICS")
    url   = cal_cfg.get("url") or cal_cfg.get("id")
    
    if not url or not url.startswith("http"):
        print(f"[bee_sync] Warning: Invalid URL for ICS calendar '{label}'")
        return []
        
    events = []
    try:
        req = request.Request(url, headers={"User-Agent": "Bee-Hive OS bee_sync/1.0"})
        with request.urlopen(req, timeout=10) as resp:
            raw = resp.read().decode("utf-8", errors="replace")

        unfolded = []
        for line in raw.splitlines():
            if line.startswith((' ', '\t')) and unfolded: unfolded[-1] += line[1:]
            else: unfolded.append(line)

        now          = datetime.datetime.now(LOCAL_TZ)
        window_start = now - datetime.timedelta(hours=6) # Match UI window
        window_end   = now + datetime.timedelta(days=DAYS_AHEAD)

        current  = {}
        in_event = False
        for line in unfolded:
            if line.startswith("BEGIN:VEVENT"):
                in_event = True
                current  = {}
            elif line.startswith("END:VEVENT"):
                in_event = False
                if "SUMMARY" not in current or "DTSTART" not in current: continue
                summary = current["SUMMARY"]
                try: dtstart = _parse_ics_dt(current["DTSTART"])
                except Exception: continue
                rrule = current.get("RRULE", "")
                if rrule:
                    for dt in _expand_rrule(dtstart, rrule, window_start, window_end):
                        events.append({
                            "icon":      get_icon(summary, label),
                            "title":     summary,
                            "time":      format_relative_date(dt),
                            "sub":       label,
                            "urgent":    "urgent" in summary.lower(),
                            "timestamp": dt.timestamp(),
                        })
                else:
                    if window_start.timestamp() <= dtstart.timestamp() <= window_end.timestamp():
                        events.append({
                            "icon":      get_icon(summary, label),
                            "title":     summary,
                            "time":      format_relative_date(dtstart),
                            "sub":       label,
                            "urgent":    "urgent" in summary.lower(),
                            "timestamp": dtstart.timestamp(),
                        })
            elif in_event and ":" in line:
                raw_key, val = line.split(":", 1)
                base_key = raw_key.split(";")[0]
                current[base_key] = val
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
        cal_type = cal.get("type", "google_api") # default to google_api
        if cal_type == "google_api":
            all_events.extend(fetch_google_gog(cal))
        elif cal_type == "ics":
            all_events.extend(fetch_ics_calendar(cal))

    all_events.sort(key=lambda x: x["timestamp"])
    
    seen = set()
    final_events = []
    for ev in all_events:
        key = f"{ev['title']}_{ev['timestamp']}"
        if key not in seen:
            seen.add(key)
            final_events.append(ev)

    max_ev = config.get("bee_events", {}).get("max_events", MAX_EVENTS)
    final_events = final_events[:max_ev]

    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, "w") as f:
        json.dump(final_events, f, indent=2, ensure_ascii=False)
        
    try:
        home_fallback = Path.home() / "beehive_os/data/events_live.json"
        home_fallback.parent.mkdir(parents=True, exist_ok=True)
        with open(home_fallback, "w") as f:
            json.dump(final_events, f, indent=2, ensure_ascii=False)
    except Exception: pass
        
    print(f"Sync complete: {len(final_events)} events written to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
