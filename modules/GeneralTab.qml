import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// GeneralTab.qml — 🏠 General Settings + Keyboard Shortcuts
// ═══════════════════════════════════════════════════════════════

Item {
    id: generalTab

    ScrollView {
        id: generalScroll
        anchors.fill: parent
        anchors.margins: 16
        clip: true

        ColumnLayout {
            width: generalScroll.availableWidth
            spacing: 16

            // ─── Language ───
            Text {
                text: "🌐 " + (BeeConfig.uiLang === "fr" ? "Langue" : "Language")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Repeater {
                    model: [{ key: "en", label: "English" }, { key: "fr", label: "Français" }]
                    delegate: Rectangle {
                        width: 100; height: 34; radius: 8
                        color: BeeConfig.uiLang === modelData.key
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                            : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.1)
                        border.color: BeeConfig.uiLang === modelData.key ? BeeTheme.accent : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.2)
                        border.width: BeeConfig.uiLang === modelData.key ? 1.5 : 1
                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: BeeConfig.uiLang === modelData.key ? BeeTheme.accent : BeeTheme.textSecondary
                            font.pixelSize: 13; font.bold: BeeConfig.uiLang === modelData.key
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { BeeConfig.setLang(modelData.key); BeeConfig.saveConfig() }
                        }
                    }
                }
            }

            Item { height: 8 }

            // ─── Startup ───
            Text {
                text: "⚡ " + (BeeConfig.uiLang === "fr" ? "Démarrage" : "Startup")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Lancer au démarrage" : "Launch at startup"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.launchAtStartup; onToggled: { BeeConfig.launchAtStartup = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 8 }

            // ─── Keyboard Shortcuts ───
            Text {
                text: "⌨️ " + (BeeConfig.uiLang === "fr" ? "Raccourcis clavier" : "Keyboard shortcuts")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            Repeater {
                model: [
                    { key: "Super + D", action: BeeConfig.uiLang === "fr" ? "Tableau de bord (MayaDash)" : "Dashboard (MayaDash)" },
                    { key: "Super + Z", action: BeeConfig.uiLang === "fr" ? "Recherche (BeeSearch)" : "Search (BeeSearch)" },
                    { key: "Super + Escape", action: "The Hive (Settings)" },
                    { key: "Super + P", action: "BeePower" },
                    { key: "Super + M", action: BeeConfig.uiLang === "fr" ? "Assistant vocal (BeeVoice)" : "Voice assistant (BeeVoice)" },
                    { key: "F12", action: BeeConfig.uiLang === "fr" ? "Changer de thème" : "Toggle theme" }
                ]
                delegate: RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    Rectangle {
                        width: 140; height: 28; radius: 6
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3); border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: modelData.key
                            color: BeeTheme.accent; font.pixelSize: 11; font.bold: true
                        }
                    }
                    Text {
                        text: modelData.action
                        color: BeeTheme.textPrimary; font.pixelSize: 13
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}