import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// BarWidgetsTab.qml — 📊 Bar & Widgets Settings
// Toggles pour la BeeBar, horloge, vibe, corners, batterie
// ═══════════════════════════════════════════════════════════════

Item {
    id: barWidgetsTab

    property string _fr: BeeConfig.uiLang === "fr"

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: barWidgetsTab.width - 32
            spacing: 16

            // ═══════════════════════════════════════════════════
            // Section: Horloge
            // ═══════════════════════════════════════════════════
            Text {
                text: "🕐 " + (_fr ? "Horloge" : "Clock")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: _fr ? "Horloge analogique" : "Analog clock"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: _fr ? "Afficher l'horloge analogique au centre du tableau de bord" : "Show analog clock in the center of the dashboard"
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

            // ═══════════════════════════════════════════════════
            // Section: Indicateurs système
            // ═══════════════════════════════════════════════════
            Text {
                text: "📟 " + (_fr ? "Indicateurs système" : "System indicators")
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
                Text { text: _fr ? "Disque" : "Disk"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.showDisk; onToggled: { BeeConfig.showDisk = checked; BeeConfig.saveConfig() } }
            }
            RowLayout { Layout.fillWidth: true; spacing: 12
                Text { text: _fr ? "Réseau" : "Network"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.showNet; onToggled: { BeeConfig.showNet = checked; BeeConfig.saveConfig() } }
            }
            RowLayout { Layout.fillWidth: true; spacing: 12
                Text { text: _fr ? "Batterie" : "Battery"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.showBattery; onToggled: { BeeConfig.showBattery = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 4 }

            // ═══════════════════════════════════════════════════
            // Section: Comportement de la barre
            // ═══════════════════════════════════════════════════
            Text {
                text: "🎛️ " + (_fr ? "Comportement de la barre" : "Bar behavior")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: _fr ? "Barre contextuelle" : "Contextual bar"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: _fr ? "La barre s'adapte au contexte de l'app active" : "Bar adapts to the active app context"
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
                        text: _fr ? "Mode furtif" : "Stealth mode"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: _fr ? "Barre minimale, icônes uniquement" : "Minimal bar, icons only"
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
                        text: _fr ? "Mode concentration" : "Focus mode"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: _fr ? "Masque les distractions, notifications minimales" : "Hide distractions, minimal notifications"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch { checked: BeeConfig.focusMode; onToggled: { BeeConfig.focusMode = checked; BeeConfig.saveConfig() } }
            }


            // Section: Vibe (Audio Visualizer)
            // ═══════════════════════════════════════════════════
            Text {
                text: "🎵 " + (_fr ? "Vibe (Visualiseur audio)" : "Vibe (Audio Visualizer)")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
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
                        text: _fr ? "Visualiseur de spectre audio en arrière-plan" : "Audio spectrum visualizer in background"
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
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: _fr ? "Mode X-Ray" : "X-Ray mode"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: _fr ? "Révèle les couleurs du fond d'écran à travers le visualiseur" : "Reveal wallpaper colors through the visualizer"
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

            Item { height: 4 }

            // ═══════════════════════════════════════════════════
            // Section: Batterie
            // ═══════════════════════════════════════════════════
            Text {
                text: "🔋 " + (_fr ? "Batterie & Économie d'énergie" : "Battery & Power Saver")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: _fr ? "Mode économie d'énergie" : "Power saver mode"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: _fr ? "Réduit les animations et les effets visuels" : "Reduces animations and visual effects"
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
                        text: _fr ? "Détection automatique" : "Auto-detect"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: _fr ? "Détecte automatiquement si sur batterie ou secteur" : "Auto-detect battery vs AC power status"
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
                    text: _fr ? "Seuil d'économie (%)" : "Saver threshold (%)"
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

            // ═══════════════════════════════════════════════════
            // Section: Hot Corners
            // ═══════════════════════════════════════════════════
            Text {
                text: "🔲 " + (_fr ? "Coins actifs" : "Hot Corners")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: _fr ? "Coins actifs (Hot Corners)" : "Hot Corners"
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: _fr ? "Actions rapides en pointant les coins de l'écran" : "Quick actions by pointing at screen corners"
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