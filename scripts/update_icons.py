#!/usr/bin/env python3
"""
Bee-Hive OS Desktop Icon Scanner
Automatically maps window classes to icons from .desktop files
"""

import os
import sys
import json
import subprocess
from pathlib import Path

# Desktop file search paths (standard XDG)
DESKTOP_PATHS = [
    "/usr/share/applications/",
    "/usr/local/share/applications/",
    os.path.expanduser("~/.local/share/applications/"),
]

# Bee-Hive OS paths
BEEHIVE_DIR = Path(__file__).parent.parent
CONFIG_FILE = BEEHIVE_DIR / "user_config.json"
LOG_FILE = BEEHIVE_DIR / "boot_scan.log"

KNOWN_MAPPINGS = {
    "kitty": "kitty",
    "zen": "zen-browser",
    "firefox": "firefox",
    "code": "code",
    "chromium": "chromium",
    "thunderbird": "thunderbird",
    "nautilus": "org.gnome.Nautilus",
    "gedit": "org.gnome.gedit",
    "gnome-terminal": "org.gnome.Terminal",
    "konsole": "org.kde.konsole",
    "dolphin": "org.kde.dolphin",
    "qterminal": "org.qterminal.qterminal",
}

def log(message):
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(message + "\n")
    except:
        pass

def parse_desktop_file(filepath):
    result = {"Name": "", "Icon": "", "Exec": "", "StartupWMClass": ""}
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
        in_desktop_entry = False
        for line in lines:
            line = line.strip()
            if not line or line.startswith("#"): continue
            if line == "[Desktop Entry]":
                in_desktop_entry = True
                continue
            if line.startswith("[") and line.endswith("]"):
                in_desktop_entry = False
                continue
            if in_desktop_entry and "=" in line:
                key, value = line.split("=", 1)
                key = key.strip()
                if key in ["Name", "Icon", "Exec", "StartupWMClass"]:
                    result[key] = value.strip()
    except:
        pass
    return result

def find_icon_path(icon_name):
    if not icon_name: return ""
    if os.path.isabs(icon_name) and os.path.exists(icon_name):
        return icon_name
    
    icon_dirs = [
        "/usr/share/icons/hicolor/scalable/apps/",
        "/usr/share/icons/hicolor/48x48/apps/",
        "/usr/share/icons/hicolor/32x32/apps/",
        "/usr/share/icons/hicolor/24x24/apps/",
        "/usr/share/icons/Adwaita/scalable/apps/",
        "/usr/share/icons/Adwaita/48x48/apps/",
        "/usr/share/icons/Adwaita/32x32/apps/",
        "/usr/share/pixmaps/",
    ]
    extensions = [".png", ".svg", ".xpm", ""]
    for icon_dir in icon_dirs:
        for ext in extensions:
            path = os.path.join(icon_dir, f"{icon_name}{ext}")
            if os.path.exists(path): return path
    return icon_name

def scan_desktop_files():
    desktop_entries = {}
    for desktop_path in DESKTOP_PATHS:
        if not os.path.isdir(desktop_path): continue
        for filename in os.listdir(desktop_path):
            if not filename.endswith(".desktop"): continue
            filepath = os.path.join(desktop_path, filename)
            info = parse_desktop_file(filepath)
            if not info["Name"] or not info["Icon"]: continue
            
            window_class = ""
            if info["StartupWMClass"]:
                window_class = info["StartupWMClass"].lower()
            if not window_class:
                app_name = os.path.splitext(filename)[0].lower()
                if app_name in KNOWN_MAPPINGS:
                    window_class = KNOWN_MAPPINGS[app_name].lower()
            if not window_class and info["Exec"]:
                exec_cmd = info["Exec"].split()[0] if info["Exec"] else ""
                if exec_cmd: window_class = os.path.basename(exec_cmd).lower()
            if not window_class:
                window_class = os.path.splitext(filename)[0].lower()
            
            icon_path = find_icon_path(info["Icon"])
            if window_class and icon_path:
                desktop_entries[window_class] = {"name": info["Name"], "icon": icon_path}
    return desktop_entries

def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--test", "-t", action="store_true")
    args = parser.parse_args()
    
    log(f"--- Scan started ---")
    desktop_entries = scan_desktop_files()
    
    if not CONFIG_FILE.exists():
        log("❌ Config file not found")
        return 1
    
    try:
        with open(CONFIG_FILE, 'r') as f:
            config = json.load(f)
        if "window_icons" not in config: config["window_icons"] = {}
        
        existing = config["window_icons"]
        updated = 0
        for wc, entry in desktop_entries.items():
            path = entry["icon"]
            if wc not in existing or existing[wc] != path:
                if not args.test:
                    config["window_icons"][wc] = path
                updated += 1
        
        if not args.test and updated > 0:
            with open(CONFIG_FILE, 'w') as f:
                json.dump(config, f, indent=2)
            log(f"✅ Updated {updated} icons")
        else:
            log(f"No updates needed ({updated} matches)")
            
    except Exception as e:
        log(f"CRITICAL ERROR: {str(e)}")
        return 1
    
    log(">> Scan complete!")
    return 0

if __name__ == "__main__":
    sys.exit(main())
