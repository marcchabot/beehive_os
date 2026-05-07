import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// ShortcutsTab.qml — ⌨️ Keyboard Shortcuts
// ═══════════════════════════════════════════════════════════════

Item {
    id: shortcutsTab

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: shortcutsTab.width - 32
            spacing: 16

            Text {
                text: "⌨️ " + (BeeConfig.uiLang === "fr" ? "Raccourcis clavier" : "Keyboard shortcuts")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            // Shortcuts list
            Repeater {
                model: [
                    { key: "Super + D", action: BeeConfig.uiLang === "fr" ? "Tableau de bord (MayaDash)" : "Dashboard (MayaDash)" },
                    { key: "Super + Z", action: BeeConfig.uiLang === "fr" ? "Recherche (BeeSearch)" : "Search (BeeSearch)" },
                    { key: "Super + Escape", action: "The Hive (Settings)" },
                    { key: "Super + P", action: "BeePower" },
                    { key: "Super + M", action: BeeConfig.uiLang === "fr" ? "Assistant vocal (BeeVoice)" : "Voice assistant (BeeVoice)" },
                    { key: "F12", action: BeeConfig.uiLang === "fr" ? "Changer de thème" : "Toggle theme" }
                ]
                delegate: RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    Rectangle {
                        width: 140; height: 28; radius: 6
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3); border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: modelData.key
                            color: BeeTheme.accent; font.pixelSize: 11; font.bold: true
                        }
                    }
                    Text {
                        text: modelData.action
                        color: BeeTheme.textPrimary; font.pixelSize: 13
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}