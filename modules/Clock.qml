import Quickshell
import QtQuick
import QtQuick.Layouts
import "."

// ═══════════════════════════════════════════════════════════════
// Clock.qml — Horloge Bee-Hive OS 🐝⏰
// Widget flottant avec horloge analogique + digitale
// Style : Nexus doré sur fond sombre, glassmorphism
// ═══════════════════════════════════════════════════════════════

Item {
    id: clockWidget
    width: 280
    height: 320
    visible: BeeConfig.analogClock
    opacity: visible ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 400 } }

    // ─── Propriétés temps ──────────────────────────────────
    property var now: new Date()
    property int hours: now.getHours()
    property int minutes: now.getMinutes()
    property int seconds: now.getSeconds()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            clockWidget.now = new Date()
            clockWidget.hours = clockWidget.now.getHours()
            clockWidget.minutes = clockWidget.now.getMinutes()
            clockWidget.seconds = clockWidget.now.getSeconds()
            analogClock.requestPaint()
        }
    }

    // ═══════════════════════════════════════════════════════════
    // FOND GLASSMORPHISM
    // ═══════════════════════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        radius: 24
        color: Qt.rgba(BeeTheme.bg.r, BeeTheme.bg.g, BeeTheme.bg.b, 0.88)
        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
        border.width: 1
        Behavior on color        { ColorAnimation { duration: 600 } }
        Behavior on border.color { ColorAnimation { duration: 600 } }

        // Lueur interne subtile
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 23
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.03)
            border.width: 1
        }
    }

    // ═══════════════════════════════════════════════════════════
    // HORLOGE ANALOGIQUE (Canvas)
    // ═══════════════════════════════════════════════════════════
    Canvas {
        id: analogClock
        width: 180; height: 180
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 25
        antialiasing: true

        // ─── Re-paint immédiat lors d'un changement de thème ──
        Connections {
            target: BeeTheme
            function onAccentChanged() { analogClock.requestPaint() }
            function onTextPrimaryChanged() { analogClock.requestPaint() }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var cx = width / 2
            var cy = height / 2
            var r = Math.min(width, height) / 2 - 8

            var accentR = BeeTheme.accent.r
            var accentG = BeeTheme.accent.g
            var accentB = BeeTheme.accent.b
            var textR   = BeeTheme.textPrimary.r
            var textG   = BeeTheme.textPrimary.g
            var textB   = BeeTheme.textPrimary.b

            // ─── Cercle extérieur ──────────────────────────
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, 2 * Math.PI)
            ctx.strokeStyle = Qt.rgba(accentR, accentG, accentB, 0.25)
            ctx.lineWidth = 2
            ctx.stroke()

            // ─── Marqueurs des heures ──────────────────────
            for (var i = 0; i < 12; i++) {
                var angle = (Math.PI / 6) * i - Math.PI / 2
                var isMain = (i % 3 === 0)
                var innerR = isMain ? r - 15 : r - 10
                var outerR = r - 4

                ctx.beginPath()
                ctx.moveTo(cx + innerR * Math.cos(angle), cy + innerR * Math.sin(angle))
                ctx.lineTo(cx + outerR * Math.cos(angle), cy + outerR * Math.sin(angle))
                ctx.strokeStyle = isMain
                    ? Qt.rgba(accentR, accentG, accentB, 0.8)
                    : Qt.rgba(textR, textG, textB, 0.2)
                ctx.lineWidth = isMain ? 2.5 : 1
                ctx.stroke()
            }

            // ─── Points des minutes ────────────────────────
            for (var m = 0; m < 60; m++) {
                if (m % 5 !== 0) {
                    var mAngle = (Math.PI / 30) * m - Math.PI / 2
                    ctx.beginPath()
                    ctx.arc(
                        cx + (r - 6) * Math.cos(mAngle),
                        cy + (r - 6) * Math.sin(mAngle),
                        0.5, 0, 2 * Math.PI
                    )
                    ctx.fillStyle = Qt.rgba(textR, textG, textB, 0.1)
                    ctx.fill()
                }
            }

            // ─── Cercle central décoratif ──────────────────
            ctx.beginPath()
            ctx.arc(cx, cy, r - 20, 0, 2 * Math.PI)
            ctx.strokeStyle = Qt.rgba(accentR, accentG, accentB, 0.06)
            ctx.lineWidth = 0.5
            ctx.stroke()

            // ─── Aiguille des heures ───────────────────────
            var hAngle = ((clockWidget.hours % 12) + clockWidget.minutes / 60) * (Math.PI / 6) - Math.PI / 2
            ctx.beginPath()
            ctx.moveTo(cx, cy)
            ctx.lineTo(cx + (r * 0.5) * Math.cos(hAngle), cy + (r * 0.5) * Math.sin(hAngle))
            ctx.strokeStyle = BeeTheme.accent
            ctx.lineWidth = 3.5
            ctx.lineCap = "round"
            ctx.stroke()

            // ─── Aiguille des minutes ──────────────────────
            var minAngle = (clockWidget.minutes + clockWidget.seconds / 60) * (Math.PI / 30) - Math.PI / 2
            ctx.beginPath()
            ctx.moveTo(cx, cy)
            ctx.lineTo(cx + (r * 0.7) * Math.cos(minAngle), cy + (r * 0.7) * Math.sin(minAngle))
            ctx.strokeStyle = Qt.rgba(textR, textG, textB, 0.85)
            ctx.lineWidth = 2
            ctx.lineCap = "round"
            ctx.stroke()

            // ─── Aiguille des secondes ─────────────────────
            var sAngle = clockWidget.seconds * (Math.PI / 30) - Math.PI / 2
            ctx.beginPath()
            ctx.moveTo(cx - 15 * Math.cos(sAngle), cy - 15 * Math.sin(sAngle))
            ctx.lineTo(cx + (r * 0.75) * Math.cos(sAngle), cy + (r * 0.75) * Math.sin(sAngle))
            ctx.strokeStyle = Qt.rgba(accentR, accentG, accentB, 0.6)
            ctx.lineWidth = 1
            ctx.lineCap = "round"
            ctx.stroke()

            // ─── Point central ─────────────────────────────
            ctx.beginPath()
            ctx.arc(cx, cy, 4, 0, 2 * Math.PI)
            ctx.fillStyle = BeeTheme.accent
            ctx.fill()

            ctx.beginPath()
            ctx.arc(cx, cy, 2, 0, 2 * Math.PI)
            ctx.fillStyle = BeeTheme.bg
            ctx.fill()
        }
    }

    // ═══════════════════════════════════════════════════════════
    // HORLOGE DIGITALE
    // ═══════════════════════════════════════════════════════════
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: analogClock.bottom
        anchors.topMargin: 15
        spacing: 4

        // Heure digitale
        Text {
            text: Qt.formatDateTime(clockWidget.now, "hh:mm")
            color: BeeTheme.textPrimary
            font {
                pixelSize: 36
                weight: Font.Light
                family: "monospace"
                letterSpacing: 4
            }
            anchors.horizontalCenter: parent.horizontalCenter
            Behavior on color { ColorAnimation { duration: 600 } }

            // Secondes en petit à côté
            Text {
                text: ":" + Qt.formatDateTime(clockWidget.now, "ss")
                color: BeeTheme.accent
                Behavior on color { ColorAnimation { duration: 600 } }
                font {
                    pixelSize: 18
                    weight: Font.Light
                    family: "monospace"
                }
                anchors.left: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 1000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
                }
            }
        }

        // Date
        Text {
            text: Qt.formatDateTime(clockWidget.now, "dddd d MMMM yyyy")
            color: BeeTheme.textSecondary
            Behavior on color { ColorAnimation { duration: 600 } }
            font { pixelSize: 12; letterSpacing: 1 }
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // Séparateur doré
        Rectangle {
            width: 60; height: 1
            anchors.horizontalCenter: parent.horizontalCenter
            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
        }

        // Petit label
        Text {
            text: (BeeConfig.tr.common && BeeConfig.tr.common.bee_hive_time) || "🐝 Bee-Hive Time"
            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.35)
            Behavior on color { ColorAnimation { duration: 600 } }
            font { pixelSize: 9; letterSpacing: 1.5 }
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
