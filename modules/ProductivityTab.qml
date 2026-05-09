import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// ProductivityTab.qml — 📅 Productivity Settings
// Calendar, Alarms, Voice, Sound
// ═══════════════════════════════════════════════════════════════

Item {
    id: productivityTab

    property string _fr: BeeConfig.uiLang === "fr"

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: productivityTab.width - 32
            spacing: 16

            // ═══════════════════════════════════════════════════
            // Section: Calendar
            // ═══════════════════════════════════════════════════
            Text {
                text: "📅 " + (_fr ? "Calendrier" : "Calendar")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: _fr ? "Widget événements" : "Events widget"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.eventsEnabled; onToggled: { BeeConfig.eventsEnabled = checked; BeeConfig.saveConfig() } }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: _fr ? "Synchronisation CalDAV" : "CalDAV sync"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.caldavEnabled; onToggled: { BeeConfig.caldavEnabled = checked; BeeConfig.saveConfig() } }
            }

            // Calendar reminders
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: _fr ? "Rappels de rendez-vous" : "Calendar reminders"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: _fr ? "Notification avant chaque événement du calendrier" : "Notification before each calendar event"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch { checked: BeeConfig.beeCalendarReminderEnabled; onToggled: { BeeConfig.beeCalendarReminderEnabled = checked; BeeConfig.saveConfig() } }
            }

            // Reminder advance
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.beeCalendarReminderEnabled
                Text {
                    text: _fr ? "Avance rappel (min)" : "Reminder advance (min)"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                Text {
                    text: BeeConfig.beeCalendarReminderMinutes + " min"
                    color: BeeTheme.accent; font.pixelSize: 13; font.bold: true
                    Layout.minimumWidth: 50; horizontalAlignment: Text.AlignRight
                }
            }
            Slider {
                Layout.fillWidth: true
                visible: BeeConfig.beeCalendarReminderEnabled
                from: 1; to: 60; stepSize: 1
                value: BeeConfig.beeCalendarReminderMinutes
                onMoved: { BeeConfig.beeCalendarReminderMinutes = Math.round(value); BeeConfig.saveConfig() }
            }

            // CalDAV auto-sync
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.caldavEnabled
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: _fr ? "Synchronisation automatique" : "Auto-sync"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: _fr ? "Synchronise CalDAV toutes les " + BeeConfig.caldavAutoSyncIntervalMin + " min" : "Sync CalDAV every " + BeeConfig.caldavAutoSyncIntervalMin + " min"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch { checked: BeeConfig.caldavAutoSync; onToggled: { BeeConfig.caldavAutoSync = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 4 }

            // ═══════════════════════════════════════════════════
            // Section: Alarms
            // ═══════════════════════════════════════════════════
            Text {
                text: "⏰ " + (_fr ? "Alarmes" : "Alarms")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: _fr ? "Alarmes activées" : "Alarms enabled"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.alarmEnabled; onToggled: { BeeConfig.alarmEnabled = checked; BeeConfig.saveConfig() } }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: _fr ? "Avance rappel (min)" : "Reminder advance (min)"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                Text {
                    text: BeeConfig.alarmAdvanceMin + " min"
                    color: BeeTheme.accent; font.pixelSize: 13; font.bold: true
                    Layout.minimumWidth: 50; horizontalAlignment: Text.AlignRight
                }
            }
            Slider {
                Layout.fillWidth: true
                from: 1; to: 60; stepSize: 1
                value: BeeConfig.alarmAdvanceMin
                onMoved: { BeeConfig.alarmAdvanceMin = Math.round(value); BeeConfig.saveConfig() }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: _fr ? "Durée répétition (min)" : "Snooze duration (min)"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                Text {
                    text: BeeConfig.alarmSnoozeMin + " min"
                    color: BeeTheme.accent; font.pixelSize: 13; font.bold: true
                    Layout.minimumWidth: 50; horizontalAlignment: Text.AlignRight
                }
            }
            Slider {
                Layout.fillWidth: true
                from: 1; to: 30; stepSize: 1
                value: BeeConfig.alarmSnoozeMin
                onMoved: { BeeConfig.alarmSnoozeMin = Math.round(value); BeeConfig.saveConfig() }
            }

            Item { height: 4 }

            // ═══════════════════════════════════════════════════
            // Section: Voice Assistant (BeeVoice)
            // ═══════════════════════════════════════════════════
            Text {
                text: "🎤 " + (_fr ? "Assistant vocal (BeeVoice)" : "Voice Assistant (BeeVoice)")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: _fr ? "Assistant vocal" : "Voice assistant"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: _fr ? "Activation par Super+M ou raccourci vocal" : "Activate with Super+M or voice shortcut"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch { checked: BeeConfig.voiceEnabled; onToggled: { BeeConfig.voiceEnabled = checked; BeeConfig.saveConfig() } }
            }

            // Voice backend selector
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.voiceEnabled
                Text {
                    text: _fr ? "Synthèse vocale" : "TTS backend"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                RowLayout {
                    spacing: 6
                    Repeater {
                        model: [
                            { key: "edge-tts", label: "Edge-TTS" },
                            { key: "elevenlabs", label: "ElevenLabs" }
                        ]
                        delegate: Rectangle {
                            width: 80; height: 30; radius: 8
                            color: BeeConfig.voiceTtsBackend === modelData.key
                                ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                            border.color: BeeConfig.voiceTtsBackend === modelData.key
                                ? BeeTheme.accent
                                : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                            border.width: BeeConfig.voiceTtsBackend === modelData.key ? 2 : 1
                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: BeeConfig.voiceTtsBackend === modelData.key ? BeeTheme.accent : BeeTheme.textSecondary
                                font.pixelSize: 11; font.bold: BeeConfig.voiceTtsBackend === modelData.key
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: { BeeConfig.voiceTtsBackend = modelData.key; BeeConfig.saveConfig() }
                            }
                        }
                    }
                }
            }

            // Whisper model selector
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.voiceEnabled
                Text {
                    text: _fr ? "Modèle Whisper (STT)" : "Whisper model (STT)"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                RowLayout {
                    spacing: 6
                    Repeater {
                        model: ["tiny", "base", "small", "medium"]
                        delegate: Rectangle {
                            width: 60; height: 28; radius: 7
                            color: BeeConfig.voiceWhisperModel === modelData
                                ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                            border.color: BeeConfig.voiceWhisperModel === modelData
                                ? BeeTheme.accent
                                : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                            border.width: BeeConfig.voiceWhisperModel === modelData ? 2 : 1
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: BeeConfig.voiceWhisperModel === modelData ? BeeTheme.accent : BeeTheme.textSecondary
                                font.pixelSize: 10; font.bold: BeeConfig.voiceWhisperModel === modelData
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: { BeeConfig.voiceWhisperModel = modelData; BeeConfig.saveConfig() }
                            }
                        }
                    }
                }
            }

            // Record duration
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.voiceEnabled
                Text {
                    text: _fr ? "Durée d'enregistrement (s)" : "Record duration (s)"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                Text {
                    text: BeeConfig.voiceRecordDuration + "s"
                    color: BeeTheme.accent; font.pixelSize: 13; font.bold: true
                    Layout.minimumWidth: 35; horizontalAlignment: Text.AlignRight
                }
            }
            Slider {
                Layout.fillWidth: true
                visible: BeeConfig.voiceEnabled
                from: 3; to: 15; stepSize: 1
                value: BeeConfig.voiceRecordDuration
                onMoved: { BeeConfig.voiceRecordDuration = Math.round(value); BeeConfig.saveConfig() }
            }

            Item { height: 4 }

            // ═══════════════════════════════════════════════════
            // Section: Sound (BeeSound)
            // ═══════════════════════════════════════════════════
            Text {
                text: "🔊 " + (_fr ? "Sons système (BeeSound)" : "System sounds (BeeSound)")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: _fr ? "Mode nuit automatique" : "Auto night mode"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: _fr ? "Réduit le volume des sons entre " + BeeConfig.soundNightStartHour + "h et " + BeeConfig.soundNightEndHour + "h" : "Reduce sound volume between " + BeeConfig.soundNightStartHour + ":00 and " + BeeConfig.soundNightEndHour + ":00"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch { checked: BeeConfig.soundNightMode; onToggled: { BeeConfig.soundNightMode = checked; BeeConfig.saveConfig() } }
            }

            // Day volume
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: _fr ? "Volume jour" : "Day volume"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                Text {
                    text: Math.round(BeeConfig.soundDayGain * 100) + "%"
                    color: BeeTheme.accent; font.pixelSize: 13; font.bold: true
                    Layout.minimumWidth: 45; horizontalAlignment: Text.AlignRight
                }
            }
            Slider {
                Layout.fillWidth: true
                from: 0.0; to: 1.0; stepSize: 0.05
                value: BeeConfig.soundDayGain
                onMoved: { BeeConfig.soundDayGain = Math.round(value * 100) / 100; BeeConfig.saveConfig() }
            }

            // Night volume
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.soundNightMode
                Text {
                    text: _fr ? "Volume nuit" : "Night volume"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                Text {
                    text: Math.round(BeeConfig.soundNightGain * 100) + "%"
                    color: BeeTheme.accent; font.pixelSize: 13; font.bold: true
                    Layout.minimumWidth: 45; horizontalAlignment: Text.AlignRight
                }
            }
            Slider {
                Layout.fillWidth: true
                visible: BeeConfig.soundNightMode
                from: 0.0; to: 1.0; stepSize: 0.05
                value: BeeConfig.soundNightGain
                onMoved: { BeeConfig.soundNightGain = Math.round(value * 100) / 100; BeeConfig.saveConfig() }
            }
        }
    }
}