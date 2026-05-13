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
        clip: true

        ColumnLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 12
            spacing: 16

            Text {
                text: "♿ " + (BeeConfig.uiLang === "fr" ? "Accessibilité" : "Accessibility")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            // High contrast
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Contraste élevé" : "High contrast"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.accessibilityHighContrast; onToggled: { BeeConfig.accessibilityHighContrast = checked; BeeConfig.saveConfig() } }
            }

            // Reduce animations
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Réduire les animations" : "Reduce animations"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.accessibilityReducedMotion; onToggled: { BeeConfig.accessibilityReducedMotion = checked; BeeConfig.saveConfig() } }
            }

            // Screen reader
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text { text: (BeeConfig.uiLang === "fr" ? "Lecteur d'écran" : "Screen reader"); color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                Switch { checked: BeeConfig.accessibilityScreenReader; onToggled: { BeeConfig.accessibilityScreenReader = checked; BeeConfig.saveConfig() } }
            }

            Item { height: 8 }

            // Text scale slider
            Text {
                text: "🔤 " + (BeeConfig.uiLang === "fr" ? "Taille du texte" : "Text scale")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                    text: (BeeConfig.uiLang === "fr" ? "Échelle du texte" : "Text scale factor")
                    color: BeeTheme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true
                }
                Text {
                    text: BeeConfig.accessibilityTextScale.toFixed(1) + "×"
                    color: BeeTheme.accent; font.pixelSize: 13; font.bold: true
                    Layout.minimumWidth: 40
                    horizontalAlignment: Text.AlignRight
                }
            }
            Slider {
                Layout.fillWidth: true
                from: 0.8; to: 1.5; stepSize: 0.1
                value: BeeConfig.accessibilityTextScale
                onMoved: { BeeConfig.accessibilityTextScale = Math.round(value * 10) / 10; BeeConfig.saveConfig() }
            }
        }
    }
}