#!/usr/bin/env python3
"""
bee_config_export.py — Bee-Hive OS Config Exporter 🐝💾
v0.8.36 — Export user configuration + data to a .bhive archive

Usage:
  python3 bee_config_export.py [--output PATH] [--include-wallpapers]

Outputs a .bhive file (ZIP archive containing JSON manifest + config data)
"""

import json
import os
import sys
import zipfile
import hashlib
import datetime
import shutil

# ─── Config paths ──────────────────────────────────────────────────────────────
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
HOME_DIR = os.path.expanduser("~")

# Config can be in project dir (dev) or ~/.config/bee-hive-os (installed)
CONFIG_PATHS = [
    os.path.join(HOME_DIR, ".config", "bee-hive-os", "user_config.json"),
    os.path.join(PROJECT_DIR, "user_config.json"),
]

DATA_DIRS = [
    os.path.join(HOME_DIR, ".config", "bee-hive-os", "data"),
    os.path.join(PROJECT_DIR, "data"),
]

WALLPAPER_DIRS = [
    os.path.join(HOME_DIR, ".config", "bee-hive-os", "wallpapers"),
    os.path.join(PROJECT_DIR, "wallpapers"),
    os.path.join(HOME_DIR, "Pictures", "Wallpapers"),
]

PROFILES_PATHS = [
    os.path.join(HOME_DIR, ".config", "bee-hive-os", "profiles.json"),
    os.path.join(PROJECT_DIR, "profiles.json"),
]


def find_config():
    """Find the user_config.json file."""
    for path in CONFIG_PATHS:
        if os.path.exists(path):
            return path
    return None


def find_data_dir():
    """Find the data directory."""
    for path in DATA_DIRS:
        if os.path.isdir(path):
            return path
    return None


def find_profiles():
    """Find the profiles.json file."""
    for path in PROFILES_PATHS:
        if os.path.exists(path):
            return path
    return None


def find_wallpapers():
    """Find all wallpaper files."""
    wallpapers = []
    seen_names = set()
    for wdir in WALLPAPER_DIRS:
        if os.path.isdir(wdir):
            for f in os.listdir(wdir):
                fpath = os.path.join(wdir, f)
                if os.path.isfile(fpath) and f.lower().endswith(('.png', '.jpg', '.jpeg', '.webp', '.gif')):
                    if f not in seen_names:
                        wallpapers.append(fpath)
                        seen_names.add(f)
    return wallpapers


def compute_hash(filepath):
    """Compute SHA256 hash of a file."""
    h = hashlib.sha256()
    try:
        with open(filepath, 'rb') as f:
            for chunk in iter(lambda: f.read(8192), b''):
                h.update(chunk)
        return h.hexdigest()
    except Exception:
        return ""


def export_config(output_path=None, include_wallpapers=False):
    """Export configuration to a .bhive file."""
    config_path = find_config()
    if not config_path:
        result = {"status": "error", "error": "No user_config.json found"}
        print(json.dumps(result))
        return 1

    # Load config
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config_data = json.load(f)
    except Exception as e:
        result = {"status": "error", "error": f"Failed to read config: {e}"}
        print(json.dumps(result))
        return 1

    # Default output path
    if not output_path:
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        export_dir = os.path.join(HOME_DIR, "Documents")
        if not os.path.isdir(export_dir):
            export_dir = HOME_DIR
        output_path = os.path.join(export_dir, f"beehive_backup_{timestamp}.bhive")

    # Create manifest
    manifest = {
        "format": "bhive",
        "version": "1.0",
        "bhive_os_version": "0.8.36",
        "exported_at": datetime.datetime.now().isoformat(),
        "exported_by": "bee_config_export.py",
        "config_hash": compute_hash(config_path),
        "files": {},
        "includes_wallpapers": include_wallpapers,
        "theme_only": False,
    }

    # Build archive
    try:
        with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zf:
            # 1. Manifest
            zf.writestr("manifest.json", json.dumps(manifest, indent=2))

            # 2. user_config.json
            zf.write(config_path, "config/user_config.json")
            manifest["files"]["config/user_config.json"] = compute_hash(config_path)

            # 3. Data files (quick_notes, events, etc.)
            data_dir = find_data_dir()
            if data_dir:
                for fname in os.listdir(data_dir):
                    fpath = os.path.join(data_dir, fname)
                    if os.path.isfile(fpath):
                        arcname = f"data/{fname}"
                        zf.write(fpath, arcname)
                        manifest["files"][arcname] = compute_hash(fpath)

            # 4. Profiles
            profiles_path = find_profiles()
            if profiles_path:
                zf.write(profiles_path, "config/profiles.json")
                manifest["files"]["config/profiles.json"] = compute_hash(profiles_path)

            # 5. Auto theme overlay (if exists)
            auto_paths = [
                os.path.join(HOME_DIR, ".config", "bee-hive-os", "user_config.auto.json"),
                os.path.join(PROJECT_DIR, "user_config.auto.json"),
            ]
            for ap in auto_paths:
                if os.path.exists(ap):
                    zf.write(ap, "config/user_config.auto.json")
                    manifest["files"]["config/user_config.auto.json"] = compute_hash(ap)
                    break

            # 6. Wallpapers (optional)
            if include_wallpapers:
                wallpapers = find_wallpapers()
                wp_count = 0
                for wp in wallpapers[:20]:  # Limit to 20 wallpapers
                    fname = os.path.basename(wp)
                    arcname = f"wallpapers/{fname}"
                    try:
                        zf.write(wp, arcname)
                        manifest["files"][arcname] = compute_hash(wp)
                        wp_count += 1
                    except Exception:
                        pass  # Skip unreadable files
                manifest["wallpaper_count"] = wp_count

            # Update manifest in archive
            zf.writestr("manifest.json", json.dumps(manifest, indent=2))

    except Exception as e:
        result = {"status": "error", "error": f"Failed to create archive: {e}"}
        print(json.dumps(result))
        return 1

    file_size = os.path.getsize(output_path)
    result = {
        "status": "ok",
        "path": output_path,
        "size_bytes": file_size,
        "size_human": f"{file_size / 1024:.1f} KB",
        "files_count": len(manifest["files"]),
        "includes_wallpapers": include_wallpapers,
        "exported_at": manifest["exported_at"],
    }
    print(json.dumps(result, indent=2))
    return 0


