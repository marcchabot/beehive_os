#!/usr/bin/env python3
"""
Bee-Hive OS Desktop Icon Scanner v0.8.33
Scans .desktop files and maps window classes to icon paths.
Updates user_config.json section 'window_icons'.

Modes:
  --scan-all   Full scan of all .desktop directories
  --update     Incremental update (only new/changed entries)
  --app <name> Lookup icon for a specific app class
  --test       Dry run, no write
  --json       Output as JSON (for programmatic use)
"""

import os
import sys
import json
import subprocess
from pathlib import Path
from datetime import datetime

# Desktop file search paths (standard XDG)
DESKTOP_PATHS = [
    os.path.expanduser("~/.local/share/applications/"),
    "/usr/share/applications/",
    "/usr/local/share/applications/",
    "/var/lib/flatpak/exports/share/applications/",
    os.path.expanduser("~/.local/share/flatpak/exports/share/applications/"),
]

# Icon search paths for resolution
ICON_SEARCH_PATHS = [
    "/usr/share/icons/hicolor/scalable/apps/",
    "/usr/share/icons/hicolor/128x128/apps/",
    "/usr/share/icons/hicolor/96x96/apps/",
    "/usr/share/icons/hicolor/48x48/apps/",
    "/usr/share/icons/hicolor/32x32/apps/",
    "/usr/share/icons/hicolor/24x24/apps/",
    "/usr/share/icons/hicolor/16x16/apps/",
    "/usr/share/icons/Adwaita/scalable/apps/",
    "/usr/share/icons/Adwaita/128x128/apps/",
    "/usr/share/icons/Adwaita/48x48/apps/",
    "/usr/share/icons/Adwaita/32x32/apps/",
    "/usr/share/pixmaps/",
]

# Cache path
CACHE_DIR = os.path.expanduser("~/.cache/bee-hive-os")
CACHE_FILE = os.path.join(CACHE_DIR, "icon-cache.json")

# Bee-Hive OS config
BEEHIVE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_FILE = os.path.join(BEEHIVE_DIR, "user_config.json")

# Known window class → .desktop file mappings (for ambiguous cases)
KNOWN_MAPPINGS = {
    "kitty": "kitty",
    "zen": "zen-browser",
    "zen-browser": "zen-browser",
    "firefox": "firefox",
    "code": "code",
    "code-url-handler": "code",
    "chromium": "chromium",
    "thunderbird": "thunderbird",
    "nautilus": "org.gnome.Nautilus",
    "dolphin": "org.kde.dolphin",
    "discord": "discord",
    "spotify": "spotify",
    "steam": "steam",
    "alacritty": "Alacritty",
    "foot": "foot",
    "obs": "com.obsproject.Studio",
    "gimp": "gimp",
    "pavucontrol": "org.pulseaudio.pavucontrol",
}


def log(msg):
    """Log to stderr for QML Process stdout parsing."""
    print(f"[IconScanner] {msg}", file=sys.stderr)


def parse_desktop_file(filepath):
    """Parse a .desktop file and extract Name, Icon, Exec, StartupWMClass."""
    result = {"Name": "", "Icon": "", "Exec": "", "StartupWMClass": "", "NoDisplay": False}
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
        in_desktop_entry = False
        for line in lines:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
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
                elif key == "NoDisplay":
                    result["NoDisplay"] = value.strip().lower() == "true"
    except Exception as e:
        log(f"Error parsing {filepath}: {e}")
    return result


