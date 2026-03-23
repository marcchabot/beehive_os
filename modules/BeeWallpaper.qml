import Quickshell
import QtQuick

// ═══════════════════════════════════════════════════════════════
// BeeWallpaper.qml — Gestionnaire de fonds d'écran 🐝🖼️
// v0.5 : Piloté par BeePalette Engine (BeeTheme.wallpaper)
// Transition crossfade 1.5s — tracker booléen (robustesse)
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
        Behavior on opacity { NumberAnimation { duration: 1500; easing.type: Easing.InOutQuad } }
    }

    // ─── Image de transition (crossfade) ─────────────────────
    Image {
        id: bgImage2
        anchors.fill: parent
        source: ""
        fillMode: Image.PreserveAspectCrop
        cache: false                        // Évite l'accumulation en VRAM après transition
        opacity: 0.0
        Behavior on opacity { NumberAnimation { duration: 1500; easing.type: Easing.InOutQuad } }
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

    // ─── Crossfade robuste (tracker booléen) ──────────────────
    // _usingImage1 indique laquelle est "dessus" indépendamment
    // de l'opacité animée — fiable même en double-transition rapide.
    function crossfadeTo(src) {
        freeTimer.stop()
        if (_usingImage1) {
            bgImage2.source  = src
            bgImage2.opacity = 1.0
            bgImage1.opacity = 0.0
            _usingImage1 = false
        } else {
            bgImage1.source  = src
            bgImage1.opacity = 1.0
            bgImage2.opacity = 0.0
            _usingImage1 = true
        }
        freeTimer.restart()
    }
}