def export_theme(output_path=None):
    """Export only visual/theme properties to a .bhivetheme file (shareable)."""
    config_path = find_config()
    if not config_path:
        result = {"status": "error", "error": "No user_config.json found"}
        print(json.dumps(result))
        return 1

    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config_data = json.load(f)
    except Exception as e:
        result = {"status": "error", "error": f"Failed to read config: {e}"}
        print(json.dumps(result))
        return 1

    # Extract only visual/theme properties
    theme_data = {
        "format": "bhivetheme",
        "version": "1.0",
        "exported_at": datetime.datetime.now().isoformat(),
        "exported_by": "bee_config_export.py",
        "theme": config_data.get("theme", "HoneyDark"),
        "visual": {},
        "wallpaper": "",
        "palette": {},
    }

    # Visual settings
    visual_keys = [
        "transitions", "nectar_sync", "color_therapy_enabled",
        "auto_theme_mode", "corners_mode", "motion_mode", "vibe_mode",
        "vibe_backend", "vibe_xray", "vibe_xray_dir", "vibe_xray_intensity",
        "vibe_xray_blend", "analog_clock", "stealth_mode", "focus_mode",
        "sound",
    ]
    for key in visual_keys:
        if key in config_data:
            theme_data["visual"][key] = config_data[key]

    # Wallpaper
    if "dashboard" in config_data and "cells" in config_data.get("dashboard", {}):
        # Check cell wallpaper references
        pass
    wallpaper = config_data.get("current_wallpaper", "")
    theme_data["wallpaper"] = wallpaper

    # Nectar palette
    if "auto_theme" in config_data and "palette" in config_data.get("auto_theme", {}):
        theme_data["palette"] = config_data["auto_theme"]["palette"]

    # Dashboard cells (visual only — icons, titles, colors, highlighted)
    if "dashboard" in config_data and "cells" in config_data.get("dashboard", {}):
        theme_data["cells_visual"] = []
        for cell in config_data["dashboard"]["cells"]:
            theme_data["cells_visual"].append({
                "icon": cell.get("icon", ""),
                "title": cell.get("title", ""),
                "subtitle": cell.get("subtitle", ""),
                "highlighted": cell.get("highlighted", False),
                "color": cell.get("color", ""),
            })

    # Accessibility visual
    if "accessibility" in config_data:
        theme_data["accessibility"] = config_data["accessibility"]

    # Default output path
    if not output_path:
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        theme_name = config_data.get("theme", "HoneyDark")
        safe_name = theme_name.replace(" ", "_").lower()
        export_dir = os.path.join(HOME_DIR, "Documents")
        if not os.path.isdir(export_dir):
            export_dir = HOME_DIR
        output_path = os.path.join(export_dir, f"beehive_theme_{safe_name}_{timestamp}.bhivetheme")

    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(theme_data, f, indent=2, ensure_ascii=False)
    except Exception as e:
        result = {"status": "error", "error": f"Failed to write theme: {e}"}
        print(json.dumps(result))
        return 1

    file_size = os.path.getsize(output_path)
    result = {
        "status": "ok",
        "path": output_path,
        "size_bytes": file_size,
        "size_human": f"{file_size / 1024:.1f} KB",
        "theme": theme_data["theme"],
        "exported_at": theme_data["exported_at"],
    }
    print(json.dumps(result, indent=2))
    return 0


def main():
    args = sys.argv[1:]
    command = args[0] if args else "export"

    if command == "export":
        output = None
        include_wp = "--include-wallpapers" in args
        # Check for --output flag
        for i, arg in enumerate(args):
            if arg == "--output" and i + 1 < len(args):
                output = args[i + 1]
        return export_config(output_path=output, include_wallpapers=include_wp)

    elif command == "theme":
        output = None
        for i, arg in enumerate(args):
            if arg == "--output" and i + 1 < len(args):
                output = args[i + 1]
        return export_theme(output_path=output)

    elif command == "help" or command == "--help" or command == "-h":
        print("🐝 Bee-Hive OS Config Exporter v0.8.36")
        print("")
        print("Usage:")
        print("  bee_config_export.py export [--output PATH] [--include-wallpapers]")
        print("    Export full configuration to a .bhive archive")
        print("")
        print("  bee_config_export.py theme [--output PATH]")
        print("    Export visual theme only to a .bhivetheme file (shareable)")
        print("")
        print("The .bhive format is a ZIP archive containing:")
        print("  - manifest.json     — Archive metadata")
        print("  - config/            — Configuration files")
        print("  - data/              — User data (notes, events)")
        print("  - wallpapers/        — Custom wallpapers (if included)")
        print("")
        print("The .bhivetheme format is a JSON file with visual properties only:")
        print("  - Theme mode, colors, palette")
        print("  - Visual settings (transitions, vibe, motion, etc.)")
        print("  - Cell layout (icons, titles, colors)")
        return 0

    else:
        print(f"Unknown command: {command}. Use 'help' for usage.")
        return 1


if __name__ == "__main__":
    sys.exit(main())