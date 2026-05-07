import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// WallpaperTab.qml — 🖼️ Wallpaper Settings
// ═══════════════════════════════════════════════════════════════

Item {
    id: wallpaperTab

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: wallpaperTab.width - 32
            spacing: 16

            // Section: Wallpaper
            Text {
                text: "🖼️ " + (BeeConfig.uiLang === "fr" ? "Fond d'écran" : "Wallpaper")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: (BeeConfig.uiLang === "fr" ? "Changer le fond d'écran" : "Change wallpaper")
                    color: BeeTheme.textPrimary; font.pixelSize: 13
                    Layout.fillWidth: true
                }
                Rectangle {
                    width: 120; height: 36; radius: 8
                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                    border.color: BeeTheme.accent; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: (BeeConfig.uiLang === "fr" ? "Parcourir" : "Browse")
                        color: BeeTheme.accent; font.pixelSize: 13; font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: BeeConfig.pickWallpaper()
                    }
                }
                Rectangle {
                    width: 120; height: 36; radius: 8
                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                    border.color: BeeTheme.accent; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "🎲 " + (BeeConfig.uiLang === "fr" ? "Aléatoire" : "Random")
                        color: BeeTheme.accent; font.pixelSize: 13; font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: BeeConfig.randomWallpaper()
                    }
                }
            }

            Item { height: 8 }

            // Section: Nectar Sync
            Text {
                text: "🍯 " + (BeeConfig.uiLang === "fr" ? "Nectar Sync" : "Nectar Sync")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: (BeeConfig.uiLang === "fr" ? "Synchroniser les couleurs avec le fond d'écran" : "Sync colors with wallpaper")
                    color: BeeTheme.textPrimary; font.pixelSize: 13
                    Layout.fillWidth: true
                }
                Switch {
                    checked: BeeConfig.nectarAutoSchedule
                    onToggled: { BeeConfig.nectarAutoSchedule = checked; BeeConfig.saveConfig() }
                }
            }
        }
    }
}