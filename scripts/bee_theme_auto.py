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
import urllib.request
import urllib.error
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
    # Check for signature BeeHive wallpapers first – use predefined palette
    signature_wallpapers = {
        "wallpaper_dark_bee.png": "HoneyDark",
        "wallpaper_light_bee.png": "HoneyLight",
        "wallpaper.png": "HoneyDark",
        "wallpaper_light.png": "HoneyLight",
    }

    if path.name in signature_wallpapers:
        # Return empty list to signal signature wallpaper – palette will be loaded separately
        return []

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


def build_palette(colors: list[ColorStat], forced_mode: str | None = None, signature_mode: str | None = None, weather_condition: str | None = None, time_aware_hour: int | None = None) -> dict:
    # If this is a signature wallpaper, use the predefined palette from theme.json
    if signature_mode:
        # Load predefined palette from themes/theme.json
        theme_file = PROJECT_ROOT / "themes" / "theme.json"
        if theme_file.exists():
            try:
                theme_data = json.loads(theme_file.read_text(encoding="utf-8"))
                palettes = theme_data.get("palettes", {})
                if signature_mode in palettes:
                    p = palettes[signature_mode]
                    return {
                        "mode": signature_mode,
                        "bg": p["background"].lstrip('#'),
                        "accent": p["accent"].lstrip('#'),
                        "secondary": p["secondary"].lstrip('#'),
                        "textPrimary": p["text_primary"].lstrip('#'),
                        "textSecondary": p["text_secondary"].lstrip('#'),
                        "separator": mix_rgb(hex_to_rgb(p["accent"].lstrip('#')), hex_to_rgb(p["background"].lstrip('#')), 0.72 if signature_mode == "HoneyDark" else 0.78),
                        "barBg": to_rgba_string(hex_to_rgb(p["background"].lstrip('#')), 0.92 if signature_mode == "HoneyDark" else 0.96),
                        "glassBg": to_rgba_string(hex_to_rgb(p["secondary"].lstrip('#')), 0.66 if signature_mode == "HoneyDark" else 0.93),
                        "glassBorder": to_rgba_string(hex_to_rgb(p["accent"].lstrip('#')), 0.28 if signature_mode == "HoneyDark" else 0.46),
                        "backdropBg": to_rgba_string(hex_to_rgb(p["background"].lstrip('#')), 0.90 if signature_mode == "HoneyDark" else 0.92),
                        "auraAlpha": 0.60 if signature_mode == "HoneyDark" else 0.35,
                        "analysis": {
                            "dominant": p["accent"].lstrip('#'),
                            "accent_source": p["accent"].lstrip('#'),
                            "average_luminance": 0.0,
                            "top_colors": [],
                            "signature": True
                        },
                    }
            except Exception:
                pass  # Fall back to auto generation if theme file unreadable

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

    # ─── Weather-aware palette shift 🐝🌦️ v0.8.39 ────────────────
    weather_suggestion = ""
    if weather_condition and weather_condition in WEATHER_TINTS:
        tint = WEATHER_TINTS[weather_condition]
        mode_key = "dark" if mode == "HoneyDark" else "light"
        shifts = tint.get(mode_key, {})
        intensity = _time_intensity(time_aware_hour)

        accent_shift = shifts.get("accent_shift", (0, 0, 0))
        bg_shift = shifts.get("bg_shift", (0, 0, 0))
        secondary_shift = shifts.get("secondary_shift", (0, 0, 0))
        weather_suggestion = shifts.get("label_en", "")

        if accent_shift != (0, 0, 0):
            accent = _apply_weather_shift(accent, accent_shift, intensity)
            bg = _apply_weather_shift(bg, bg_shift, intensity)
            secondary = _apply_weather_shift(secondary, secondary_shift, intensity)
            separator = mix_rgb(accent, bg, 0.72 if mode == "HoneyDark" else 0.78)
            text_secondary = mix_rgb(text_primary, bg, 0.58 if mode == "HoneyDark" else 0.42)
            print(f"Weather-aware: applied {weather_condition} palette shift (intensity={intensity:.2f})")

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


