import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// MayaDashConfigCells.qml — Alvéoles (Cell Editor) 🍯
// ═══════════════════════════════════════════════════════════════

Item {
    id: cellsTab
    property string _fr: BeeConfig.uiLang === "fr" ? "1" : ""

    // ─── Module Library (available presets for cell replacement) ───
    property var moduleLibrary: [
        { icon: "\uD83D\uDCC5", title: _fr ? "Famille Chabot" : "Family Calendar", subtitle: _fr ? "Calendrier" : "Calendar", detail: _fr ? "Agenda Familial\nGoogle Calendar" : "Family Agenda\nGoogle Calendar", action: "url:https://calendar.google.com/calendar/u/0/r", highlighted: true },
        { icon: "\uD83D\uDCC5", title: _fr ? "Calendrier" : "Calendar", subtitle: _fr ? "Agenda" : "Schedule", detail: _fr ? "\u00C9v\u00E9nements du jour\nRappels" : "Today's events\nReminders", action: "detail:calendar", highlighted: false },
        { icon: "\uD83D\uDCDD", title: "BeeNotes", subtitle: _fr ? "Notes" : "Notes", detail: _fr ? "Notes rapides\nChecklist" : "Quick notes\nChecklist", action: "detail:notes", highlighted: false },
        { icon: "\uD83D\uDDA5\uFE0F", title: _fr ? "Syst\u00E8me" : "System", subtitle: "CachyOS", detail: "CPU/GPU/RAM\nTemp\u00E9ratures", action: "detail:monitor", highlighted: false },
        { icon: "\uD83C\uDF10", title: _fr ? "R\u00E9seau" : "Network", subtitle: _fr ? "Speed Test" : "Speed Test", detail: _fr ? "Latence & D\u00E9bit\nTest de vitesse" : "Latency & Speed\nSpeed Test", action: "detail:network", highlighted: true },
        { icon: "\uD83C\uDF45", title: "BeeFocus", subtitle: _fr ? "Pomodoro" : "Pomodoro", detail: _fr ? "Minuteur de concentration" : "Focus timer", action: "detail:focus", highlighted: false },
        { icon: "\uD83D\uDC1D", title: "Maya Status", subtitle: _fr ? "En ligne" : "Online", detail: _fr ? "IA Assistante\nConnect\u00E9e" : "AI Assistant\nConnected", action: "url:http://192.168.13.100:18789/", highlighted: true },
        { icon: "\u26F0\uFE0F", title: "Tremblant", subtitle: _fr ? "Conditions ski" : "Ski conditions", detail: _fr ? "Mont-Tremblant\nConditions de ski" : "Mont-Tremblant\nSki conditions", action: "url:https://www.tremblant.ca/montagne/conditions-ski", highlighted: false },
        { icon: "\uD83D\uDCB0", title: "Powerland", subtitle: _fr ? "Gestion" : "Management", detail: _fr ? "Documents\nGoogle Drive" : "Documents\nGoogle Drive", action: "url:https://drive.google.com", highlighted: false },
        { icon: "\uD83C\uDFAE", title: _fr ? "Jeux" : "Gaming", subtitle: "GeForce Now", detail: _fr ? "Cloud Gaming\nGeForce Now" : "Cloud Gaming\nGeForce Now", action: "app:flatpak run com.nvidia.geforcenow", highlighted: false },
        { icon: "\u2699\uFE0F", title: _fr ? "Param\u00E8tres" : "Settings", subtitle: "Bee-Hive OS", detail: _fr ? "Configuration\nPr\u00E9f\u00E9rences" : "Configuration\nPreferences", action: "toggle:settings", highlighted: false }
    ]

    property bool libraryOpen: false

    // ─── Module Library Popup ───
    Rectangle {
        id: libraryPopup
        visible: cellsTab.libraryOpen
        z: 500
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.4)
        radius: 12

        MouseArea { anchors.fill: parent; onClicked: cellsTab.libraryOpen = false }

        Rectangle {
            width: 280; height: 400
            anchors.centerIn: parent
            radius: 14
            color: BeeTheme.mode === "HoneyDark" ? Qt.rgba(0.08, 0.07, 0.10, 0.98) : Qt.rgba(0.97, 0.95, 0.91, 0.98)
            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 14; spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: _fr ? "\uD83D\uDD04 Remplacer par..." : "\uD83D\uDD04 Replace with..."
                        color: BeeTheme.accent; font.bold: true; font.pixelSize: 14
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        width: 26; height: 26; radius: 13
                        color: closeLib.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.3) : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
                        Text { text: "\u2715"; color: BeeTheme.accent; font.pixelSize: 12; anchors.centerIn: parent }
                        MouseArea { id: closeLib; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cellsTab.libraryOpen = false }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15) }

                ListView {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true; spacing: 4
                    model: cellsTab.moduleLibrary

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 48; radius: 8
                        color: modHov.containsMouse
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.18)
                            : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                        border.color: modHov.containsMouse
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.5)
                            : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.10)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                            Text { text: modelData.icon; font.pixelSize: 20 }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 1
                                Text { text: modelData.title; color: BeeTheme.textPrimary; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
                                Text { text: modelData.subtitle; color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.5); font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                            }
                        }

                        MouseArea {
                            id: modHov
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // Replace the selected cell with this module's data
                                var idx = dashConfig.selectedIndex
                                if (idx >= 0 && idx < BeeConfig.cells.count) {
                                    BeeConfig.cells.set(idx, {
                                        icon: modelData.icon,
                                        title: modelData.title,
                                        subtitle: modelData.subtitle,
                                        detail: modelData.detail,
                                        action: modelData.action,
                                        highlighted: modelData.highlighted,
                                        customizable: true,
                                        color: BeeConfig.cells.get(idx).color || ""
                                    })
                                    BeeConfig.cellsRevision++
                                    BeeConfig.saveConfig()
                                    dashConfig.loadCell(idx)
                                    cellsTab.libraryOpen = false
                                    BeeBarState.logAction("My Hive", _fr ? "Alv\u00E9ole remplac\u00E9e" : "Cell replaced", "\uD83D\uDD04")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent; anchors.margins: 16; spacing: 14

        // ─── Cell List ───
        Rectangle {
            Layout.preferredWidth: 168; Layout.fillHeight: true
            radius: 12
            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.04)
            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.10)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 7

                Text {
                    text: _fr ? "Alvéoles" : "Cells"
                    color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.40)
                    font.pixelSize: 9; font.bold: true; font.letterSpacing: 2
                }

                ListView {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true; model: BeeConfig.cells; spacing: 4

                    delegate: Rectangle {
                        width: parent ? parent.width : 0
                        height: 46; radius: 9
                        color: dashConfig.selectedIndex === index
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                            : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                        border.color: dashConfig.selectedIndex === index
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.50)
                            : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.12)
                        border.width: 1
                        Behavior on color       { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 9; spacing: 8
                            Text {
                                text: (dashConfig.selectedIndex === index)
                                    ? (dashConfig.editIcon || "🐝") : (model.icon || "🐝")
                                font.pixelSize: 18
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 1
                                Text {
                                    text: (dashConfig.selectedIndex === index)
                                        ? (dashConfig.editTitle || "—") : (model.title || "—")
                                    color: dashConfig.selectedIndex === index ? BeeTheme.accent : BeeTheme.textPrimary
                                    font.pixelSize: 11; font.bold: true
                                    Layout.fillWidth: true; elide: Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                Text {
                                    visible: model.customizable === false
                                    text: "🔒 protected"; font.pixelSize: 8
                                    color: Qt.rgba(1.0, 0.65, 0.2, 0.65)
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: dashConfig.loadCell(index)
                        }
                    }
                }
            }
        }

        // ─── Edit Form ───
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true
            radius: 12
            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.03)
            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08)
            border.width: 1

            // Placeholder
            ColumnLayout {
                visible: dashConfig.selectedIndex < 0
                anchors.centerIn: parent; spacing: 14
                Text {
                    text: "🍯"; font.pixelSize: 44
                    Layout.alignment: Qt.AlignHCenter
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.4; duration: 2500; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 2500; easing.type: Easing.InOutSine }
                    }
                }
                Text {
                    text: _fr ? "Sélectionnez une alvéole" : "Select a cell"
                    color: BeeTheme.accent; font.bold: true; font.pixelSize: 14; font.letterSpacing: 0.6
                    Layout.alignment: Qt.AlignHCenter
                    Behavior on color { ColorAnimation { duration: 600 } }
                }
            }

            // Form
            Flickable {
                visible: dashConfig.selectedIndex >= 0
                anchors.fill: parent; anchors.margins: 16
                contentHeight: editForm.implicitHeight; clip: true

                // Sync action ComboBox when cell is loaded
                Connections {
                    target: dashConfig
                    function onEditActionChanged() { actionCombo.syncToAction(dashConfig.editAction) }
                }

                ColumnLayout {
                    id: editForm
                    width: parent.width; spacing: 10

                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Text { text: dashConfig.editIcon || "🐝"; font.pixelSize: 32 }
                        ColumnLayout {
                            spacing: 2; Layout.fillWidth: true
                            Text {
                                text: dashConfig.editTitle || "Cell"
                                color: BeeTheme.accent; font.bold: true; font.pixelSize: 15
                                elide: Text.ElideRight; Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                            Text {
                                text: dashConfig.editCustomizable
                                    ? (_fr ? "Modifiable" : "Editable")
                                    : (_fr ? "Lecture seule" : "Read-only")
                                color: dashConfig.editCustomizable
                                    ? Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.4)
                                    : Qt.rgba(1.0, 0.65, 0.2, 0.75)
                                font.pixelSize: 10
                            }
                        }
                    }
                    Rectangle { height: 1; Layout.fillWidth: true; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15) }

                    component FieldLabel: Text {
                        property string labelText: ""
                        text: labelText
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.5)
                        font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.5
                    }
                    component BeeField: TextField {
                        Layout.fillWidth: true; height: 36
                        enabled: dashConfig.editCustomizable
                        leftPadding: 10; rightPadding: 10
                        color: BeeTheme.textPrimary
                        font.pixelSize: 12
                        background: Rectangle {
                            radius: 7
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, parent.enabled ? 0.07 : 0.03)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, parent.activeFocus ? 0.5 : (parent.enabled ? 0.15 : 0.07))
                            border.width: 1
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            Behavior on color        { ColorAnimation { duration: 150 } }
                        }
                    }

                    FieldLabel { labelText: _fr ? "Icône" : "Icon" }
                    BeeField { id: iconField; placeholderText: "🌐 📅 🎵"; onTextEdited: { if (!dashConfig._loading) dashConfig.editIcon = text } }

                    FieldLabel { labelText: _fr ? "Titre" : "Title" }
                    BeeField { id: titleField; placeholderText: _fr ? "Mon Module" : "My Module"; onTextEdited: { if (!dashConfig._loading) dashConfig.editTitle = text } }

                    FieldLabel { labelText: _fr ? "Sous-titre" : "Subtitle" }
                    BeeField { id: subtitleField; placeholderText: _fr ? "Description" : "Description"; onTextEdited: { if (!dashConfig._loading) dashConfig.editSubtitle = text } }

                    FieldLabel { labelText: _fr ? "Détail" : "Detail" }
                    Rectangle {
                        Layout.fillWidth: true; height: 64; radius: 7
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, dashConfig.editCustomizable ? 0.07 : 0.03)
                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, detailInput.activeFocus ? 0.5 : (dashConfig.editCustomizable ? 0.15 : 0.07))
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        TextEdit {
                            id: detailInput; anchors.fill: parent; anchors.margins: 9
                            enabled: dashConfig.editCustomizable; color: BeeTheme.textPrimary
                            font.pixelSize: 11; wrapMode: TextEdit.Wrap
                            onTextChanged: { if (!dashConfig._loading) dashConfig.editDetail = text }
                            Text {
                                visible: parent.text === ""
                                text: _fr ? "Détail affiché sous le titre" : "Detail shown under the title"
                                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.3)
                                font.pixelSize: 11; anchors.fill: parent
                            }
                        }
                    }

                    FieldLabel { labelText: _fr ? "Action" : "Action" }
                    // ─── Action Selector: ComboBox + custom field ───
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        ComboBox {
                            id: actionCombo
                            Layout.fillWidth: true; height: 36
                            enabled: dashConfig.editCustomizable
                            model: ListModel {
                                id: actionModel
                                ListElement { label: "\uD83D\uDD12 Verrouillé" ; value: "none" }
                                ListElement { label: "\uD83D\uDCC5 Calendrier"; value: "detail:calendar" }
                                ListElement { label: "\uD83D\uDCDD Notes"; value: "detail:notes" }
                                ListElement { label: "\uD83D\uDDA5\uFE0F Système"; value: "detail:monitor" }
                                ListElement { label: "\uD83C\uDF10 Réseau"; value: "detail:network" }
                                ListElement { label: "\uD83C\uDF45 Pomodoro"; value: "detail:focus" }
                                ListElement { label: "\u2699\uFE0F Paramètres"; value: "toggle:settings" }
                                ListElement { label: "\uD83C\uDF10 URL..."; value: "url:" }
                                ListElement { label: "\uD83D\uDCBB Application..."; value: "app:" }
                                ListElement { label: "\u270F\uFE0F Personnalisé..."; value: "custom" }
                            }
                            textRole: "label"
                            property bool _syncing: false
                            onCurrentIndexChanged: {
                                if (_syncing || !enabled) return
                                var val = actionModel.get(currentIndex).value
                                if (val === "custom") {
                                    customActionField.visible = true
                                    customActionField.forceActiveFocus()
                                } else if (val === "url:") {
                                    customActionField.visible = true
                                    customActionField.text = "url:https://"
                                    if (!dashConfig._loading) dashConfig.editAction = "url:https://"
                                    customActionField.forceActiveFocus()
                                } else if (val === "app:") {
                                    customActionField.visible = true
                                    customActionField.text = "app:"
                                    if (!dashConfig._loading) dashConfig.editAction = "app:"
                                    customActionField.forceActiveFocus()
                                } else {
                                    customActionField.visible = false
                                    if (!dashConfig._loading) dashConfig.editAction = val
                                }
                            }
                            function syncToAction(act) {
                                _syncing = true
                                for (var i = 0; i < actionModel.count; i++) {
                                    if (actionModel.get(i).value === act) {
                                        currentIndex = i
                                        customActionField.visible = false
                                        _syncing = false
                                        return
                                    }
                                }
                                // Custom action
                                if (act && act.startsWith("url:")) {
                                    currentIndex = 7
                                    customActionField.visible = true
                                    customActionField.text = act
                                } else if (act && act.startsWith("app:")) {
                                    currentIndex = 8
                                    customActionField.visible = true
                                    customActionField.text = act
                                } else {
                                    currentIndex = 9
                                    customActionField.visible = true
                                    customActionField.text = act || ""
                                }
                                _syncing = false
                            }
                            contentItem: Text {
                                text: actionCombo.displayText
                                color: BeeTheme.textPrimary
                                font.pixelSize: 12
                                leftPadding: 10
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 7
                                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, actionCombo.enabled ? 0.07 : 0.03)
                                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, actionCombo.activeFocus ? 0.5 : (actionCombo.enabled ? 0.15 : 0.07))
                                border.width: 1
                            }
                            popup: Popup {
                                y: actionCombo.height
                                width: actionCombo.width
                                implicitHeight: contentItem.implicitHeight
                                padding: 1
                                contentItem: ListView {
                                    clip: true; spacing: 2
                                    model: actionCombo.popup.visible ? actionCombo.delegateModel : null
                                    implicitHeight: contentHeight
                                }
                                background: Rectangle {
                                    radius: 8
                                    color: BeeTheme.mode === "HoneyDark" ? Qt.rgba(0.12, 0.11, 0.14, 0.98) : Qt.rgba(0.97, 0.95, 0.91, 0.98)
                                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                                    border.width: 1
                                }
                            }
                            delegate: ItemDelegate {
                                width: actionCombo.width
                                height: 34
                                contentItem: Text {
                                    text: model.label
                                    color: actionCombo.highlightedIndex === index ? BeeTheme.accent : BeeTheme.textPrimary
                                    font.pixelSize: 12
                                    leftPadding: 10
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: 4
                                    color: highlighted ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15) : "transparent"
                                }
                                highlighted: actionCombo.highlightedIndex === index
                            }
                        }
                        BeeField {
                            id: customActionField
                            Layout.fillWidth: true; height: 36
                            visible: false
                            placeholderText: "url:https://... ou app:command"
                            onTextEdited: { if (!dashConfig._loading) dashConfig.editAction = text }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        ColumnLayout {
                            spacing: 1; Layout.fillWidth: true
                            Text {
                                text: _fr ? "Mis en évidence" : "Highlighted"; color: BeeTheme.textPrimary
                                font.pixelSize: 12; font.bold: true
                                Behavior on color { ColorAnimation { duration: 600 } }
                            }
                            Text { text: _fr ? "Brillance dorée autour de la cellule" : "Golden glow around the cell"; color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.4); font.pixelSize: 9 }
                        }
                        Switch {
                            checked: dashConfig.editHighlighted; enabled: dashConfig.editCustomizable
                            onCheckedChanged: { if (!dashConfig._loading) dashConfig.editHighlighted = checked }
                        }
                    }

                    // ─── Action Buttons ───
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Layout.topMargin: 8

                        // Add cell
                        Rectangle {
                            width: 90; height: 30; radius: 15
                            color: Qt.rgba(0.2, 0.7, 0.3, 0.15)
                            border.color: Qt.rgba(0.2, 0.7, 0.3, 0.40); border.width: 1
                            Text { text: _fr ? "\u2795 Ajouter" : "\u2795 Add"; color: "#4CAF50"; font.pixelSize: 10; font.bold: true; anchors.centerIn: parent }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BeeConfig.cells.append({
                                        icon: "\uD83D\uDC1D", title: "New Cell", subtitle: "", detail: "",
                                        action: "none", highlighted: false, customizable: true, color: ""
                                    })
                                    BeeConfig.saveConfig()
                                    dashConfig.selectedIndex = BeeConfig.cells.count - 1
                                    dashConfig.loadCell(dashConfig.selectedIndex)
                                    BeeBarState.logAction("My Hive", _fr ? "Nouvelle alv\u00E9ole ajout\u00E9e" : "New cell added", "\u2795")
                                }
                            }
                        }

                        // Replace cell (module library)
                        Rectangle {
                            width: 100; height: 30; radius: 15
                            color: dashConfig.selectedIndex >= 0 ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.12) : Qt.rgba(0.5, 0.5, 0.5, 0.08)
                            border.color: dashConfig.selectedIndex >= 0 ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.35) : "#888888"
                            border.width: 1
                            opacity: dashConfig.selectedIndex >= 0 ? 1 : 0.4
                            Text { text: _fr ? "\uD83D\uDD04 Remplacer" : "\uD83D\uDD04 Replace"; color: dashConfig.selectedIndex >= 0 ? BeeTheme.accent : "#888888"; font.pixelSize: 10; font.bold: true; anchors.centerIn: parent }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                enabled: dashConfig.selectedIndex >= 0
                                onClicked: { if (dashConfig.selectedIndex >= 0) cellsTab.libraryOpen = true }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Delete cell
                        Rectangle {
                            width: 100; height: 30; radius: 15
                            color: dashConfig.selectedIndex >= 0 && dashConfig._cellDeletable ? Qt.rgba(0.9, 0.2, 0.2, 0.15) : Qt.rgba(0.5, 0.5, 0.5, 0.1)
                            border.color: dashConfig.selectedIndex >= 0 && dashConfig._cellDeletable ? "#ff4444" : "#888888"
                            border.width: 1
                            opacity: dashConfig.selectedIndex >= 0 && dashConfig._cellDeletable ? 1 : 0.5
                            Text { text: _fr ? "🗑️ Supprimer" : "🗑️ Delete"; color: dashConfig.selectedIndex >= 0 && dashConfig._cellDeletable ? "#ff4444" : "#888888"; font.pixelSize: 11; font.bold: true; anchors.centerIn: parent }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                enabled: dashConfig.selectedIndex >= 0 && dashConfig._cellDeletable
                                onClicked: {
                                    if (dashConfig.selectedIndex >= 0 && dashConfig._cellDeletable) {
                                        BeeConfig.cells.remove(dashConfig.selectedIndex)
                                        dashConfig.selectedIndex = -1
                                        BeeConfig.saveConfig()
                                        BeeBarState.logAction("My Hive", _fr ? "Alvéole supprimée" : "Cell deleted", "🗑️")
                                    }
                                }
                            }
                        }

                        // Save
                        Rectangle {
                            width: 130; height: 30; radius: 15
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.40); border.width: 1
                            Text { text: dashConfig.selectedIndex >= 0 ? (_fr ? "💾 Sauvegarder" : "💾 Save") : ""; color: BeeTheme.accent; font.pixelSize: 11; font.bold: true; anchors.centerIn: parent; Behavior on color { ColorAnimation { duration: 600 } } }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    dashConfig.applyEdits()
                                    BeeBarState.logAction("My Hive", _fr ? "Alvéoles sauvegardées" : "Cells saved", "🍯")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}