import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// HistoryTab.qml — 📋 Activity Journal
// ═══════════════════════════════════════════════════════════════

Item {
    id: historyTab

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: historyTab.width - 32
            spacing: 16

            Text {
                text: "📋 " + (BeeConfig.uiLang === "fr" ? "Journal d'activité" : "Activity journal")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Activer le journal" : "Enable history"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.historyEnabled; onToggled: { BeeConfig.historyEnabled = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 16 }

            Text {
                text: (BeeConfig.uiLang === "fr" ? "L'historique des actions sera disponible ici." : "Action history will appear here.")
                color: BeeTheme.textSecondary; font.pixelSize: 12; font.italic: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }
}