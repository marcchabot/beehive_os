import QtQuick
import QtQuick.Effects

// ═══════════════════════════════════════════════════════════════
// BeeOSD.qml — On-Screen Display BeeAura 🐝🎚️
// v0.8.6 : Notifications & OSD Phase
//
// Affiche un overlay centré (glassmorphisme doré/noir) pour :
//   volume     — niveau sonore 0-100 %
//   mute       — sourdine active
//   brightness — luminosité écran 0-100 %
//   kbd        — rétro-éclairage clavier 0-100 %
//
// Déclenché via : quickshell ipc call root showOSD "volume" "75"
// ─── Architecture ──────────────────────────────────────────────
//   Écoute BeeBarState.osdReceived(type, value)
//   Animation séquentielle : fondu entrant → pause → fondu sortant
//   Scale BeeAura avec easing organique
// ═══════════════════════════════════════════════════════════════

Item {
    id: osd
    anchors.fill: parent

    // ─── Signal pour notifier la fin de l'animation ───────────
    signal animationComplete()

    // ─── État interne ─────────────────────────────────────────
    property string currentType:  "volume"
    property int    currentValue: 0

    // ─── Résolution icône selon type ET valeur ────────────────
    function iconFor(t, v) {
        switch (t) {
            case "mute":       return "🔇"
            case "volume":     return v === 0 ? "🔈" : (v < 50 ? "🔉" : "🔊")
            case "brightness": return "☀️"
            case "kbd":        return "⌨️"
            default:           return "◈"
        }
    }

    function labelFor(t) {
        switch (t) {
            case "mute":       return "Sourdine"
            case "volume":     return "Volume"
            case "brightness": return "Luminosité"
            case "kbd":        return "Clavier"
            default:           return t
        }
    }

    // ─── Écoute BeeBarState ───────────────────────────────────
    Connections {
        target: BeeBarState
        function onOsdReceived(type, value) {
            osd.currentType  = type
            osd.currentValue = value
            osdAnim.restart()
            BeeSound.playEvent("osd." + (type || "generic"), {})
        }
    }

    // ─── Animation : fondu entrant → pause → fondu sortant ───
    SequentialAnimation {
        id: osdAnim

        onStopped: {
            console.log("BeeOSD: Animation complete, emitting signal")
            osd.animationComplete()
        }

        // Entrée : scale + opacité
        ParallelAnimation {
            NumberAnimation {
                target: panel; property: "opacity"
                from: 0.0; to: 1.0
                duration: 220; easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: panel; property: "scale"
                from: 0.84; to: 1.0
                duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.1
            }
        }

        // Plateau visible
        PauseAnimation { duration: 1800 }

        // Sortie : fondu + légère réduction
        ParallelAnimation {
            NumberAnimation {
                target: panel; property: "opacity"
                to: 0.0; duration: 380; easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: panel; property: "scale"
                to: 0.92; duration: 380; easing.type: Easing.InCubic
            }
        }
    }

    // ─── Panel glassmorphisme ─────────────────────────────────
    Rectangle {
        id: panel

        anchors.centerIn: parent
        width:   300
        height:  110
        radius:  22
        opacity: 0.0
        scale:   0.84

        color:        BeeTheme.glassBg
        border.color: BeeTheme.glassBorder
        border.width: 1.5

        // Glow BeeAura doré (pas de décalage — halo centré)
        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled:     true
            shadowEnabled:          true
            shadowColor:            BeeTheme.auraGlow
            shadowBlur:             0.88
            shadowVerticalOffset:   0
            shadowHorizontalOffset: 0
        }

        // ─── Ligne supérieure : icône + libellé + valeur ──────
        Row {
            anchors {
                top:              parent.top
                topMargin:        20
                horizontalCenter: parent.horizontalCenter
            }
            spacing: 10

            Text {
                text:              osd.iconFor(osd.currentType, osd.currentValue)
                font.pixelSize:    22
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                text:              osd.labelFor(osd.currentType)
                font.pixelSize:    16
                font.weight:       Font.Medium
                color:             BeeTheme.textPrimary
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                // Valeur masquée si sourdine
                text:              osd.currentType === "mute" ? "" : (osd.currentValue + "%")
                font.pixelSize:    14
                font.weight:       Font.Bold
                color:             BeeTheme.accent
                verticalAlignment: Text.AlignVCenter
            }
        }

        // ─── Barre de progression ─────────────────────────────
        Rectangle {
            id: barTrack
            anchors {
                bottom:           parent.bottom
                bottomMargin:     22
                horizontalCenter: parent.horizontalCenter
            }
            width:  parent.width - 48
            height: 8
            radius: 4
            // Piste : teinte accent très atténuée
            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)

            // Remplissage doré animé
            Rectangle {
                id: barFill
                height: parent.height
                radius: parent.radius
                // Disparaît en sourdine ; minimum = caps pour éviter l'artefact radius
                width: osd.currentType === "mute"
                       ? 0
                       : Math.max(radius * 2, barTrack.width * Math.min(osd.currentValue, 100) / 100)

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.darker(BeeTheme.accent, 1.3) }
                    GradientStop { position: 1.0; color: BeeTheme.accent                 }
                }

                Behavior on width {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }

                // Liseré lumineux sur le bord de la barre
                Rectangle {
                    anchors.fill: parent
                    radius:       parent.radius
                    color:        "transparent"
                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.55)
                    border.width: 1
                }
            }
        }
    }
}
