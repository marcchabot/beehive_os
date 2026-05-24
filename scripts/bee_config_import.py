#!/usr/bin/env python3
"""
bee_config_import.py — Bee-Hive OS Config Importer 🐝📥
v0.8.36 — Import .bhive archives and .bhivetheme files

Usage:
  python3 bee_config_import.py <path> [--merge] [--dry-run]
  python3 bee_config_import.py theme <path> [--dry-run]

Merge strategy:
  --merge (default): Preserve tokens/secrets, overwrite visual settings
  --overwrite: Replace everything (dangerous)
  --dry-run: Show what would change without writing
"""

import json
import os
import sys
import zipfile
import shutil
import hashlib
import datetime

# ─── Config paths ──────────────────────────────────────────────────────────────
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
HOME_DIR = os.path.expanduser("~")

CONFIG_PATHS = [
    os.path.join(HOME_DIR, ".config", "bee-hive-os", "user_config.json"),
    os.path.join(PROJECT_DIR, "user_config.json"),
]

DATA_DEST_DIRS = [
    os.path.join(HOME_DIR, ".config", "bee-hive-os", "data"),
    os.path.join(PROJECT_DIR, "data"),
]

WALLPAPER_DEST_DIRS = [
    os.path.join(HOME_DIR, ".config", "bee-hive-os", "wallpapers"),
    os.path.join(PROJECT_DIR, "wallpapers"),
]

PROFILES_DEST_PATHS = [
    os.path.join(HOME_DIR, ".config", "bee-hive-os", "profiles.json"),
    os.path.join(PROJECT_DIR, "profiles.json"),
]

# ─── Sensitive keys that should NEVER be overwritten during merge ──────────────
SENSITIVE_KEYS = {
    "caldav_password", "caldav.username", "caldav.url",
    "events_ics_url", "events_live_path",
    "bee_voice.elevenlabs_voice_id", "bee_voice.ollama_url",
}

# Keys that are always preserved (user-specific data)
PRESERVE_KEYS = {
    "calendars", "pinned_apps", "window_icons",
    "context_rules", "active_profile", "profiles",
    "quick_notes_enabled", "events_enabled",
}

# Keys that are safe to overwrite from import (visual/theme settings)
VISUAL_KEYS = {
    "theme", "transitions", "nectar_sync", "color_therapy_enabled",
    "auto_theme_mode", "auto_theme", "corners_mode", "motion_mode",
    "vibe_mode", "vibe_backend", "vibe_xray", "vibe_xray_dir",
    "vibe_xray_intensity", "vibe_xray_blend", "analog_clock",
    "sound", "stealth_mode", "focus_mode", "dashboard",
    "accessibility", "battery_mode", "auto_icons",
}


def find_config_path():
    """Find the user_config.json file."""
    for path in CONFIG_PATHS:
        if os.path.exists(path):
            return path
    # Default to project dir for new installs
    return CONFIG_PATHS[-1]


def find_data_dir():
    """Find/create the data directory."""
    for path in DATA_DEST_DIRS:
        if os.path.isdir(path):
            return path
    # Create default
    default = DATA_DEST_DIRS[-1]
    os.makedirs(default, exist_ok=True)
    return default


def find_wallpaper_dir():
    """Find/create the wallpapers directory."""
    for path in WALLPAPER_DEST_DIRS:
        if os.path.isdir(path):
            return path
    default = WALLPAPER_DEST_DIRS[-1]
    os.makedirs(default, exist_ok=True)
    return default


def find_profiles_path():
    """Find the profiles.json path."""
    for path in PROFILES_DEST_PATHS:
        if os.path.exists(path):
            return path
    return PROFILES_DEST_PATHS[-1]


