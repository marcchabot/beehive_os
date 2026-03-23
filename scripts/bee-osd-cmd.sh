#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# bee-osd-cmd.sh 🐝🎚️  — Bee-Hive OS v0.8.6
# Wrapper wpctl/brightnessctl → OSD BeeAura via Quickshell IPC
#
# Usage :
#   bee-osd-cmd.sh volume   toggle       # Mute/Unmute
#   bee-osd-cmd.sh volume   5%+          # Volume +5 %
#   bee-osd-cmd.sh volume   5%-          # Volume -5 %
#   bee-osd-cmd.sh brightness 5%+        # Écran +5 %
#   bee-osd-cmd.sh brightness 5%-        # Écran -5 %
#   bee-osd-cmd.sh kbd      5%+          # Clavier +5 %
#   bee-osd-cmd.sh kbd      5%-          # Clavier -5 %
# ═══════════════════════════════════════════════════════════════

TYPE="$1"
ACTION="$2"

_ipc_osd() {
    quickshell -p ~/beehive_os/shell.qml ipc call root showOSD "$1" "$2"
}

case "$TYPE" in
    volume)
        if [ "$ACTION" = "toggle" ]; then
            wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        else
            wpctl set-volume @DEFAULT_AUDIO_SINK@ "$ACTION"
        fi
        IS_MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -c "MUTED")
        if [ "$IS_MUTED" -ge 1 ]; then
            _ipc_osd "mute" 0
        else
            VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%d", $2 * 100}')
            _ipc_osd "volume" "$VOL"
        fi
        ;;
    brightness)
        brightnessctl set "$ACTION"
        MAX=$(brightnessctl max)
        CUR=$(brightnessctl get)
        PCT=$(( CUR * 100 / MAX ))
        _ipc_osd "brightness" "$PCT"
        ;;
    kbd)
        brightnessctl --device='*::kbd_backlight' set "$ACTION"
        MAX=$(brightnessctl --device='*::kbd_backlight' max)
        CUR=$(brightnessctl --device='*::kbd_backlight' get)
        PCT=$(( CUR * 100 / MAX ))
        _ipc_osd "kbd" "$PCT"
        ;;
    *)
        echo "Usage: bee-osd-cmd.sh {volume|brightness|kbd} {action}" >&2
        exit 1
        ;;
esac
