import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Io

// ═══════════════════════════════════════════════════════════════
// BeeSystemMonitor.qml — System Monitor Widget for MayaDash 🐝📊
// v1.0 : CPU, RAM, Temps, Fans, Top Processes, Uptime
// Backend: _bee_sysmon_collect.sh (JSON via Process)
// ═══════════════════════════════════════════════════════════════

Item {
    id: sysmonRoot

    width: 340
    height: 480

    // ─── Signal pour fermer le PanelWindow parent ────────────────
    signal closeRequested()

    // ─── Translations ─────────────────────────────────────────────
    property var tr: BeeConfig.tr.sysmon || ({})

    // ─── Data Model ──────────────────────────────────────────────
    property var sysData: ({
        cpu: { usage: 0, freq: 0 },
        mem: { used: 0, total: 0, pct: 0, swap_used: 0, swap_total: 0, swap_pct: 0 },
        temps: { cpu: 0, gpu: 0 },
        fans: [],
        top: [],
        uptime: "0d 0h 0m"
    })

    // ─── CPU History (30 points for graph) ───────────────────────
    property var cpuHistory: []
    property int maxHistoryPoints: 30

    // ─── FPS Counter ─────────────────────────────────────────────
    property int fpsCount: 0
    property int fpsValue: 0
    property var fpsTimestamp: Date.now()

    // ─── Collect system data via Process ──────────────────────────
    Process {
        id: sysmonProc
        running: false
        command: ["bash", Qt.resolvedUrl("../scripts/_bee_sysmon_collect.sh").toString().replace("file://", "")]

        stdout: SplitParser {
            onRead: (line) => {
                try {
                    var data = JSON.parse(line)
                    sysmonRoot.sysData = data

                    // Update CPU history
                    var hist = sysmonRoot.cpuHistory.slice()
                    hist.push(data.cpu.usage)
                    if (hist.length > sysmonRoot.maxHistoryPoints)
                        hist.shift()
                    sysmonRoot.cpuHistory = hist

                    // FPS estimate
                    var now = Date.now()
                    sysmonRoot.fpsCount++
                    if (now - sysmonRoot.fpsTimestamp >= 1000) {
                        sysmonRoot.fpsValue = sysmonRoot.fpsCount
                        sysmonRoot.fpsCount = 0
                        sysmonRoot.fpsTimestamp = now
                    }
                } catch (e) {
                    console.warn("BeeSystemMonitor: Parse error:", e)
                }
            }
        }

        onExited: (code, status) => {
            // Restart after brief pause
            restartTimer.start()
        }
    }

    // ─── Refresh Timer (every 2s) ────────────────────────────────
    Timer {
        id: refreshTimer
        interval: 2000
        running: sysmonRoot.visible
        repeat: true
        onTriggered: {
            sysmonProc.running = false
            sysmonProc.running = true
        }
    }

    // ─── Restart Timer (fallback if process exits) ───────────────
    Timer {
        id: restartTimer
        interval: 500
        onTriggered: {
            if (sysmonRoot.visible) {
                sysmonProc.running = true
            }
        }
    }

    Component.onCompleted: {
        sysmonProc.running = true
    }

    // ─── Helper: temperature color ────────────────────────────────
    function tempColor(temp) {
        if (temp < 60) return Qt.rgba(0.3, 0.69, 0.31, 1)  // Green - cool
        if (temp < 80) return Qt.rgba(1, 0.72, 0.11, 1)    // Amber - warm
        return Qt.rgba(0.96, 0.26, 0.21, 1)                 // Red - hot
    }

    // ─── Helper: progress bar color ──────────────────────────────
    function progressColor(pct) {
        if (pct < 60) return BeeTheme.accent
        if (pct < 85) return Qt.rgba(1, 0.72, 0.11, 1) // Amber
        return Qt.rgba(0.96, 0.26, 0.21, 1)               // Red
    }

    // ─── Main Panel ──────────────────────────────────────────────
    Rectangle {
        id: mainPanel
        anchors.centerIn: parent
        width: 340
        height: 480
        radius: 14
        color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.92)
        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.35)
        border.width: 1

        // ─── Subtle glow effect ───────────────────────────────────
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
            shadowBlur: 0.4
            shadowVerticalOffset: 4
            shadowHorizontalOffset: 0
        }

        // ─── Header ──────────────────────────────────────────────
        Rectangle {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 42
            radius: 14
            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)

            // Bottom corners: square (overlap with content)
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.radius
                color: parent.color
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "📊 " + (tr.title || "System Monitor")
                color: BeeTheme.text
                font.pixelSize: 15
                font.bold: true
                font.family: "Inter"
            }

            // FPS counter
            Text {
                anchors.right: closeBtn.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: sysmonRoot.fpsValue + " fps"
                color: Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.5)
                font.pixelSize: 10
                font.family: "JetBrains Mono"
            }

            // Close button ✕
            Rectangle {
                id: closeBtn
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 26
                radius: 13
                color: closeBtnMa.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.8) : Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.15)

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: closeBtnMa.containsMouse ? "white" : BeeTheme.text
                    font.pixelSize: 13
                    font.bold: true
                }

                MouseArea {
                    id: closeBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sysmonRoot.closeRequested()
                }

                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        // ─── Scrollable Content ──────────────────────────────────
        Flickable {
            id: flick
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 0
            clip: true
            contentHeight: contentColumn.height + 16
            contentWidth: width

            Column {
                id: contentColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                // ─── CPU Section ──────────────────────────────────
                SectionCard {
                    title: "🖥️ " + (tr.cpu || "CPU")
                    width: parent.width - 24

                    // CPU Usage graph (sparkline)
                    Canvas {
                        id: cpuGraph
                        width: parent.width
                        height: 50
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)

                            var hist = sysmonRoot.cpuHistory
                            if (hist.length < 2) return

                            // Background
                            ctx.fillStyle = Qt.rgba(BeeTheme.bg.r, BeeTheme.bg.g, BeeTheme.bg.b, 0.3)
                            ctx.fillRect(0, 0, width, height)

                            // Grid lines
                            ctx.strokeStyle = Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.08)
                            ctx.lineWidth = 0.5
                            for (var g = 0; g < 5; g++) {
                                var gy = (height / 4) * g
                                ctx.beginPath()
                                ctx.moveTo(0, gy)
                                ctx.lineTo(width, gy)
                                ctx.stroke()
                            }

                            // Area fill
                            var step = width / (sysmonRoot.maxHistoryPoints - 1)
                            var x0 = width - (hist.length - 1) * step

                            ctx.beginPath()
                            ctx.moveTo(x0, height)
                            for (var i = 0; i < hist.length; i++) {
                                var x = x0 + i * step
                                var y = height - (hist[i] / 100) * height
                                ctx.lineTo(x, y)
                            }
                            ctx.lineTo(x0 + (hist.length - 1) * step, height)
                            ctx.closePath()
                            ctx.fillStyle = Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                            ctx.fill()

                            // Line
                            ctx.beginPath()
                            for (var j = 0; j < hist.length; j++) {
                                var xl = x0 + j * step
                                var yl = height - (hist[j] / 100) * height
                                if (j === 0) ctx.moveTo(xl, yl)
                                else ctx.lineTo(xl, yl)
                            }
                            ctx.strokeStyle = BeeTheme.accent
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }

                        Connections {
                            target: sysmonRoot
                            function onCpuHistoryChanged() { cpuGraph.requestPaint() }
                        }
                    }

                    // CPU % + frequency
                    Row {
                        spacing: 8
                        width: parent.width

                        Text {
                            text: sysmonRoot.sysData.cpu.usage.toFixed(1) + "%"
                            color: sysmonRoot.progressColor(sysmonRoot.sysData.cpu.usage)
                            font.pixelSize: 18
                            font.bold: true
                            font.family: "JetBrains Mono"
                        }

                        Text {
                            text: "@ " + sysmonRoot.sysData.cpu.freq + " MHz"
                            color: Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.6)
                            font.pixelSize: 11
                            font.family: "JetBrains Mono"
                        }
                    }

                    // CPU progress bar
                    ProgressBar {
                        width: parent.width
                        value: sysmonRoot.sysData.cpu.usage / 100
                        barColor: sysmonRoot.progressColor(sysmonRoot.sysData.cpu.usage)
                    }
                }

                // ─── Memory Section ───────────────────────────────
                SectionCard {
                    title: "💾 " + (tr.memory || "Memory")
                    width: parent.width - 24

                    // RAM bar
                    Row {
                        spacing: 6
                        width: parent.width

                        Text {
                            text: "RAM"
                            color: Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.7)
                            font.pixelSize: 11
                            font.bold: true
                            font.family: "Inter"
                        }
                        Text {
                            text: sysmonRoot.sysData.mem.used + " / " + sysmonRoot.sysData.mem.total + " GB"
                            color: BeeTheme.text
                            font.pixelSize: 12
                            font.family: "JetBrains Mono"
                        }
                    }

                    ProgressBar {
                        width: parent.width
                        value: sysmonRoot.sysData.mem.pct / 100
                        barColor: sysmonRoot.progressColor(sysmonRoot.sysData.mem.pct)
                    }

                    // Swap
                    Row {
                        spacing: 6
                        width: parent.width

                        Text {
                            text: "Swap"
                            color: Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.7)
                            font.pixelSize: 11
                            font.bold: true
                            font.family: "Inter"
                        }
                        Text {
                            text: sysmonRoot.sysData.mem.swap_used + " / " + sysmonRoot.sysData.mem.swap_total + " GB"
                            color: BeeTheme.text
                            font.pixelSize: 12
                            font.family: "JetBrains Mono"
                        }
                    }

                    ProgressBar {
                        width: parent.width
                        value: sysmonRoot.sysData.mem.swap_pct / 100
                        barColor: sysmonRoot.progressColor(sysmonRoot.sysData.mem.swap_pct)
                    }
                }

                // ─── Temperatures Section ─────────────────────────
                SectionCard {
                    title: "🌡️ " + (tr.temperatures || "Temperatures")
                    width: parent.width - 24

                    Row {
                        spacing: 16
                        width: parent.width

                        // CPU Temp
                        Column {
                            spacing: 2

                            Text {
                                text: "CPU"
                                color: Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.7)
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "Inter"
                            }
                            Text {
                                text: sysmonRoot.sysData.temps.cpu + "°C"
                                color: sysmonRoot.tempColor(sysmonRoot.sysData.temps.cpu)
                                font.pixelSize: 20
                                font.bold: true
                                font.family: "JetBrains Mono"

                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }

                        // GPU Temp
                        Column {
                            spacing: 2

                            Text {
                                text: "GPU"
                                color: Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.7)
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "Inter"
                            }
                            Text {
                                text: sysmonRoot.sysData.temps.gpu + "°C"
                                color: sysmonRoot.tempColor(sysmonRoot.sysData.temps.gpu)
                                font.pixelSize: 20
                                font.bold: true
                                font.family: "JetBrains Mono"

                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }
                    }

                    // Temp threshold legend
                    Row {
                        spacing: 12

                        Row {
                            spacing: 3
                            Rectangle { width: 8; height: 8; radius: 4; color: "#4CAF50" }
                            Text { text: "<60°"; color: Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.5); font.pixelSize: 9; font.family: "Inter" }
                        }
                        Row {
                            spacing: 3
                            Rectangle { width: 8; height: 8; radius: 4; color: "#FFB81C" }
                            Text { text: "60-80°"; color: Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.5); font.pixelSize: 9; font.family: "Inter" }
                        }
                        Row {
                            spacing: 3
                            Rectangle { width: 8; height: 8; radius: 4; color: "#F44336" }
                            Text { text: ">80°"; color: Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.5); font.pixelSize: 9; font.family: "Inter" }
                        }
                    }
                }

                // ─── Fans Section ──────────────────────────────────
                SectionCard {
                    title: "🌀 " + (tr.fans || "Fans")
                    width: parent.width - 24

                    Column {
                        spacing: 4
                        width: parent.width

                        Repeater {
                            model: sysmonRoot.sysData.fans

                            Row {
                                spacing: 6

                                Text {
                                    text: modelData.label || "Fan"
                                    color: Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.7)
                                    font.pixelSize: 11
                                    font.family: "Inter"
                                }
                                Text {
                                    text: modelData.rpm + " RPM"
                                    color: BeeTheme.accent
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.family: "JetBrains Mono"
                                }
                            }
                        }
                    }

                    // No fans placeholder
                    Text {
                        visible: sysmonRoot.sysData.fans.length === 0
                        text: tr.no_fans || "No fan data available"
                        color: Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.4)
                        font.pixelSize: 10
                        font.italic: true
                        font.family: "Inter"
                    }
                }

                // ─── Top Processes Section ─────────────────────────
                SectionCard {
                    title: "⚡ " + (tr.top_processes || "Top Processes")
                    width: parent.width - 24

                    Column {
                        spacing: 3
                        width: parent.width

                        // Header row
                        Row {
                            spacing: 4
                            width: parent.width

                            Text { text: "PID"; color: Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.5); font.pixelSize: 9; font.family: "JetBrains Mono"; width: 45 }
                            Text { text: tr.process || "Process"; color: Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.5); font.pixelSize: 9; font.bold: true; font.family: "Inter"; width: 100 }
                            Text { text: "CPU%"; color: Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.5); font.pixelSize: 9; font.family: "JetBrains Mono"; width: 45; horizontalAlignment: Text.AlignRight }
                            Text { text: "MEM%"; color: Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.5); font.pixelSize: 9; font.family: "JetBrains Mono"; width: 45; horizontalAlignment: Text.AlignRight }
                        }

                        Repeater {
                            model: sysmonRoot.sysData.top

                            Row {
                                spacing: 4
                                width: parent.width

                                Text { text: String(modelData.pid); color: Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.6); font.pixelSize: 10; font.family: "JetBrains Mono"; width: 45 }
                                Text { text: modelData.name; color: BeeTheme.text; font.pixelSize: 10; font.family: "JetBrains Mono"; width: 100; elide: Text.ElideRight }
                                Text { text: modelData.cpu.toFixed(1); color: sysmonRoot.progressColor(modelData.cpu); font.pixelSize: 10; font.family: "JetBrains Mono"; width: 45; horizontalAlignment: Text.AlignRight }
                                Text { text: modelData.mem.toFixed(1); color: Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.7); font.pixelSize: 10; font.family: "JetBrains Mono"; width: 45; horizontalAlignment: Text.AlignRight }
                            }
                        }
                    }
                }

                // ─── Uptime Section ───────────────────────────────
                SectionCard {
                    title: "⏱️ " + (tr.uptime || "Uptime")
                    width: parent.width - 24

                    Text {
                        text: sysmonRoot.sysData.uptime
                        color: BeeTheme.accent
                        font.pixelSize: 16
                        font.bold: true
                        font.family: "JetBrains Mono"
                    }
                }

                // Bottom padding
                Item { height: 8 }
            }
        }
    }

    // ─── Reusable Section Card Component ─────────────────────────
    component SectionCard: Column {
        id: sectionCard
        property string title: ""

        spacing: 6

        Rectangle {
            width: sectionCard.width
            height: 1
            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
        }

        Text {
            text: sectionCard.title
            color: BeeTheme.accent
            font.pixelSize: 12
            font.bold: true
            font.family: "Inter"
        }
    }

    // ─── Reusable Progress Bar Component ─────────────────────────
    component ProgressBar: Item {
        id: pbar
        property real value: 0
        property color barColor: BeeTheme.accent

        width: parent ? parent.width : 200
        height: 6

        Rectangle {
            anchors.fill: parent
            radius: 3
            color: Qt.rgba(BeeTheme.text.r, BeeTheme.text.g, BeeTheme.text.b, 0.1)
        }

        Rectangle {
            width: Math.max(0, pbar.width * Math.min(1, Math.max(0, pbar.value)))
            height: pbar.height
            radius: 3
            color: pbar.barColor

            Behavior on color { ColorAnimation { duration: 300 } }
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutSine } }
        }
    }
}