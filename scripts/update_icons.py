#!/usr/bin/env python3
"""
Bee-Hive OS Desktop Icon Scanner
Automatically maps window classes to icons from .desktop files

Usage:
    python3 update_icons.py        # Scan and update config
    python3 update_icons.py --test # Dry run, show what would be added
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
CACHE_FILE = BEEHIVE_DIR / ".cache" / "icon_cache.json"

# Known window class mappings (Hyprland -> Desktop Entry)
# Some apps don't use StartupWMClass, so we map them manually
KNOWN_MAPPINGS = {
    "kitty": "kitty",           # Kitty terminal
    "zen": "zen-browser",       # Zen browser
    "firefox": "firefox",       # Firefox
    "code": "code",             # VS Code
    "chromium": "chromium",     # Chromium
    "thunderbird": "thunderbird", # Thunderbird
    "nautilus": "org.gnome.Nautilus", # GNOME Files
    "gedit": "org.gnome.gedit", # GNOME Text Editor
    "gnome-terminal": "org.gnome.Terminal", # GNOME Terminal
    "konsole": "org.kde.konsole", # KDE Konsole
    "dolphin": "org.kde.dolphin", # KDE Dolphin
    "qterminal": "org.qterminal.qterminal", # QTerminal
}

def parse_desktop_file(filepath):
    """
    Parse a .desktop file and extract relevant information.
    Returns dict with keys: Name, Icon, Exec, StartupWMClass
    """
    result = {
        "Name": "",
        "Icon": "",
        "Exec": "",
        "StartupWMClass": ""
    }
    
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
        
        in_desktop_entry = False
        
        for line in lines:
            line = line.strip()
            
            # Skip comments and empty lines
            if not line or line.startswith("#"):
                continue
            
            # Start of Desktop Entry section
            if line == "[Desktop Entry]":
                in_desktop_entry = True
                continue
            
            # Other sections - we only care about Desktop Entry
            if line.startswith("[") and line.endswith("]"):
                in_desktop_entry = False
                continue
            
            if in_desktop_entry and "=" in line:
                key, value = line.split("=", 1)
                key = key.strip()
                
                if key in ["Name", "Icon", "Exec", "StartupWMClass"]:
                    result[key] = value.strip()
    
    except Exception as e:
        # Silently skip problematic files
        pass
    
    return result

def find_icon_path(icon_name):
    """
    Resolve icon name to actual file path using gtk-icon-theme
    Falls back to checking common locations
    """
    if not icon_name:
        return ""
    
    # Check if it's already an absolute path
    if os.path.isabs(icon_name) and os.path.exists(icon_name):
        return icon_name
    
    # Try to find icon via gtk-icon-theme (if available)
    try:
        result = subprocess.run(
            ["gtk4-icon-browser", "--list-icons", icon_name],
            capture_output=True,
            text=True,
            timeout=2
        )
        if result.returncode == 0 and result.stdout:
            for line in result.stdout.splitlines():
                if icon_name in line.lower():
                    return line.strip()
    except (subprocess.SubprocessError, FileNotFoundError):
        pass
    
    # Common icon directories to check
    icon_dirs = [
        "/usr/share/icons/hicolor/48x48/apps/",
        "/usr/share/icons/hicolor/32x32/apps/",
        "/usr/share/icons/hicolor/24x24/apps/",
        "/usr/share/icons/hicolor/scalable/apps/",
        "/usr/share/icons/Adwaita/48x48/apps/",
        "/usr/share/icons/Adwaita/32x32/apps/",
        "/usr/share/icons/Adwaita/scalable/apps/",
        "/usr/share/pixmaps/",
    ]
    
    # Check various extensions
    extensions = [".png", ".svg", ".xpm", ""]
    
    for icon_dir in icon_dirs:
        for ext in extensions:
            path = os.path.join(icon_dir, f"{icon_name}{ext}")
            if os.path.exists(path):
                return path
    
    # Check for theme-specific paths
    for size in ["48", "32", "24", "16", "scalable"]:
        for theme in ["hicolor", "Adwaita", "gnome", "breeze"]:
            path = f"/usr/share/icons/{theme}/{size}x{size}/apps/{icon_name}.png"
            if os.path.exists(path):
                return path
    
    return icon_name  # Return the name as fallback

def scan_desktop_files():
    """
    Scan all .desktop files and build mapping of window classes to icons
    """
    icon_mapping = {}
    desktop_entries = {}
    
    print("🔍 Scanning .desktop files...")
    
    for desktop_path in DESKTOP_PATHS:
        if not os.path.isdir(desktop_path):
            continue
        
        print(f"  📁 {desktop_path}")
        
        for filename in os.listdir(desktop_path):
            if not filename.endswith(".desktop"):
                continue
            
            filepath = os.path.join(desktop_path, filename)
            info = parse_desktop_file(filepath)
            
            if not info["Name"] or not info["Icon"]:
                continue
            
            # Determine the window class key
            window_class = ""
            
            # Priority 1: StartupWMClass
            if info["StartupWMClass"]:
                window_class = info["StartupWMClass"].lower()
            
            # Priority 2: Known mapping
            if not window_class:
                app_name = os.path.splitext(filename)[0].lower()
                if app_name in KNOWN_MAPPINGS:
                    window_class = KNOWN_MAPPINGS[app_name].lower()
            
            # Priority 3: Extract from Exec
            if not window_class and info["Exec"]:
                # Get basename from Exec command
                exec_cmd = info["Exec"].split()[0] if info["Exec"] else ""
                if exec_cmd:
                    window_class = os.path.basename(exec_cmd).lower()
            
            # Priority 4: Use filename without .desktop
            if not window_class:
                window_class = os.path.splitext(filename)[0].lower()
            
            # Resolve icon path
            icon_path = find_icon_path(info["Icon"])
            
            if window_class and icon_path:
                desktop_entries[window_class] = {
                    "name": info["Name"],
                    "icon": icon_path,
                    "desktop_file": filename
                }
    
    print(f"✅ Found {len(desktop_entries)} desktop entries")
    return desktop_entries

def get_current_window_classes():
    """
    Get list of window classes currently known to the system
    by checking user_config.json and running get_window_icon.py
    """
    window_classes = set()
    
    # Check existing config
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE, 'r') as f:
                config = json.load(f)
            
            if "window_icons" in config:
                window_classes.update(config["window_icons"].keys())
        except Exception:
            pass
    
    # Try to get active window class
    try:
        result = subprocess.run(
            ["python3", str(BEEHIVE_DIR / "scripts" / "get_window_icon.py")],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0 and result.stdout.strip():
            window_classes.add(result.stdout.strip().lower())
    except Exception:
        pass
    
    return list(window_classes)

def update_user_config(desktop_entries, dry_run=False):
    """
    Update user_config.json with new icon mappings
    """
    if not CONFIG_FILE.exists():
        print(f"❌ Config file not found: {CONFIG_FILE}")
        return
    
    try:
        with open(CONFIG_FILE, 'r') as f:
            config = json.load(f)
        
        # Ensure window_icons section exists
        if "window_icons" not in config:
            config["window_icons"] = {}
        
        existing_mappings = config["window_icons"]
        added_count = 0
        updated_count = 0
        
        # Update mappings
        for window_class, entry in desktop_entries.items():
            icon_path = entry["icon"]
            
            # Skip if it's an emoji or custom mapping (starts with :)
            if window_class in existing_mappings and existing_mappings[window_class].startswith(":"):
                continue
            
            # Add or update mapping
            if window_class not in existing_mappings:
                if not dry_run:
                    config["window_icons"][window_class] = icon_path
                print(f"  ➕ Add: {window_class} → {icon_path}")
                added_count += 1
            elif existing_mappings[window_class] != icon_path:
                if not dry_run:
                    config["window_icons"][window_class] = icon_path
                print(f"  🔄 Update: {window_class} → {icon_path}")
                updated_count += 1
        
        # Save config
        if not dry_run:
            # Create backup
            backup_file = CONFIG_FILE.with_suffix(".json.bak")
            import shutil
            shutil.copy2(CONFIG_FILE, backup_file)
            
            # Write updated config
            with open(CONFIG_FILE, 'w') as f:
                json.dump(config, f, indent=2)
            
            print(f"\n✅ Config updated: {added_count} added, {updated_count} updated")
            print(f"   Backup saved to: {backup_file}")
        else:
            print(f"\n📋 Dry run: Would add {added_count}, update {updated_count}")
        
        # Save cache
        if not dry_run:
            CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
            with open(CACHE_FILE, 'w') as f:
                json.dump({
                    "timestamp": os.path.getmtime(CONFIG_FILE),
                    "mappings": config["window_icons"]
                }, f, indent=2)
        
    except Exception as e:
        print(f"❌ Error updating config: {e}")

def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Update Bee-Hive OS icon mappings from .desktop files")
    parser.add_argument("--test", "-t", action="store_true", help="Dry run, don't modify config")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    args = parser.parse_args()
    
    print("🐝 Bee-Hive OS Desktop Icon Scanner")
    print("=" * 50)
    
    # Scan desktop files
    desktop_entries = scan_desktop_files()
    
    if not desktop_entries:
        print("❌ No desktop entries found")
        return 1
    
    # Get current window classes
    window_classes = get_current_window_classes()
    if window_classes:
        print(f"\n📊 Current window classes: {len(window_classes)}")
        if args.verbose:
            for wc in sorted(window_classes):
                print(f"  • {wc}")
    
    # Filter entries to only include relevant window classes
    relevant_entries = {}
    for window_class, entry in desktop_entries.items():
        # Include if it matches a known window class or is in KNOWN_MAPPINGS
        if (window_class in window_classes or 
            any(wc.startswith(window_class) or window_class.startswith(wc) 
                for wc in window_classes) or
            window_class in KNOWN_MAPPINGS.values()):
            relevant_entries[window_class] = entry
    
    print(f"\n🎯 Relevant entries for current system: {len(relevant_entries)}")
    
    # Update config
    update_user_config(relevant_entries, dry_run=args.test)
    
    print("\n✅ Scan complete!")
    if args.test:
        print("   Run without --test to apply changes")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())