def validate_bhive(path):
    """Validate a .bhive archive. Returns (valid, manifest, errors)."""
    errors = []
    manifest = None

    if not os.path.exists(path):
        return False, None, [f"File not found: {path}"]

    if not path.endswith('.bhive'):
        # Could still be a valid zip, just warn
        pass

    try:
        with zipfile.ZipFile(path, 'r') as zf:
            names = zf.namelist()

            # Check for manifest
            if "manifest.json" not in names:
                errors.append("Missing manifest.json in archive")
                return False, None, errors

            # Read and validate manifest
            try:
                manifest = json.loads(zf.read("manifest.json").decode('utf-8'))
            except Exception as e:
                errors.append(f"Invalid manifest.json: {e}")
                return False, None, errors

            if manifest.get("format") != "bhive":
                errors.append(f"Not a bhive archive (format={manifest.get('format')})")
                return False, None, errors

            # Check for config file
            if "config/user_config.json" not in names:
                errors.append("Missing config/user_config.json in archive")
                return False, None, errors

            # Verify config is valid JSON
            try:
                config_data = json.loads(zf.read("config/user_config.json").decode('utf-8'))
            except Exception as e:
                errors.append(f"Invalid config JSON: {e}")
                return False, None, errors

    except zipfile.BadZipFile:
        errors.append("Not a valid ZIP archive")
        return False, None, errors
    except Exception as e:
        errors.append(f"Error reading archive: {e}")
        return False, None, errors

    return True, manifest, errors


def validate_bhivetheme(path):
    """Validate a .bhivetheme file. Returns (valid, theme_data, errors)."""
    errors = []

    if not os.path.exists(path):
        return False, None, [f"File not found: {path}"]

    try:
        with open(path, 'r', encoding='utf-8') as f:
            theme_data = json.load(f)
    except Exception as e:
        return False, None, [f"Invalid JSON: {e}"]

    if theme_data.get("format") != "bhivetheme":
        return False, None, [f"Not a bhivetheme file (format={theme_data.get('format')})"]

    return True, theme_data, errors


def merge_config(local_cfg, import_cfg, mode="merge"):
    """Merge imported config into local config with smart conflict resolution."""
    merged = json.parse(json.dumps(local_cfg)) if False else json.loads(json.dumps(local_cfg))

    if mode == "overwrite":
        # Full overwrite — but still preserve sensitive data
        merged.update(import_cfg)
        # Restore sensitive keys
        for key in SENSITIVE_KEYS:
            parts = key.split(".")
            if len(parts) == 2:
                if parts[0] in local_cfg and parts[1] in local_cfg[parts[0]]:
                    if parts[0] not in merged:
                        merged[parts[0]] = {}
                    merged[parts[0]][parts[1]] = local_cfg[parts[0]][parts[1]]
        return merged

    # Smart merge mode: preserve local data, import visual settings
    # 1. Always preserve sensitive and user-specific keys
    for key in PRESERVE_KEYS:
        if key in local_cfg:
            merged[key] = local_cfg[key]

    # 2. Import visual/theme keys from the archive
    for key in VISUAL_KEYS:
        if key in import_cfg:
            merged[key] = import_cfg[key]

    # 3. Merge nested caldav — preserve password/username, import other settings
    if "caldav" in import_cfg:
        if "caldav" not in merged:
            merged["caldav"] = {}
        for subkey in import_cfg["caldav"]:
            if subkey not in ("password", "username"):
                merged["caldav"][subkey] = import_cfg["caldav"][subkey]

    # 4. Merge bee_voice — preserve API keys, import other settings
    if "bee_voice" in import_cfg:
        if "bee_voice" not in merged:
            merged["bee_voice"] = {}
        for subkey in import_cfg["bee_voice"]:
            if subkey not in ("ollama_url", "elevenlabs_voice_id"):
                merged["bee_voice"][subkey] = import_cfg["bee_voice"][subkey]

    # 5. Preserve lang preference
    merged["lang"] = local_cfg.get("lang", "fr")

    return merged