def resolve_icon_path(icon_name):
    """Resolve an icon name to an absolute file path."""
    if not icon_name:
        return ""

    # Already absolute path
    if os.path.isabs(icon_name) and os.path.exists(icon_name):
        return icon_name

    # Search in icon directories
    extensions = [".svg", ".png", ".xpm", ""]
    for icon_dir in ICON_SEARCH_PATHS:
        for ext in extensions:
            path = os.path.join(icon_dir, f"{icon_name}{ext}")
            if os.path.exists(path):
                return path

    # Try gtk-query-icon-theme (if available)
    try:
        result = subprocess.run(
            ["gtk4-query-icon-theme", icon_name],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0 and result.stdout.strip():
            path = result.stdout.strip().split('\n')[0]
            if os.path.exists(path):
                return path
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass

    # Try older gtk-query
    try:
        result = subprocess.run(
            ["gtk-query-icon-theme-3.0", icon_name],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0 and result.stdout.strip():
            path = result.stdout.strip().split('\n')[0]
            if os.path.exists(path):
                return path
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass

    # Return the icon name as-is (might be a themed icon)
    return icon_name


def scan_desktop_files():
    """Scan all .desktop directories and build icon mapping."""
    desktop_entries = {}

    for desktop_path in DESKTOP_PATHS:
        if not os.path.isdir(desktop_path):
            continue
        try:
            for filename in os.listdir(desktop_path):
                if not filename.endswith(".desktop"):
                    continue
                filepath = os.path.join(desktop_path, filename)
                info = parse_desktop_file(filepath)

                # Skip hidden .desktop files
                if info["NoDisplay"]:
                    continue
                if not info["Name"] or not info["Icon"]:
                    continue

                # Determine window class
                window_class = ""
                if info["StartupWMClass"]:
                    window_class = info["StartupWMClass"].lower()
                if not window_class:
                    app_name = os.path.splitext(filename)[0].lower()
                    if app_name in KNOWN_MAPPINGS:
                        window_class = KNOWN_MAPPINGS[app_name].lower()
                if not window_class and info["Exec"]:
                    exec_cmd = info["Exec"].split()[0] if info["Exec"] else ""
                    if exec_cmd:
                        window_class = os.path.basename(exec_cmd).lower()
                if not window_class:
                    window_class = os.path.splitext(filename)[0].lower()

                icon_path = resolve_icon_path(info["Icon"])
                if window_class and icon_path:
                    desktop_entries[window_class] = {
                        "name": info["Name"],
                        "icon": icon_path
                    }
        except Exception as e:
            log(f"Error scanning {desktop_path}: {e}")

    return desktop_entries


def load_cache():
    """Load the icon cache."""
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, 'r') as f:
                return json.load(f)
        except Exception:
            pass
    return {"icons": {}, "last_scan": None}


def save_cache(cache):
    """Save the icon cache."""
    os.makedirs(CACHE_DIR, exist_ok=True)
    cache["last_scan"] = datetime.now().isoformat()
    try:
        with open(CACHE_FILE, 'w') as f:
            json.dump(cache, f, indent=2)
    except Exception as e:
        log(f"Error saving cache: {e}")


def load_config():
    """Load user_config.json."""
    if not os.path.exists(CONFIG_FILE):
        log(f"Config file not found: {CONFIG_FILE}")
        return {}
    try:
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    except Exception as e:
        log(f"Error loading config: {e}")
        return {}


def save_config(config):
    """Save user_config.json."""
    try:
        with open(CONFIG_FILE, 'w') as f:
            json.dump(config, f, indent=2)
        log(f"Config saved with {len(config.get('window_icons', {}))} icons")
    except Exception as e:
        log(f"Error saving config: {e}")
        return False
    return True


def cmd_scan_all(test_mode=False):
    """Full scan: scan all .desktop files and update config."""
    log("Running full icon scan...")
    desktop_entries = scan_desktop_files()
    cache = load_cache()

    config = load_config()
    if "window_icons" not in config:
        config["window_icons"] = {}

    existing = config["window_icons"]
    updated = 0

    for wc, entry in desktop_entries.items():
        path = entry["icon"]
        if wc not in existing or existing[wc] != path:
            if not test_mode:
                config["window_icons"][wc] = path
            updated += 1

    # Update cache
    cache["icons"] = desktop_entries
    save_cache(cache)

    if not test_mode and updated > 0:
        save_config(config)
        log(f"✅ Updated {updated} icons (total: {len(config['window_icons'])})")
    elif not test_mode:
        log(f"No updates needed ({updated} matches)")
    else:
        log(f"DRY RUN: {updated} icons would be updated")

    return {"updated": updated, "total": len(config.get("window_icons", {}))}


def cmd_update(test_mode=False):
    """Incremental update: only add new entries, don't overwrite existing."""
    log("Running incremental icon update...")
    desktop_entries = scan_desktop_files()

    config = load_config()
    if "window_icons" not in config:
        config["window_icons"] = {}

    existing = config["window_icons"]
    added = 0

    for wc, entry in desktop_entries.items():
        if wc not in existing:
            if not test_mode:
                config["window_icons"][wc] = entry["icon"]
            added += 1

    if not test_mode and added > 0:
        save_config(config)
        log(f"✅ Added {added} new icons (total: {len(config['window_icons'])})")
    else:
        log(f"No new icons to add ({added} new)")

    return {"added": added, "total": len(config.get("window_icons", {}))}


def cmd_app_lookup(app_name):
    """Lookup icon for a specific app class."""
    desktop_entries = scan_desktop_files()

    # Try direct match
    app_lower = app_name.lower()
    if app_lower in desktop_entries:
        return desktop_entries[app_lower]

    # Try known mappings
    if app_lower in KNOWN_MAPPINGS:
        mapped = KNOWN_MAPPINGS[app_lower].lower()
        if mapped in desktop_entries:
            return desktop_entries[mapped]

    # Try partial match
    for wc, entry in desktop_entries.items():
        if app_lower in wc or wc.startswith(app_lower):
            return entry

    return None


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Bee-Hive OS Desktop Icon Scanner")
    parser.add_argument("--scan-all", "-a", action="store_true", help="Full scan of all .desktop directories")
    parser.add_argument("--update", "-u", action="store_true", help="Incremental update (only new entries)")
    parser.add_argument("--app", "-p", type=str, help="Lookup icon for a specific app class")
    parser.add_argument("--test", "-t", action="store_true", help="Dry run, no write")
    parser.add_argument("--json", "-j", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    if args.app:
        result = cmd_app_lookup(args.app)
        if result:
            if args.json:
                print(json.dumps({"app": args.app, "result": result}))
            else:
                log(f"Found icon for {args.app}: {result['icon']} ({result['name']})")
            return 0
        else:
            if args.json:
                print(json.dumps({"app": args.app, "result": None}))
            else:
                log(f"No icon found for {args.app}")
            return 1

    if args.scan_all:
        result = cmd_scan_all(test_mode=args.test)
        if args.json:
            print(json.dumps(result))
        return 0

    if args.update:
        result = cmd_update(test_mode=args.test)
        if args.json:
            print(json.dumps(result))
        return 0

    # Default: incremental update
    result = cmd_update(test_mode=args.test)
    if args.json:
        print(json.dumps(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())