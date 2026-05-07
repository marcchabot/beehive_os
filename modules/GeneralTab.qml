import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// GeneralTab.qml — 🏠 General Settings
// ═══════════════════════════════════════════════════════════════

Item {
    id: generalTab

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: generalTab.width - 32
            spacing: 16

            // Section: Language
            Text {
                text: "🌐 " + (BeeConfig.uiLang === "fr" ? "Langue" : "Language")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Repeater {
                    model: [{ key: "en", label: "English" }, { key: "fr", label: "Français" }]
                    delegate: Rectangle {
                        width: 100; height: 34; radius: 8
                        color: BeeConfig.uiLang === modelData.key
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                            : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.1)
                        border.color: BeeConfig.uiLang === modelData.key ? BeeTheme.accent : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.2)
                        border.width: BeeConfig.uiLang === modelData.key ? 1.5 : 1
                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: BeeConfig.uiLang === modelData.key ? BeeTheme.accent : BeeTheme.textSecondary
                            font.pixelSize: 13; font.bold: BeeConfig.uiLang === modelData.key
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { BeeConfig.uiLang = modelData.key; BeeConfig.saveConfig() }
                        }
                    }
                }
            }

            Item { height: 8 }

            // Section: Startup
            Text {
                text: "⚡ " + (BeeConfig.uiLang === "fr" ? "Démarrage" : "Startup")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: (BeeConfig.uiLang === "fr" ? "Lancer au démarrage" : "Launch at startup")
                    color: BeeTheme.textPrimary; font.pixelSize: 13
                    Layout.fillWidth: true
                }
                Switch {
                    checked: BeeConfig.launchAtStartup
                    onToggled: { BeeConfig.launchAtStartup = checked; BeeConfig.saveConfig() }
                }
            }
        }
    }
}