def import_config(path, mode="merge", dry_run=False):
    """Import a .bhive configuration archive."""
    valid, manifest, errors = validate_bhive(path)
    if not valid:
        result = {"status": "error", "errors": errors}
        print(json.dumps(result, indent=2))
        return 1

    config_path = find_config_path()
    data_dir = find_data_dir()
    wp_dir = find_wallpaper_dir()
    profiles_path = find_profiles_path()

    # Load current config
    local_cfg = {}
    if os.path.exists(config_path):
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                local_cfg = json.load(f)
        except Exception:
            local_cfg = {}

    changes = []

    with zipfile.ZipFile(path, 'r') as zf:
        # Read imported config
        import_cfg = json.loads(zf.read("config/user_config.json").decode('utf-8'))

        # Merge configs
        merged_cfg = merge_config(local_cfg, import_cfg, mode)
        changes.append(f"Config merged ({mode} mode)")

        # Backup current config
        if not dry_run:
            backup_path = config_path + f".bak.{datetime.datetime.now().strftime('%Y%m%d%H%M%S')}"
            if os.path.exists(config_path):
                shutil.copy2(config_path, backup_path)
                changes.append(f"Backup saved: {backup_path}")

        # Write merged config
        if not dry_run:
            os.makedirs(os.path.dirname(config_path), exist_ok=True)
            with open(config_path, 'w', encoding='utf-8') as f:
                json.dump(merged_cfg, f, indent=2, ensure_ascii=False)
            changes.append(f"Config written to {config_path}")
        else:
            changes.append(f"[DRY RUN] Would write merged config to {config_path}")

        # Import data files
        for name in zf.namelist():
            if name.startswith("data/") and not name.endswith("/"):
                fname = os.path.basename(name)
                dest = os.path.join(data_dir, fname)

                # Don't overwrite events_live.json (live data)
                if fname == "events_live.json":
                    changes.append(f"Skipped live data: {fname}")
                    continue

                if not dry_run:
                    with open(dest, 'wb') as f:
                        f.write(zf.read(name))
                    changes.append(f"Data imported: {fname}")
                else:
                    changes.append(f"[DRY RUN] Would import data: {fname}")

        # Import profiles
        if "config/profiles.json" in zf.namelist():
            profiles_data = zf.read("config/profiles.json").decode('utf-8')
            if not dry_run:
                with open(profiles_path, 'w', encoding='utf-8') as f:
                    f.write(profiles_data)
                changes.append(f"Profiles imported")
            else:
                changes.append(f"[DRY RUN] Would import profiles")

        # Import wallpapers
        wp_count = 0
        for name in zf.namelist():
            if name.startswith("wallpapers/") and not name.endswith("/"):
                fname = os.path.basename(name)
                dest = os.path.join(wp_dir, fname)
                if not dry_run:
                    with open(dest, 'wb') as f:
                        f.write(zf.read(name))
                    changes.append(f"Wallpaper imported: {fname}")
                else:
                    changes.append(f"[DRY RUN] Would import wallpaper: {fname}")
                wp_count += 1

        if wp_count > 0:
            changes.append(f"Total wallpapers imported: {wp_count}")

    result = {
        "status": "ok" if not dry_run else "dry_run",
        "mode": mode,
        "source": path,
        "changes": changes,
        "manifest": {
            "version": manifest.get("bhive_os_version", "unknown"),
            "exported_at": manifest.get("exported_at", "unknown"),
        }
    }
    print(json.dumps(result, indent=2))
    return 0


