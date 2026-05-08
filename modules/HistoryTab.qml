import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// HistoryTab.qml — 📋 Notification History
// ═══════════════════════════════════════════════════════════════

Item {
    id: historyTab

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: historyTab.width - 32
            spacing: 16

            // Header
            Text {
                text: "📋 " + (BeeConfig.uiLang === "fr" ? "Historique des notifications" : "Notification history")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Activer l'historique" : "Enable history"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.historyEnabled; onToggled: { BeeConfig.historyEnabled = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 4 }

            // History list
            ListView {
                id: historyList
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 400)
                spacing: 4
                model: BeeBarState.historyModel
                clip: true

                delegate: Rectangle {
                    width: historyList.width
                    height: 48
                    radius: 8
                    color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.15)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Text {
                            text: modelData.icon || "🐝"
                            font.pixelSize: 18
                            Layout.preferredWidth: 28
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                text: modelData.category || ""
                                color: BeeTheme.textPrimary
                                font.pixelSize: 12
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: modelData.message || ""
                                color: BeeTheme.textSecondary
                                font.pixelSize: 11
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                        Text {
                            text: modelData.timestamp || ""
                            color: BeeTheme.textSecondary
                            font.pixelSize: 10
                            Layout.preferredWidth: 46
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

            // Empty state
            Text {
                Layout.fillWidth: true
                visible: BeeBarState.historyModel.length === 0
                text: BeeConfig.uiLang === "fr"
                    ? "Aucune notification pour le moment."
                    : "No notifications yet."
                color: BeeTheme.textSecondary
                font.pixelSize: 12
                font.italic: true
                horizontalAlignment: Text.AlignHCenter
            }

            // Clear all button
            Button {
                Layout.alignment: Qt.AlignHCenter
                visible: BeeBarState.historyModel.length > 0
                text: BeeConfig.uiLang === "fr" ? "Effacer tout" : "Clear all"
                onClicked: BeeBarState.clearHistory()

                background: Rectangle {
                    radius: 8
                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                    border.width: 1
                }
                contentItem: Text {
                    text: parent.text
                    color: BeeTheme.accent
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}