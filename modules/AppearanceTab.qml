import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// AppearanceTab.qml — 🎨 Appearance & Theme Settings
// ═══════════════════════════════════════════════════════════════

Item {
    id: appearanceTab

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: appearanceTab.width - 32
            spacing: 16

            // ─── Theme Mode ───
            Text {
                text: "🎨 " + (BeeConfig.uiLang === "fr" ? "Thème" : "Theme")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Repeater {
                    model: [
                        { key: "HoneyDark", icon: "🌙", label: "Dark", labelFr: "Sombre" },
                        { key: "HoneyLight", icon: "☀️", label: "Light", labelFr: "Clair" }
                    ]
                    delegate: Rectangle {
                        width: 130; height: 70; radius: 12
                        color: BeeConfig.mode === modelData.key
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                            : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.08)
                        border.color: BeeConfig.mode === modelData.key
                            ? BeeTheme.accent
                            : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.5)
                        border.width: BeeConfig.mode === modelData.key ? 2 : 1.5
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        Behavior on border.width { NumberAnimation { duration: 200 } }

                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 4
                            Text {
                                text: modelData.icon; font.pixelSize: 24
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: BeeConfig.uiLang === "fr" ? modelData.labelFr : modelData.label
                                color: BeeConfig.mode === modelData.key ? BeeTheme.accent : BeeTheme.textSecondary
                                font.pixelSize: 12; font.bold: BeeConfig.mode === modelData.key
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onClicked: { BeeTheme.setMode(modelData.key); BeeConfig.mode = modelData.key; BeeConfig.saveConfig() }
                        }
                    }
                }
            }

            // ─── Nectar Sync (Auto-adjust theme) ───
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: (BeeConfig.uiLang === "fr" ? "Synchronisation Nectar" : "Nectar Sync")
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: (BeeConfig.uiLang === "fr" ? "Ajuster automatiquement le thème selon l'heure et le fond d'écran" : "Auto-adjust theme based on time of day and wallpaper")
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch {
                    checked: BeeConfig.nectarAutoSchedule
                    onToggled: { BeeConfig.nectarAutoSchedule = checked; BeeConfig.saveConfig() }
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: (BeeConfig.uiLang === "fr" ? "Couleurs du fond d'écran" : "Wallpaper colors")
                        color: BeeTheme.textPrimary; font.pixelSize: 13; font.bold: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                    Text {
                        text: (BeeConfig.uiLang === "fr" ? "Extrait les couleurs dominantes du fond d'écran" : "Extract dominant colors from wallpaper")
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                        font.pixelSize: 10; font.italic: true
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Switch {
                    checked: BeeConfig.nectarSync
                    onToggled: { BeeConfig.nectarSync = checked; BeeConfig.saveConfig() }
                }
            }

            Item { height: 4 }

            // ─── Bar Style ───
            Text {
                text: "📊 " + (BeeConfig.uiLang === "fr" ? "Style de la barre" : "Bar style")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Barre contextuelle" : "Contextual bar"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.contextualBar; onToggled: { BeeConfig.contextualBar = checked; BeeConfig.saveConfig() } }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Mode furtif (minimal)" : "Stealth mode (minimal)"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.stealthMode; onToggled: { BeeConfig.stealthMode = checked; BeeConfig.saveConfig() } }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Mode concentration" : "Focus mode"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.focusMode; onToggled: { BeeConfig.focusMode = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 4 }

            // ─── Indicators ───
            Text {
                text: "📟 " + (BeeConfig.uiLang === "fr" ? "Indicateurs système" : "System indicators")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout { Layout.fillWidth: true; spacing: 12; Text { text: "CPU"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true } Switch { checked: BeeConfig.showCpu; onToggled: { BeeConfig.showCpu = checked; BeeConfig.saveConfig() } } }
            RowLayout { Layout.fillWidth: true; spacing: 12; Text { text: "RAM"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true } Switch { checked: BeeConfig.showRam; onToggled: { BeeConfig.showRam = checked; BeeConfig.saveConfig() } } }
            RowLayout { Layout.fillWidth: true; spacing: 12; Text { text: "DISK"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true } Switch { checked: BeeConfig.showDisk; onToggled: { BeeConfig.showDisk = checked; BeeConfig.saveConfig() } } }
            RowLayout { Layout.fillWidth: true; spacing: 12; Text { text: "NET"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true } Switch { checked: BeeConfig.showNet; onToggled: { BeeConfig.showNet = checked; BeeConfig.saveConfig() } } }
            RowLayout { Layout.fillWidth: true; spacing: 12; Text { text: "BAT"; color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true } Switch { checked: BeeConfig.showBattery; onToggled: { BeeConfig.showBattery = checked; BeeConfig.saveConfig() } } }
        }
    }
}