def import_theme(path, dry_run=False):
    """Import a .bhivetheme file (visual properties only)."""
    valid, theme_data, errors = validate_bhivetheme(path)
    if not valid:
        result = {"status": "error", "errors": errors}
        print(json.dumps(result, indent=2))
        return 1

    config_path = find_config_path()

    # Load current config
    local_cfg = {}
    if os.path.exists(config_path):
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                local_cfg = json.load(f)
        except Exception:
            local_cfg = {}

    changes = []

    # Apply theme mode
    if "theme" in theme_data:
        local_cfg["theme"] = theme_data["theme"]
        changes.append(f"Theme set to {theme_data['theme']}")

    # Apply visual settings
    if "visual" in theme_data:
        for key, value in theme_data["visual"].items():
            # Skip sensitive keys
            if key in ("caldav", "bee_voice"):
                changes.append(f"Skipped sensitive key: {key}")
                continue
            local_cfg[key] = value
            changes.append(f"Applied visual setting: {key}")

    # Apply palette
    if "palette" in theme_data and theme_data["palette"]:
        if "auto_theme" not in local_cfg:
            local_cfg["auto_theme"] = {}
        local_cfg["auto_theme"]["palette"] = theme_data["palette"]
        changes.append("Applied custom palette")

    # Apply wallpaper reference (not the file, just the path)
    if "wallpaper" in theme_data and theme_data["wallpaper"]:
        local_cfg["current_wallpaper"] = theme_data["wallpaper"]
        changes.append(f"Wallpaper reference set")

    # Apply cell visual layout (icons, titles, highlighted, colors only)
    if "cells_visual" in theme_data and theme_data["cells_visual"]:
        if "dashboard" not in local_cfg:
            local_cfg["dashboard"] = {}
        if "cells" not in local_cfg.get("dashboard", {}):
            local_cfg["dashboard"]["cells"] = []

        cells = local_cfg.get("dashboard", {}).get("cells", [])
        imported_cells = theme_data["cells_visual"]

        # Match by title or position
        for i, ic in enumerate(imported_cells):
            if i < len(cells):
                # Update visual properties only
                cells[i]["icon"] = ic.get("icon", cells[i].get("icon", ""))
                cells[i]["title"] = ic.get("title", cells[i].get("title", ""))
                cells[i]["subtitle"] = ic.get("subtitle", cells[i].get("subtitle", ""))
                cells[i]["highlighted"] = ic.get("highlighted", cells[i].get("highlighted", False))
                cells[i]["color"] = ic.get("color", cells[i].get("color", ""))
                changes.append(f"Updated cell visual: {ic.get('title', f'cell_{i}')}")
            else:
                # Add new cell if we have fewer cells than the theme
                cells.append({
                    "icon": ic.get("icon", "📦"),
                    "title": ic.get("title", ""),
                    "subtitle": ic.get("subtitle", ""),
                    "detail": ic.get("detail", ""),
                    "action": ic.get("action", "none"),
                    "highlighted": ic.get("highlighted", False),
                    "customizable": True,
                    "color": ic.get("color", ""),
                })
                changes.append(f"Added cell: {ic.get('title', f'cell_{i}')}")

        local_cfg["dashboard"]["cells"] = cells

    # Apply accessibility visual
    if "accessibility" in theme_data:
        local_cfg["accessibility"] = theme_data["accessibility"]
        changes.append("Applied accessibility settings")

    # Backup and save
    if not dry_run:
        backup_path = config_path + f".bak.{datetime.datetime.now().strftime('%Y%m%d%H%M%S')}"
        if os.path.exists(config_path):
            shutil.copy2(config_path, backup_path)
            changes.append(f"Backup saved: {backup_path}")

        os.makedirs(os.path.dirname(config_path), exist_ok=True)
        with open(config_path, 'w', encoding='utf-8') as f:
            json.dump(local_cfg, f, indent=2, ensure_ascii=False)
        changes.append(f"Config written to {config_path}")
    else:
        changes.append(f"[DRY RUN] Would write config to {config_path}")

    result = {
        "status": "ok" if not dry_run else "dry_run",
        "theme": theme_data.get("theme", "unknown"),
        "changes": changes,
    }
    print(json.dumps(result, indent=2))
    return 0


def main():
    args = sys.argv[1:]
    if not args or args[0] in ("help", "--help", "-h"):
        print("🐝 Bee-Hive OS Config Importer v0.8.36")
        print("")
        print("Usage:")
        print("  bee_config_import.py <path.bhive> [--merge|--overwrite] [--dry-run]")
        print("    Import a full configuration archive")
        print("")
        print("  bee_config_import.py theme <path.bhivetheme> [--dry-run]")
        print("    Import a visual theme file")
        print("")
        print("Options:")
        print("  --merge      Preserve tokens/secrets, overwrite visual settings (default)")
        print("  --overwrite  Replace everything (preserves caldav password)")
        print("  --dry-run    Show what would change without writing")
        return 0

    if args[0] == "theme":
        if len(args) < 2:
            print("Error: theme import requires a path argument")
            return 1
        path = args[1]
        dry_run = "--dry-run" in args
        return import_theme(path, dry_run=dry_run)
    else:
        path = args[0]
        mode = "overwrite" if "--overwrite" in args else "merge"
        dry_run = "--dry-run" in args
        return import_config(path, mode=mode, dry_run=dry_run)


if __name__ == "__main__":
    sys.exit(main())