# ─── Weather-Aware Palette Logic 🐝🌦️ v0.8.39 ────────────────────

def fetch_weather(city: str = "Blainville") -> dict | None:
    """Fetch weather data from wttr.in API.

    Returns a dict with keys: temperature, feels_like, weather_code,
    description, humidity, wind_speed, city or None on failure.
    """
    try:
        url = f"https://wttr.in/{city}?format=j1"
        req = urllib.request.Request(url, headers={"User-Agent": "bee-hive-os/0.8.39"})
        with urllib.request.urlopen(req, timeout=8) as resp:
            data = json.loads(resp.read().decode("utf-8"))

        current = data.get("current_condition", [{}])[0]
        weather_code = int(current.get("weatherCode", "0") or "0")
        # wttr.in uses meteo codes; also check description for thunderstorm
        desc_list = current.get("weatherDesc", [{}])
        desc = desc_list[0].get("value", "") if desc_list else ""

        result = {
            "temperature": float(current.get("temp_C", "0") or "0"),
            "feels_like": float(current.get("FeelsLikeC", "0") or "0"),
            "weather_code": weather_code,
            "description": desc,
            "humidity": int(current.get("humidity", "0") or "0"),
            "wind_speed": float(current.get("windspeedKmph", "0") or "0"),
            "city": city,
        }

        # Detect thunderstorm from description (wttr.in codes can be unreliable)
        desc_lower = desc.lower()
        if any(w in desc_lower for w in ["thunder", "storm", "lightning", "orage", "tonnerre"]):
            result["_is_storm"] = True

        return result
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, KeyError, IndexError) as e:
        print(f"Weather fetch error: {e}")
        return None


def classify_weather(data: dict) -> str:
    """Classify weather data into a palette condition.

    Returns one of: 'sunny', 'cloudy', 'rainy', 'snowy', 'stormy', 'clear'.
    """
    if data is None:
        return "clear"

    # Check storm first (from description detection)
    if data.get("_is_storm"):
        return "stormy"

    code = data.get("weather_code", 0)
    desc = data.get("description", "").lower()

    # WMO-inspired classification from wttr.in weatherCode
    # Clear / Sunny
    if code in (113, 0, 1) or "sunny" in desc or "clear" in desc or "dégagé" in desc:
        return "sunny"

    # Overcast / Cloudy
    if code in (116, 119, 122) or "cloud" in desc or "overcast" in desc or "nuageux" in desc:
        return "cloudy"

    # Fog / Mist
    if code in (143, 248, 260) or "fog" in desc or "mist" in desc or "brouillard" in desc:
        return "cloudy"

    # Rain
    if code in (176, 200, 263, 266, 293, 296, 299, 302, 305, 308, 311, 314, 317, 353, 356, 359, 386, 389, 392, 395) or \
       "rain" in desc or "shower" in desc or "pluie" in desc or "averse" in desc:
        return "rainy"

    # Drizzle → rainy
    if code in (179, 182, 185, 227, 230, 320, 323, 326, 329, 332, 335, 338, 350) or \
       "drizzle" in desc or "bruine" in desc:
        return "rainy"

    # Snow
    if code in (227, 230, 320, 323, 326, 329, 332, 335, 338, 368, 371, 374, 377, 392, 395) or \
       "snow" in desc or "neige" in desc:
        return "snowy"

    # Thunderstorm
    if code in (200, 386, 389, 392, 395) or \
       "thunder" in desc or "storm" in desc or "orage" in desc:
        return "stormy"

    # Partly cloudy
    if code in (116,) or "partly" in desc or "partiel" in desc:
        return "cloudy"

    # Default fallback
    return "clear"


# ─── Weather Palette Adjustments 🐝🎨 ───────────────────────────

