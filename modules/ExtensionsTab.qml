import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// ExtensionsTab.qml — 🔌 Extensions & Plugins
// ═══════════════════════════════════════════════════════════════

Item {
    id: extensionsTab

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: extensionsTab.width - 32
            spacing: 16

            Text {
                text: "🔌 " + (BeeConfig.uiLang === "fr" ? "Extensions" : "Extensions")
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

            Item { height: 16 }

            Text {
                text: (BeeConfig.uiLang === "fr" ? "Les extensions seront disponibles dans une mise à jour future." : "Extensions will be available in a future update.")
                color: BeeTheme.textSecondary; font.pixelSize: 12; font.italic: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }
}