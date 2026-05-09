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
                    BeeField { id: actionField; placeholderText: "none | app:nom | toggle:settings"; onTextEdited: { if (!dashConfig._loading) dashConfig.editAction = text } }

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
                        Layout.fillWidth: true; spacing: 10
                        Layout.topMargin: 8

                        // Add cell
                        Rectangle {
                            width: 100; height: 30; radius: 15
                            color: Qt.rgba(0.2, 0.7, 0.3, 0.15)
                            border.color: Qt.rgba(0.2, 0.7, 0.3, 0.40); border.width: 1
                            Text { text: _fr ? "➕ Ajouter" : "➕ Add"; color: "#4CAF50"; font.pixelSize: 11; font.bold: true; anchors.centerIn: parent }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BeeConfig.cells.append({
                                        icon: "🐝", title: "New Cell", subtitle: "", detail: "",
                                        action: "none", highlighted: false, customizable: true, color: ""
                                    })
                                    BeeConfig.saveConfig()
                                    dashConfig.selectedIndex = BeeConfig.cells.count - 1
                                    dashConfig.loadCell(dashConfig.selectedIndex)
                                    BeeBarState.logAction("My Hive", _fr ? "Nouvelle alvéole ajoutée" : "New cell added", "➕")
                                }
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