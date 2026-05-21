import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "."

// ═══════════════════════════════════════════════════════════════
// AccessibilityTab.qml — ♿ Accessibility Settings
// v0.8.33: Contrast level selector (AA/AAA), Orca detection,
//   preview card, keyboard shortcuts info
// ═══════════════════════════════════════════════════════════════

Item {
    id: accessibilityTab

    // ─── i18n shortcut ─────────────────────────────────────────
    readonly property var s: BeeConfig.tr && BeeConfig.tr.settings ? BeeConfig.tr.settings : ({})

    // ─── Orca detection state ───────────────────────────────────
    property string orcaStatus: "unknown"  // "running" | "stopped" | "not_installed" | "unknown"

    // ─── Contrast level descriptions ────────────────────────────
    readonly property var contrastLevels: [
        { key: "none", label: s.contrast_none || "None",     desc: s.contrast_none_desc || "Default contrast",      emoji: "⚪" },
        { key: "AA",   label: "AA",                          desc: s.contrast_aa_desc || "WCAG AA (4.5:1 ratio)",   emoji: "🟡" },
        { key: "AAA",  label: "AAA",                         desc: s.contrast_aaa_desc || "WCAG AAA (7:1 ratio)",   emoji: "🟢" }
    ]

    // ─── Contrast level visual properties ────────────────────────
    readonly property real contrastTextAlpha: BeeConfig.accessibilityLevel === "AAA" ? 1.0 :
                                              BeeConfig.accessibilityLevel === "AA"  ? 0.95 : 0.85
    readonly property real contrastBorderAlpha: BeeConfig.accessibilityLevel === "AAA" ? 0.8 :
                                                BeeConfig.accessibilityLevel === "AA"  ? 0.5 : 0.25
    readonly property bool contrastBorders: BeeConfig.accessibilityLevel !== "none"

    // ─── Process: detect Orca screen reader ──────────────────────
    property Process orcaDetectProc: Process {
        id: _orcaDetectProc
        command: ["bash", "-c", "if command -v orca &>/dev/null; then if pgrep -x orca &>/dev/null; then echo 'running'; else echo 'stopped'; fi; else echo 'not_installed'; fi"]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                var status = line.trim()
                if (status === "running" || status === "stopped" || status === "not_installed") {
                    orcaStatus = status
                }
            }
        }
        onExited: (code, status) => {
            console.log("[AccessibilityTab] Orca detection completed:", orcaStatus)
        }
    }

    // ─── Process: launch Orca ───────────────────────────────────
    property Process orcaLaunchProc: Process {
        id: _orcaLaunchProc
        running: false
        command: ["bash", "-c", "orca &"]
        onExited: (code, status) => {
            // Re-detect after launch
            _orcaDetectProc.running = false
            _orcaDetectProc.running = true
        }
    }

    // ─── Process: install Orca ──────────────────────────────────
    property Process orcaInstallProc: Process {
        id: _orcaInstallProc
        running: false
        command: ["bash", "-c", "notify-send 'Bee-Hive OS' 'Installing Orca screen reader...' && xdg-terminal-emulator sudo pacman -S orca"]
        onExited: (code, status) => {
            // Re-detect after install attempt
            _orcaDetectProc.running = false
            _orcaDetectProc.running = true
        }
    }

    // ─── Detect Orca on load ────────────────────────────────────
    Component.onCompleted: {
        _orcaDetectProc.running = true
    }

    ScrollView {
        id: accessibilityScroll
        anchors.fill: parent
        anchors.margins: 16
        clip: true

        ColumnLayout {
            width: accessibilityScroll.availableWidth
            spacing: 16

            // ─── ♿ Title ────────────────────────────────────────────
            Text {
                text: "♿ " + (s.accessibility || "Accessibility")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            // ─── 🔆 Contrast Level Selector ──────────────────────────
            Text {
                text: "🔆 " + (s.contrast_level || "Contrast Level")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            // Contrast level buttons
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Repeater {
                    model: contrastLevels
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72
                        radius: 10
                        color: BeeConfig.accessibilityLevel === modelData.key
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.18)
                            : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.04)
                        border.color: BeeConfig.accessibilityLevel === modelData.key
                            ? BeeTheme.accent
                            : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                        border.width: BeeConfig.accessibilityLevel === modelData.key ? 2 : 1

                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                text: modelData.emoji + " " + modelData.label
                                color: BeeConfig.accessibilityLevel === modelData.key ? BeeTheme.accent : BeeTheme.textPrimary
                                font.bold: BeeConfig.accessibilityLevel === modelData.key
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: modelData.desc
                                color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.7)
                                font.pixelSize: 9
                                font.italic: true
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onClicked: {
                                BeeConfig.accessibilityLevel = modelData.key
                                BeeConfig.accessibilityHighContrast = (modelData.key !== "none")
                                BeeConfig.saveConfig()
                            }
                        }
                    }
                }
            }

            // ─── High contrast toggle (kept for backward compat) ─────
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: s.high_contrast || "High contrast"
                    color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, contrastTextAlpha)
                    font.pixelSize: 13; Layout.fillWidth: true
                }
                Switch {
                    checked: BeeConfig.accessibilityHighContrast
                    onToggled: {
                        BeeConfig.accessibilityHighContrast = checked
                        if (!checked && BeeConfig.accessibilityLevel !== "none") {
                            BeeConfig.accessibilityLevel = "none"
                        } else if (checked && BeeConfig.accessibilityLevel === "none") {
                            BeeConfig.accessibilityLevel = "AA"
                        }
                        BeeConfig.saveConfig()
                    }
                }
            }

            Item { height: 4 }

            // ─── 🔊 Screen Reader (Orca) Detection & Control ────────
            Text {
                text: "🔊 " + (s.screen_reader_section || "Screen Reader")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            // Orca status card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: orcaLayout.height + 24
                radius: 10
                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06)
                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                border.width: 1

                ColumnLayout {
                    id: orcaLayout
                    anchors.centerIn: parent
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Text {
                            text: orcaStatus === "running" ? "🟢" :
                                  orcaStatus === "stopped" ? "🟡" :
                                  orcaStatus === "not_installed" ? "🔴" : "⚪"
                            font.pixelSize: 14
                        }
                        Text {
                            text: orcaStatus === "running" ? (s.orca_running || "Orca is running") :
                                  orcaStatus === "stopped" ? (s.orca_stopped || "Orca installed but stopped") :
                                  orcaStatus === "not_installed" ? (s.orca_not_installed || "Orca not installed") :
                                  (s.orca_detecting || "Detecting...")
                            color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                            Layout.fillWidth: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        // Launch/Stop button
                        Rectangle {
                            visible: orcaStatus === "stopped" || orcaStatus === "running"
                            width: 120; height: 30; radius: 8
                            color: orcaStatus === "running"
                                ? Qt.rgba(1, 0.3, 0.3, 0.15)
                                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                            border.color: orcaStatus === "running"
                                ? Qt.rgba(1, 0.3, 0.3, 0.5)
                                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.5)
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: orcaStatus === "running" ? (s.orca_stop || "Stop Orca") : (s.orca_launch || "Launch Orca")
                                color: orcaStatus === "running" ? "#FF6666" : BeeTheme.accent
                                font.pixelSize: 11; font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (orcaStatus === "running") {
                                        Qt.createQmlObject('import Quickshell.Io; Process { command: ["bash", "-c", "pkill -x orca"]; running: true }', accessibilityTab, "OrcaKill")
                                        orcaDetectTimer.start()
                                    } else {
                                        _orcaLaunchProc.running = true
                                        orcaDetectTimer.start()
                                    }
                                }
                            }
                        }
                        // Install button
                        Rectangle {
                            visible: orcaStatus === "not_installed"
                            width: 140; height: 30; radius: 8
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.5)
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: s.orca_install || "Install Orca"
                                color: BeeTheme.accent; font.pixelSize: 11; font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: _orcaInstallProc.running = true
                            }
                        }
                        // Refresh button
                        Rectangle {
                            width: 30; height: 30; radius: 8
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                            border.width: 1
                            Text {
                                anchors.centerIn: parent; text: "🔄"; font.pixelSize: 12
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    _orcaDetectProc.running = false
                                    _orcaDetectProc.running = true
                                }
                            }
                        }
                    }
                }
            }

            // Screen reader toggle (persistent preference)
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: s.screen_reader || "Screen reader"
                    color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, contrastTextAlpha)
                    font.pixelSize: 13; Layout.fillWidth: true
                }
                Switch {
                    checked: BeeConfig.accessibilityScreenReader
                    onToggled: { BeeConfig.accessibilityScreenReader = checked; BeeConfig.saveConfig() }
                }
            }

            // Timer to re-detect Orca after launch/stop
            Timer {
                id: orcaDetectTimer
                interval: 2000
                onTriggered: {
                    _orcaDetectProc.running = false
                    _orcaDetectProc.running = true
                }
            }

            Item { height: 4 }

            // ─── Reduce animations ─────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: s.reduce_animations || "Reduce animations"
                    color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, contrastTextAlpha)
                    font.pixelSize: 13; Layout.fillWidth: true
                }
                Switch {
                    checked: BeeConfig.accessibilityReducedMotion
                    onToggled: { BeeConfig.accessibilityReducedMotion = checked; BeeConfig.saveConfig() }
                }
            }

            Item { height: 4 }

            // ─── 🔤 Text Scale Slider ──────────────────────────────────
            Text {
                text: "🔤 " + (s.text_scale || "Text scale")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: s.text_scale_factor || "Text scale factor"
                    color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, contrastTextAlpha)
                    font.pixelSize: 13; Layout.fillWidth: true
                }
                Text {
                    text: BeeConfig.accessibilityTextScale.toFixed(1) + "×"
                    color: BeeTheme.accent; font.pixelSize: 13; font.bold: true
                    Layout.minimumWidth: 40; horizontalAlignment: Text.AlignRight
                }
            }
            Slider {
                Layout.fillWidth: true
                from: 0.8; to: 1.5; stepSize: 0.1
                value: BeeConfig.accessibilityTextScale
                onMoved: { BeeConfig.accessibilityTextScale = Math.round(value * 10) / 10; BeeConfig.saveConfig() }
            }

            Item { height: 4 }

            // ─── 👁️ Accessibility Preview Card ────────────────────────
            Text {
                text: "👁️ " + (s.accessibility_preview || "Preview")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: previewContent.height + 24
                radius: 10
                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.04)
                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, contrastBorderAlpha)
                border.width: contrastBorders ? 2 : 1

                ColumnLayout {
                    id: previewContent
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: s.preview_sample_text || "Sample Text"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, contrastTextAlpha)
                        font.pixelSize: Math.round(14 * BeeConfig.accessibilityTextScale)
                        font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: s.preview_body_text || "This is how body text will appear with your current accessibility settings. Adjust contrast level, text scale, and animations above."
                        color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, contrastTextAlpha * 0.8)
                        font.pixelSize: Math.round(11 * BeeConfig.accessibilityTextScale)
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Rectangle {
                            width: 80; height: Math.round(28 * BeeConfig.accessibilityTextScale)
                            radius: 6
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, contrastBorderAlpha)
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: s.preview_button || "Button"
                                color: BeeTheme.accent
                                font.pixelSize: Math.round(10 * BeeConfig.accessibilityTextScale)
                                font.bold: true
                            }
                        }
                        Text {
                            text: BeeConfig.accessibilityLevel === "AAA" ? "✅ AAA" :
                                  BeeConfig.accessibilityLevel === "AA"  ? "⚠️ AA" : "⚪ " + (s.contrast_none || "None")
                            color: BeeConfig.accessibilityLevel === "AAA" ? "#4CAF50" :
                                   BeeConfig.accessibilityLevel === "AA"  ? "#FFB81C" : BeeTheme.textSecondary
                            font.pixelSize: Math.round(11 * BeeConfig.accessibilityTextScale)
                            font.bold: true
                        }
                    }
                }
            }

            Item { height: 4 }

            // ─── ⌨️ Keyboard Shortcuts Info ─────────────────────────────
            Text {
                text: "⌨️ " + (s.keyboard_shortcuts_a11y || "Keyboard Shortcuts")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            ColumnLayout {
                Layout.fillWidth: true; spacing: 6

                // Shortcut row helper component
                Component {
                    id: shortcutRow
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
                        Rectangle {
                            width: 110; height: 24; radius: 5
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.25)
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: modelData.key
                                color: BeeTheme.accent; font.pixelSize: 10; font.bold: true
                                font.family: "monospace"
                            }
                        }
                        Text {
                            text: modelData.desc
                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, contrastTextAlpha)
                            font.pixelSize: Math.round(12 * BeeConfig.accessibilityTextScale)
                            Layout.fillWidth: true; wrapMode: Text.WordWrap
                        }
                    }
                }

                Repeater {
                    model: [
                        { key: "Super + M",  desc: s.shortcut_voice || "Toggle voice assistant" },
                        { key: "Esc",         desc: s.shortcut_close || "Close panel / dialog" },
                        { key: "Tab",         desc: s.shortcut_tab || "Navigate between elements" },
                        { key: "Super + Tab", desc: s.shortcut_switch || "Switch workspace" },
                        { key: "Super + A",   desc: s.shortcut_accessibility || "Accessibility settings" }
                    ]
                    delegate: Loader {
                        Layout.fillWidth: true
                        sourceComponent: shortcutRow
                        onLoaded: item.modelData = modelData
                    }
                }
            }

            Item { height: 8 }
        }
    }
}