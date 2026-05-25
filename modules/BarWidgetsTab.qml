import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// BarWidgetsTab.qml — 📊 Bar & Widgets Settings
// Toggles pour la BeeBar, horloge, vibe, corners, batterie
// v0.8.37: Contextual Rules Editor
// ═══════════════════════════════════════════════════════════════

Item {
    id: barWidgetsTab

    // ─── i18n shortcut ─────────────────────────────────────────
    readonly property var s: BeeConfig.tr && BeeConfig.tr.settings ? BeeConfig.tr.settings : ({})

    // ─── Contextual Rules Editor State ──────────────────────────
    property bool showAddRuleForm: false
    property string newRuleClass: ""
    property string newRuleIcon: "📊"
    property string newRuleLabel: ""
    property string newRuleAction: "shell:btop"

    // ─── Available action presets ───────────────────────────────
    readonly property var actionPresets: [
        { value: "shell:btop",            label: "Shell: btop" },
        { value: "shell:dolphin ~/Downloads", label: "Shell: Dolphin Downloads" },
        { value: "shell:pavucontrol",    label: "Shell: pavucontrol" },
        { value: "shell:steam",          label: "Shell: Steam" },
        { value: "detail:network",       label: "Detail: Network" },
        { value: "detail:focus",         label: "Detail: Focus" },
        { value: "detail:weather",       label: "Detail: Weather" },
        { value: "detail:notes",         label: "Detail: Notes" },
        { value: "detail:sysmon",        label: "Detail: System Monitor" },
        { value: "custom",              label: "Custom…" }
    ]

    // ─── Helper: Get all app classes from context_rules ─────────
    function _getRuleClasses() {
        var rules = BeeConfig.context_rules
        if (!rules || typeof rules !== 'object') return []
        return Object.keys(rules)
    }

    // ─── Helper: Get rules array for a class ────────────────────
    function _getRulesForClass(className) {
        var rules = BeeConfig.context_rules
        if (!rules || !rules[className]) return []
        return rules[className]
    }

    // ─── Helper: Delete an app class from context_rules ────────
    function _deleteRuleClass(className) {
        var rules = JSON.parse(JSON.stringify(BeeConfig.context_rules || {}))
        delete rules[className]
        BeeConfig.context_rules = rules
        BeeConfig.saveConfig()
    }

    // ─── Helper: Delete a single rule from a class ──────────────
    function _deleteRuleAtIndex(className, index) {
        var rules = JSON.parse(JSON.stringify(BeeConfig.context_rules || {}))
        if (!rules[className]) return
        rules[className].splice(index, 1)
        if (rules[className].length === 0) {
            delete rules[className]
        }
        BeeConfig.context_rules = rules
        BeeConfig.saveConfig()
    }

    // ─── Helper: Update a rule property ─────────────────────────
    function _updateRule(className, index, field, value) {
        var rules = JSON.parse(JSON.stringify(BeeConfig.context_rules || {}))
        if (!rules[className] || !rules[className][index]) return
        rules[className][index][field] = value
        BeeConfig.context_rules = rules
        BeeConfig.saveConfig()
    }

    // ─── Helper: Add a new rule ─────────────────────────────────
    function _addRule() {
        var cls = newRuleClass.trim().toLowerCase()
        if (!cls) return
        var rules = JSON.parse(JSON.stringify(BeeConfig.context_rules || {}))
        if (!rules[cls]) rules[cls] = []
        rules[cls].push({
            icon: newRuleIcon,
            label: newRuleLabel || cls.toUpperCase().slice(0, 3),
            action: newRuleAction === "custom" ? "shell:echo" : newRuleAction
        })
        BeeConfig.context_rules = rules
        BeeConfig.saveConfig()
        // Reset form
        newRuleClass = ""
        newRuleIcon = "📊"
        newRuleLabel = ""
        newRuleAction = "shell:btop"
        showAddRuleForm = false
    }

    // ─── Helper: Detect active window class ─────────────────────
    function _detectActiveWindow() {
        var cls = (BeeBarState.activeWindowClass || "").toLowerCase()
        if (cls && cls !== "none" && cls !== "unknown") {
            newRuleClass = cls
        }
    }

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

            Item { height: 4 }

            // ─── Contextual Rules Editor 🎛️🐝 ─────────────────────
            Text {
                text: "🐝 " + (s.ctx_rules_title || "Contextual Rules")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            Text {
                text: s.ctx_rules_desc || "Define per-app shortcuts shown in the BeeBar when that app is active"
                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                font.pixelSize: 10; font.italic: true
                Layout.fillWidth: true; wrapMode: Text.WordWrap
            }

            // ─── Rule list (one section per app class) ────────────
            Repeater {
                model: _getRuleClasses()

                delegate: ColumnLayout {
                    id: ruleClassSection
                    required property string modelData
                    required property int index
                    Layout.fillWidth: true
                    spacing: 4

                    // ─── App class header with delete button ────
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8

                        Rectangle {
                            width: 28; height: 28; radius: 6
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "🖥️"; font.pixelSize: 14
                            }
                        }

                        Text {
                            text: modelData
                            color: BeeTheme.accent
                            font.pixelSize: 13; font.bold: true
                            Layout.fillWidth: true
                        }

                        // Delete entire app class
                        Rectangle {
                            width: 28; height: 28; radius: 6
                            color: Qt.rgba(1.0, 0.3, 0.3, 0.1)
                            border.color: Qt.rgba(1.0, 0.3, 0.3, 0.4)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "❌"; font.pixelSize: 12
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: _deleteRuleClass(modelData)
                            }
                        }
                    }

                    // ─── Rules for this app class ───────────────
                    Repeater {
                        model: _getRulesForClass(ruleClassSection.modelData)

                        delegate: RowLayout {
                            id: ruleRow
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            Layout.leftIndent: 36
                            spacing: 6

                            // Icon
                            Rectangle {
                                width: 30; height: 26; radius: 5
                                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08)
                                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.25)
                                border.width: 1

                                TextInput {
                                    id: iconEdit
                                    anchors.centerIn: parent
                                    text: modelData.icon || "📊"
                                    font.pixelSize: 13
                                    color: BeeTheme.textPrimary
                                    horizontalAlignment: Qt.AlignHCenter
                                    maximumLength: 4
                                    onActiveFocusChanged: {
                                        if (!activeFocus && text.length === 0) text = "📊"
                                    }
                                    onEditingFinished: {
                                        _updateRule(ruleClassSection.modelData, ruleRow.index, "icon", text)
                                    }
                                }
                            }

                            // Label
                            Rectangle {
                                width: 70; height: 26; radius: 5
                                color: Qt.rgba(BeeTheme.bg.r, BeeTheme.bg.g, BeeTheme.bg.b, 0.6)
                                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                                border.width: 1

                                TextInput {
                                    id: labelEdit
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: modelData.label || ""
                                    font.pixelSize: 12
                                    color: BeeTheme.textPrimary
                                    verticalAlignment: Qt.AlignVCenter
                                    maximumLength: 8
                                    onEditingFinished: {
                                        _updateRule(ruleClassSection.modelData, ruleRow.index, "label", text)
                                    }
                                }
                            }

                            // Action (read-only display + full path in tooltip)
                            Rectangle {
                                Layout.fillWidth: true; height: 26; radius: 5
                                color: Qt.rgba(BeeTheme.bg.r, BeeTheme.bg.g, BeeTheme.bg.b, 0.6)
                                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.25)
                                border.width: 1
                                clip: true

                                TextInput {
                                    id: actionEdit
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: modelData.action || ""
                                    font.pixelSize: 11
                                    color: BeeTheme.textSecondary
                                    verticalAlignment: Qt.AlignVCenter
                                    onEditingFinished: {
                                        _updateRule(ruleClassSection.modelData, ruleRow.index, "action", text)
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.IBeamCursor
                                    onClicked: actionEdit.forceActiveFocus()
                                }
                            }

                            // Delete this rule
                            Rectangle {
                                width: 24; height: 24; radius: 5
                                color: Qt.rgba(1.0, 0.3, 0.3, 0.08)
                                border.color: Qt.rgba(1.0, 0.3, 0.3, 0.3)
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"; font.pixelSize: 10
                                    color: Qt.rgba(1.0, 0.4, 0.4, 0.8)
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: _deleteRuleAtIndex(ruleClassSection.modelData, ruleRow.index)
                                }
                            }
                        }
                    }
                }
            }

            // ─── Empty state ────────────────────────────────────
            Text {
                visible: _getRuleClasses().length === 0
                text: s.ctx_rules_empty || "No contextual rules defined. Add one below!"
                color: BeeTheme.textSecondary
                font.pixelSize: 11; font.italic: true
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            // ─── Detect Active Window + Add Rule buttons ─────
            RowLayout {
                Layout.fillWidth: true; spacing: 8

                // Detect active window button
                Rectangle {
                    width: detectBtnLayout.implicitWidth + 20
                    height: 34; radius: 8
                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
                    border.width: 1

                    RowLayout {
                        id: detectBtnLayout
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "🔍"; font.pixelSize: 14 }
                        Text {
                            text: s.ctx_rules_detect || "Detect Active Window"
                            color: BeeTheme.accent; font.pixelSize: 11; font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            _detectActiveWindow()
                            if (newRuleClass.length > 0 && !showAddRuleForm) showAddRuleForm = true
                        }
                    }
                }

                // Add rule button
                Rectangle {
                    width: addBtnLayout.implicitWidth + 20
                    height: 34; radius: 8
                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                    border.color: BeeTheme.accent
                    border.width: 1.5

                    RowLayout {
                        id: addBtnLayout
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "➕"; font.pixelSize: 14 }
                        Text {
                            text: s.ctx_rules_add || "Add Rule"
                            color: BeeTheme.accent; font.pixelSize: 11; font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: showAddRuleForm = !showAddRuleForm
                    }
                }
            }

            // ─── Add Rule Inline Form ────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: showAddRuleForm ? addRuleFormLayout.implicitHeight + 24 : 0
                visible: showAddRuleForm
                radius: 10
                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06)
                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                border.width: 1
                clip: true

                ColumnLayout {
                    id: addRuleFormLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Text {
                        text: s.ctx_rules_new || "New Contextual Rule"
                        color: BeeTheme.accent
                        font.bold: true; font.pixelSize: 13
                    }

                    // App class name
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Text {
                            text: s.ctx_rules_app_class || "App class:"
                            color: BeeTheme.textPrimary; font.pixelSize: 12
                            Layout.preferredWidth: 80
                        }
                        Rectangle {
                            Layout.fillWidth: true; height: 30; radius: 6
                            color: Qt.rgba(BeeTheme.bg.r, BeeTheme.bg.g, BeeTheme.bg.b, 0.8)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
                            border.width: 1

                            TextInput {
                                id: newClassInput
                                anchors.fill: parent; anchors.margins: 6
                                color: BeeTheme.textPrimary; font.pixelSize: 13
                                verticalAlignment: Qt.AlignVCenter
                                placeholderText: s.ctx_rules_class_placeholder || "e.g. firefox, kitty, code"
                                placeholderTextColor: BeeTheme.textSecondary
                                text: barWidgetsTab.newRuleClass
                                onTextChanged: barWidgetsTab.newRuleClass = text.toLowerCase().trim()
                                maximumLength: 30
                                selectByMouse: true
                                Keys.onReturnPressed: _addRule()
                            }
                        }
                    }

                    // Icon + Label row
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8

                        // Icon
                        RowLayout {
                            spacing: 4
                            Text {
                                text: s.ctx_rules_icon || "Icon:"
                                color: BeeTheme.textPrimary; font.pixelSize: 12
                            }
                            Rectangle {
                                width: 40; height: 30; radius: 6
                                color: Qt.rgba(BeeTheme.bg.r, BeeTheme.bg.g, BeeTheme.bg.b, 0.8)
                                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
                                border.width: 1

                                TextInput {
                                    id: newIconInput
                                    anchors.centerIn: parent
                                    text: barWidgetsTab.newRuleIcon
                                    font.pixelSize: 14
                                    color: BeeTheme.textPrimary
                                    horizontalAlignment: Qt.AlignHCenter
                                    maximumLength: 4
                                    onTextChanged: barWidgetsTab.newRuleIcon = text
                                    onActiveFocusChanged: {
                                        if (!activeFocus && text.length === 0) text = "📊"
                                    }
                                }
                            }
                        }

                        // Label
                        RowLayout {
                            spacing: 4; Layout.fillWidth: true
                            Text {
                                text: s.ctx_rules_label || "Label:"
                                color: BeeTheme.textPrimary; font.pixelSize: 12
                            }
                            Rectangle {
                                Layout.fillWidth: true; height: 30; radius: 6
                                color: Qt.rgba(BeeTheme.bg.r, BeeTheme.bg.g, BeeTheme.bg.b, 0.8)
                                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
                                border.width: 1

                                TextInput {
                                    id: newLabelInput
                                    anchors.fill: parent; anchors.margins: 6
                                    color: BeeTheme.textPrimary; font.pixelSize: 12
                                    verticalAlignment: Qt.AlignVCenter
                                    placeholderText: s.ctx_rules_label_placeholder || "e.g. CPU, DLs, NET"
                                    placeholderTextColor: BeeTheme.textSecondary
                                    text: barWidgetsTab.newRuleLabel
                                    onTextChanged: barWidgetsTab.newRuleLabel = text
                                    maximumLength: 8
                                    selectByMouse: true
                                    Keys.onReturnPressed: _addRule()
                                }
                            }
                        }
                    }

                    // Action dropdown
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Text {
                            text: s.ctx_rules_action || "Action:"
                            color: BeeTheme.textPrimary; font.pixelSize: 12
                            Layout.preferredWidth: 80
                        }

                        // Action preset buttons
                        Flow {
                            Layout.fillWidth: true
                            spacing: 4

                            Repeater {
                                model: barWidgetsTab.actionPresets

                                delegate: Rectangle {
                                    height: 26; radius: 5
                                    width: actionPresetLabel.implicitWidth + 12
                                    color: barWidgetsTab.newRuleAction === modelData.value
                                        ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                                        : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                                    border.color: barWidgetsTab.newRuleAction === modelData.value
                                        ? BeeTheme.accent
                                        : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                                    border.width: barWidgetsTab.newRuleAction === modelData.value ? 1.5 : 1

                                    Text {
                                        id: actionPresetLabel
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: barWidgetsTab.newRuleAction === modelData.value ? BeeTheme.accent : BeeTheme.textSecondary
                                        font.pixelSize: 10
                                        font.bold: barWidgetsTab.newRuleAction === modelData.value
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: barWidgetsTab.newRuleAction = modelData.value
                                    }
                                }
                            }
                        }
                    }

                    // Custom action text input (visible only when "custom" selected)
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        visible: barWidgetsTab.newRuleAction === "custom"

                        Text {
                            text: "shell:"
                            color: BeeTheme.accent; font.pixelSize: 12
                            font.bold: true; font.italic: true
                        }
                        Rectangle {
                            Layout.fillWidth: true; height: 30; radius: 6
                            color: Qt.rgba(BeeTheme.bg.r, BeeTheme.bg.g, BeeTheme.bg.b, 0.8)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
                            border.width: 1

                            TextInput {
                                id: customActionInput
                                anchors.fill: parent; anchors.margins: 6
                                color: BeeTheme.textPrimary; font.pixelSize: 12
                                verticalAlignment: Qt.AlignVCenter
                                placeholderText: s.ctx_rules_custom_placeholder || "e.g. alacritty -e htop"
                                placeholderTextColor: BeeTheme.textSecondary
                                selectByMouse: true
                                onTextChanged: {
                                    if (text.length > 0) {
                                        barWidgetsTab.newRuleAction = "shell:" + text
                                    }
                                }
                                Keys.onReturnPressed: _addRule()
                            }
                        }
                    }

                    // Create / Cancel buttons
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8

                        Rectangle {
                            width: 100; height: 32; radius: 8
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                            border.color: BeeTheme.accent; border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: s.ctx_rules_create || "Create"
                                color: BeeTheme.accent; font.pixelSize: 12; font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: _addRule()
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
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    showAddRuleForm = false
                                    newRuleClass = ""
                                    newRuleIcon = "📊"
                                    newRuleLabel = ""
                                    newRuleAction = "shell:btop"
                                }
                            }
                        }
                    }
                }
            }

            Item { height: 4 }

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


        }
    }
}