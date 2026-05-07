import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// AppearanceTab.qml — 🎨 Appearance Settings
// ═══════════════════════════════════════════════════════════════

Item {
    id: appearanceTab

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: appearanceTab.width - 32
            spacing: 16

            // Section: Theme
            Text {
                text: "🎨 " + (BeeConfig.uiLang === "fr" ? "Thème" : "Theme")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Repeater {
                    model: [
                        { key: "HoneyDark", label: "🌙 Dark", labelFr: "🌙 Sombre" },
                        { key: "HoneyLight", label: "☀️ Light", labelFr: "☀️ Clair" }
                    ]
                    delegate: Rectangle {
                        width: 110; height: 36; radius: 8
                        color: BeeConfig.mode === modelData.key
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                            : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.1)
                        border.color: BeeConfig.mode === modelData.key ? BeeTheme.accent : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.2)
                        border.width: BeeConfig.mode === modelData.key ? 1.5 : 1
                        Text {
                            anchors.centerIn: parent
                            text: BeeConfig.uiLang === "fr" ? modelData.labelFr : modelData.label
                            color: BeeConfig.mode === modelData.key ? BeeTheme.accent : BeeTheme.textSecondary
                            font.pixelSize: 13; font.bold: BeeConfig.mode === modelData.key
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { BeeConfig.mode = modelData.key; BeeConfig.saveConfig() }
                        }
                    }
                }
            }

            Item { height: 8 }

            // Section: Adaptive
            Text {
                text: "🌅 " + (BeeConfig.uiLang === "fr" ? "Mode adaptatif" : "Adaptive mode")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: (BeeConfig.uiLang === "fr" ? "Ajuster le thème selon l'heure" : "Adjust theme based on time of day")
                    color: BeeTheme.textPrimary; font.pixelSize: 13
                    Layout.fillWidth: true
                }
                Switch {
                    checked: BeeConfig.adaptiveEnabled
                    onToggled: { BeeConfig.adaptiveEnabled = checked; BeeConfig.saveConfig() }
                }
            }
        }
    }
}