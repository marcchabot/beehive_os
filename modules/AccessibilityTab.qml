import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// AccessibilityTab.qml — ♿ Accessibility Settings
// ═══════════════════════════════════════════════════════════════

Item {
    id: accessibilityTab

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: accessibilityTab.width - 32
            spacing: 16

            Text {
                text: "♿ " + (BeeConfig.uiLang === "fr" ? "Accessibilité" : "Accessibility")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Contraste élevé" : "High contrast"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.accessibilityHighContrast; onToggled: { BeeConfig.accessibilityHighContrast = checked; BeeConfig.saveConfig() } }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Réduire les animations" : "Reduce motion"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.accessibilityReducedMotion; onToggled: { BeeConfig.accessibilityReducedMotion = checked; BeeConfig.saveConfig() } }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Lecteur d'écran" : "Screen reader"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.accessibilityScreenReader; onToggled: { BeeConfig.accessibilityScreenReader = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 8 }

            // Text scale
            Text {
                text: "🔤 " + (BeeConfig.uiLang === "fr" ? "Taille du texte" : "Text scale")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Repeater {
                    model: [
                        { value: 0, label: "S", labelFr: "P" },
                        { value: 1, label: "M", labelFr: "M" },
                        { value: 2, label: "L", labelFr: "G" },
                        { value: 3, label: "XL", labelFr: "TG" }
                    ]
                    delegate: Rectangle {
                        width: 50; height: 34; radius: 8
                        color: BeeConfig.accessibilityTextScale === modelData.value
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                            : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.1)
                        border.color: BeeConfig.accessibilityTextScale === modelData.value ? BeeTheme.accent : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.2)
                        Text {
                            anchors.centerIn: parent
                            text: BeeConfig.uiLang === "fr" ? modelData.labelFr : modelData.label
                            color: BeeConfig.accessibilityTextScale === modelData.value ? BeeTheme.accent : BeeTheme.textSecondary
                            font.pixelSize: 13; font.bold: BeeConfig.accessibilityTextScale === modelData.value
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { BeeConfig.accessibilityTextScale = modelData.value; BeeConfig.saveConfig() }
                        }
                    }
                }
            }
        }
    }
}