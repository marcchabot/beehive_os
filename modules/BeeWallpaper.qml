import Quickshell
import QtQuick

// ═══════════════════════════════════════════════════════════════
// BeeWallpaper.qml — Gestionnaire de fonds d'écran 🐝🖼️
// v0.6 : Smooth crossfade 1.8s InOutSine + slight scale effect
// Enhanced transition polish for BeeHive OS visual coherence
// ═══════════════════════════════════════════════════════════════

Item {
    id: wallpaperRoot
    anchors.fill: parent
    z: -100

    // ─── Tracker d'image active (bool, pas opacité) ───────────
    // Évite les bugs si crossfadeTo() est appelé pendant une
    // transition en cours (opacité encore en mouvement).
    property bool _usingImage1: true

    // ─── Image active ─────────────────────────────────────────
    Image {
        id: bgImage1
        anchors.fill: parent
        source: BeeTheme.wallpaper          // Source initiale depuis le thème
        fillMode: Image.PreserveAspectCrop
        cache: false                        // Évite l'accumulation en VRAM après transition
        opacity: 1.0
        Behavior on opacity { NumberAnimation { duration: 1800; easing.type: Easing.InOutSine } }
        Behavior on scale { NumberAnimation { duration: 1800; easing.type: Easing.InOutSine } }
    }

    // ─── Image de transition (crossfade) ─────────────────────
    Image {
        id: bgImage2
        anchors.fill: parent
        source: ""
        fillMode: Image.PreserveAspectCrop
        cache: false
        opacity: 0.0
        scale: 1.02   // Slight zoom for entrance
        Behavior on opacity { NumberAnimation { duration: 1800; easing.type: Easing.InOutSine } }
        Behavior on scale { NumberAnimation { duration: 1800; easing.type: Easing.InOutSine } }
    }

    // ─── Timer de libération texture (2s après fin de crossfade) ─
    // Libère la source de l'image en arrière-plan pour éviter
    // l'accumulation de textures 4K en VRAM.
    Timer {
        id: freeTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (wallpaperRoot._usingImage1) bgImage2.source = ""
            else                            bgImage1.source = ""
        }
    }

    // ─── Overlay adapté au thème ──────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: BeeTheme.mode === "HoneyDark" ? 0.20 : 0.05
        Behavior on opacity { NumberAnimation { duration: 1500 } }
    }

    // ─── Réagit aux changements de wallpaper ──────────────────
    Connections {
        target: BeeTheme
        function onWallpaperChanged() { crossfadeTo(BeeTheme.wallpaper) }
    }

    // ─── Crossfade robuste avec léger zoom (polish visuel) ──────
    // L'image sortante fait un léger zoom-out (1.0→1.02)
    // L'image entrante fait un léger zoom-in (1.02→1.0)
    // pour un effet plus cinématique que le simple fondu.
    function crossfadeTo(src) {
        freeTimer.stop()
        if (_usingImage1) {
            bgImage2.source  = src
            bgImage2.opacity = 1.0
            bgImage2.scale   = 1.0
            bgImage1.opacity = 0.0
            bgImage1.scale   = 1.02
            _usingImage1 = false
        } else {
            bgImage1.source  = src
            bgImage1.opacity = 1.0
            bgImage1.scale   = 1.0
            bgImage2.opacity = 0.0
            bgImage2.scale   = 1.02
            _usingImage1 = true
        }
        freeTimer.restart()
    }
}