# Named palette tints for weather conditions
WEATHER_TINTS: dict[str, dict] = {
    "sunny": {
        "dark": {
            "accent_shift": (30, 10, -10),    # warmer, more amber
            "bg_shift": (5, 3, -2),            # slightly warmer bg
            "secondary_shift": (8, 5, -3),
            "label_en": "Sunny → Warm Amber Palette",
            "label_fr": "Ensoleillé → Palette Amber Chaud",
        },
        "light": {
            "accent_shift": (25, 8, -8),
            "bg_shift": (8, 5, -3),
            "secondary_shift": (10, 6, -4),
            "label_en": "Sunny → Warm Amber Palette",
            "label_fr": "Ensoleillé → Palette Amber Chaud",
        },
    },
    "cloudy": {
        "dark": {
            "accent_shift": (-15, -5, 20),       # cooler, blue-grey
            "bg_shift": (-2, -1, 5),
            "secondary_shift": (-5, -2, 10),
            "label_en": "Cloudy → Cool Blue-Grey Palette",
            "label_fr": "Nuageux → Palette Bleu-Gris Doux",
        },
        "light": {
            "accent_shift": (-10, -5, 15),
            "bg_shift": (-3, -1, 5),
            "secondary_shift": (-5, -2, 8),
            "label_en": "Cloudy → Cool Blue-Grey Palette",
            "label_fr": "Nuageux → Palette Bleu-Gris Doux",
        },
    },
    "rainy": {
        "dark": {
            "accent_shift": (-20, -10, 30),      # blue-grey, cool
            "bg_shift": (-3, -2, 8),
            "secondary_shift": (-8, -5, 15),
            "label_en": "Rainy → Cool Blue-Grey Palette",
            "label_fr": "Pluvieux → Palette Bleu-Gris Froide",
        },
        "light": {
            "accent_shift": (-15, -8, 25),
            "bg_shift": (-5, -3, 8),
            "secondary_shift": (-6, -3, 12),
            "label_en": "Rainy → Cool Blue-Grey Palette",
            "label_fr": "Pluvieux → Palette Bleu-Gris Froide",
        },
    },
    "snowy": {
        "dark": {
            "accent_shift": (20, 20, 40),         # icy white-blue
            "bg_shift": (8, 8, 15),
            "secondary_shift": (10, 10, 20),
            "label_en": "Snowy → Cold White-Blue Palette",
            "label_fr": "Neigeux → Palette Blanc-Bleu Pâle",
        },
        "light": {
            "accent_shift": (15, 15, 35),
            "bg_shift": (5, 5, 10),
            "secondary_shift": (8, 8, 18),
            "label_en": "Snowy → Cold White-Blue Palette",
            "label_fr": "Neigeux → Palette Blanc-Bleu Pâle",
        },
    },
    "stormy": {
        "dark": {
            "accent_shift": (-25, -15, 40),      # deep dramatic blue-purple
            "bg_shift": (-5, -3, 10),
            "secondary_shift": (-10, -8, 20),
            "label_en": "Stormy → Dark Dramatic Palette",
            "label_fr": "Orageux → Palette Sombre Dramatique",
        },
        "light": {
            "accent_shift": (-20, -12, 35),
            "bg_shift": (-3, -2, 8),
            "secondary_shift": (-8, -5, 15),
            "label_en": "Stormy → Dark Dramatic Palette",
            "label_fr": "Orageux → Palette Sombre Dramatique",
        },
    },
    "clear": {
        "dark": {
            "accent_shift": (0, 0, 0),
            "bg_shift": (0, 0, 0),
            "secondary_shift": (0, 0, 0),
            "label_en": "Clear → Default Palette",
            "label_fr": "Dégagé → Palette par défaut",
        },
        "light": {
            "accent_shift": (0, 0, 0),
            "bg_shift": (0, 0, 0),
            "secondary_shift": (0, 0, 0),
            "label_en": "Clear → Default Palette",
            "label_fr": "Dégagé → Palette par défaut",
        },
    },
}


def _apply_weather_shift(rgb: tuple[int, int, int], shift: tuple[int, int, int], intensity: float = 0.35) -> tuple[int, int, int]:
    """Apply an RGB shift to a color at a given intensity (0-1)."""
    return (
        clamp(int(rgb[0] + shift[0] * intensity), 0, 255),
        clamp(int(rgb[1] + shift[1] * intensity), 0, 255),
        clamp(int(rgb[2] + shift[2] * intensity), 0, 255),
    )


