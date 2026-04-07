#!/usr/bin/env python3
"""Bee-Hive OS wallpaper-driven theme extractor/mapper.

Phase 1 (Sprint Framework Universel):
1) Extract dominant colors from wallpaper.
2) Map them to a Bee-Hive-compatible palette (Honey/Noir direction).
3) Generate user_config.auto.json overlay.
"""

from __future__ import annotations

import argparse
import colorsys
import datetime as dt
import json
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

try:
    from PIL import Image
    HAS_PIL = True
except Exception:
    Image = None
    HAS_PIL = False


SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent


@dataclass(frozen=True)
class ColorStat:
    rgb: tuple[int, int, int]
    ratio: float

    @property
    def hex(self) -> str:
        return rgb_to_hex(self.rgb)

    @property
    def hls(self) -> tuple[float, float, float]:
        r, g, b = [c / 255.0 for c in self.rgb]
        return colorsys.rgb_to_hls(r, g, b)

    @property
    def hue(self) -> float:
        return self.hls[0]

    @property
    def lightness(self) -> float:
        return self.hls[1]

    @property
    def saturation(self) -> float:
        return self.hls[2]


def clamp(value: float, low: float, high: float) -> float:
    return max(low, min(high, value))


def rgb_to_hex(rgb: tuple[int, int, int]) -> str:
    return "#{:02X}{:02X}{:02X}".format(*rgb)


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    raw = value.lstrip("#")
    return (int(raw[0:2], 16), int(raw[2:4], 16), int(raw[4:6], 16))


