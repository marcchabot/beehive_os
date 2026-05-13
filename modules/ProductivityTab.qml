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

    // ─── i18n shortcut ─────────────────────────────────────────
    readonly property var s: BeeConfig.tr && BeeConfig.tr.settings ? BeeConfig.tr.settings : ({})

    ScrollView {
        id: productivityScroll
        anchors.fill: parent
        anchors.margins: 16
        clip: true

        ColumnLayout {
            width: productivityScroll.availableWidth
            spacing: 16

            // ─── Calendar ───
            Text {
                text: "📅 " + (s.calendar || "Calendar")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: s.events_widget || "Events widget"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.eventsEnabled; onToggled: { BeeConfig.eventsEnabled = checked; BeeConfig.saveConfig() } }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: s.caldav_sync || "CalDAV sync"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.caldavEnabled; onToggled: { BeeConfig.caldavEnabled = checked; BeeConfig.saveConfig() } }
            }

            // Calendar reminders
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: s.calendar_reminders || "Calendar reminders"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: s.calendar_reminders_desc || "Notification before each calendar event"
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
                    text: s.reminder_advance || "Reminder advance (min)"
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
                        text: s.auto_sync || "Auto-sync"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: (s.auto_sync_desc || "Sync CalDAV every %1 min").arg(BeeConfig.caldavAutoSyncIntervalMin)
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch { checked: BeeConfig.caldavAutoSync; onToggled: { BeeConfig.caldavAutoSync = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 4 }

            // ─── Alarms ───
            Text {
                text: "⏰ " + (s.alarms || "Alarms")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: s.alarms_enabled || "Alarms enabled"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.alarmEnabled; onToggled: { BeeConfig.alarmEnabled = checked; BeeConfig.saveConfig() } }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: s.alarm_advance || "Reminder advance (min)"
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
                    text: s.alarm_snooze || "Snooze duration (min)"
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

            // ─── Voice Assistant (BeeVoice) ───
            Text {
                text: "🎤 " + (s.voice_assistant || "Voice Assistant (BeeVoice)")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: s.voice_assistant_title || "Voice assistant"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: s.voice_assistant_desc || "Activate with Super+M or voice shortcut"
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
                    text: s.tts_backend || "TTS backend"
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
                    text: s.whisper_model || "Whisper model (STT)"
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
                    text: s.record_duration || "Record duration (s)"
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

            // ─── Sound (BeeSound) ───
            Text {
                text: "🔊 " + (s.sounds || "System sounds (BeeSound)")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: s.sound_night_mode || "Auto night mode"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: (s.sound_night_mode_desc || "Reduce sound volume between %1 and %2").arg(BeeConfig.soundNightStartHour + (BeeConfig.uiLang === "fr" ? "h" : ":00")).arg(BeeConfig.soundNightEndHour + (BeeConfig.uiLang === "fr" ? "h" : ":00"))
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
                    text: s.sound_day_gain || "Day volume"
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
                    text: s.sound_night_gain || "Night volume"
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