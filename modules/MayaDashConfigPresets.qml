import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// MayaDashConfigPresets.qml — Presets Management 🎨
// ═══════════════════════════════════════════════════════════════

Item {
    id: presetsTab
    property string _fr: BeeConfig.uiLang === "fr" ? "1" : ""

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: presetsTab.width - 40
            spacing: 16

            Text {
                text: "🎨 " + (_fr ? "Préréglages d'alvéoles" : "Cell Presets")
                color: BeeTheme.accent; font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            Text {
                text: _fr ? "Appliquez un agencement prédéfini à vos alvéoles." : "Apply a predefined layout to your cells."
                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true
            }

            // ─── Preset Cards ───
            Repeater {
                model: BeePresets.presets

                delegate: Rectangle {
                    Layout.fillWidth: true; height: 64; radius: 12
                    color: BeeTheme.mode === "HoneyDark"
                        ? Qt.rgba(0.12, 0.11, 0.14, 0.9)
                        : Qt.rgba(1.0, 1.0, 1.0, 0.7)
                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 300 } }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 14; spacing: 12

                        Text { text: modelData.icon || "🍯"; font.pixelSize: 28 }

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 2
                            Text {
                                text: modelData.name || "Preset"
                                color: BeeTheme.textPrimary; font.bold: true; font.pixelSize: 13
                                Behavior on color { ColorAnimation { duration: 600 } }
                            }
                            Text {
                                text: (modelData.cells ? modelData.cells.length : 0) + (_fr ? " alvéoles" : " cells")
                                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.5)
                                font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true
                            }
                        }

                        Rectangle {
                            width: 90; height: 32; radius: 16
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: _fr ? "Appliquer" : "Apply"
                                color: BeeTheme.accent; font.pixelSize: 11; font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: {
                                    BeePresets.applyPreset(modelData.name)
                                    BeeConfig.saveConfig()
                                    BeeBarState.logAction("Presets", _fr ? "Preset appliqué : " + modelData.name : "Preset applied: " + modelData.name, "🎨")
                                }
                            }
                        }
                    }
                }
            }

            Item { height: 20 }

            // ─── Reset ───
            Rectangle {
                Layout.fillWidth: true; height: 44; radius: 10
                color: Qt.rgba(0.9, 0.2, 0.2, 0.08)
                border.color: Qt.rgba(0.9, 0.2, 0.2, 0.25); border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: _fr ? "🔄 Réinitialiser aux valeurs par défaut" : "🔄 Reset to defaults"
                    color: "#ff6666"; font.pixelSize: 12; font.bold: true
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        BeePresets.applyPreset("default")
                        BeeConfig.saveConfig()
                    }
                }
            }
        }
    }
}