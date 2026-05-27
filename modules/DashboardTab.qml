import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// DashboardTab.qml — 📊 Dashboard Settings (MayaDash, BeeMotion, BeeVibe, etc.)
// Restores all lost settings from the BeeSettings → BeeConfig refactoring
// ═══════════════════════════════════════════════════════════════

Item {
    id: dashboardTab

    // ─── i18n shortcut ─────────────────────────────────────────
    readonly property var s: BeeConfig.tr && BeeConfig.tr.settings ? BeeConfig.tr.settings : ({})
    readonly property var sd: BeeConfig.tr && BeeConfig.tr.settings && BeeConfig.tr.settings.dashboard ? BeeConfig.tr.settings.dashboard : ({})

    ScrollView {
        id: dashboardScroll
        anchors.fill: parent
        anchors.margins: 16
        clip: true

        ColumnLayout {
            width: dashboardScroll.availableWidth
            spacing: 16

            // ─── 🐝 Dashboard Title ───
            Text {
                text: "🐝 " + (sd.dash_title || "Dashboard Title")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: sd.dash_title || "Dashboard Title"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                TextField {
                    id: dashTitleField
                    text: BeeConfig.dashTitle
                    color: BeeTheme.textPrimary
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 220
                    background: Rectangle {
                        radius: 8
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08)
                        border.color: dashTitleField.activeFocus ? BeeTheme.accent : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                        border.width: dashTitleField.activeFocus ? 2 : 1
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

            // ─── 🎬 BeeMotion (Parallax 3D) ───
            Text {
                text: "🎬 " + (sd.motion || "Parallax 3D (BeeMotion)")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: sd.motion || "Parallax 3D (BeeMotion)"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: BeeConfig.uiLang === "fr"
                            ? "Effet de parallaxe 3D sur le tableau de bord"
                            : "3D parallax effect on the dashboard"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch {
                    checked: BeeConfig.motionMode
                    onToggled: { BeeConfig.motionMode = checked; BeeConfig.saveConfig() }
                }
            }

            Item { height: 4 }

            // ─── 🎵 BeeVibe (Audio Visualizer) ───
            Text {
                text: "🎵 " + (sd.vibe || "Audio Visualizer (BeeVibe)")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            // Vibe toggle
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: sd.vibe || "Audio Visualizer (BeeVibe)"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: BeeConfig.uiLang === "fr"
                            ? "Visualiseur de spectre audio en arrière-plan"
                            : "Audio spectrum visualizer in background"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch {
                    checked: BeeConfig.vibeMode
                    onToggled: { BeeConfig.vibeMode = checked; BeeConfig.saveConfig() }
                }
            }

            // Vibe backend selector (visible when vibe is on)
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.vibeMode
                Text {
                    text: sd.vibe_backend || "Audio backend"
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

            // Vibe X-Ray toggle (visible when vibe is on)
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.vibeMode
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: sd.vibe_xray || "X-ray mode"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: BeeConfig.uiLang === "fr"
                            ? "Révèle les couleurs du fond d'écran à travers le visualiseur"
                            : "Reveal wallpaper colors through the visualizer"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch {
                    checked: BeeConfig.vibeXray
                    onToggled: { BeeConfig.vibeXray = checked; BeeConfig.saveConfig() }
                }
            }

            // X-Ray intensity slider (visible when X-Ray is on)
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.vibeMode && BeeConfig.vibeXray
                Text {
                    text: sd.vibe_xray_intensity || "X-ray intensity"
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
                onMoved: { BeeConfig.vibeXrayIntensity = Math.round(value * 100) / 100; BeeConfig.saveConfig() }
            }

            // X-Ray blend selector (visible when X-Ray is on)
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.vibeMode && BeeConfig.vibeXray
                Text {
                    text: sd.vibe_xray_blend || "X-ray blend"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                RowLayout {
                    spacing: 6
                    Repeater {
                        model: [
                            { key: "Normal", label: "Normal" },
                            { key: "Screen", label: "Screen" },
                            { key: "Overlay", label: "Overlay" },
                            { key: "Multiply", label: "Multiply" }
                        ]
                        delegate: Rectangle {
                            width: 72; height: 30; radius: 8
                            color: BeeConfig.vibeXrayBlend === modelData.key
                                ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                            border.color: BeeConfig.vibeXrayBlend === modelData.key
                                ? BeeTheme.accent
                                : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                            border.width: BeeConfig.vibeXrayBlend === modelData.key ? 2 : 1
                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: BeeConfig.vibeXrayBlend === modelData.key ? BeeTheme.accent : BeeTheme.textSecondary
                                font.pixelSize: 11; font.bold: BeeConfig.vibeXrayBlend === modelData.key
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: { BeeConfig.vibeXrayBlend = modelData.key; BeeConfig.saveConfig() }
                            }
                        }
                    }
                }
            }

            Item { height: 4 }

            // ─── 🕰️ Analog Clock ───
            Text {
                text: "🕰️ " + (sd.analog_clock || "Analog Clock")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: sd.analog_clock || "Analog Clock"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: BeeConfig.uiLang === "fr"
                            ? "Horloge analogique au centre du tableau de bord"
                            : "Analog clock in the center of the dashboard"
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

            // ─── 🕐 Clock Format ───
            Text {
                text: "🕐 " + (sd.clock_format || "Clock Format")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: sd.clock_format || "Time format"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                RowLayout {
                    spacing: 6
                    Repeater {
                        model: [
                            { key: "24h", label: "24h" },
                            { key: "12h", label: "12h" }
                        ]
                        delegate: Rectangle {
                            width: 64; height: 30; radius: 8
                            color: BeeConfig.clockFormat === modelData.key
                                ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                            border.color: BeeConfig.clockFormat === modelData.key
                                ? BeeTheme.accent
                                : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                            border.width: BeeConfig.clockFormat === modelData.key ? 2 : 1
                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: BeeConfig.clockFormat === modelData.key ? BeeTheme.accent : BeeTheme.textSecondary
                                font.pixelSize: 11; font.bold: BeeConfig.clockFormat === modelData.key
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: { BeeConfig.clockFormat = modelData.key; BeeConfig.saveConfig() }
                            }
                        }
                    }
                }
            }

            Item { height: 4 }

            // ─── 📊 BeeBar Stats ───
            Text {
                text: "📊 " + (sd.bar_stats || "Bar Statistics")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            // CPU
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: sd.show_cpu || "CPU"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.showCpu; onToggled: { BeeConfig.showCpu = checked; BeeConfig.saveConfig() } }
            }
            // RAM
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: sd.show_ram || "RAM"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.showRam; onToggled: { BeeConfig.showRam = checked; BeeConfig.saveConfig() } }
            }
            // Network
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: sd.show_net || "Network"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.showNet; onToggled: { BeeConfig.showNet = checked; BeeConfig.saveConfig() } }
            }
            // Disk
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: sd.show_disk || "Disk"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.showDisk; onToggled: { BeeConfig.showDisk = checked; BeeConfig.saveConfig() } }
            }
            // Battery
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: sd.show_battery || "Battery"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.showBattery; onToggled: { BeeConfig.showBattery = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 4 }

            // ─── 🔋 Battery Mode ───
            Text {
                text: "🔋 " + (sd.battery_mode || "Battery Saver")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: sd.battery_mode || "Battery Saver"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: BeeConfig.uiLang === "fr"
                            ? "Réduit les animations pour économiser la batterie"
                            : "Reduce animations to save battery"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch {
                    checked: BeeConfig.batteryMode
                    onToggled: { BeeConfig.batteryMode = checked; BeeConfig.saveConfig() }
                }
            }

            // Auto battery saver
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.batteryMode
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: sd.battery_auto || "Auto-enable on low battery"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: BeeConfig.uiLang === "fr"
                            ? "Active automatiquement le mode économie quand la batterie est faible"
                            : "Automatically enable saver mode when battery is low"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch {
                    checked: BeeConfig.batteryModeAuto
                    onToggled: { BeeConfig.batteryModeAuto = checked; BeeConfig.saveConfig() }
                }
            }

            // Battery threshold slider (visible when battery mode is on)
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.batteryMode
                Text {
                    text: sd.battery_threshold || "Threshold (%)"
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
                visible: BeeConfig.batteryMode
                from: 5; to: 50; stepSize: 5
                value: BeeConfig.batteryThreshold
                onMoved: { BeeConfig.batteryThreshold = Math.round(value); BeeConfig.saveConfig() }
            }

            Item { height: 4 }

            // ─── 📐 Hot Corners ───
            Text {
                text: "📐 " + (sd.hot_corners || "Hot Corners")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: sd.hot_corners || "Hot Corners"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: BeeConfig.uiLang === "fr"
                            ? "Raccourcis déclenchés depuis les coins de l'écran"
                            : "Shortcuts triggered from screen corners"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch {
                    checked: BeeConfig.cornersMode
                    onToggled: { BeeConfig.cornersMode = checked; BeeConfig.saveConfig() }
                }
            }

            Item { height: 4 }

            // ─── 🎛️ Contextual Bar ───
            Text {
                text: "🎛️ " + (sd.contextual_bar || "Contextual Bar")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: sd.contextual_bar || "Contextual Bar"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: BeeConfig.uiLang === "fr"
                            ? "La barre s'adapte au contexte de l'application active"
                            : "Bar adapts to the active app context"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch {
                    checked: BeeConfig.contextualBar
                    onToggled: { BeeConfig.contextualBar = checked; BeeConfig.saveConfig() }
                }
            }

            // ─── Auto-Icons Toggle 🐝🖼️ v0.8.33 ────────────────
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: sd.auto_icons || "Auto-Icons"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: BeeConfig.uiLang === "fr"
                            ? "Icônes automatiques depuis les fichiers .desktop"
                            : "Automatic icons from .desktop files"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch {
                    checked: BeeConfig.autoIconsEnabled
                    onToggled: { BeeConfig.autoIconsEnabled = checked; BeeConfig.saveConfig() }
                }
            }

            Item { height: 4 }

            // ─── 🌤️ Weather Settings ───
            Text {
                text: "🌤️ " + (sd.weather || "Weather")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            // City
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: sd.weather_city || "City"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                TextField {
                    id: dashWeatherCityField
                    text: BeeConfig.weatherCity
                    color: BeeTheme.textPrimary
                    font.pixelSize: 13
                    Layout.preferredWidth: 220
                    placeholderText: "Blainville"
                    placeholderTextColor: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.5)
                    background: Rectangle {
                        radius: 8
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08)
                        border.color: dashWeatherCityField.activeFocus ? BeeTheme.accent : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                        border.width: dashWeatherCityField.activeFocus ? 2 : 1
                    }
                    onAccepted: { BeeConfig.weatherCity = text; BeeConfig.saveConfig() }
                    onActiveFocusChanged: {
                        if (!activeFocus && text !== BeeConfig.weatherCity) { BeeConfig.weatherCity = text; BeeConfig.saveConfig() }
                    }
                }
            }

            // Unit selector
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: sd.weather_unit || "Unit"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                RowLayout {
                    spacing: 6
                    Repeater {
                        model: [
                            { key: "metric", label: "°C" },
                            { key: "imperial", label: "°F" }
                        ]
                        delegate: Rectangle {
                            width: 64; height: 30; radius: 8
                            color: BeeConfig.weatherUnit === modelData.key
                                ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                            border.color: BeeConfig.weatherUnit === modelData.key
                                ? BeeTheme.accent
                                : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                            border.width: BeeConfig.weatherUnit === modelData.key ? 2 : 1
                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: BeeConfig.weatherUnit === modelData.key ? BeeTheme.accent : BeeTheme.textSecondary
                                font.pixelSize: 11; font.bold: BeeConfig.weatherUnit === modelData.key
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: { BeeConfig.weatherUnit = modelData.key; BeeConfig.saveConfig() }
                            }
                        }
                    }
                }
            }

            // Language selector
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: sd.weather_lang || "Language"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                RowLayout {
                    spacing: 6
                    Repeater {
                        model: [
                            { key: "fr", label: "FR" },
                            { key: "en", label: "EN" }
                        ]
                        delegate: Rectangle {
                            width: 64; height: 30; radius: 8
                            color: BeeConfig.weatherLang === modelData.key
                                ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                            border.color: BeeConfig.weatherLang === modelData.key
                                ? BeeTheme.accent
                                : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                            border.width: BeeConfig.weatherLang === modelData.key ? 2 : 1
                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: BeeConfig.weatherLang === modelData.key ? BeeTheme.accent : BeeTheme.textSecondary
                                font.pixelSize: 11; font.bold: BeeConfig.weatherLang === modelData.key
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: { BeeConfig.weatherLang = modelData.key; BeeConfig.saveConfig() }
                            }
                        }
                    }
                }
            }

            // Latitude
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: sd.weather_lat || "Latitude"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                TextField {
                    id: dashWeatherLatField
                    text: BeeConfig.weatherLat.toString()
                    color: BeeTheme.textPrimary
                    font.pixelSize: 13
                    Layout.preferredWidth: 220
                    placeholderText: "45.67"
                    placeholderTextColor: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.5)
                    background: Rectangle {
                        radius: 8
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08)
                        border.color: dashWeatherLatField.activeFocus ? BeeTheme.accent : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                        border.width: dashWeatherLatField.activeFocus ? 2 : 1
                    }
                    onAccepted: { BeeConfig.weatherLat = parseFloat(text) || 0; BeeConfig.saveConfig() }
                    onActiveFocusChanged: {
                        if (!activeFocus) { BeeConfig.weatherLat = parseFloat(text) || 0; BeeConfig.saveConfig() }
                    }
                }
            }

            // Longitude
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: sd.weather_lon || "Longitude"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                TextField {
                    id: dashWeatherLonField
                    text: BeeConfig.weatherLon.toString()
                    color: BeeTheme.textPrimary
                    font.pixelSize: 13
                    Layout.preferredWidth: 220
                    placeholderText: "-73.88"
                    placeholderTextColor: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.5)
                    background: Rectangle {
                        radius: 8
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08)
                        border.color: dashWeatherLonField.activeFocus ? BeeTheme.accent : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                        border.width: dashWeatherLonField.activeFocus ? 2 : 1
                    }
                    onAccepted: { BeeConfig.weatherLon = parseFloat(text) || 0; BeeConfig.saveConfig() }
                    onActiveFocusChanged: {
                        if (!activeFocus) { BeeConfig.weatherLon = parseFloat(text) || 0; BeeConfig.saveConfig() }
                    }
                }
            }
        }
    }
}