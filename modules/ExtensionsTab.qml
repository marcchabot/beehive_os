import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// ExtensionsTab.qml — 🧩 Extensions & Plugins
// ═══════════════════════════════════════════════════════════════

Item {
    id: extensionsTab

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        clip: true

        ColumnLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 12
            spacing: 16

            Text {
                text: "🧩 " + (BeeConfig.uiLang === "fr" ? "Extensions" : "Extensions")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Activer les plugins communautaires" : "Enable community plugins"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.pluginsEnabled; onToggled: { BeeConfig.pluginsEnabled = checked; BeeConfig.saveConfig() } }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Mise à jour automatique" : "Auto-update"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.pluginAutoUpdate; onToggled: { BeeConfig.pluginAutoUpdate = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 24 }

            // Coming soon placeholder
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                radius: 16
                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08)
                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "🧩"
                        font.pixelSize: 40
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: BeeConfig.uiLang === "fr"
                            ? "Les extensions arrivent bientôt"
                            : "Extensions coming soon"
                        color: BeeTheme.textPrimary
                        font.pixelSize: 15
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: BeeConfig.uiLang === "fr"
                            ? "Bee-Hive OS supportera les plugins communautaires"
                            : "Bee-Hive OS will support community plugins"
                        color: BeeTheme.textSecondary
                        font.pixelSize: 12
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}