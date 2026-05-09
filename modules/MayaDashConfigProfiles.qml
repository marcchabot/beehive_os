import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// MayaDashConfigProfiles.qml — User Profiles 👤
// ═══════════════════════════════════════════════════════════════

Item {
    id: profilesTab
    property string _fr: BeeConfig.uiLang === "fr" ? "1" : ""

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: profilesTab.width - 40
            spacing: 16

            Text {
                text: "👤 " + (_fr ? "Profils" : "Profiles")
                color: BeeTheme.accent; font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            Text {
                text: _fr ? "Gérez vos profils de configuration utilisateur." : "Manage your user configuration profiles."
                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true
            }

            // ─── Active Profile ───
            Rectangle {
                Layout.fillWidth: true; height: 72; radius: 12
                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.10)
                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.30)
                border.width: 2

                RowLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 12

                    Text { text: "🐝"; font.pixelSize: 32 }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text {
                            text: _fr ? "Profil actif : Par défaut" : "Active profile: Default"
                            color: BeeTheme.accent; font.bold: true; font.pixelSize: 13
                        }
                        Text {
                            text: _fr ? "Configuration actuelle de votre tableau de bord" : "Current dashboard configuration"
                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.5)
                            font.pixelSize: 10
                        }
                    }
                }
            }

            // ─── Coming Soon ───
            ColumnLayout {
                Layout.fillWidth: true; spacing: 8
                Layout.topMargin: 16

                Text {
                    text: _fr ? "🚧 Fonctionnalités à venir" : "🚧 Coming soon"
                    color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.4)
                    font.pixelSize: 13; font.bold: true; font.letterSpacing: 0.5
                }

                Repeater {
                    model: [
                        { icon: "💾", text: _fr ? "Sauvegarder le profil actuel" : "Save current profile" },
                        { icon: "📋", text: _fr ? "Charger un profil sauvegardé" : "Load a saved profile" },
                        { icon: "🔄", text: _fr ? "Synchroniser entre appareils (Nectar Sync)" : "Sync across devices (Nectar Sync)" }
                    ]

                    delegate: RowLayout {
                        spacing: 8
                        Text { text: modelData.icon; font.pixelSize: 14; opacity: 0.5 }
                        Text {
                            text: modelData.text
                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.35)
                            font.pixelSize: 11; font.italic: true
                        }
                    }
                }
            }
        }
    }
}