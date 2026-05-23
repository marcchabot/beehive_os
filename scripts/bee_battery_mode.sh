#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# bee_battery_mode.sh — Battery Status Detection 🐝🔋
# v0.8.35: Reads /sys/class/power_supply/ to detect battery state
# Outputs JSON: { "on_battery": bool, "percentage": int, "status": string }
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# Find battery path
BAT_PATH=""
for p in /sys/class/power_supply/BAT* /sys/class/power_supply/bat*; do
    if [ -d "$p" ]; then
        BAT_PATH="$p"
        break
    fi
done

# Find AC path
AC_PATH=""
for p in /sys/class/power_supply/AC* /sys/class/power_supply/ac* /sys/class/power_supply/ADP*; do
    if [ -d "$p" ]; then
        AC_PATH="$p"
        break
    fi
done

# Defaults
on_battery=false
percentage=100
status="Unknown"

# Read battery status
if [ -n "$BAT_PATH" ] && [ -f "$BAT_PATH/status" ]; then
    bat_status=$(cat "$BAT_PATH/status" 2>/dev/null || echo "Unknown")
    case "$bat_status" in
        Discharging*) on_battery=true; status="Discharging" ;;
        Charging*) on_battery=false; status="Charging" ;;
        Full*) on_battery=false; status="Full" ;;
        Not\ charging*) on_battery=false; status="Not charging" ;;
        *) on_battery=false; status="$bat_status" ;;
    esac
elif [ -n "$AC_PATH" ] && [ -f "$AC_PATH/online" ]; then
    # No battery found — check AC adapter
    ac_online=$(cat "$AC_PATH/online" 2>/dev/null || echo "1")
    if [ "$ac_online" = "0" ]; then
        on_battery=true
        status="Discharging (AC offline)"
    else
        on_battery=false
        status="On AC power"
    fi
else
    # No battery or AC detected — assume desktop/AC
    on_battery=false
    percentage=100
    status="No battery detected"
fi

# Read battery percentage
if [ -n "$BAT_PATH" ]; then
    if [ -f "$BAT_PATH/capacity" ]; then
        percentage=$(cat "$BAT_PATH/capacity" 2>/dev/null || echo 100)
    elif [ -f "$BAT_PATH/energy_now" ] && [ -f "$BAT_PATH/energy_full" ]; then
        energy_now=$(cat "$BAT_PATH/energy_now" 2>/dev/null || echo 0)
        energy_full=$(cat "$BAT_PATH/energy_full" 2>/dev/null || echo 1)
        if [ "$energy_full" -gt 0 ] 2>/dev/null; then
            percentage=$(( energy_now * 100 / energy_full ))
        fi
    fi
fi

# Output JSON for QML SplitParser
printf '{"on_battery": %s, "percentage": %d, "status": "%s"}\n' "$on_battery" "$percentage" "$status"