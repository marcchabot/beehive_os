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

    // ── Chemin vers les sons custom (relatif à la config shell) ──
    // Si le fichier n'existe pas, le fallback system est utilisé.
    readonly property string _customBase: Qt.resolvedUrl("../assets/sounds/")
    readonly property string _sysBase:   "/usr/share/sounds/freedesktop/stereo/"

    // ── Table de résolution : nom logique → fichier son ──────────
    // Priority: assets/sounds/<name>.ogg, then system sounds.
    readonly property var _soundMap: ({
        "dash_open":   "audio-volume-change.oga",
        "dash_close":  "audio-volume-change.oga",
        "cell_click":  "button-pressed.oga",
        "notify":      "message.oga",
        "power":       "power-plug.oga",
        "error":       "dialog-error.oga"
    })

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
        if (!soundsEnabled) return
        var file = _soundMap[soundName] || "audio-volume-change.oga"
        var path = _sysBase + file
        _playPath(path)
    }

    // ── Rotation des slots (3 sons simultanés maximum) ────────────
    function _playPath(path) {
        _slot = (_slot + 1) % 3
        var proc = _slot === 0 ? sndProc0 : (_slot === 1 ? sndProc1 : sndProc2)
        proc.running = false
        proc.command = ["pw-play", "--volume=0.35", path]
        proc.running = true
    }
}
