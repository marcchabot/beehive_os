#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════
# Bee-Hive OS — Theme Harmony Engine 🐝🍯
# v1.2.0 : Nectar Sync — Thunar & GTK Deep Integration
# ═══════════════════════════════════════════════════════════════
import json
import os
import subprocess

# --- Configuration paths ---
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_DIR = os.path.join(BASE_DIR, "config")

# --- Bee-Hive Honey Palette ---
PALETTE = {
    "bg": "#0D0D0D",
    "accent": "#FFB81C",
    "secondary": "#1A1A1A",
    "text": "#FFFFFF",
    "grey": "#AAAAAA"
}

def sync_gtk():
    # CSS pour GTK 3 et 4 (Thunar utilise GTK 3)
    css = f"""
/* 🍯 Bee-Hive OS — Thunar & GTK Harmony */

/* Couleurs de base */
@define-color accent_color {PALETTE['accent']};
@define-color accent_bg_color {PALETTE['accent']};
@define-color accent_fg_color {PALETTE['bg']};
@define-color selected_bg_color {PALETTE['accent']};
@define-color selected_fg_color {PALETTE['bg']};

/* Thunar: Selection and Focus */
.view:selected, .view:selected:focus {{
    background-color: {PALETTE['accent']};
    color: {PALETTE['bg']};
}}

/* Thunar: Sidebar (Sidepane) */
.sidebar row:selected {{
    background-color: {PALETTE['accent']};
    color: {PALETTE['bg']};
}}

/* Thunar: Path bar (Pathbar) */
.path-bar button:checked {{
    background-color: {PALETTE['accent']};
    color: {PALETTE['bg']};
    border-color: {PALETTE['accent']};
}}

/* Menus et Boutons */
button:checked {{ background-color: {PALETTE['accent']}; color: {PALETTE['bg']}; }}
selection {{ background-color: {PALETTE['accent']}; color: {PALETTE['bg']}; }}
"""
    
    for path in ["~/.config/gtk-3.0/gtk.css", "~/.config/gtk-4.0/gtk.css"]:
        full_path = os.path.expanduser(path)
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        with open(full_path, 'w') as f:
            f.write(css)
    print("✅ GTK 3/4: Thunar is now harmonized in Honey Yellow.")

def sync_icons():
    # If Papirus is installed, change folder color
    print("🐝 Attempting to change Papirus icon color...")
    
    # Try 'amber' (more honey-like) first, then 'yellow'
    # Explicitly target Papirus-Dark as it's the active theme
    themes = ["Papirus-Dark", "Papirus"]
    colors = ["amber", "yellow"]
    
    success = False
    for theme in themes:
        for color in colors:
            try:
                # Command: papirus-folders -c <color> -t <theme>
                subprocess.run(["papirus-folders", "-c", color, "-t", theme], 
                             check=True, capture_output=True)
                print(f"✅ Icons: Folders {theme} changed to {color.upper()}! 🍯")
                success = True
                break
            except subprocess.CalledProcessError:
                continue
        if success: break
    
    if not success:
        print("⚠️ Cannot change color. Check if 'Papirus-Icon-Theme' is installed.")

def main():
    print("🐝 Bee-Hive sync for Thunar...")
    sync_gtk()
    sync_icons()
    print("\n🍯 Thunar is now ready! Relaunch Thunar to see the result.")

if __name__ == "__main__":
    main()
