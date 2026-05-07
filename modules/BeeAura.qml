import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "."

// ═══════════════════════════════════════════════════════════
// BeeAura.qml — Bee-Hive OS OSD System 🎚️
// v1.0 : Dynamic Overlays for Volume, Brightness, and Keys
// ═══════════════════════════════════════════════════════════

Rectangle {
    id: beeAura
    anchors.centerIn: parent
    width: 300; height: 80
    radius: 20
    color: "transparent"
    visible: false
    opacity: 0

    // ─── OSD State ──────────────────────────────────────────
    property string osdType: "volume" // volume | brightness | mute | kbd
    property int    osdValue: 0
    property string osdIcon: "🔊"
    property string osdLabel: "Volume"

    // ─── Animation ──────────────────────────────────────────
    Behavior on opacity { NumberAnimation { duration: 200 } }
    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
    property real dashScale: 1.0

    // ─── Event Listener ─────────────────────────────────────
    Connections {
        target: BeeBarState
        function onOsdReceived(type, value) {
            beeAura.osdType = type
            beeAura.osdValue = value
            
            if (type === "volume") {
                beeAura.osdIcon = value === 0 ? "🔇" : "🔊"
                beeAura.osdLabel = "Volume"
            } else if (type === "brightness") {
                beeAura.osdIcon = "☀️"
                beeAura.osdLabel = "Luminosité"
            } else if (type === "mute") {
                beeAura.osdIcon = "🔇"
                beeAura.osdLabel = "Muet"
            } else {
                beeAura.osdIcon = "⌨️"
                beeAura.osdLabel = "Clavier"
            }

            beeAura.visible = true
            beeAura.opacity = 1.0
            beeAura.dashScale = 1.0
            
            // Auto-hide timer
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: {
            beeAura.opacity = 0
            beeAura.dashScale = 0.9
            hideTimer.onFinished: beeAura.visible = false
        }
    }

    // ─── Visuals ────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.9)
        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
        border.width: 1
        scale: beeAura.dashScale

        RowLayout {
            anchors.centerIn: parent
            spacing: 20

            Text {
                text: beeAura.osdIcon
                font.pixelSize: 24
                color: BeeTheme.accent
            }

            Column {
                Layout.fillWidth: true
                spacing: 4
                Text {
                    text: beeAura.osdLabel
                    color: BeeTheme.textSecondary
                    font.pixelSize: 12; font.bold: true
                    horizontalAlignment: Text.AlignLeft
                }
                
                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: BeeTheme.separator
                    
                    Rectangle {
                        width: parent.width * (Math.min(beeAura.osdValue, 100) / 100)
                        height: parent.height
                        radius: 3
                        color: BeeTheme.accent
                        Behavior on width { NumberAnimation { duration: 150 } }
                    }
                }
                
                Text {
                    text: beeAura.osdValue + "%"
                    color: BeeTheme.textPrimary
                    font.pixelSize: 14; font.bold: true; font.family: "monospace"
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
