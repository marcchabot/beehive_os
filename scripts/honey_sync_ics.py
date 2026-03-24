#!/usr/bin/env python3
import json
import os
import sys
import datetime
from urllib import request
from urllib.error import URLError

# Configuration paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
CONFIG_FILE = os.path.join(PROJECT_DIR, "user_config.json")
OUTPUT_FILE = os.path.join(PROJECT_DIR, "data/events.json")

def load_config():
    if not os.path.exists(CONFIG_FILE):
        return None
    with open(CONFIG_FILE, "r") as f:
        return json.load(f)

def get_icon(summary):
    summary = summary.lower()
    if "soccer" in summary or "match" in summary: return "⚽"
    if "pharmacie" in summary or "réunion" in summary or "meeting" in summary: return "💊"
    if "telus" in summary or "appel" in summary: return "📞"
    if "étude" in summary or "école" in summary: return "📚"
    if "karaté" in summary or "karate" in summary: return "🥋"
    if "ménage" in summary: return "🧹"
    if "livraison" in summary or "lufa" in summary: return "📦"
    if "paro" in summary or "dentiste" in summary: return "🦷"
    if "poubelle" in summary or "recyclage" in summary: return "🗑️"
    if "coupe" in summary or "cut" in summary: return "✂️"
    return "📅"

def parse_ics(ics_data):
    events = []
    lines = ics_data.split('\n')
    
    current_event = {}
    in_event = False
    
    for i in range(len(lines)):
        line = lines[i].strip()
        
        # Handle folded lines (ICS format wraps long lines with a space on the next line)
        while i + 1 < len(lines) and lines[i+1].startswith(' '):
            i += 1
            line += lines[i][1:]
            
        if line == "BEGIN:VEVENT":
            in_event = True
            current_event = {}
        elif line == "END:VEVENT":
            in_event = False
            if 'DTSTART' in current_event and 'SUMMARY' in current_event:
                events.append(current_event)
        elif in_event:
            if ':' in line:
                key, val = line.split(':', 1)
                # Remove parameters like DTSTART;TZID=...
                key = key.split(';')[0]
                current_event[key] = val

    return events

def process_events(raw_events):
    processed = []
    now = datetime.datetime.now(datetime.timezone.utc)
    
    for evt in raw_events:
        dtstart = evt.get('DTSTART', '')
        summary = evt.get('SUMMARY', 'Sans titre')
        location = evt.get('LOCATION', '')
        
        if not dtstart: continue
        
        try:
            # Parse ICS date formats (YYYYMMDD or YYYYMMDDTHHMMSSZ)
            if 'T' in dtstart:
                # With time
                dt_obj = datetime.datetime.strptime(dtstart.replace('Z', ''), "%Y%m%dT%H%M%S")
                if dtstart.endswith('Z'):
                    dt_obj = dt_obj.replace(tzinfo=datetime.timezone.utc)
                else:
                    # Best effort local time assumption if no Z (ICS standard is tricky with timezones)
                    dt_obj = dt_obj.replace(tzinfo=datetime.timezone.utc)
                    
                # Skip past events
                if dt_obj < now - datetime.timedelta(hours=24):
                    continue
                    
                time_str = dt_obj.strftime("%Hh%M")
                ts = dt_obj.timestamp()
            else:
                # Full day event (YYYYMMDD)
                dt_obj = datetime.datetime.strptime(dtstart, "%Y%m%d").replace(tzinfo=datetime.timezone.utc)
                
                # Skip past events
                if dt_obj < now - datetime.timedelta(hours=48):
                    continue
                    
                time_str = "Toute la journée"
                ts = dt_obj.timestamp()
                
            # Shorten location
            if len(location) > 30:
                location = location[:27] + "..."
                
            processed.append({
                "icon": get_icon(summary),
                "title": summary,
                "time": time_str,
                "sub": location.strip(),
                "urgent": "urgent" in summary.lower(),
                "timestamp": ts
            })
            
        except Exception as e:
            print(f"Skipping event {summary} due to date parsing error: {e}")
            continue
            
    # Sort and return next 5
    processed.sort(key=lambda x: x["timestamp"])
    return processed[:5]

def main():
    print("🐝 Bee-Hive OS: ICS Calendar Sync")
    config = load_config()
    
    if not config:
        print("❌ Cannot find user_config.json")
        sys.exit(1)
        
    ics_url = config.get("events_ics_url", "")
    
    if not ics_url or not ics_url.startswith("http"):
        print("ℹ️ No valid 'events_ics_url' found in user_config.json. Skipping sync.")
        sys.exit(0)
        
    print(f"📥 Fetching calendar from: {ics_url[:30]}...")
    
    try:
        req = request.Request(ics_url, headers={'User-Agent': 'Bee-Hive OS Sync'})
        with request.urlopen(req, timeout=10) as response:
            ics_data = response.read().decode('utf-8')
    except URLError as e:
        print(f"❌ Failed to download ICS: {e}")
        sys.exit(1)
        
    raw_events = parse_ics(ics_data)
    final_events = process_events(raw_events)
    
    if not os.path.exists(os.path.dirname(OUTPUT_FILE)):
        os.makedirs(os.path.dirname(OUTPUT_FILE))
        
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(final_events, f, indent=2, ensure_ascii=False)
        
    print(f"✅ Successfully extracted {len(final_events)} upcoming events!")

if __name__ == "__main__":
    main()
