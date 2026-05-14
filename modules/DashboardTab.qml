import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// DashboardTab.qml — 📊 Dashboard Settings
// Dashboard title, BeeMotion, BeeVibe, Clock, BeeBar stats,
// Battery mode, Hot corners, Contextual bar
// ═══════════════════════════════════════════════════════════════

Item {
    id: dashboardTab

    // ─── i18n shortcut ─────────────────────────────────────────
    readonly property var s: BeeConfig.tr && BeeConfig.tr.settings ? BeeConfig.tr.settings : ({})

    ScrollView {
        id: dashboardScroll
        anchors.fill: parent
        anchors.margins: 16
        clip: true

        ColumnLayout {
            width: dashboardScroll.availableWidth
            spacing: 16

            // ─── Dashboard Title ───
            Text {
                text: "🐝 " + (s.dash_title || "Dashboard Title")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: s.dash_title_label || "Title"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.minimumWidth: 80
                }
                TextField {
                    id: dashTitleField
                    Layout.fillWidth: true
                    text: BeeConfig.dashTitle
                    color: BeeTheme.textPrimary
                    font.pixelSize: 13
                    placeholderText: s.dash_title_placeholder || "My Dashboard"
                    placeholderTextColor: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.4)
                    background: Rectangle {
                        radius: 8
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                        border.color: dashTitleField.activeFocus ? BeeTheme.accent : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                        border.width: dashTitleField.activeFocus ? 2 : 1
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        Behavior on border.width { NumberAnimation { duration: 200 } }
                    }
                    onAccepted: {
                        BeeConfig.dashTitle = text
                        BeeConfig.saveConfig()
                    }
                    onActiveFocusChanged: {
                        if (!activeFocus && text !== BeeConfig.dashTitle) {
                            BeeConfig.dashTitle = text
                            BeeConfig.saveConfig()
                        }
                    }
                }
            }

            Item { height: 4 }

            // ─── BeeMotion (Parallax 3D) ───
            Text {
                text: "🎬 " + (s.bee_motion || "BeeMotion (Parallax 3D)")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: s.bee_motion || "Parallax 3D"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: s.bee_motion_desc || "3D parallax effect that follows mouse movement"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch { checked: BeeConfig.motionMode; onToggled: { BeeConfig.motionMode = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 4 }

            // ─── BeeVibe (Audio Visualizer) ───
            Text {
                text: "🎵 " + (s.vibe || "Vibe (Audio Visualizer)")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: s.vibe_visualizer || "Audio visualizer"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: s.vibe_visualizer_desc || "Audio spectrum visualizer in background"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch { checked: BeeConfig.vibeMode; onToggled: { BeeConfig.vibeMode = checked; BeeConfig.saveConfig() } }
            }

            // Vibe backend selector
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.vibeMode
                Text {
                    text: s.vibe_backend || "Backend"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                RowLayout {
                    spacing: 6
                    Repeater {
                        model: [
                            { key: "auto", label: "Auto" },
                            { key: "cava-bg", label: "Cava BG" },
                            { key: "cava", label: "Cava" },
                            { key: "simulation", label: "Sim" }
                        ]
                        delegate: Rectangle {
                            width: 64; height: 30; radius: 8
                            color: BeeConfig.vibeBackend === modelData.key
                                ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                            border.color: BeeConfig.vibeBackend === modelData.key
                                ? BeeTheme.accent
                                : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                            border.width: BeeConfig.vibeBackend === modelData.key ? 2 : 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: BeeConfig.vibeBackend === modelData.key ? BeeTheme.accent : BeeTheme.textSecondary
                                font.pixelSize: 11; font.bold: BeeConfig.vibeBackend === modelData.key
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: { BeeConfig.vibeBackend = modelData.key; BeeConfig.saveConfig() }
                            }
                        }
                    }
                }
            }

            // X-Ray mode
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.vibeMode
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: s.vibe_xray || "X-Ray mode"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: s.vibe_xray_desc || "Reveal wallpaper colors through the visualizer"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch { checked: BeeConfig.vibeXray; onToggled: { BeeConfig.vibeXray = checked; BeeConfig.saveConfig() } }
            }

            // X-Ray intensity
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.vibeMode && BeeConfig.vibeXray
                Text {
                    text: s.vibe_intensity || "X-Ray intensity"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                Text {
                    text: Math.round(BeeConfig.vibeXrayIntensity * 100) + "%"
                    color: BeeTheme.accent; font.pixelSize: 13; font.bold: true
                    Layout.minimumWidth: 45; horizontalAlignment: Text.AlignRight
                }
            }
            Slider {
                Layout.fillWidth: true
                visible: BeeConfig.vibeMode && BeeConfig.vibeXray
                from: 0.1; to: 1.0; stepSize: 0.05
                value: BeeConfig.vibeXrayIntensity
                onMoved: { BeeConfig.vibeXrayIntensity = value; BeeConfig.saveConfig() }
            }

            // X-Ray blend mode
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.vibeMode && BeeConfig.vibeXray
                Text {
                    text: s.vibe_xray_blend || "X-Ray blend"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                RowLayout {
                    spacing: 6
                    Repeater {
                        model: ["Normal", "Screen", "Multiply", "Overlay"]
                        delegate: Rectangle {
                            width: 72; height: 28; radius: 7
                            color: BeeConfig.vibeXrayBlend === modelData
                                ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                            border.color: BeeConfig.vibeXrayBlend === modelData
                                ? BeeTheme.accent
                                : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                            border.width: BeeConfig.vibeXrayBlend === modelData ? 2 : 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: BeeConfig.vibeXrayBlend === modelData ? BeeTheme.accent : BeeTheme.textSecondary
                                font.pixelSize: 10; font.bold: BeeConfig.vibeXrayBlend === modelData
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: { BeeConfig.vibeXrayBlend = modelData; BeeConfig.saveConfig() }
                            }
                        }
                    }
                }
            }

            Item { height: 4 }

            // ─── Analog Clock ───
            Text {
                text: "🕰️ " + (s.clock || "Clock")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: s.analog_clock || "Analog clock"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: s.analog_clock_desc || "Show analog clock in the center of the dashboard"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch { checked: BeeConfig.analogClock; onToggled: { BeeConfig.analogClock = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 4 }

            // ─── BeeBar System Indicators ───
            Text {
                text: "📊 " + (s.beebar_stats || "BeeBar Indicators")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout { Layout.fillWidth: true; spacing: 12
                Text { text: "CPU"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.showCpu; onToggled: { BeeConfig.showCpu = checked; BeeConfig.saveConfig() } }
            }
            RowLayout { Layout.fillWidth: true; spacing: 12
                Text { text: "RAM"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.showRam; onToggled: { BeeConfig.showRam = checked; BeeConfig.saveConfig() } }
            }
            RowLayout { Layout.fillWidth: true; spacing: 12
                Text { text: s.disk || "Disk"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.showDisk; onToggled: { BeeConfig.showDisk = checked; BeeConfig.saveConfig() } }
            }
            RowLayout { Layout.fillWidth: true; spacing: 12
                Text { text: s.network || "Network"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.showNet; onToggled: { BeeConfig.showNet = checked; BeeConfig.saveConfig() } }
            }
            RowLayout { Layout.fillWidth: true; spacing: 12
                Text { text: s.battery || "Battery"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.showBattery; onToggled: { BeeConfig.showBattery = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 4 }

            // ─── Battery Mode ───
            Text {
                text: "🔋 " + (s.battery_mode || "Battery & Power Saver")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: s.battery_mode || "Power saver mode"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: s.battery_mode_desc || "Reduces animations and visual effects"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch { checked: BeeConfig.batteryMode; onToggled: { BeeConfig.batteryMode = checked; BeeConfig.saveConfig() } }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: s.battery_saver || "Auto-detect"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: s.battery_saver_desc || "Auto-detect battery vs AC power status"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch { checked: BeeConfig.batteryModeAuto; onToggled: { BeeConfig.batteryModeAuto = checked; BeeConfig.saveConfig() } }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: !BeeConfig.batteryModeAuto
                Text {
                    text: s.battery_threshold || "Saver threshold (%)"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                Text {
                    text: BeeConfig.batteryThreshold + "%"
                    color: BeeTheme.accent; font.pixelSize: 13; font.bold: true
                    Layout.minimumWidth: 45; horizontalAlignment: Text.AlignRight
                }
            }
            Slider {
                Layout.fillWidth: true
                visible: !BeeConfig.batteryModeAuto
                from: 5; to: 50; stepSize: 5
                value: BeeConfig.batteryThreshold
                onMoved: { BeeConfig.batteryThreshold = value; BeeConfig.saveConfig() }
            }

            Item { height: 4 }

            // ─── Hot Corners ───
            Text {
                text: "📐 " + (s.corners || "Hot Corners")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: s.corners || "Hot Corners"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: s.corners_desc || "Quick actions by pointing at screen corners"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch { checked: BeeConfig.cornersMode; onToggled: { BeeConfig.cornersMode = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 4 }

            // ─── Contextual Bar ───
            Text {
                text: "🎛️ " + (s.bar_behavior || "Bar behavior")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: s.contextual_bar || "Contextual bar"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: s.contextual_bar_desc || "Bar adapts to the active app context"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch { checked: BeeConfig.contextualBar; onToggled: { BeeConfig.contextualBar = checked; BeeConfig.saveConfig() } }
            }
        }
    }
}