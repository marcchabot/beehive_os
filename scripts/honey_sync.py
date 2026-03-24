#!/usr/bin/env python3
import json
import subprocess
import datetime
import os
import zoneinfo
import sys

# --- 🐝 BEE-HIVE OS : HONEY-SYNC (LOCAL VERSION) 🐝 ---
# This script fetches Google Calendar events and saves them to data/events.json.
# It uses the 'gog' CLI (Google Workspace CLI) for secure authentication.
# --------------------------------------------------------------------------

# 1. Configuration - Customize your calendars here!
CALENDARS = [
    {"id": "primary", "label": "Perso"},
    # Add more calendar IDs here. Example:
    # {"id": "your-family-id@group.calendar.google.com", "label": "Famille"},
]

# 2. Paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
# If run from beehive_os root or scripts/ folder
if os.path.basename(SCRIPT_DIR) == "scripts":
    PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
else:
    PROJECT_DIR = SCRIPT_DIR

OUTPUT_FILE = os.path.join(PROJECT_DIR, "data/events.json")

# 3. Timezone for display
LOCAL_TZ = zoneinfo.ZoneInfo("America/Toronto")

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

def check_gog_installed():
    try:
        subprocess.run(["gog", "--version"], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

def fetch_events():
    all_events = []
    
    now = datetime.datetime.now(datetime.timezone.utc)
    from_date = now.strftime("%Y-%m-%dT%H:%M:%SZ")
    
    for cal in CALENDARS:
        # Use gog CLI to fetch events in JSON format
        cmd = ["gog", "calendar", "list", cal['id'], "--from", from_date, "--max", "10", "--json"]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                data = json.loads(result.stdout)
                for event in data.get("events", []):
                    start_data = event.get("start", {})
                    start_val = start_data.get("dateTime") or start_data.get("date")
                    if not start_val: continue
                    
                    # Parse time
                    if "T" in start_val:
                        # Handle ISO format with timezone
                        dt_local = datetime.datetime.fromisoformat(start_val.replace("Z", "+00:00")).astimezone(LOCAL_TZ)
                        time_str = dt_local.strftime("%Hh%M")
                        ts = dt_local.timestamp()
                    else:
                        dt_local = datetime.datetime.strptime(start_val, "%Y-%m-%d").replace(tzinfo=LOCAL_TZ)
                        time_str = "Toute la journée"
                        ts = dt_local.timestamp()
                    
                    location = event.get("location", "")
                    if len(location) > 30:
                        location = location[:27] + "..."
                    
                    all_events.append({
                        "icon": get_icon(event.get("summary", "")),
                        "title": event.get("summary", "Sans titre"),
                        "time": time_str,
                        "sub": f"{cal['label']} — {location}".strip(" — "),
                        "urgent": "urgent" in event.get("description", "").lower(),
                        "timestamp": ts
                    })
            else:
                print(f"⚠️ Warning: Could not fetch {cal['label']}. Make sure 'gog' is authorized.")
        except Exception as e:
            print(f"❌ Error fetching {cal['label']}: {e}")

    # Sort by timestamp
    all_events.sort(key=lambda x: x["timestamp"])
    return all_events[:5]  # Keep top 5

def main():
    if not check_gog_installed():
        print("❌ Error: 'gog' CLI not found.")
        print("Please install it: yay -S gogcli")
        print("Or compile: go install github.com/steipete/gogcli/cmd/gog@latest")
        sys.exit(1)

    if not os.path.exists(os.path.dirname(OUTPUT_FILE)):
        os.makedirs(os.path.dirname(OUTPUT_FILE))
        
    print("🐝 Fetching your nectar (events)...")
    events = fetch_events()
    
    with open(OUTPUT_FILE, "w") as f:
        json.dump(events, f, indent=2, ensure_ascii=False)
    
    if len(events) > 0:
        print(f"✅ Successfully synced {len(events)} events to {OUTPUT_FILE} 🍯")
    else:
        print("ℹ️ No upcoming events found. Dashboard will be empty.")

if __name__ == "__main__":
    main()
