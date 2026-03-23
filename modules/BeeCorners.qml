import Quickshell
import QtQuick

// ═══════════════════════════════════════════════════════════════
// BeeCorners.qml — Coins d'écran arrondis (Fake Rounding) 🐝📱
// Ajoute une bordure organique à l'écran pour un look Premium
// ═══════════════════════════════════════════════════════════════

Item {
    id: cornersRoot
    anchors.fill: parent
    z: 1000 // Toujours par-dessus tout

    property int cornerRadius: 24
    property color cornerColor: "#000000"
    property bool active: true

    visible: active

    // Coin Haut-Gauche
    Canvas {
        width: cornerRadius; height: cornerRadius
        anchors.left: parent.left; anchors.top: parent.top
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = cornerColor
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(width, 0)
            ctx.arcTo(0, 0, 0, height, cornerRadius)
            ctx.closePath()
            ctx.fill()
        }
    }

    // Coin Haut-Droite
    Canvas {
        width: cornerRadius; height: cornerRadius
        anchors.right: parent.right; anchors.top: parent.top
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = cornerColor
            ctx.beginPath()
            ctx.moveTo(width, 0)
            ctx.lineTo(0, 0)
            ctx.arcTo(width, 0, width, height, cornerRadius)
            ctx.closePath()
            ctx.fill()
        }
    }

    // Coin Bas-Gauche
    Canvas {
        width: cornerRadius; height: cornerRadius
        anchors.left: parent.left; anchors.bottom: parent.bottom
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = cornerColor
            ctx.beginPath()
            ctx.moveTo(0, height)
            ctx.lineTo(width, height)
            ctx.arcTo(0, height, 0, 0, cornerRadius)
            ctx.closePath()
            ctx.fill()
        }
    }

    // Coin Bas-Droite
    Canvas {
        width: cornerRadius; height: cornerRadius
        anchors.right: parent.right; anchors.bottom: parent.bottom
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = cornerColor
            ctx.beginPath()
            ctx.moveTo(width, height)
            ctx.lineTo(0, height)
            ctx.arcTo(width, height, width, 0, cornerRadius)
            ctx.closePath()
            ctx.fill()
        }
    }
}
