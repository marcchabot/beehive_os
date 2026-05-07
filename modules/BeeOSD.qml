import QtQuick
import QtQuick.Effects

// ═══════════════════════════════════════════════════════════════
// BeeOSD.qml — On-Screen Display BeeAura 🐝🎚️
// v0.9.0 : Premium OSD Redesign — macOS-style bars, animated icons
//   volume     → coloré barre + icône animée
//   brightness → cercle lumineux
//   mute       → icône barrée animée
//   kbd        → barre colorée clavier
//
// Glassmorphism BeeHive cohérent, animations fluides type macOS
// Déclenché via : quickshell ipc call root showOSD "volume" "75"
// ═══════════════════════════════════════════════════════════════

Item {
    id: osd
    anchors.fill: parent

    // ─── Signal pour notifier la fin de l'animation ───────────
    signal animationComplete()

    // ─── État interne ─────────────────────────────────────────
    property string currentType:  "volume"
    property int    currentValue: 0

    // ─── Couleur adaptative par type ──────────────────────────
    property color osdAccent: {
        switch (currentType) {
            case "mute":       return Qt.rgba(0.9, 0.3, 0.3, 1)   // Rouge
            case "volume":     return BeeTheme.accent                // Doré
            case "brightness": return Qt.rgba(1.0, 0.85, 0.3, 1)   // Soleil doré
            case "kbd":        return Qt.rgba(0.4, 0.7, 1.0, 1)   // Bleu clavier
            default:           return BeeTheme.accent
        }
    }

    // ─── Résolution icône selon type ET valeur ────────────────
    function iconFor(t, v) {
        switch (t) {
            case "mute":       return "🔇"
            case "volume":     return v === 0 ? "🔈" : (v < 33 ? "🔉" : (v < 66 ? "🔉" : "🔊"))
            case "brightness": return v < 33 ? "🌙" : (v < 66 ? "🌤️" : "☀️")
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

    // ─── Animation : macOS-style bubble ────────────────────────
    // Smooth fade-in → slight scale bounce → hold → fade-out
    SequentialAnimation {
        id: osdAnim

        onStopped: {
            osd.animationComplete()
        }

        // Entrée : opacity + scale spring
        ParallelAnimation {
            NumberAnimation {
                target: panel; property: "opacity"
                from: 0.0; to: 1.0
                duration: 250; easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: panel; property: "scale"
                from: 0.7; to: 1.0
                duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.4
            }
            NumberAnimation {
                target: panel; property: "yOffset"
                from: 20; to: 0
                duration: 300; easing.type: Easing.OutCubic
            }
        }

        // Micro-bounce settle
        NumberAnimation {
            target: panel; property: "scale"
            from: 1.0; to: 0.97; duration: 80; easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: panel; property: "scale"
            from: 0.97; to: 1.0; duration: 120; easing.type: Easing.OutElastic; easing.amplitude: 0.3
        }

        // Plateau visible
        PauseAnimation { duration: 1600 }

        // Sortie : fondu + réduction douce
        ParallelAnimation {
            NumberAnimation {
                target: panel; property: "opacity"
                to: 0.0; duration: 400; easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: panel; property: "scale"
                to: 0.88; duration: 400; easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: panel; property: "yOffset"
                to: -10; duration: 400; easing.type: Easing.InCubic
            }
        }
    }

    // ─── Panel glassmorphisme premium ─────────────────────────
    Rectangle {
        id: panel

        property real yOffset: 0

        anchors.centerIn: parent
        y: parent.height / 2 - height / 2 + yOffset
        width:   320
        height:  currentType === "brightness" ? 160 : 130
        radius:  24
        opacity: 0.0
        scale:   0.7

        color:        BeeTheme.glassBg
        border.color: Qt.rgba(osdAccent.r, osdAccent.g, osdAccent.b, 0.35)
        border.width: 1.5

        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutCubic } }
        Behavior on border.color { ColorAnimation { duration: 250 } }

        // Glow BeeAura — accent color matches type
        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled:     true
            shadowEnabled:          true
            shadowColor:            Qt.rgba(osdAccent.r, osdAccent.g, osdAccent.b, 0.5)
            shadowBlur:             0.92
            shadowVerticalOffset:   0
            shadowHorizontalOffset: 0
        }

        // ─── Brightness: Circle Mode ──────────────────────────
        Item {
            visible: osd.currentType === "brightness"
            anchors.fill: parent
            anchors.margins: 16

            // Circular progress background
            Rectangle {
                id: brightnessCircleBg
                anchors.centerIn: parent
                width: 100
                height: 100
                radius: 50
                color: "transparent"
                border.color: Qt.rgba(osdAccent.r, osdAccent.g, osdAccent.b, 0.2)
                border.width: 6

                // Circular progress fill
                Rectangle {
                    id: brightnessArc
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: osdAccent
                    border.width: 6
                    clip: true

                    // Radial sweep effect using rotation
                    Rectangle {
                        id: brightnessSweep
                        width: parent.width
                        height: parent.height / 2
                        anchors.top: parent.top
                        color: osdAccent
                        opacity: 0.9
                        transform: Rotation {
                            origin.x: brightnessSweep.width / 2
                            origin.y: brightnessSweep.height
                            angle: Math.min(osd.currentValue / 100 * 360, 360)
                        }
                    }
                }

                // Center content
                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        text: osd.iconFor(osd.currentType, osd.currentValue)
                        font.pixelSize: 28
                        anchors.horizontalCenter: parent.horizontalCenter

                        // Pulse animation for brightness icon
                        SequentialAnimation on font.pixelSize {
                            running: osd.currentType === "brightness" && osdAnim.running
                            loops: Animation.Infinite
                            NumberAnimation { to: 32; duration: 600; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 28; duration: 600; easing.type: Easing.InOutSine }
                        }
                    }

                    Text {
                        text: osd.currentValue + "%"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: BeeTheme.textPrimary
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            Text {
                text: osd.labelFor(osd.currentType)
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.6)
                anchors.top: brightnessCircleBg.bottom
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // ─── Volume / Mute / KBD: Bar Mode ───────────────────
        Item {
            visible: osd.currentType !== "brightness"
            anchors.fill: parent
            anchors.margins: 20

            // ─── Top row: animated icon + label + value ────────
            Row {
                id: topRow
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                }
                spacing: 10

                // Animated icon container
                Item {
                    width: 36
                    height: 36
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: osdIcon
                        text: osd.iconFor(osd.currentType, osd.currentValue)
                        font.pixelSize: 26
                        anchors.centerIn: parent

                        // Bounce animation on icon
                        SequentialAnimation on scale {
                            running: osdAnim.running
                            NumberAnimation { to: 1.15; duration: 150; easing.type: Easing.OutCubic }
                            NumberAnimation { to: 1.0; duration: 200; easing.type: Easing.OutElastic; easing.amplitude: 0.5 }
                        }
                    }
                }

                Text {
                    text: osd.labelFor(osd.currentType)
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    color: BeeTheme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Value bubble (macOS-style rounded pill)
                Rectangle {
                    width: valueText.implicitWidth + 16
                    height: 26
                    radius: 13
                    color: Qt.rgba(osdAccent.r, osdAccent.g, osdAccent.b, 0.18)
                    border.color: Qt.rgba(osdAccent.r, osdAccent.g, osdAccent.b, 0.4)
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter
                    visible: osd.currentType !== "mute"

                    Text {
                        id: valueText
                        text: osd.currentValue + "%"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: osdAccent
                        anchors.centerIn: parent
                    }
                }
            }

            // ─── Barre de progression premium ─────────────────
            Rectangle {
                id: barTrack
                anchors {
                    bottom: parent.bottom
                    bottomMargin: 10
                    horizontalCenter: parent.horizontalCenter
                }
                width: parent.width - 24
                height: 10
                radius: 5
                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.12)

                // Fill gradient bar
                Rectangle {
                    id: barFill
                    height: parent.height
                    radius: parent.radius
                    width: osd.currentType === "mute"
                           ? 0
                           : Math.max(radius * 2, barTrack.width * Math.min(osd.currentValue, 100) / 100)

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0.0
                            color: Qt.rgba(osdAccent.r, osdAccent.g, osdAccent.b, 0.7)
                        }
                        GradientStop {
                            position: 1.0
                            color: osdAccent
                        }
                    }

                    Behavior on width {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }

                    // Glow on the tip of the bar
                    Rectangle {
                        id: barTipGlow
                        width: 20
                        height: parent.height + 8
                        radius: height / 2
                        anchors {
                            right: parent.right
                            rightMargin: -4
                            verticalCenter: parent.verticalCenter
                        }
                        color: Qt.rgba(osdAccent.r, osdAccent.g, osdAccent.b, 0.4)
                        visible: osd.currentType !== "mute"

                        // Pulsing glow
                        SequentialAnimation on opacity {
                            running: osdAnim.running
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.8; duration: 500; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0.3; duration: 500; easing.type: Easing.InOutSine }
                        }
                    }

                    // Subtle inner highlight
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.color: Qt.rgba(1, 1, 1, 0.15)
                        border.width: 1
                    }
                }

                // Track inner shadow
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: Qt.rgba(osdAccent.r, osdAccent.g, osdAccent.b, 0.08)
                    border.width: 1
                }
            }
        }
    }
}