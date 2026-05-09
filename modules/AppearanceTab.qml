import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// AppearanceTab.qml — 🎨 Appearance & Theme Settings
// ═══════════════════════════════════════════════════════════════

Item {
    id: appearanceTab

    property string _fr: BeeConfig.uiLang === "fr"

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: appearanceTab.width - 32
            spacing: 16

            // ─── Theme Mode ───
            Text {
                text: "🎨 " + (_fr ? "Thème" : "Theme")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Repeater {
                    model: [
                        { key: "HoneyDark", icon: "🌙", label: "Dark", labelFr: "Sombre" },
                        { key: "HoneyLight", icon: "☀️", label: "Light", labelFr: "Clair" }
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
                                text: _fr ? modelData.labelFr : modelData.label
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
                text: "🍯 " + (_fr ? "Nectar Sync — Thème adaptatif" : "Nectar Sync — Adaptive Theme")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: _fr ? "Nectar Sync 🍯" : "Nectar Sync 🍯"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: _fr ? "Adaptation automatique du thème au fond d'écran" : "Automatic theme adaptation to the chosen wallpaper"
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
                        text: _fr ? "Mode jour/nuit automatique" : "Auto day/night schedule"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: _fr ? "🌙 Sombre le soir → ☀️ Clair le matin" : "🌙 Dark at night → ☀️ Light in the morning"
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

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: _fr ? "Thème selon l'heure" : "Time-of-day theming"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: _fr ? "Ajuste les couleurs automatiquement selon le moment de la journée" : "Automatically adjust colors based on time of day"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch {
                    checked: BeeConfig.timeOfDayEnabled
                    onToggled: { BeeConfig.timeOfDayEnabled = checked; BeeConfig.saveConfig() }
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: _fr ? "Ambiance météo" : "Weather ambient"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: _fr ? "Adapte le thème aux conditions météorologiques locales" : "Adapt theme to local weather conditions"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch {
                    checked: BeeConfig.weatherAmbientEnabled
                    onToggled: { BeeConfig.weatherAmbientEnabled = checked; BeeConfig.saveConfig() }
                }
            }

            Item { height: 4 }

            // ─── Color Therapy ───
            Text {
                text: "✨ " + (_fr ? "Thérapie chromatique" : "Color Therapy")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: _fr ? "Cycle chromatique" : "Color cycle"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: _fr ? "Pulsation lente des couleurs d'accent pour un effet apaisant" : "Slow accent color pulse cycle for a calming effect"
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
        }
    }
}