import QtQuick
import QtQuick.Effects

// ════════════════════════════════════════════════════════════
// BeePower.qml — Menu d'alimentation Bee-Hive OS 🐝⚡
// v1.0 : 4 alvéoles hexagonales (Éteindre/Redémarrer/Quitter/Verrouiller)
// ════════════════════════════════════════════════════════════

Item {
    id: beePower

    signal closeRequested()
    signal actionRequested(string cmd)

    // ─── Backdrop semi-transparent (clic → fermer) ────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.75)

        MouseArea {
            anchors.fill: parent
            onClicked: beePower.closeRequested()
        }
    }

    // ─── Panneau central ──────────────────────────────────────
    Rectangle {
        id: panel
        width:  480
        height: 440
        anchors.centerIn: parent
        radius: 26
        color: BeeTheme.mode === "HoneyDark"
            ? Qt.rgba(0.03, 0.03, 0.05, 0.98)
            : Qt.rgba(0.97, 0.95, 0.92, 0.98)
        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.45)
        border.width: 1

        Behavior on color        { ColorAnimation { duration: 600 } }
        Behavior on border.color { ColorAnimation { duration: 600 } }

        // Ombre / glow doré
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.22)
            shadowBlur: 0.9
            shadowVerticalOffset:   0
            shadowHorizontalOffset: 0
        }

        // Intercepte les clicks (ne ferme pas le backdrop)
        MouseArea { anchors.fill: parent; onClicked: {} }

        // ─── Ligne accent haut ─────────────────────────────────
        Rectangle {
            width: parent.width * 0.55
            height: 1
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.75) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // ─── Header ────────────────────────────────────────────
        Row {
            anchors.top:     parent.top
            anchors.left:    parent.left
            anchors.topMargin:  24
            anchors.leftMargin: 28
            spacing: 10

            Text {
                text: "⚡"
                font.pixelSize: 20
                color: BeeTheme.accent
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "BEE POWER"
                font.bold: true
                font.pixelSize: 15
                font.letterSpacing: 3
                color: BeeTheme.accent
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Bouton fermeture (Top Right)
        Rectangle {
            id: closeRect
            anchors { right: parent.right; top: parent.top; margins: 12 }
            z: 100
            width: 32; height: 32; radius: 16
            color: closeHov.containsMouse
                ? Qt.rgba(1.0, 0.3, 0.3, 0.2)
                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
            border.color: closeHov.containsMouse
                ? Qt.rgba(1.0, 0.3, 0.3, 0.5)
                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                text: "✕"; anchors.centerIn: parent
                color: closeHov.containsMouse ? "#ff5555" : BeeTheme.accent
                font { pixelSize: 14; bold: true }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            MouseArea {
                id: closeHov; anchors.fill: parent
                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                onClicked: beePower.closeRequested()
            }
        }

        // ─── Sous-titre ────────────────────────────────────────
        Text {
            anchors.top:              parent.top
            anchors.topMargin:        74
            anchors.horizontalCenter: parent.horizontalCenter
            text: (BeeConfig.tr.power && BeeConfig.tr.power.subtitle) || "What would you like to do?"
            font.pixelSize: 13
            font.letterSpacing: 1
            color: BeeTheme.textPrimary
            opacity: 0.85
        }

        // ─── Grille 2×2 d'alvéoles hexagonales ────────────────
        Grid {
            columns: 2
            spacing: 22
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 18

            Repeater {
                model: [
                    { icon: "⚡",  key: "shutdown", cmd: "systemctl poweroff",     col: "#FF5555" },
                    { icon: "↺",  key: "reboot",   cmd: "systemctl reboot",        col: "#FFB81C" },
                    { icon: "⇦",  key: "logout",   cmd: "hyprctl dispatch exit 0", col: "#4FC3F7" },
                    { icon: "🔒", key: "lock",     cmd: "hyprlock",                col: "#A5D6A7" },
                ]

                delegate: Item {
                    id: hexCell

                    // Capture des propriétés du modèle
                    readonly property string btnIcon:  modelData.icon
                    readonly property string btnCmd:   modelData.cmd
                    readonly property string btnLabel: {
                        var p = BeeConfig.tr.power
                        if (!p) {
                            var fb = { shutdown: "Éteindre", reboot: "Redémarrer", logout: "Déconnexion", lock: "Verrouiller" }
                            return fb[modelData.key] || modelData.key
                        }
                        return p[modelData.key] || modelData.key
                    }
                    readonly property color  btnColor: modelData.col
                    property bool hovered: false

                    // Hexagone pointy-top : rayon centre-sommet = 58px
                    readonly property real hexR: 58
                    width:  Math.round(hexR * Math.sqrt(3))   // ≈ 100px
                    height: hexR * 2                           // = 116px

                    // ─── Canvas hexagonal ──────────────────────
                    Canvas {
                        id: hexCanvas
                        anchors.fill: parent

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            var cx = width  / 2
                            var cy = height / 2
                            var r  = hexCell.hexR - 2   // légère marge interne

                            // Pointy-top : 1er sommet en haut (angle -90°)
                            ctx.beginPath()
                            for (var i = 0; i < 6; i++) {
                                var angle = Math.PI / 3 * i - Math.PI / 2
                                var x = cx + r * Math.cos(angle)
                                var y = cy + r * Math.sin(angle)
                                if (i === 0) ctx.moveTo(x, y)
                                else         ctx.lineTo(x, y)
                            }
                            ctx.closePath()

                            // Composantes RGB de la couleur d'action
                            var cr = Math.round(hexCell.btnColor.r * 255)
                            var cg = Math.round(hexCell.btnColor.g * 255)
                            var cb = Math.round(hexCell.btnColor.b * 255)

                            ctx.fillStyle   = "rgba(" + cr + "," + cg + "," + cb + "," + (hexCell.hovered ? 0.28 : 0.07) + ")"
                            ctx.fill()
                            ctx.strokeStyle = "rgba(" + cr + "," + cg + "," + cb + "," + (hexCell.hovered ? 0.85 : 0.38) + ")"
                            ctx.lineWidth   = hexCell.hovered ? 1.8 : 1.2
                            ctx.stroke()
                        }
                    }

                    // ─── Icône + label ─────────────────────────
                    Column {
                        anchors.centerIn: parent
                        spacing: 7

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: hexCell.btnIcon
                            font.pixelSize: 28
                            color: hexCell.hovered ? hexCell.btnColor : BeeTheme.textPrimary
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: hexCell.btnLabel
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1
                            color: hexCell.hovered ? hexCell.btnColor : BeeTheme.textPrimary
                            opacity: hexCell.hovered ? 1.0 : 0.85
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    // ─── Interactions souris ───────────────────
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: { hexCell.hovered = true;  hexCanvas.requestPaint() }
                        onExited:  { hexCell.hovered = false; hexCanvas.requestPaint() }
                        onClicked: beePower.actionRequested(hexCell.btnCmd)
                    }
                }
            }
        }

        // ─── Footer hint ───────────────────────────────────────
        Text {
            anchors.bottom:           parent.bottom
            anchors.bottomMargin:     18
            anchors.horizontalCenter: parent.horizontalCenter
            text: (BeeConfig.tr.power && BeeConfig.tr.power.footer) || "click outside to close"
            font.pixelSize: 11
            font.letterSpacing: 0.8
            color: BeeTheme.textPrimary
            opacity: 0.60
        }
    }

    // ─── Animation d'apparition (scale + fade) ────────────────
    Component.onCompleted: {
        panel.scale   = 0.88
        panel.opacity = 0.0
        appearAnim.start()
    }

    ParallelAnimation {
        id: appearAnim
        running: false
        NumberAnimation {
            target: panel; property: "scale"
            from: 0.88; to: 1.0
            duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.2
        }
        NumberAnimation {
            target: panel; property: "opacity"
            from: 0.0; to: 1.0
            duration: 190
        }
    }
}
