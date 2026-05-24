import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// AppearanceTab.qml — 🎨 Appearance & Theme Settings
// ═══════════════════════════════════════════════════════════════

Item {
    id: appearanceTab

    // ─── i18n shortcut ─────────────────────────────────────────
    readonly property var s: BeeConfig.tr && BeeConfig.tr.settings ? BeeConfig.tr.settings : ({})

    ScrollView {
        id: appearanceScroll
        anchors.fill: parent
        anchors.margins: 16
        clip: true

        ColumnLayout {
            width: appearanceScroll.availableWidth
            spacing: 16

            // ─── Theme Mode ───
            Text {
                text: "🎨 " + (s.theme || "Theme")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Repeater {
                    model: [
                        { key: "HoneyDark", icon: "🌙", labelEn: "Dark", labelFr: "Sombre" },
                        { key: "HoneyLight", icon: "☀️", labelEn: "Light", labelFr: "Clair" }
                    ]
                    delegate: Rectangle {
                        width: 130; height: 70; radius: 12
                        color: BeeConfig.mode === modelData.key
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                            : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.08)
                        border.color: BeeConfig.mode === modelData.key
                            ? BeeTheme.accent
                            : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.5)
                        border.width: BeeConfig.mode === modelData.key ? 2 : 1.5
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        Behavior on border.width { NumberAnimation { duration: 200 } }

                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 4
                            Text {
                                text: modelData.icon; font.pixelSize: 24
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: BeeConfig.uiLang === "fr" ? modelData.labelFr : modelData.labelEn
                                color: BeeConfig.mode === modelData.key ? BeeTheme.accent : BeeTheme.textSecondary
                                font.pixelSize: 12; font.bold: BeeConfig.mode === modelData.key
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onClicked: { BeeTheme.setMode(modelData.key); BeeConfig.mode = modelData.key; BeeConfig.saveConfig() }
                        }
                    }
                }
            }

            Item { height: 4 }

            // ─── Nectar Sync (Adaptive Theme) ───
            Text {
                text: "🍯 " + (s.nectar_sync || "Nectar Sync — Adaptive Theme")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: s.nectar_sync_title || "Nectar Sync 🍯"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: s.nectar_sync_desc || "Automatic theme adaptation to the chosen wallpaper"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch {
                    checked: BeeConfig.adaptiveEnabled
                    onToggled: { BeeConfig.adaptiveEnabled = checked; BeeConfig.saveConfig() }
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: s.auto_day_night || "Auto day/night schedule"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: s.auto_day_night_desc || "🌙 Dark at night → ☀️ Light in the morning"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch {
                    checked: BeeConfig.nectarAutoSchedule
                    onToggled: { BeeConfig.nectarAutoSchedule = checked; BeeConfig.saveConfig() }
                }
            }

            Item { height: 4 }

            // ─── Nectar Auto-Theme (Time/Weather) 🐝🎨☀️🌧️ v0.8.25 ───
            Text {
                text: "🎨☀️🌧️ " + (s.auto_theme || "Nectar Auto-Theme")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            // Auto-theme mode selector
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Text {
                    text: s.auto_theme_mode || "Mode:"
                    color: BeeTheme.textSecondary; font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter
                }
                Repeater {
                    model: [
                        { key: "off", icon: "⛔", labelEn: "Off", labelFr: "Désactivé" },
                        { key: "timeOfDay", icon: "☀️🌙", labelEn: "Time of Day", labelFr: "Heure du jour" },
                        { key: "weather", icon: "🌧️", labelEn: "Weather", labelFr: "Météo" },
                        { key: "combined", icon: "🎨", labelEn: "Combined", labelFr: "Combiné" }
                    ]
                    delegate: Rectangle {
                        width: 90; height: 50; radius: 8
                        color: BeeConfig.autoThemeMode === modelData.key
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                            : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.08)
                        border.color: BeeConfig.autoThemeMode === modelData.key
                            ? BeeTheme.accent
                            : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.5)
                        border.width: BeeConfig.autoThemeMode === modelData.key ? 2 : 1
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        Behavior on border.width { NumberAnimation { duration: 200 } }

                        RowLayout {
                            anchors.centerIn: parent; spacing: 3
                            Text { text: modelData.icon; font.pixelSize: 14 }
                            Text {
                                text: BeeConfig.uiLang === "fr" ? modelData.labelFr : modelData.labelEn
                                color: BeeConfig.autoThemeMode === modelData.key ? BeeTheme.accent : BeeTheme.textSecondary
                                font.pixelSize: 9; font.bold: BeeConfig.autoThemeMode === modelData.key
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { BeeConfig.autoThemeMode = modelData.key; BeeConfig.saveConfig() }
                        }
                    }
                }
            }

            Text {
                text: {
                    var mode = BeeConfig.autoThemeMode
                    if (mode === "off") return s.auto_theme_off_desc || "Auto-theme disabled"
                    if (mode === "timeOfDay") return s.auto_theme_timeofday_desc || "Theme follows time of day (light by day, dark by night)"
                    if (mode === "weather") return s.auto_theme_weather_desc || "Accent follows weather (sunny=amber, rain=blue-grey)"
                    if (mode === "combined") return s.auto_theme_combined_desc || "Time of day + weather accent combined"
                    return ""
                }
                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                font.pixelSize: 10; font.italic: true
                Layout.fillWidth: true; wrapMode: Text.WordWrap
            }

            Item { height: 4 }

            // ─── Color Therapy ───
            Text {
                text: "✨ " + (s.color_therapy || "Color Therapy")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: s.color_cycle || "Color cycle"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: s.color_cycle_desc || "Slow accent color pulse cycle for a calming effect"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch {
                    checked: BeeConfig.colorTherapyEnabled
                    onToggled: { BeeConfig.colorTherapyEnabled = checked; BeeConfig.saveConfig() }
                }
            }

            Item { height: 4 }

            // ─── Community Theme Export 🐝🎨 v0.8.36 ────────────────────
            Text {
                text: "🎨✨ " + (s.community_theme || "Community Theme")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: s.export_my_theme || "Export my theme"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: s.export_theme_desc || "Create a shareable .bhivetheme file with your visual settings"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }

                Rectangle {
                    width: 160; height: 38; radius: 10
                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.5)
                    border.width: 1.5

                    RowLayout {
                        anchors.centerIn: parent; spacing: 6
                        Text { text: "✨"; font.pixelSize: 16 }
                        Text {
                            text: s.export_theme_btn || "Export Theme"
                            color: BeeTheme.accent; font.pixelSize: 12; font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: BeeConfig.exportTheme()
                    }
                }
            }

            // Import theme button
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: s.import_theme || "Import theme"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: s.import_theme_desc || "Apply a .bhivetheme file from the community"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }

                Rectangle {
                    width: 160; height: 38; radius: 10
                    color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.12)
                    border.color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.4)
                    border.width: 1.5

                    RowLayout {
                        anchors.centerIn: parent; spacing: 6
                        Text { text: "📥"; font.pixelSize: 16 }
                        Text {
                            text: s.import_theme_btn || "Import Theme"
                            color: BeeTheme.textPrimary; font.pixelSize: 12; font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: themeImportDialog.visible = true
                    }
                }
            }

            // Theme import path dialog
            Rectangle {
                id: themeImportDialog
                visible: false
                Layout.fillWidth: true
                height: themeImportDialog.visible ? themeImportFormLayout.implicitHeight + 24 : 0
                radius: 10
                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06)
                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                border.width: 1
                clip: true

                ColumnLayout {
                    id: themeImportFormLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Text {
                        text: s.import_theme_file || "Import .bhivetheme file"
                        color: BeeTheme.accent
                        font.bold: true; font.pixelSize: 13
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 8

                        Text {
                            text: s.file_path || "Path:"
                            color: BeeTheme.textPrimary; font.pixelSize: 12
                            Layout.preferredWidth: 60
                        }

                        Rectangle {
                            Layout.fillWidth: true; height: 30; radius: 6
                            color: Qt.rgba(BeeTheme.bg.r, BeeTheme.bg.g, BeeTheme.bg.b, 0.8)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
                            border.width: 1

                            TextInput {
                                id: themeImportPathInput
                                anchors.fill: parent; anchors.margins: 6
                                color: BeeTheme.textPrimary; font.pixelSize: 12
                                verticalAlignment: Qt.AlignVCenter
                                placeholderText: s.theme_path_placeholder || "~/Documents/beehive_theme.bhivetheme"
                                placeholderTextColor: BeeTheme.textSecondary
                                selectByMouse: true
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 8

                        Rectangle {
                            width: 120; height: 32; radius: 8
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                            border.color: BeeTheme.accent; border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: s.apply_theme || "Apply Theme"
                                color: BeeTheme.accent; font.pixelSize: 11; font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var path = themeImportPathInput.text.trim()
                                    if (path.length > 0) {
                                        BeeConfig.importTheme(path)
                                        themeImportDialog.visible = false
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: 80; height: 32; radius: 8
                            color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.1)
                            border.color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.3); border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: s.cancel || "Cancel"
                                color: BeeTheme.textSecondary; font.pixelSize: 12
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: themeImportDialog.visible = false
                            }
                        }
                    }
                }
            }

            // Theme export/import status
            Text {
                visible: BeeConfig.configExportStatus !== "idle" && (BeeConfig.configExportStatus === "exporting" || BeeConfig.configExportStatus === "done" || BeeConfig.configExportStatus === "error")
                text: {
                    if (BeeConfig.configExportStatus === "done")
                        return "✅ " + (s.theme_exported || "Theme exported!")
                    if (BeeConfig.configExportStatus === "error")
                        return "❌ " + (BeeConfig.configExportMessage || "Export failed")
                    if (BeeConfig.configExportStatus === "exporting")
                        return "⏳ " + (s.exporting || "Exporting...")
                    return ""
                }
                color: {
                    if (BeeConfig.configExportStatus === "done") return "#4CAF50"
                    if (BeeConfig.configExportStatus === "error") return "#FF5252"
                    return BeeTheme.textSecondary
                }
                font.pixelSize: 11; font.italic: true
                Layout.fillWidth: true; wrapMode: Text.WordWrap
            }
        }
    }
}