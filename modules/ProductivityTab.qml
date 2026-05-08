import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// ProductivityTab.qml — 📅 Productivity Settings
// ═══════════════════════════════════════════════════════════════

Item {
    id: productivityTab

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: productivityTab.width - 32
            spacing: 16

            // Section: Calendar
            Text {
                text: "📅 " + (BeeConfig.uiLang === "fr" ? "Calendrier" : "Calendar")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Widget événements" : "Events widget"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.eventsEnabled; onToggled: { BeeConfig.eventsEnabled = checked; BeeConfig.saveConfig() } }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Synchronisation CalDAV" : "CalDAV sync"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.caldavEnabled; onToggled: { BeeConfig.caldavEnabled = checked; BeeConfig.saveConfig() } }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Rappels" : "Reminders"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.alarmEnabled; onToggled: { BeeConfig.alarmEnabled = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 8 }

            // Section: Focus
            Text {
                text: "🎯 " + (BeeConfig.uiLang === "fr" ? "Mode concentration" : "Focus mode")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Activer le mode concentration" : "Enable focus mode"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.focusMode; onToggled: { BeeConfig.focusMode = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 8 }

            // Section: Alarm settings
            Text {
                text: "⏰ " + (BeeConfig.uiLang === "fr" ? "Paramètres d'alarme" : "Alarm settings")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            // Alarm advance minutes
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: (BeeConfig.uiLang === "fr" ? "Avance rappel (min)" : "Reminder advance (min)")
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                Text {
                    text: BeeConfig.alarmAdvanceMin + " min"
                    color: BeeTheme.accent; font.pixelSize: 13; font.bold: true
                    Layout.minimumWidth: 50
                    horizontalAlignment: Text.AlignRight
                }
            }
            Slider {
                Layout.fillWidth: true
                from: 1; to: 60; stepSize: 1
                value: BeeConfig.alarmAdvanceMin
                onMoved: { BeeConfig.alarmAdvanceMin = Math.round(value); BeeConfig.saveConfig() }
            }

            Item { height: 4 }

            // Snooze duration
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: (BeeConfig.uiLang === "fr" ? "Durée répétition (min)" : "Snooze duration (min)")
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                Text {
                    text: BeeConfig.alarmSnoozeMin + " min"
                    color: BeeTheme.accent; font.pixelSize: 13; font.bold: true
                    Layout.minimumWidth: 50
                    horizontalAlignment: Text.AlignRight
                }
            }
            Slider {
                Layout.fillWidth: true
                from: 1; to: 30; stepSize: 1
                value: BeeConfig.alarmSnoozeMin
                onMoved: { BeeConfig.alarmSnoozeMin = Math.round(value); BeeConfig.saveConfig() }
            }
        }
    }
}