def _time_intensity(hour: int | None) -> float:
    """Compute weather adjustment intensity based on time of day.

    Night = more dramatic shift (0.5), midday = subtle (0.25).
    This ensures night + rain = very dark cool palette, not washed out.
    """
    if hour is None:
        return 0.35
    if hour < 6 or hour >= 21:
        return 0.50  # Night: more dramatic
    elif hour < 9 or hour >= 18:
        return 0.40  # Dawn/dusk: moderate
    else:
        return 0.25  # Daytime: subtle


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
    # 🐝 v0.8.21 — Nectar Sync 2.0 flags (passed by BeeConfig.qml)
    parser.add_argument("--time-aware", action="store_true", help="Enable time-of-day awareness")
    parser.add_argument("--timezone", type=str, default="America/Toronto", help="Timezone for time-aware mode")
    parser.add_argument("--weather-aware", action="store_true", help="Enable weather-based awareness")
    parser.add_argument("--weather-city", type=str, default="Blainville", help="City for weather-aware mode")
    args = parser.parse_args()

    wallpaper = args.wallpaper.resolve() if args.wallpaper else resolve_default_wallpaper().resolve()
    if not wallpaper.exists():
        raise FileNotFoundError(f"Wallpaper not found: {wallpaper}")

    colors = extract_palette(wallpaper, max_colors=max(6, args.max_colors))
    
    # Detect signature wallpaper for preset palette
    signature_mode = None
    if not colors:
        sig_map = {
            "wallpaper_dark_bee.png": "HoneyDark",
            "wallpaper_light_bee.png": "HoneyLight",
            "wallpaper.png": "HoneyDark",
            "wallpaper_light.png": "HoneyLight",
        }
        signature_mode = sig_map.get(wallpaper.name)
    
    forced_mode = None if args.mode == "auto" else args.mode

    # 🐝 v0.8.21 — Time-aware mode override
    time_aware_hour = None
    if args.time_aware and not forced_mode:
        import datetime as _dt
        try:
            import pytz
            tz = pytz.timezone(args.timezone)
        except Exception:
            import zoneinfo
            tz = zoneinfo.ZoneInfo(args.timezone)
        hour = _dt.datetime.now(tz).hour
        time_aware_hour = hour
        # Morning (6-18) = Light, Evening (18-6) = Dark
        if 6 <= hour < 18:
            forced_mode = "HoneyLight"
        else:
            forced_mode = "HoneyDark"
        print(f"Time-aware: hour={hour} in {args.timezone} → mode={forced_mode}")

    # 🐝 v0.8.39 — Weather-aware palette adjustment
    weather_data = None
    weather_condition = None
    weather_suggestion = ""
    if args.weather_aware:
        weather_data = fetch_weather(args.weather_city)
        if weather_data:
            weather_condition = classify_weather(weather_data)
            print(f"Weather-aware: city={args.weather_city} condition={weather_condition} "
                  f"temp={weather_data.get('temperature', 'N/A')}°C")
        else:
            print(f"Weather-aware: could not fetch weather for {args.weather_city}, skipping")

    palette = build_palette(
        colors,
        forced_mode=forced_mode,
        signature_mode=signature_mode,
        weather_condition=weather_condition,
        time_aware_hour=time_aware_hour,
    )
    effective_mode = forced_mode or args.mode
    overlay = build_overlay(wallpaper, palette, effective_mode)

    # 🐝 v0.8.39 — Inject Nectar Sync flags & weather data into overlay metadata
    if "auto_theme" not in overlay:
        overlay["auto_theme"] = {}
    nectar_meta = overlay["auto_theme"]
    nectar_meta["time_aware"] = args.time_aware
    nectar_meta["timezone"] = args.timezone if args.time_aware else None
    nectar_meta["weather_aware"] = args.weather_aware
    nectar_meta["weather_city"] = args.weather_city if args.weather_aware else None
    if weather_data:
        nectar_meta["weather_data"] = weather_data
        nectar_meta["weather_condition"] = weather_condition
    if weather_suggestion:
        nectar_meta["weather_suggestion"] = weather_suggestion

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
