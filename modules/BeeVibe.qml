import QtQuick
import Quickshell.Io

// ═══════════════════════════════════════════════════════════════
// BeeVibe.qml — Moteur de visualisation audio 🐝🎵
// v1.0 : Lecture Cava (raw ASCII) + simulation de repli
//        Expose barValues[0..7] (0.0–1.0) aux alvéoles MayaDash
// ═══════════════════════════════════════════════════════════════

Item {
    id: beeVibe
    visible: false   // pure data component, no visual rendering

    // ─── API publique ───────────────────────────────────────────
    property bool active: false
    // 8 normalized values 0.0–1.0, one per cell
    property var barValues: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

    // ─── État interne ───────────────────────────────────────────
    // Passe à true dès que Cava envoie sa première trame valide
    property bool _cavaLive: false

    // ═══════════════════════════════════════════════════════════
    // PROCESSUS CAVA
    // Config inline : 8 barres, 20 fps, sortie ASCII sur stdout
    // bar_delimiter=32 (espace), frame_delimiter=10 (newline)
    // ═══════════════════════════════════════════════════════════
    property Process cavaProc: Process {
        id: _cavaProc
        running: beeVibe.active

        command: [
            "bash", "-c",
            "tmp=$(mktemp /tmp/.beevibe_XXXXXX.conf); " +
            "printf '[general]\\nbars = 8\\nframerate = 20\\n\\n" +
            "[output]\\nmethod = raw\\nraw_target = /dev/stdout\\n" +
            "data_format = ascii\\nascii_max_range = 100\\n" +
            "bar_delimiter = 32\\nframe_delimiter = 10\\n' > \"$tmp\"; " +
            "exec cava -p \"$tmp\""
        ]

        // Read line by line (one line = a frame of 8 values)
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                var parts = line.trim().split(" ")
                if (parts.length < 8) return
                var vals = []
                for (var i = 0; i < 8; i++) {
                    var v = parseInt(parts[i])
                    vals.push(isNaN(v) ? 0.0 : Math.max(0.0, Math.min(1.0, v / 100.0)))
                }
                beeVibe.barValues = vals
                if (!beeVibe._cavaLive) beeVibe._cavaLive = true
            }
        }

        onExited: (code, status) => {
            beeVibe._cavaLive = false
            beeVibe.barValues = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        }
    }

    // ═══════════════════════════════════════════════════════════
    // SIMULATION — repli si Cava est absent ou inactif
    // Ondes sinusoïdales décalées → aspect équaliseur vivant
    // ~12 fps, très léger CPU (pas de traitement audio réel)
    // ═══════════════════════════════════════════════════════════
    property real _simPhase: 0.0

    Timer {
        interval: 80   // ~12 fps
        repeat:   true
        running:  beeVibe.active && !beeVibe._cavaLive

        onTriggered: {
            beeVibe._simPhase += 0.14
            var ph = beeVibe._simPhase
            var vals = []
            for (var i = 0; i < 8; i++) {
                // Deux harmoniques décalées par barre → mouvement fluide
                var v = 0.08 + 0.42 * Math.abs(Math.sin(ph + i * 0.85))
                                    * Math.abs(Math.cos(ph * 0.38 + i * 0.6))
                vals.push(Math.max(0.0, Math.min(1.0, v)))
            }
            beeVibe.barValues = vals
        }
    }

    // ─── Remise à zéro à la désactivation ─────────────────────
    onActiveChanged: {
        if (!active) {
            _cavaLive = false
            barValues = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        }
    }
}
}

}
