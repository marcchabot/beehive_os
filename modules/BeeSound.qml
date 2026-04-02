pragma Singleton
import QtQuick
import Quickshell.Io

// ═══════════════════════════════════════════════════════════════
// BeeSound.qml — Singleton effets sonores Bee-Hive OS 🐝🔊
// Utilise pw-play (PipeWire) pour des sons discrets et élégants.
// Automatic fallback to freedesktop system sounds.
// Pool de 3 Process pour éviter les fuites mémoire.
// ═══════════════════════════════════════════════════════════════

QtObject {
    id: beeSound

    // ── Activer/désactiver tous les sons ─────────────────────────
    property bool soundsEnabled: true

    // ── Chemins sons (priorité custom OGG Opus, puis fallback système) ──
    readonly property string _customBase: Qt.resolvedUrl("../assets/sounds/").toString().replace("file://", "")
    readonly property string _sysBase: "/usr/share/sounds/freedesktop/stereo/"

    // ── Table centrale des événements ─────────────────────────────
    readonly property var _eventMap: ({
        // BeeSound 3.0 taxonomy
        "dash.open":     { fileBase: "audio-volume-change", cooldownMs: 130 },
        "dash.close":    { fileBase: "audio-volume-change", cooldownMs: 130 },
        "ui.cell.click": { fileBase: "button-pressed",      cooldownMs: 90  },
        "notify.info":   { fileBase: "message",             cooldownMs: 250 },
        "osd.volume":    { fileBase: "button-pressed",      cooldownMs: 90  },
        "osd.brightness":{ fileBase: "button-pressed",      cooldownMs: 90  },
        "osd.kbd":       { fileBase: "button-pressed",      cooldownMs: 90  },
        "osd.mute":      { fileBase: "button-pressed",      cooldownMs: 90  },
        "osd.generic":   { fileBase: "button-pressed",      cooldownMs: 90  },
        "power.action":  { fileBase: "power-plug",          cooldownMs: 300 },
        "system.error":  { fileBase: "dialog-error",        cooldownMs: 250 },

        // Legacy aliases (compatibility bridge)
        "dash_open":  { fileBase: "audio-volume-change", cooldownMs: 130 },
        "dash_close": { fileBase: "audio-volume-change", cooldownMs: 130 },
        "cell_click": { fileBase: "button-pressed",      cooldownMs: 90  },
        "notify":     { fileBase: "message",             cooldownMs: 250 },
        "power":      { fileBase: "power-plug",          cooldownMs: 300 },
        "error":      { fileBase: "dialog-error",        cooldownMs: 250 }
    })
    property var _lastEventMs: ({})

    // ── Pool de 3 Process réutilisables (zéro création dynamique) ─
    property int _slot: 0

    property Process _p0: Process {
        id: sndProc0
        running: false
        stdout: SplitParser { onRead: {} }
        stderr: SplitParser { onRead: {} }
    }
    property Process _p1: Process {
        id: sndProc1
        running: false
        stdout: SplitParser { onRead: {} }
        stderr: SplitParser { onRead: {} }
    }
    property Process _p2: Process {
        id: sndProc2
        running: false
        stdout: SplitParser { onRead: {} }
        stderr: SplitParser { onRead: {} }
    }

    // ── API publique ──────────────────────────────────────────────
    function play(soundName) {
        return playEvent(soundName, {})
    }

    function playEvent(eventName, opts) {
        if (!soundsEnabled) return false
        var options = opts || {}
        var cfg = _eventMap[eventName] || _eventMap["dash.open"]
        var cooldown = options.cooldownMs !== undefined ? options.cooldownMs : cfg.cooldownMs
        if (!_acquireCooldown(eventName, cooldown)) return false

        var fileBase = options.fileBase || cfg.fileBase || "audio-volume-change"
        var gain = _resolveGain(options)
        _playCandidates(_candidatePaths(fileBase), gain)
        return true
    }

    function _acquireCooldown(eventName, cooldownMs) {
        var cd = Math.max(0, cooldownMs || 0)
        if (cd <= 0) return true
        var now = Date.now()
        var map = _lastEventMs
        var last = map[eventName] || 0
        if (now - last < cd) return false
        map[eventName] = now
        _lastEventMs = map
        return true
    }

    function _candidatePaths(fileBase) {
        var b = fileBase || "audio-volume-change"
        return [
            _customBase + b + ".ogg", // Priorité OGG Opus
            _customBase + b + ".oga",
            _sysBase + b + ".ogg",
            _sysBase + b + ".oga"
        ]
    }

    function _resolveGain(options) {
        if (options && options.gain !== undefined) return _clampGain(options.gain)

        var dayGain = _configNumber("soundDayGain", 0.35)
        var nightEnabled = _configBool("soundNightMode", true)
        if (!nightEnabled) return dayGain

        var startHour = _configInt("soundNightStartHour", 22)
        var endHour = _configInt("soundNightEndHour", 7)
        var hour = new Date().getHours()
        if (_inNightWindow(hour, startHour, endHour))
            return _configNumber("soundNightGain", 0.18)
        return dayGain
    }

    function _inNightWindow(hour, startHour, endHour) {
        if (startHour === endHour) return false
        if (startHour < endHour) return hour >= startHour && hour < endHour
        return hour >= startHour || hour < endHour
    }

    function _configBool(key, fallback) {
        if (typeof BeeConfig !== "undefined" && BeeConfig[key] !== undefined) return BeeConfig[key] === true
        return fallback === true
    }

    function _configInt(key, fallback) {
        if (typeof BeeConfig !== "undefined" && BeeConfig[key] !== undefined) {
            var v = parseInt(BeeConfig[key])
            if (!isNaN(v)) return Math.max(0, Math.min(23, v))
        }
        return fallback
    }

    function _configNumber(key, fallback) {
        if (typeof BeeConfig !== "undefined" && BeeConfig[key] !== undefined) {
            var v = Number(BeeConfig[key])
            if (!isNaN(v)) return _clampGain(v)
        }
        return _clampGain(fallback)
    }

    function _clampGain(v) {
        var n = Number(v)
        if (isNaN(n)) return 0.35
        return Math.max(0.0, Math.min(1.0, n))
    }

    // ── Rotation des slots (3 sons simultanés maximum) ────────────
    function _playCandidates(candidates, gain) {
        _slot = (_slot + 1) % 3
        var proc = _slot === 0 ? sndProc0 : (_slot === 1 ? sndProc1 : sndProc2)
        proc.running = false
        var g = _clampGain(gain).toFixed(2)
        proc.command = [
            "bash",
            "-c",
            "gain=\"$1\"; shift; for c in \"$@\"; do [ -f \"$c\" ] && exec pw-play --volume=\"$gain\" \"$c\"; done; exit 0",
            "bee-sound",
            g
        ].concat(candidates || [])
        proc.running = true
    }
}
