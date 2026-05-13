import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// BarWidgetsTab.qml — 📊 Bar & Widgets Settings
// Toggles pour la BeeBar, horloge, vibe, corners, batterie
// ═══════════════════════════════════════════════════════════════

Item {
    id: barWidgetsTab

    // ─── i18n shortcut ─────────────────────────────────────────
    readonly property var s: BeeConfig.tr && BeeConfig.tr.settings ? BeeConfig.tr.settings : ({})

    ScrollView {
        id: barWidgetsScroll
        anchors.fill: parent
        anchors.margins: 16
        clip: true

        ColumnLayout {
            width: barWidgetsScroll.availableWidth
            spacing: 16

            // ─── Clock ───
            Text {
                text: "🕐 " + (s.clock || "Clock")
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
                Switch {
                    checked: BeeConfig.analogClock
                    onToggled: { BeeConfig.analogClock = checked; BeeConfig.saveConfig() }
                }
            }

            Item { height: 4 }

            // ─── System indicators ───
            Text {
                text: "📟 " + (s.system_indicators || "System indicators")
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

            // ─── Bar behavior ───
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

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: s.stealth_mode || "Stealth mode"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: s.stealth_mode_desc || "Minimal bar, icons only"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch { checked: BeeConfig.stealthMode; onToggled: { BeeConfig.stealthMode = checked; BeeConfig.saveConfig() } }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: s.focus_mode || "Focus mode"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: s.focus_mode_desc || "Hide distractions, minimal notifications"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch { checked: BeeConfig.focusMode; onToggled: { BeeConfig.focusMode = checked; BeeConfig.saveConfig() } }
            }

            // ─── Vibe (Audio Visualizer) ───
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
                Text {
                    text: s.vibe_backend || "Backend"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                RowLayout {
                    spacing: 6
                    Repeater {
                        model: ["auto", "cava-bg", "cava"]
                        delegate: Rectangle {
                            width: 72; height: 30; radius: 8
                            color: BeeConfig.vibeBackend === modelData
                                ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                            border.color: BeeConfig.vibeBackend === modelData
                                ? BeeTheme.accent
                                : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                            border.width: BeeConfig.vibeBackend === modelData ? 2 : 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: BeeConfig.vibeBackend === modelData ? BeeTheme.accent : BeeTheme.textSecondary
                                font.pixelSize: 11; font.bold: BeeConfig.vibeBackend === modelData
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: { BeeConfig.vibeBackend = modelData; BeeConfig.saveConfig() }
                            }
                        }
                    }
                }
            }

            // X-Ray mode
            RowLayout {
                Layout.fillWidth: true; spacing: 12
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
                visible: BeeConfig.vibeXray
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
                visible: BeeConfig.vibeXray
                from: 0.1; to: 1.0; stepSize: 0.05
                value: BeeConfig.vibeXrayIntensity
                onMoved: { BeeConfig.vibeXrayIntensity = value; BeeConfig.saveConfig() }
            }

            // X-Ray blend mode
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.vibeXray
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

            // ─── Battery & Power Saver ───
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
                text: "🔲 " + (s.corners || "Hot Corners")
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

            // ─── Contextual Blur 🌫️ ─────────────────────
            RowLayout {
                spacing: 10
                Layout.fillWidth: true
                ColumnLayout {
                    spacing: 1
                    Text {
                        text: s.contextual_blur || "Contextual blur"
                        color: BeeTheme.textPrimary; font.pixelSize: 12; font.bold: true
                        Behavior on color { ColorAnimation { duration: 600 } }
                    }
                    Text {
                        text: s.contextual_blur_desc || "Blur overlay panels for depth"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch { checked: BeeConfig.contextualBlurEnabled; onToggled: { BeeConfig.contextualBlurEnabled = checked; BeeConfig.saveConfig() } }
            }

            // ─── Blur Intensity Slider 🎚️ ─────────────
            RowLayout {
                spacing: 10
                Layout.fillWidth: true
                visible: BeeConfig.contextualBlurEnabled
                ColumnLayout {
                    spacing: 1
                    Text {
                        text: s.blur_intensity || "Blur intensity"
                        color: BeeTheme.textPrimary; font.pixelSize: 12; font.bold: true
                        Behavior on color { ColorAnimation { duration: 600 } }
                    }
                    Slider {
                        from: 0.1; to: 1.0; stepSize: 0.05
                        value: BeeConfig.contextualBlurIntensity
                        onMoved: { BeeConfig.contextualBlurIntensity = value; BeeConfig.saveConfig() }
                        Layout.fillWidth: true
                        Layout.minimumWidth: 120
                    }
                }
            }
        }
    }
}