import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// BarWidgetsTab.qml — 🍯 Presets & Alvéoles (Dashboard Layout)
// ═══════════════════════════════════════════════════════════════

Item {
    id: barWidgetsTab

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: barWidgetsTab.width - 32
            spacing: 16

            // ─── Presets ───
            Text {
                text: "🎯 " + (BeeConfig.uiLang === "fr" ? "Préréglages" : "Presets")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            // Restore button
            Rectangle {
                Layout.fillWidth: true; height: 36; radius: 10
                color: restHov.containsMouse ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15) : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06)
                border.color: BeePresets && BeePresets.hasAutoSave && BeePresets.hasAutoSave() ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.30) : Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.10)
                border.width: 1
                opacity: BeePresets && BeePresets.hasAutoSave && BeePresets.hasAutoSave() ? 1.0 : 0.4
                RowLayout {
                    anchors.centerIn: parent; spacing: 6
                    Text { text: "↩️"; font.pixelSize: 14 }
                    Text {
                        text: (BeeConfig.uiLang === "fr" ? "Restaurer la dernière grille" : "Restore last layout")
                        color: BeeTheme.textPrimary; font.pixelSize: 12; font.bold: true
                    }
                }
                MouseArea {
                    id: restHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: if (BeePresets && BeePresets.restoreAutoSave) BeePresets.restoreAutoSave()
                }
            }

            Item { height: 8 }

            // Preset cards
            Text {
                text: (BeeConfig.uiLang === "fr" ? "PRÉRÉGLAGES SAUVEGARDÉS" : "SAVED PRESETS")
                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.40)
                font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.5
            }

            Flow {
                Layout.fillWidth: true; spacing: 14
                Repeater {
                    model: BeePresets && BeePresets.presets ? BeePresets.presets : []
                    delegate: Rectangle {
                        width: 170; height: 140; radius: 14
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06)
                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15); border.width: 1

                        property bool hovered: false
                        property bool isDefault: modelData.name === "Travail" || modelData.name === "Gaming" || modelData.name === "Weekend"

                        ColumnLayout {
                            anchors { fill: parent; margins: 12; topMargin: 14 }; spacing: 4
                            RowLayout {
                                spacing: 6
                                Text { text: modelData.icon || "🍯"; font.pixelSize: 20 }
                                Text {
                                    text: modelData.name || ""
                                    color: BeeTheme.accent; font.pixelSize: 13; font.bold: true
                                    Layout.fillWidth: true; elide: Text.ElideRight
                                }
                            }
                            Text {
                                text: (modelData.cells ? modelData.cells.length : 0) + (BeeConfig.uiLang === "fr" ? " alvéoles" : " cells")
                                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.35)
                                font.pixelSize: 9
                            }
                            // Mini grid preview
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 50; radius: 8
                                color: Qt.rgba(BeeTheme.glassBg.r, BeeTheme.glassBg.g, BeeTheme.glassBg.b, 0.4)
                                Grid {
                                    anchors { fill: parent; margins: 4 }; columns: 4; spacing: 2
                                    Repeater {
                                        model: modelData.cells ? modelData.cells.slice(0, 8) : []
                                        delegate: Rectangle {
                                            width: 32; height: 20; radius: 4
                                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.10)
                                            Text { text: modelData.icon || "📦"; font.pixelSize: 8; anchors.centerIn: parent }
                                        }
                                    }
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onEntered: parent.hovered = true; onExited: parent.hovered = false
                            onClicked: if (BeePresets && BeePresets.applyPreset) BeePresets.applyPreset(modelData.name)
                        }
                    }
                }
            }

            Item { height: 8 }

            // ─── Save Current ───
            Text {
                text: (BeeConfig.uiLang === "fr" ? "SAUVEGARDER LA GRILLE ACTUELLE" : "SAVE CURRENT LAYOUT")
                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.40)
                font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.5
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 10
                TextField {
                    id: presetNameField
                    Layout.fillWidth: true; height: 36
                    placeholderText: (BeeConfig.uiLang === "fr" ? "Nom du préréglage" : "Preset name")
                    color: BeeTheme.textPrimary; font.pixelSize: 12
                    leftPadding: 10; rightPadding: 10
                    background: Rectangle {
                        radius: 7
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.07)
                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, presetNameField.activeFocus ? 0.5 : 0.15)
                        border.width: 1
                    }
                }
                Rectangle {
                    width: 100; height: 36; radius: 10
                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.16)
                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.40); border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: (BeeConfig.uiLang === "fr" ? "Sauvegarder" : "Save")
                        color: BeeTheme.accent; font.pixelSize: 12; font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var name = presetNameField.text.trim()
                            if (name.length > 0 && BeePresets && BeePresets.saveCurrentAsPreset) {
                                BeePresets.saveCurrentAsPreset(name, "🍯")
                                presetNameField.text = ""
                            }
                        }
                    }
                }
            }
        }
    }
}