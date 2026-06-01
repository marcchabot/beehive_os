import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// GeneralTab.qml — 🏠 General Settings + Profiles + Keyboard Shortcuts
// v0.8.35: Performance section + Battery Mode toggle
// ═══════════════════════════════════════════════════════════════

Item {
    id: generalTab

    // ─── i18n shortcut ─────────────────────────────────────────
    readonly property var s: BeeConfig.tr && BeeConfig.tr.settings ? BeeConfig.tr.settings : ({})

    // ─── Profile creation state ────────────────────────────────
    property bool showAddProfile: false
    property string newProfileName: ""
    property string newProfileIcon: "👤"

    readonly property var iconOptions: [
        "👤", "👨‍💻", "👩‍💼", "🧒", "👦", "👧", "👨‍🔧", "👩‍🍳",
        "🎮", "📚", "🎵", "🏃", "🧑‍🎨", "🧑‍🔬", "👨‍🚀", "🦊"
    ]

    ScrollView {
        id: generalScroll
        anchors.fill: parent
        anchors.margins: 16
        clip: true

        ColumnLayout {
            width: generalScroll.availableWidth
            spacing: 16

            // ─── 👥 Profiles Section ──────────────────────────
            Text {
                text: "👥 " + (s.profiles || "Profiles")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            // Profile cards row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Repeater {
                    model: BeeProfiles.profiles

                    delegate: Rectangle {
                        id: profileCard
                        width: 90
                        height: showAddProfile ? 0 : 100
                        radius: 12
                        visible: !showAddProfile || modelData.id === BeeProfiles.activeProfileId

                        // Active border glow
                        color: modelData.id === BeeProfiles.activeProfileId
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.12)
                            : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.08)
                        border.color: modelData.id === BeeProfiles.activeProfileId
                            ? BeeTheme.accent
                            : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.3)
                        border.width: modelData.id === BeeProfiles.activeProfileId ? 2 : 1

                        // Active glow effect
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -2
                            radius: 14
                            color: "transparent"
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                            border.width: modelData.id === BeeProfiles.activeProfileId ? 1 : 0
                            visible: modelData.id === BeeProfiles.activeProfileId
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: modelData.icon || "👤"
                                font.pixelSize: 28
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: modelData.name || modelData.id
                                color: modelData.id === BeeProfiles.activeProfileId
                                    ? BeeTheme.accent
                                    : BeeTheme.textPrimary
                                font.pixelSize: 11
                                font.bold: modelData.id === BeeProfiles.activeProfileId
                                Layout.alignment: Qt.AlignHCenter
                                Layout.maximumWidth: 80
                                elide: Text.ElideRight
                            }
                            // Active indicator dot
                            Rectangle {
                                width: 6; height: 6; radius: 3
                                color: modelData.id === BeeProfiles.activeProfileId
                                    ? BeeTheme.accent
                                    : "transparent"
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.id !== BeeProfiles.activeProfileId) {
                                    BeeProfiles.switchWithTransition(modelData.id)
                                }
                            }
                        }

                        // Transition animation feedback
                        Connections {
                            target: BeeProfiles
                            function onTransitionOpacityChanged() {
                                if (BeeProfiles.transitionActive && modelData.id === BeeProfiles.activeProfileId) {
                                    profileCard.opacity = 1.0 - (1.0 - BeeProfiles.transitionOpacity) * 0.3
                                } else {
                                    profileCard.opacity = 1.0
                                }
                            }
                        }
                    }
                }

                // ─── "+" Add Profile Card ─────────────────────
                Rectangle {
                    width: 90
                    height: 100
                    radius: 12
                    color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.06)
                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "➕"
                            font.pixelSize: 28
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: s.add_profile || "Add"
                            color: BeeTheme.textSecondary
                            font.pixelSize: 11
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            generalTab.showAddProfile = !generalTab.showAddProfile
                            generalTab.newProfileName = ""
                            generalTab.newProfileIcon = "👤"
                        }
                    }
                }
            }

            // ─── Add Profile Inline Form ──────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: showAddProfile ? addFormLayout.implicitHeight + 24 : 0
                visible: showAddProfile
                radius: 10
                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06)
                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                border.width: 1
                clip: true

                ColumnLayout {
                    id: addFormLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Text {
                        text: s.new_profile || "New Profile"
                        color: BeeTheme.accent
                        font.bold: true
                        font.pixelSize: 13
                    }

                    // Name input
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: s.profile_name || "Name:"
                            color: BeeTheme.textPrimary
                            font.pixelSize: 12
                            Layout.preferredWidth: 60
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 30
                            radius: 6
                            color: Qt.rgba(BeeTheme.bg.r, BeeTheme.bg.g, BeeTheme.bg.b, 0.8)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
                            border.width: 1

                            TextInput {
                                id: profileNameInput
                                anchors.fill: parent
                                anchors.margins: 6
                                color: BeeTheme.textPrimary
                                font.pixelSize: 13
                                verticalAlignment: Qt.AlignVCenter
                                maximumLength: 20
                                text: generalTab.newProfileName
                                onTextChanged: generalTab.newProfileName = text
                                Keys.onReturnPressed: _createProfile()
                            }
                        }
                    }

                    // Icon picker
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Text {
                            text: s.profile_icon || "Icon:"
                            color: BeeTheme.textPrimary
                            font.pixelSize: 12
                            Layout.preferredWidth: 60
                        }
                        Repeater {
                            model: generalTab.iconOptions
                            delegate: Rectangle {
                                width: 32; height: 32; radius: 6
                                color: generalTab.newProfileIcon === modelData
                                    ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                                    : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.1)
                                border.color: generalTab.newProfileIcon === modelData
                                    ? BeeTheme.accent
                                    : "transparent"
                                border.width: generalTab.newProfileIcon === modelData ? 1.5 : 0
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.pixelSize: 18
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: generalTab.newProfileIcon = modelData
                                }
                            }
                        }
                    }

                    // Create / Cancel buttons
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            width: 80; height: 30; radius: 8
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                            border.color: BeeTheme.accent; border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: s.create || "Create"
                                color: BeeTheme.accent
                                font.pixelSize: 12; font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: generalTab._createProfile()
                            }
                        }
                        Rectangle {
                            width: 80; height: 30; radius: 8
                            color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.1)
                            border.color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.3); border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: s.cancel || "Cancel"
                                color: BeeTheme.textSecondary
                                font.pixelSize: 12
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: generalTab.showAddProfile = false
                            }
                        }
                    }
                }
            }

            Item { height: 8 }

            // ─── Language ───
            Text {
                text: "🌐 " + (s.language || "Language")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Repeater {
                    model: [{ key: "en", label: "English" }, { key: "fr", label: "Français" }]
                    delegate: Rectangle {
                        width: 100; height: 34; radius: 8
                        color: BeeConfig.uiLang === modelData.key
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                            : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.1)
                        border.color: BeeConfig.uiLang === modelData.key ? BeeTheme.accent : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.2)
                        border.width: BeeConfig.uiLang === modelData.key ? 1.5 : 1
                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: BeeConfig.uiLang === modelData.key ? BeeTheme.accent : BeeTheme.textSecondary
                            font.pixelSize: 13; font.bold: BeeConfig.uiLang === modelData.key
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { BeeConfig.setLang(modelData.key); BeeConfig.saveConfig() }
                        }
                    }
                }
            }

            Item { height: 8 }

            // ─── Startup ───
            Text {
                text: "⚡ " + (s.launch_at_startup || "Startup")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: s.launch_at_startup || "Launch at startup"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.launchAtStartup; onToggled: { BeeConfig.launchAtStartup = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 8 }

            // ─── Keyboard Shortcuts ───
            Text {
                text: "⌨️ " + (s.keyboard_shortcuts || "Keyboard shortcuts")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            Repeater {
                model: [
                    { key: "Super + D", action_en: "Dashboard (MayaDash)", action_fr: "Tableau de bord (MayaDash)" },
                    { key: "Super + Z", action_en: "Search (BeeSearch)", action_fr: "Recherche (BeeSearch)" },
                    { key: "Super + Escape", action_en: "The Hive (Settings)", action_fr: "The Hive (Paramètres)" },
                    { key: "Super + P", action_en: "BeePower", action_fr: "BeePower" },
                    { key: "Super + M", action_en: "Voice assistant (BeeVoice)", action_fr: "Assistant vocal (BeeVoice)" },
                    { key: "F12", action_en: "Toggle theme", action_fr: "Changer de thème" }
                ]
                delegate: RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    Rectangle {
                        width: 140; height: 28; radius: 6
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3); border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: modelData.key
                            color: BeeTheme.accent; font.pixelSize: 11; font.bold: true
                        }
                    }
                    Text {
                        text: BeeConfig.uiLang === "fr" ? modelData.action_fr : modelData.action_en
                        color: BeeTheme.textPrimary; font.pixelSize: 13
                        Layout.fillWidth: true
                    }
                }
            }

            Item { height: 8 }

            // ─── ⚡ Performance Section v0.8.35 ──────────────────────
            Text {
                text: "⚡ " + (s.performance || "Performance")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            // Startup time
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: s.startup_time || "Startup time:"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                Text {
                    text: BeePerformance.startupTimeMs > 0
                        ? (BeePerformance.startupTimeMs + " ms")
                        : (s.not_yet_measured || "—")
                    color: BeePerformance.startupTimeMs > 0 ? BeeTheme.accent : BeeTheme.textSecondary
                    font.pixelSize: 13; font.bold: BeePerformance.startupTimeMs > 0
                }
            }

            // RAM usage
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: s.ram_usage || "RAM usage:"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                Text {
                    text: BeePerformance.ramUsageMb > 0
                        ? (BeePerformance.ramUsageMb.toFixed(1) + " MB")
                        : (s.calculating || "...")
                    color: BeePerformance.ramUsageMb > 0 ? BeeTheme.accent : BeeTheme.textSecondary
                    font.pixelSize: 13; font.bold: BeePerformance.ramUsageMb > 0
                }
            }

            // Idle state
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: s.status || "Status:"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                Text {
                    text: BeePerformance.isIdle
                        ? (s.idle || "Idle")
                        : (s.active || "Active")
                    color: BeePerformance.isIdle ? BeeTheme.textSecondary : "#4CAF50"
                    font.pixelSize: 13; font.bold: true
                }
            }

            Item { height: 8 }

            // ─── 🔋 Battery Mode Section v0.8.35 ────────────────────
            Text {
                text: "🔋 " + (s.battery_mode || "Battery Mode")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            // Battery Mode toggle
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: (s.battery_mode || "Battery Mode") + (BeeConfig.batteryMode ? " ⚡" : "")
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                Switch {
                    checked: BeeConfig.batteryMode
                    onToggled: {
                        BeeConfig.batteryMode = checked
                        // If manual toggle, disable auto-detect
                        if (checked) BeeConfig.batteryModeAuto = false
                        else BeeConfig.batteryModeAuto = true
                        BeeConfig.saveConfig()
                    }
                }
            }

            // Auto-detect toggle
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: s.auto_detect_battery || "Auto-detect battery status"
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                Switch {
                    checked: BeeConfig.batteryModeAuto
                    onToggled: {
                        BeeConfig.batteryModeAuto = checked
                        BeeConfig.saveConfig()
                    }
                }
            }

            // Battery status info
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: (s.battery_status || "Battery") + ": " + BeeConfig.batteryStatus
                    color: BeeTheme.textSecondary; font.pixelSize: 12; Layout.fillWidth: true
                }
                Text {
                    text: BeeConfig.batteryPercentage + "%"
                    color: BeeConfig.batteryPercentage <= 20 ? "#FF5252" : BeeTheme.accent
                    font.pixelSize: 12; font.bold: true
                }
            }

            // Effects when battery mode is active
            Text {
                text: BeeConfig.reducedAnimations
                    ? (s.battery_effects_active || "⚡ Reduced animations, Vibe/Motion disabled")
                    : (s.battery_effects_none || "")
                color: BeeTheme.textSecondary
                font.pixelSize: 11
                font.italic: true
                visible: BeeConfig.reducedAnimations
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Item { height: 8 }

            // ─── 💾 Config Import/Export 🐝 v0.8.36 ──────────────────────
            Text {
                text: "💾 " + (s.config_import_export || "Config Import/Export")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            // Export buttons row
            RowLayout {
                Layout.fillWidth: true; spacing: 10

                // Export Config
                Rectangle {
                    width: 160; height: 38; radius: 10
                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.5)
                    border.width: 1.5

                    RowLayout {
                        anchors.centerIn: parent; spacing: 6
                        Text { text: "📤"; font.pixelSize: 16 }
                        Text {
                            text: s.export_config || "Export Config"
                            color: BeeTheme.accent; font.pixelSize: 12; font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: BeeConfig.exportConfig(false)
                    }
                }

                // Export with Wallpapers
                Rectangle {
                    width: 180; height: 38; radius: 10
                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08)
                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent; spacing: 6
                        Text { text: "🖼️"; font.pixelSize: 16 }
                        Text {
                            text: s.export_with_wallpapers || "Export + Wallpapers"
                            color: BeeTheme.textPrimary; font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: BeeConfig.exportConfig(true)
                    }
                }

                // Import Config
                Rectangle {
                    width: 150; height: 38; radius: 10
                    color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.12)
                    border.color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.4)
                    border.width: 1.5

                    RowLayout {
                        anchors.centerIn: parent; spacing: 6
                        Text { text: "📥"; font.pixelSize: 16 }
                        Text {
                            text: s.import_config || "Import Config"
                            color: BeeTheme.textPrimary; font.pixelSize: 12; font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: importFileDialog.visible = true
                    }
                }
            }

            // Import file path dialog
            Rectangle {
                id: importFileDialog
                visible: false
                Layout.fillWidth: true
                height: importFileDialog.visible ? importFormLayout.implicitHeight + 24 : 0
                radius: 10
                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06)
                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                border.width: 1
                clip: true

                ColumnLayout {
                    id: importFormLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Text {
                        text: s.import_config_file || "Import .bhive file"
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
                                id: importPathInput
                                anchors.fill: parent; anchors.margins: 6
                                color: BeeTheme.textPrimary; font.pixelSize: 12
                                verticalAlignment: Qt.AlignVCenter
                                placeholderText: s.import_path_placeholder || "~/Documents/beehive_backup.bhive"
                                selectByMouse: true
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 8

                        // Merge import (safe)
                        Rectangle {
                            width: 120; height: 32; radius: 8
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                            border.color: BeeTheme.accent; border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: s.import_merge || "Merge Import"
                                color: BeeTheme.accent; font.pixelSize: 11; font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var path = importPathInput.text.trim()
                                    if (path.length > 0) {
                                        BeeConfig.importConfig(path, false)
                                        importFileDialog.visible = false
                                    }
                                }
                            }
                        }

                        // Overwrite import (dangerous)
                        Rectangle {
                            width: 130; height: 32; radius: 8
                            color: Qt.rgba(1.0, 0.3, 0.3, 0.1)
                            border.color: "#FF5252"; border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: s.import_overwrite || "⚠ Overwrite"
                                color: "#FF5252"; font.pixelSize: 11; font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var path = importPathInput.text.trim()
                                    if (path.length > 0) {
                                        BeeConfig.importConfig(path, true)
                                        importFileDialog.visible = false
                                    }
                                }
                            }
                        }

                        // Cancel
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
                                onClicked: importFileDialog.visible = false
                            }
                        }
                    }

                    // Status message
                    Text {
                        visible: BeeConfig.configExportStatus !== "idle" || BeeConfig.configImportStatus !== "idle"
                        text: {
                            if (BeeConfig.configExportStatus === "done")
                                return "✅ " + (s.export_success || "Export successful") + ": " + BeeConfig.configExportMessage
                            if (BeeConfig.configExportStatus === "error")
                                return "❌ " + (BeeConfig.configExportMessage || "Export failed")
                            if (BeeConfig.configExportStatus === "exporting")
                                return "⏳ " + (s.exporting || "Exporting...")
                            if (BeeConfig.configImportStatus === "done")
                                return "✅ " + (s.import_success || "Import successful")
                            if (BeeConfig.configImportStatus === "error")
                                return "❌ " + (BeeConfig.configImportMessage || "Import failed")
                            if (BeeConfig.configImportStatus === "importing")
                                return "⏳ " + (s.importing || "Importing...")
                            return ""
                        }
                        color: {
                            if (BeeConfig.configExportStatus === "done" || BeeConfig.configImportStatus === "done") return "#4CAF50"
                            if (BeeConfig.configExportStatus === "error" || BeeConfig.configImportStatus === "error") return "#FF5252"
                            return BeeTheme.textSecondary
                        }
                        font.pixelSize: 11; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
            }

            // Import description text
            Text {
                text: s.config_import_desc || "Export your full configuration or import from a .bhive file. Merge preserves your data, Overwrite replaces everything."
                color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.6)
                font.pixelSize: 10; font.italic: true
                Layout.fillWidth: true; wrapMode: Text.WordWrap
            }
        }
    }

    // ─── Helper: Create a new profile ──────────────────────────
    function _createProfile() {
        var name = newProfileName.trim()
        if (name.length === 0) return
        var icon = newProfileIcon
        var id = BeeProfiles.createProfile(name, icon)
        if (id) {
            showAddProfile = false
            newProfileName = ""
            newProfileIcon = "👤"
            BeeBarState.dispatchNotification(
                "👤 " + (s.profile_created || "Profile Created"),
                name,
                icon
            )
        }
    }
}