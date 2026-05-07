import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// BarWidgetsTab.qml — 📊 Bar & Widgets Settings
// ═══════════════════════════════════════════════════════════════

Item {
    id: barWidgetsTab

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: barWidgetsTab.width - 32
            spacing: 16

            // Section: Bar
            Text {
                text: "📊 " + (BeeConfig.uiLang === "fr" ? "Barre & Widgets" : "Bar & Widgets")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Barre contextuelle" : "Contextual bar"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.contextualBar; onToggled: { BeeConfig.contextualBar = checked; BeeConfig.saveConfig() } }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Mode furtif" : "Stealth mode"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.stealthMode; onToggled: { BeeConfig.stealthMode = checked; BeeConfig.saveConfig() } }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Mode concentration" : "Focus mode"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.focusMode; onToggled: { BeeConfig.focusMode = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 8 }

            // Section: Indicators
            Text {
                text: "📟 " + (BeeConfig.uiLang === "fr" ? "Indicateurs" : "Indicators")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout { Layout.fillWidth: true; spacing: 12; Text { text: "CPU"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true } Switch { checked: BeeConfig.showCpu; onToggled: { BeeConfig.showCpu = checked; BeeConfig.saveConfig() } } }
            RowLayout { Layout.fillWidth: true; spacing: 12; Text { text: "RAM"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true } Switch { checked: BeeConfig.showRam; onToggled: { BeeConfig.showRam = checked; BeeConfig.saveConfig() } } }
            RowLayout { Layout.fillWidth: true; spacing: 12; Text { text: "DISK"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true } Switch { checked: BeeConfig.showDisk; onToggled: { BeeConfig.showDisk = checked; BeeConfig.saveConfig() } } }
            RowLayout { Layout.fillWidth: true; spacing: 12; Text { text: "NET"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true } Switch { checked: BeeConfig.showNet; onToggled: { BeeConfig.showNet = checked; BeeConfig.saveConfig() } } }
            RowLayout { Layout.fillWidth: true; spacing: 12; Text { text: "BAT"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true } Switch { checked: BeeConfig.showBattery; onToggled: { BeeConfig.showBattery = checked; BeeConfig.saveConfig() } } }
        }
    }
}