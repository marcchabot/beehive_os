import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// ═══════════════════════════════════════════════════════════════
// BeeSettings.qml — Panneau de configuration Bee-Hive OS 🐝⚙️
// v0.5 : i18n intégré — sélecteur FR/EN + toutes chaînes traduites
// ═══════════════════════════════════════════════════════════════

Rectangle {
    id: settingsRoot
    width: 450
    height: 680
    radius: 24

    // ─── Handy shortcut to settings translations ──────
    property var _s: BeeConfig.tr.settings || {}

    // ─── Fond et bordure adaptatifs au thème ──────────────────
    color: BeeTheme.mode === "HoneyDark"
        ? Qt.rgba(0.05, 0.05, 0.07, 0.95)
        : Qt.rgba(0.97, 0.95, 0.92, 0.97)
    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
    border.width: 1
    visible: false

    anchors.centerIn: parent

    Behavior on color        { ColorAnimation  { duration: 600 } }
    Behavior on border.color { ColorAnimation  { duration: 600 } }

    // ─── Signals to shell.qml ────────────────────────────────
    signal cornersToggled(bool val)
    signal motionToggled(bool val)
    signal vibeToggled(bool val)
    signal stealthToggled(bool val)
    signal focusToggled(bool val)

    // ─── Header ───────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 20

        RowLayout {
            spacing: 15
            Text { text: "⚙️"; font.pixelSize: 24 }
            Text {
                text: settingsRoot._s.title || "Bee-Hive Settings"
                color: BeeTheme.accent
                font { bold: true; pixelSize: 20; letterSpacing: 1 }
                Layout.fillWidth: true
                Behavior on color { ColorAnimation { duration: 600 } }
            }
        }

        // Bouton fermeture (Top Right)
        Rectangle {
            id: closeRect
            anchors { right: parent.right; top: parent.top; margins: 12 }
            z: 100
            width: 32; height: 32; radius: 16
            color: closeHov.containsMouse
                ? Qt.rgba(1.0, 0.3, 0.3, 0.2)
                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
            border.color: closeHov.containsMouse
                ? Qt.rgba(1.0, 0.3, 0.3, 0.5)
                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                text: "✕"; anchors.centerIn: parent
                color: closeHov.containsMouse ? "#ff5555" : BeeTheme.accent
                font { pixelSize: 14; bold: true }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            MouseArea {
                id: closeHov; anchors.fill: parent
                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                onClicked: settingsRoot.visible = false
            }
        }

        Rectangle {
            height: 1; Layout.fillWidth: true
            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
            Behavior on color { ColorAnimation { duration: 600 } }
        }

        // ─── Options ──────────────────────────────────────────
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: optionsColumn.height
            clip: true

            ColumnLayout {
                id: optionsColumn
                width: parent.width
                spacing: 25

                // Template réutilisable pour une ligne de réglage
                component SettingRow: RowLayout {
                    property string label:   ""
                    property string desc:    ""
                    property bool   checked: false
                    signal toggled(bool val)

                    spacing: 20

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: label
                            color: BeeTheme.textPrimary
                            font { bold: true; pixelSize: 14 }
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                        Text {
                            text: desc
                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.4)
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                    Switch {
                        checked: parent.checked
                        onCheckedChanged: parent.toggled(checked)
                    }
                }

                // ── BeePalette — v0.5 : transitions animées ───
                SettingRow {
                    label:   settingsRoot._s.palette   || "BeePalette 🎨"
                    desc:    settingsRoot._s.palette_desc || "Switch between HoneyDark 🌙 and HoneyLight ☀️."
                    checked: BeeTheme.mode === "HoneyLight"
                    onToggled: (val) => {
                        BeeTheme.setMode(val ? "HoneyLight" : "HoneyDark")
                        BeeConfig.saveConfig()
                    }
                }

                // ── Nectar Sync 🍯 — v0.6 ─────────────────────
                SettingRow {
                    label:   settingsRoot._s.nectar_sync      || "Nectar Sync 🍯"
                    desc:    settingsRoot._s.nectar_sync_desc  || "Automatic theme adaptation to the chosen wallpaper."
                    checked: BeeTheme.nectarSync
                    onToggled: (val) => {
                        BeeTheme.nectarSync = val
                        BeeConfig.saveConfig()
                    }
                }

                // ── BeeMotion ─────────────────────────────────
                SettingRow {
                    label:   settingsRoot._s.motion      || "BeeMotion (Parallax)"
                    desc:    settingsRoot._s.motion_desc  || "3D depth effect on the MayaDash."
                    checked: BeeConfig.motionMode
                    onToggled: (val) => {
                        BeeConfig.motionMode = val
                        BeeConfig.saveConfig()
                        settingsRoot.motionToggled(val)
                    }
                }

                // ── BeeVibe ───────────────────────────────────
                SettingRow {
                    label:   settingsRoot._s.vibe      || "BeeVibe (Audio)"
                    desc:    settingsRoot._s.vibe_desc  || "Audio visualizer integrated into the cells."
                    checked: BeeConfig.vibeMode
                    onToggled: (val) => settingsRoot.vibeToggled(val)
                }

                // ── Bee-Hive Time (Analog) ─────────────────────
                SettingRow {
                    label:   settingsRoot._s.clock      || "Bee-Hive Time (Horloge) 🕰️"
                    desc:    settingsRoot._s.clock_desc  || "Afficher l'horloge analogique au centre du tableau de bord."
                    checked: BeeConfig.analogClock
                    onToggled: (val) => {
                        BeeConfig.analogClock = val
                        BeeConfig.saveConfig()
                    }
                }

                // ── Focus Mode ─────────────────────────────────
                SettingRow {
                    label:   settingsRoot._s.focus_mode  || "Mode Focus 🎯"
                    desc:    settingsRoot._s.focus_desc   || "Hides the dashboard, clock, and events."
                    checked: BeeConfig.focusMode
                    onToggled: (val) => {
                        BeeConfig.focusMode = val
                        BeeConfig.saveConfig()
                        settingsRoot.focusToggled(val)
                    }
                }

                // ── Stealth Mode ──────────────────────────────
                SettingRow {
                    label:   settingsRoot._s.stealth_mode  || "Stealth Mode 🫥"
                    desc:    settingsRoot._s.stealth_desc   || "BeeBar hides after 3s of inactivity."
                    checked: BeeConfig.stealthMode
                    onToggled: (val) => settingsRoot.stealthToggled(val)
                }

                // ── BeeBar Stats ──────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        text: "Affichage BeeBar 📊"
                        color: BeeTheme.accent
                        font { bold: true; pixelSize: 13; letterSpacing: 1 }
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 10
                        Repeater {
                            model: [
                                { label: "CPU", prop: "showCpu" },
                                { label: "RAM", prop: "showRam" },
                                { label: "NET", prop: "showNet" },
                                { label: "DISK", prop: "showDisk" },
                                { label: "BAT", prop: "showBattery" }
                            ]
                            Rectangle {
                                width: 75; height: 32; radius: 8
                                color: BeeConfig[modelData.prop]
                                    ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.22)
                                    : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, BeeConfig[modelData.prop] ? 0.6 : 0.2)
                                border.width: 1
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: BeeConfig[modelData.prop] ? BeeTheme.accent : BeeTheme.textSecondary
                                    font { pixelSize: 11; bold: BeeConfig[modelData.prop] }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        BeeConfig[modelData.prop] = !BeeConfig[modelData.prop]
                                        BeeConfig.saveConfig()
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Effets Sonores ────────────────────────────
                SettingRow {
                    label:   settingsRoot._s.sound      || "Effets Sonores"
                    desc:    settingsRoot._s.sound_desc  || "Enable hive ambient sounds."
                    checked: true
                }

                // ── Sélecteur de langue / Language selector ───
                RowLayout {
                    spacing: 20

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: settingsRoot._s.language || "Langue"
                            color: BeeTheme.textPrimary
                            font { bold: true; pixelSize: 14 }
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                        Text {
                            text: settingsRoot._s.language_desc || "Changer la langue de l'interface."
                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.4)
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Row {
                        spacing: 8
                        Repeater {
                            model: [
                                { code: "fr", label: "🇫🇷 FR" },
                                { code: "en", label: "🇬🇧 EN" }
                            ]
                            Rectangle {
                                property bool isActive: BeeConfig.uiLang === modelData.code
                                width: 62; height: 28; radius: 8
                                color: isActive
                                    ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.22)
                                    : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06)
                                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, isActive ? 0.65 : 0.20)
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: isActive ? BeeTheme.accent : BeeTheme.textPrimary
                                    font { pixelSize: 12; bold: isActive }
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        BeeConfig.setLang(modelData.code)
                                        BeeConfig.saveConfig()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ─── Footer ───────────────────────────────────────────
        Text {
            text: "Bee-Hive OS v1.3.6 · Launch Edition 🐝🚀"
            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.2)
            font.pixelSize: 9
            Layout.alignment: Qt.AlignHCenter
        }
    }
}

    }
}
}
