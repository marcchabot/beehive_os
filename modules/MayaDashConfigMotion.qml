import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// MayaDashConfigMotion.qml — Animations & Transitions 🌀
// ═══════════════════════════════════════════════════════════════

Item {
    id: motionTab
    property string _fr: BeeConfig.uiLang === "fr" ? "1" : ""

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: motionTab.width - 40
            spacing: 16

            // ─── Parallax ───
            Text {
                text: "🌀 " + (_fr ? "Mouvement" : "Motion")
                color: BeeTheme.accent; font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: _fr ? "Effet parallaxe" : "Parallax effect"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: _fr ? "Inclinaison 3D selon la position de la souris" : "3D tilt following mouse position"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch {
                    checked: BeeBarState.motionActive
                    onToggled: { BeeBarState.motionActive = checked }
                }
            }

            Item { height: 4 }

            // ─── Visual effects ───
            Text {
                text: "✨ " + (_fr ? "Effets visuels" : "Visual effects")
                color: BeeTheme.accent; font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: _fr ? "Réduit les animations et les effets visuels" : "Reduces animations and visual effects"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: _fr ? "Mode simplifié pour de meilleures performances" : "Simplified mode for better performance"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch {
                    checked: BeeConfig.batterySaverActive
                    onToggled: { BeeConfig.batterySaverActive = checked; BeeConfig.saveConfig() }
                }
            }

            Item { height: 4 }

            // ─── Audio visualizer ───
            Text {
                text: "🎵 " + (_fr ? "Visualiseur audio" : "Audio visualizer")
                color: BeeTheme.accent; font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: _fr ? "Visualiseur audio" : "Audio visualizer"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: _fr ? "Barres de spectre audio dans les alvéoles" : "Audio spectrum bars in cells"
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

            // Vibe backend
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.vibeMode
                Text {
                    text: _fr ? "Backend" : "Backend"
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
                visible: BeeConfig.vibeMode
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: _fr ? "Mode X-Ray" : "X-Ray mode"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: _fr ? "Révèle les couleurs du fond d'écran" : "Reveal wallpaper colors"
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
                visible: BeeConfig.vibeMode && BeeConfig.vibeXray
                Text {
                    text: _fr ? "Intensité X-Ray" : "X-Ray intensity"
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
                onMoved: { BeeConfig.vibeXrayIntensity = value; BeeConfig.saveConfig() }
            }

            // X-Ray blend mode
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                visible: BeeConfig.vibeMode && BeeConfig.vibeXray
                Text {
                    text: _fr ? "Fusion X-Ray" : "X-Ray blend"
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
        }
    }
}