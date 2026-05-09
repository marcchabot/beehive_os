#!/usr/bin/env python3
"""Bee-Hive OS × cava-bg config merger.

Merges Bee-Hive settings (X-Ray, colors, audio bars) into the existing
cava-bg config.toml, preserving all other cava-bg settings.

Usage: python3 cava-bg-merge.py [--xray|--no-xray] [--intensity 0.8] [--blend Normal] [--dynamic-colors true|false]
"""
import sys
import json

try:
    import tomllib
except ImportError:
    import tomli as tomllib

try:
    import tomli_w
    HAS_TOMLI_W = True
except ImportError:
    HAS_TOMLI_W = False

from pathlib import Path

CONFIG_PATH = Path.home() / ".config" / "cava-bg" / "config.toml"

def main():
    # Parse arguments
    xray = None
    intensity = None
    blend = None
    dynamic_colors = None
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--xray":
            xray = True
        elif args[i] == "--no-xray":
            xray = False
        elif args[i] == "--intensity" and i + 1 < len(args):
            intensity = float(args[i + 1])
            i += 1
        elif args[i] == "--blend" and i + 1 < len(args):
            blend = args[i + 1]
            i += 1
        elif args[i] == "--dynamic-colors" and i + 1 < len(args):
            dynamic_colors = args[i + 1].lower() == "true"
            i += 1
        i += 1

    # Read existing config
    if CONFIG_PATH.exists():
        with open(CONFIG_PATH, "rb") as f:
            cfg = tomllib.load(f)
    else:
        cfg = {}

    # ── Bee-Hive controlled settings ──

    # General
    cfg.setdefault("general", {})
    if dynamic_colors is not None:
        cfg["general"]["dynamic_colors"] = dynamic_colors
    elif xray is not None:
        # X-Ray mode: disable dynamic_colors so bars reveal wallpaper through mask
        cfg["general"]["dynamic_colors"] = not xray
    cfg["general"]["framerate"] = 60
    cfg["general"]["corner_radius"] = 0.0
    cfg["general"]["disable_audio"] = False
    cfg["general"]["background_color"] = {"hex": "#000000", "alpha": 0.0}

    # Display
    cfg.setdefault("display", {})
    cfg["display"]["position"] = "Fill"
    cfg["display"]["anchor_top"] = True
    cfg["display"]["anchor_bottom"] = True
    cfg["display"]["anchor_left"] = True
    cfg["display"]["anchor_right"] = True
    cfg["display"]["layer"] = "Bottom"
    cfg["display"]["opacity"] = 1.0

    # Audio bars — honey gold style
    cfg.setdefault("audio", {})
    cfg["audio"]["bar_count"] = 76
    cfg["audio"]["bar_width"] = 6.0
    cfg["audio"]["bar_spacing"] = 2.0
    cfg["audio"]["gap"] = 0.1
    cfg["audio"]["bar_alpha"] = 0.85
    cfg["audio"]["height_scale"] = 1.0
    cfg["audio"]["smoothing"] = 0.8
    cfg["audio"]["max_bar_height"] = 220.0
    cfg["audio"]["min_bar_height"] = 0.0
    cfg["audio"]["bar_shape"] = "Rectangle"
    cfg["audio"]["bar_color"] = {"hex": "#F5A623", "alpha": 1.0}

    # Colors — honey gradient
    cfg.setdefault("colors", {})
    cfg["colors"]["use_gradient"] = True
    cfg["colors"]["gradient_direction"] = "BottomToTop"
    cfg["colors"]["palette"] = [[0.98, 0.72, 0.11, 1.0], [0.83, 0.59, 0.04, 1.0]]

    # X-Ray
    if xray is not None:
        cfg.setdefault("xray", {})
        cfg["xray"]["enabled"] = xray
        cfg["xray"]["auto_detect"] = True
        cfg["xray"]["use_background_color"] = False

    if intensity is not None:
        cfg.setdefault("xray", {})
        cfg["xray"]["intensity"] = intensity
        cfg.setdefault("xray_mask", {})
        cfg["xray_mask"]["intensity"] = intensity

    if blend is not None:
        cfg.setdefault("xray", {})
        cfg["xray"]["blend_mode"] = blend
        cfg.setdefault("xray_mask", {})
        cfg["xray_mask"]["blend_mode"] = blend

    # X-Ray mask defaults
    cfg.setdefault("xray_mask", {})
    cfg["xray_mask"]["gamma"] = cfg["xray_mask"].get("gamma", 1.2)
    cfg["xray_mask"]["opacity"] = cfg["xray_mask"].get("opacity", 1.0)
    cfg["xray_mask"]["use_background"] = False

    # Wallpaper auto-detect
    cfg.setdefault("wallpaper", {})
    cfg["wallpaper"]["auto_detect_wallpaper"] = True
    cfg["wallpaper"]["sync_interval_seconds"] = 10

    # Performance
    cfg.setdefault("performance", {})
    cfg["performance"]["vsync"] = True
    cfg["performance"]["multi_threaded_decode"] = True

    # Advanced
    cfg.setdefault("advanced", {})
    cfg["advanced"]["verbose_logging"] = False

    # Write back as TOML
    CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)

    if HAS_TOMLI_W:
        with open(CONFIG_PATH, "wb") as f:
            tomli_w.dump(cfg, f)
    else:
        # Fallback: simple TOML writer
        def write_toml(data, f, prefix=""):
            for key, val in data.items():
                if isinstance(val, dict):
                    section = f"{prefix}.{key}" if prefix else key
                    f.write(f"\n[{section}]\n")
                    write_toml(val, f, section)
                elif isinstance(val, list):
                    f.write(f"{key} = {json.dumps(val)}\n")
                elif isinstance(val, bool):
                    f.write(f"{key} = {str(val).lower()}\n")
                elif isinstance(val, (int, float)):
                    f.write(f"{key} = {val}\n")
                elif isinstance(val, str):
                    f.write(f'{key} = "{val}"\n')

        with open(CONFIG_PATH, "w") as f:
            write_toml(cfg, f)

    print("CONFIG_WRITTEN")

if __name__ == "__main__":
    main()