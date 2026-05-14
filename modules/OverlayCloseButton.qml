import QtQuick

// ═══════════════════════════════════════════════════════════════
// OverlayCloseButton.qml — Floating ✕ close button for overlays 🐝✕
// Unified style: accent-colored, positioned top-right, hover effect
// ═══════════════════════════════════════════════════════════════

Rectangle {
    id: closeBtn
    width: 34; height: 34; radius: 17
    color: closeBtnHover.containsMouse
        ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.45)
        : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
    border.color: closeBtnHover.containsMouse
        ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.9)
        : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.35)
    border.width: 1.5

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    Text {
        anchors.centerIn: parent
        text: "\u2715"   // ✕
        font.pixelSize: 16
        font.bold: true
        color: BeeTheme.accent
    }

    MouseArea {
        id: closeBtnHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: closeBtn.closeAction()
    }

    signal closeAction()
}