def mix_rgb(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    t = clamp(t, 0.0, 1.0)
    return (
        int(round(a[0] + (b[0] - a[0]) * t)),
        int(round(a[1] + (b[1] - a[1]) * t)),
        int(round(a[2] + (b[2] - a[2]) * t)),
    )


def rel_luminance(rgb: tuple[int, int, int]) -> float:
    def channel(c: int) -> float:
        x = c / 255.0
        if x <= 0.03928:
            return x / 12.92
        return ((x + 0.055) / 1.055) ** 2.4

    r, g, b = (channel(x) for x in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast_ratio(a: tuple[int, int, int], b: tuple[int, int, int]) -> float:
    la = rel_luminance(a)
    lb = rel_luminance(b)
    light = max(la, lb)
    dark = min(la, lb)
    return (light + 0.05) / (dark + 0.05)


def hue_distance(a: float, b: float) -> float:
    delta = abs(a - b)
    return min(delta, 1.0 - delta)


def _extract_palette_pillow(path: Path, max_colors: int = 24, sample_size: int = 256) -> list[ColorStat]:
    with Image.open(path) as img:
        rgb_img = img.convert("RGB")
        rgb_img.thumbnail((sample_size, sample_size))
        quantized = rgb_img.convert("P", palette=Image.ADAPTIVE, colors=max_colors)

        counts: Iterable[tuple[int, int]] = quantized.getcolors(maxcolors=sample_size * sample_size) or []
        palette = quantized.getpalette() or []

    total = sum(count for count, _ in counts) or 1
    rows: list[ColorStat] = []

    for count, idx in sorted(counts, key=lambda it: it[0], reverse=True):
        base = idx * 3
        if base + 2 >= len(palette):
            continue
        rgb = (palette[base], palette[base + 1], palette[base + 2])
        ratio = count / total

        # Skip noise-like colors.
        r, g, b = rgb
        if max(rgb) - min(rgb) < 4:
            continue
        if r < 4 and g < 4 and b < 4:
            continue

        rows.append(ColorStat(rgb=rgb, ratio=ratio))

    return rows[:max_colors]


def _extract_palette_imagemagick(path: Path, max_colors: int = 24, sample_size: int = 256) -> list[ColorStat]:
    cmd = [
        "convert",
        str(path),
        "-resize",
        f"{sample_size}x{sample_size}!",
        "-colors",
        str(max_colors),
        "-depth",
        "8",
        "-format",
        "%c",
        "histogram:info:-",
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True, check=True)
    lines = proc.stdout.splitlines()

    raw_rows: list[tuple[int, tuple[int, int, int]]] = []
    for line in lines:
        match = re.match(r"\s*(\d+):\s*\(([^)]+)\)", line)
        if not match:
            continue
        count = int(match.group(1))
        channels = match.group(2).split(",")
        if len(channels) < 3:
            continue
        try:
            r = int(float(channels[0].strip()))
            g = int(float(channels[1].strip()))
            b = int(float(channels[2].strip()))
        except ValueError:
            continue
        raw_rows.append((count, (r, g, b)))

    total = sum(c for c, _ in raw_rows) or 1
    rows: list[ColorStat] = []
    for count, rgb in sorted(raw_rows, key=lambda it: it[0], reverse=True):
        r, g, b = rgb
        if max(rgb) - min(rgb) < 4:
            continue
        if r < 4 and g < 4 and b < 4:
            continue
        rows.append(ColorStat(rgb=rgb, ratio=count / total))

    return rows[:max_colors]


def extract_palette(path: Path, max_colors: int = 24, sample_size: int = 256) -> list[ColorStat]:
    if HAS_PIL:
        return _extract_palette_pillow(path, max_colors=max_colors, sample_size=sample_size)
    return _extract_palette_imagemagick(path, max_colors=max_colors, sample_size=sample_size)


def choose_mode(colors: list[ColorStat], forced_mode: str | None = None) -> str:
    if forced_mode in {"HoneyDark", "HoneyLight"}:
        return forced_mode

    if not colors:
        return "HoneyDark"

    avg_lum = sum(rel_luminance(c.rgb) * c.ratio for c in colors)
    avg_lightness = sum(c.lightness * c.ratio for c in colors)
    blended = (avg_lum * 0.65) + (avg_lightness * 0.35)
    dominant_lightness = pick_dominant(colors).lightness

    if blended >= 0.50:
        return "HoneyLight"
    if blended <= 0.40:
        return "HoneyDark"
    return "HoneyLight" if dominant_lightness >= 0.52 else "HoneyDark"


def pick_dominant(colors: list[ColorStat]) -> ColorStat:
    return colors[0] if colors else ColorStat((255, 184, 28), 1.0)


def pick_accent_source(colors: list[ColorStat]) -> ColorStat:
    # Option 1: Use the dominant color (top 1) as accent source for faithful wallpaper reflection.
    return pick_dominant(colors)


def normalize_accent(source: ColorStat, mode: str) -> tuple[int, int, int]:
    # Preserve the original hue from the wallpaper for true fidelity.
    # Only adjust saturation and lightness to meet Bee-Hive contrast/readability standards.
    h, l, s = source.hls

    if mode == "HoneyDark":
        s = clamp(max(s, 0.55), 0.55, 0.95)
        l = clamp(0.52 + (l - 0.5) * 0.35, 0.48, 0.66)
    else:
        s = clamp(max(s, 0.50), 0.50, 0.90)
        l = clamp(0.28 + (l - 0.5) * 0.20, 0.22, 0.38)

    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return (int(round(r * 255)), int(round(g * 255)), int(round(b * 255)))


def choose_text_on(bg: tuple[int, int, int]) -> tuple[int, int, int]:
    white = (255, 255, 255)
    black = (26, 26, 26)
    return white if contrast_ratio(bg, white) >= contrast_ratio(bg, black) else black


def to_rgba_string(rgb: tuple[int, int, int], alpha: float) -> str:
    return f"rgba({rgb[0]}, {rgb[1]}, {rgb[2]}, {alpha:.2f})"


def build_palette(colors: list[ColorStat], forced_mode: str | None = None) -> dict:
    mode = choose_mode(colors, forced_mode=forced_mode)
    dominant = pick_dominant(colors).rgb
    accent_source = pick_accent_source(colors)
    accent = normalize_accent(accent_source, mode)

    if mode == "HoneyDark":
        base_bg = hex_to_rgb("#0D0D0D")
        base_secondary = hex_to_rgb("#1A1A1A")
        bg = mix_rgb(base_bg, dominant, 0.14)
        secondary = mix_rgb(base_secondary, dominant, 0.10)
        text_primary = choose_text_on(bg)
        text_secondary = mix_rgb(text_primary, bg, 0.58)
        separator = mix_rgb(accent, bg, 0.72)
        backdrop = mix_rgb(bg, (0, 0, 0), 0.22)
        bar_bg_alpha = 0.92
        glass_bg_alpha = 0.66
    else:
        base_bg = hex_to_rgb("#F5F0E8")
        base_secondary = hex_to_rgb("#EBE2D3")
        bright_dominant = mix_rgb(dominant, (255, 255, 255), 0.45)
        bg = mix_rgb(base_bg, bright_dominant, 0.22)
        secondary = mix_rgb(base_secondary, bright_dominant, 0.16)
        text_primary = choose_text_on(bg)
        text_secondary = mix_rgb(text_primary, bg, 0.42)
        separator = mix_rgb(accent, bg, 0.78)
        backdrop = mix_rgb(bg, (255, 255, 255), 0.06)
        bar_bg_alpha = 0.96
        glass_bg_alpha = 0.93

    return {
        "mode": mode,
        "bg": rgb_to_hex(bg),
        "accent": rgb_to_hex(accent),
        "secondary": rgb_to_hex(secondary),
        "textPrimary": rgb_to_hex(text_primary),
        "textSecondary": rgb_to_hex(text_secondary),
        "separator": rgb_to_hex(separator),
        "barBg": to_rgba_string(bg, bar_bg_alpha),
        "glassBg": to_rgba_string(secondary, glass_bg_alpha),
        "glassBorder": to_rgba_string(accent, 0.28 if mode == "HoneyDark" else 0.46),
        "backdropBg": to_rgba_string(backdrop, 0.90 if mode == "HoneyDark" else 0.92),
        "auraAlpha": 0.60 if mode == "HoneyDark" else 0.35,
        "analysis": {
            "dominant": rgb_to_hex(dominant),
            "accent_source": accent_source.hex,
            "average_luminance": round(sum(rel_luminance(c.rgb) * c.ratio for c in colors), 4) if colors else 0.0,
            "top_colors": [
                {"hex": c.hex, "ratio": round(c.ratio, 4)}
                for c in colors[:8]
            ],
        },
    }


def build_overlay(wallpaper_path: Path, palette: dict, mode_arg: str) -> dict:
    mode = palette["mode"]
    now = dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()

    return {
        "theme": mode,
        "auto_theme": {
            "enabled": True,
            "engine": "bee_theme_auto.py@0.2.0",
            "generated_at": now,
            "source_wallpaper": str(wallpaper_path),
            "palette": {
                key: value
                for key, value in palette.items()
                if key != "analysis" and key != "mode"
            },
            "analysis": palette["analysis"],
            "mapping_notes": {
                "honey_axis_hue": 42,
                "mode_logic": (
                    "forced via --mode (HoneyDark|HoneyLight)"
                    if mode_arg in {"HoneyDark", "HoneyLight"}
                    else "auto mode uses blended luminance/lightness with neutral band disambiguation"
                ),
                "brand_constraint": "accent hue is pulled toward honey to preserve Bee-Hive identity",
            },
        },
    }


def resolve_default_wallpaper() -> Path:
    candidates = [
        PROJECT_ROOT / "assets" / "wallpaper.png",
        PROJECT_ROOT / "wallpapers" / "wallpaper.png",
        PROJECT_ROOT / "assets" / "wallpaper_dark_bee.png",
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    raise FileNotFoundError("No default wallpaper found in assets/ or wallpapers/.")


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate Bee-Hive auto theme overlay from wallpaper")
    parser.add_argument(
        "--wallpaper",
        type=Path,
        default=None,
        help="Path to wallpaper file (default: auto-detect in assets/wallpapers)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=PROJECT_ROOT / "user_config.auto.json",
        help="Output overlay JSON path",
    )
    parser.add_argument("--max-colors", type=int, default=24, help="Color buckets for extraction")
    parser.add_argument(
        "--mode",
        choices=["auto", "HoneyDark", "HoneyLight"],
        default="auto",
        help="Theme mode strategy: auto-detect or force HoneyDark/HoneyLight",
    )
    args = parser.parse_args()

    wallpaper = args.wallpaper.resolve() if args.wallpaper else resolve_default_wallpaper().resolve()
    if not wallpaper.exists():
        raise FileNotFoundError(f"Wallpaper not found: {wallpaper}")

    colors = extract_palette(wallpaper, max_colors=max(6, args.max_colors))
    forced_mode = None if args.mode == "auto" else args.mode
    palette = build_palette(colors, forced_mode=forced_mode)
    overlay = build_overlay(wallpaper, palette, args.mode)

    output = args.output.resolve() if not args.output.is_absolute() else args.output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(overlay, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")

    print("🐝 Bee-Hive auto theme generated")
    print(f"Wallpaper: {wallpaper}")
    print(f"Mode: {overlay['theme']}")
    print(f"Accent: {overlay['auto_theme']['palette']['accent']}")
    print(f"Output: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
