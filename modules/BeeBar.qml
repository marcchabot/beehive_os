import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "."

// ═══════════════════════════════════════════════════════════════
// BeeBar.qml — Bee-Hive OS Status Bar 🐝
// v1.6.1 : Final anchor cleanup (Zero Warning Edition)
// ═══════════════════════════════════════════════════════════════

Rectangle {
    id: beeBar
    
    // ─── Style Flottant ───────────────────────────────────
    width: parent.width - 40
    height: 44
    radius: 18
    anchors.horizontalCenter: parent.horizontalCenter

    y: 12
    opacity: 1.0

    Behavior on y       { NumberAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    Behavior on opacity { NumberAnimation { duration: 250 } }

    Component.onCompleted: BeeBarState.barShown = true

    function dispatchModuleAction(action) {
        if (!action || action === "none") return

        if (action === "toggle:settings") {
            root.controlTab = 3
            root.controlVisible = true
            BeeSound.playEvent("dash.open")
            return
        }

        if (action === "toggle:studio") {
            root.controlTab = 0
            root.controlVisible = true
            BeeSound.playEvent("dash.open")
            return
        }

        if (action === "toggle:dash") {
            root.toggleDash()
            return
        }

        if (action === "toggle:power") {
            BeeBarState.powerVisible = !BeeBarState.powerVisible
            BeeSound.playEvent(BeeBarState.powerVisible ? "dash.open" : "dash.close")
            return
        }

        if (action === "toggle:theme") {
            BeeTheme.toggle()
            BeeSound.playEvent("ui.cell.click")
            return
        }

        if (action.startsWith("app:")) {
            var appName = action.substring(4).trim()
            if (!appName) return
            var appProc = Qt.createQmlObject('import QtQuick; import Quickshell.Io; Process { command: ["gtk-launch", "' + appName + '"] }', beeBar, "BeeBarModuleApp")
            appProc.start()
            return
        }

        if (action.startsWith("shell:")) {
            var shellCmd = action.substring(6)
            var shellProc = Qt.createQmlObject('import QtQuick; import Quickshell.Io; Process { command: ["bash", "-c", "' + shellCmd + '"] }', beeBar, "BeeBarModuleShell")
            shellProc.start()
            return
        }

        if (action.startsWith("url:")) {
            var url = action.substring(4).trim()
            if (!url) return
            Qt.openUrlExternally(url)
            return
        }

        console.warn("BeeBar: module action non reconnue →", action)
    }





    color: BeeTheme.barBg
    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.25)
    border.width: 1

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0,0,0, BeeTheme.mode === "HoneyDark" ? 0.4 : 0.15)
        shadowBlur: 0.6
        shadowVerticalOffset: 3
    }

    // ─── System properties ─────────────────────────────────
    property string cpuUsage: "—"
    property string ramUsed: "—"
    property string ramTotal: "—"
    property int cpuPercent: 0
    property int ramPercent: 0
    property string netSpeed: "—"
    property string diskUsed: "—"
    property int diskPercent: 0
    property int batteryPercent: 100
    property string batteryStatus: "—"

    property Process batteryProc: Process {
        id: _batteryProc
        command: ["bash", "-c", "find /sys/class/power_supply/ -maxdepth 1 -name \"BAT*\" | head -n 1 | xargs -I {} bash -c \"cat {}/capacity; cat {}/status\""]
        running: BeeConfig.showBattery
        stdout: StdioCollector {
            onStreamFinished: (text) => {
                var lines = text.trim().split("\n")
                if (lines.length >= 2) {
                    beeBar.batteryPercent = parseInt(lines[0])
                    beeBar.batteryStatus = lines[1]
                }
                batteryTimer.start()
            }
        }
    }

    property Process diskProc: Process {
        id: _diskProc
        command: ["bash", "-c", "LC_ALL=C df -h / | awk 'NR==2{print $3, $5}' | sed 's/%//'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: (text) => {
                var parts = text.trim().split(" ")
                if (parts.length >= 2) {
                    beeBar.diskUsed = parts[0]
                    beeBar.diskPercent = parseInt(parts[1])
                }
                diskTimer.start()
            }
        }
    }

    property Process netProc: Process {
        id: _netProc
        command: ["bash", "-c", "read t1 < <(awk '/eth0|wlan0|enp|wlp/{s+=$2+$10} END{print s}' /proc/net/dev); sleep 1; read t2 < <(awk '/eth0|wlan0|enp|wlp/{s+=$2+$10} END{print s}' /proc/net/dev); bps=$((t2-t1)); if [ $bps -lt 1024 ]; then echo \"${bps}B/s\"; elif [ $bps -lt 1048576 ]; then echo \"$((bps/1024))K/s\"; else echo \"$(awk \"BEGIN {printf \\\"%.1fM/s\\\", $bps/1048576}\")\"; fi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: (text) => {
                beeBar.netSpeed = text.trim()
                netTimer.start()
            }
        }
    }

    property Process cpuProc: Process {
        id: _cpuProc
        command: ["bash", "-c", "read _ a b c d _ < /proc/stat; s1=$((a+b+c+d)); i1=$d; sleep 1; read _ a b c d _ < /proc/stat; s2=$((a+b+c+d)); i2=$d; dt=$((s2-s1)); di=$((i2-i1)); if [ $dt -gt 0 ]; then echo $(( (dt-di)*100/dt )); else echo 0; fi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: (text) => {
                var val = parseInt(text.trim())
                if (!isNaN(val)) {
                    beeBar.cpuPercent = val
                    beeBar.cpuUsage = val + "%"
                }
                cpuTimer.start()
            }
        }
    }

    property Process ramProc: Process {
        id: _ramProc
        command: ["bash", "-c", "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{u=t-a; printf \"%d %d %d\", u/1024, t/1024, u*100/t}' /proc/meminfo"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: (text) => {
                var parts = text.trim().split(" ")
                if (parts.length >= 3) {
                    var usedMB = parseInt(parts[0])
                    var totalMB = parseInt(parts[1])
                    var pct = parseInt(parts[2])
                    beeBar.ramUsed = usedMB >= 1024 ? (usedMB / 1024).toFixed(1) + "G" : usedMB + "M"
                    beeBar.ramTotal = totalMB >= 1024 ? (totalMB / 1024).toFixed(0) + "G" : totalMB + "M"
                    beeBar.ramPercent = pct
                }
                ramTimer.start()
            }
        }
    }

    Timer { id: cpuTimer; interval: 3000; onTriggered: cpuProc.running = true }
    Timer { id: ramTimer; interval: 5000; onTriggered: ramProc.running = true }
    Timer { id: netTimer; interval: 2000; onTriggered: netProc.running = true }
    Timer { id: batteryTimer; interval: 10000; onTriggered: batteryProc.running = BeeConfig.showBattery }
    Timer { id: diskTimer; interval: 60000; onTriggered: diskProc.running = true }

    property string currentTime: Qt.formatDateTime(new Date(), "hh:mm")
    property string currentDate: Qt.formatDateTime(new Date(), "ddd d MMM")
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            beeBar.currentTime = Qt.formatDateTime(new Date(), "hh:mm")
            beeBar.currentDate = Qt.formatDateTime(new Date(), "ddd d MMM")
        }
    }

    // ─── Conteneur Principal ─────────────────────────────
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 12

        // ─── LEFT ───
        RowLayout {
            spacing: 12
            Layout.alignment: Qt.AlignVCenter
            
            RowLayout {
                spacing: 10
                Text { 
                    text: {
                        var activeClass = BeeBarState.activeWindowClass || "";
                        var icons = BeeConfig.window_icons || {};
                        return icons[activeClass] || icons["default"] || "🐝";
                    }
                    font.pixelSize: 18 
                }
                Text {
                    text: BeeBarState.focusActive ? (BeeConfig.tr.common && BeeConfig.tr.common.focus_label) || 'FOCUS' : (BeeConfig.tr.common && BeeConfig.tr.common.beehive_label) || 'BEE-HIVE'
                    font { bold: true; pixelSize: 13; letterSpacing: 2 }
                    color: BeeBarState.focusActive ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.7) : BeeTheme.accent
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.toggleDash()
                    }
                }

                Rectangle {
                    visible: BeeBarState.focusActive
                    width: 6; height: 6; radius: 3; color: BeeTheme.accent
                    SequentialAnimation on opacity {
                        running: BeeBarState.focusActive; loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 1200; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
                    }
                }
            }

            Rectangle { width: 1; height: 20; color: BeeTheme.separator; Layout.alignment: Qt.AlignVCenter }

            RowLayout {
                spacing: 8
                Repeater {
                    model: 5
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === index + 1) ? BeeTheme.accent : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.25)
                        scale: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === index + 1) ? 1.2 : 1.0
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                        MouseArea { 
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; 
                            onClicked: {
                                BeeSound.playEvent("ui.cell.click")
                                Hyprland.dispatch("workspace " + (index + 1).toString()) 
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // ─── DROITE ───
        RowLayout {
            spacing: 24
            Layout.alignment: Qt.AlignVCenter

            // Ressources Interactives
            Item {
                implicitWidth: resourceRow.implicitWidth
                implicitHeight: resourceRow.implicitHeight
                Layout.alignment: Qt.AlignVCenter
                
                RowLayout {
                    id: resourceRow
                    spacing: 24
                    anchors.fill: parent
                    
                    RowLayout {
                        visible: BeeConfig.showCpu; spacing: 6
                        Rectangle {
                            width: 40; height: 4; radius: 2; Layout.alignment: Qt.AlignVCenter
                            color: BeeTheme.separator
                            Rectangle {
                                width: parent.width * (Math.min(beeBar.cpuPercent, 100) / 100)
                                height: parent.height; radius: 2; color: beeBar.cpuPercent > 80 ? '#FF4444' : BeeTheme.accent
                            }
                        }
                        Text { text: (BeeConfig.tr.bar && BeeConfig.tr.bar.tooltip_cpu) || 'CPU'; color: BeeTheme.textSecondary; font { pixelSize: 10; bold: true } }
                        Text { text: beeBar.cpuUsage; color: BeeTheme.accent; font { pixelSize: 12; bold: true; family: "monospace" } }
                    }

                    RowLayout {
                        visible: BeeConfig.showRam; spacing: 6
                        Rectangle {
                            width: 40; height: 4; radius: 2; Layout.alignment: Qt.AlignVCenter
                            color: BeeTheme.separator
                            Rectangle {
                                width: parent.width * (Math.min(beeBar.ramPercent, 100) / 100)
                                height: parent.height; radius: 2; color: beeBar.ramPercent > 85 ? '#FF4444' : BeeTheme.accent
                            }
                        }
                        Text { text: (BeeConfig.tr.bar && BeeConfig.tr.bar.tooltip_ram) || 'RAM'; color: BeeTheme.textSecondary; font { pixelSize: 10; bold: true } }
                        Text { text: beeBar.ramUsed; color: BeeTheme.accent; font { pixelSize: 12; bold: true; family: "monospace" } }
                    }

                    RowLayout {
                        visible: BeeConfig.showNet; spacing: 6
                        Text { text: (BeeConfig.tr.bar && BeeConfig.tr.bar.tooltip_net) || 'NET'; color: BeeTheme.textSecondary; font { pixelSize: 10; bold: true } }
                        Text { text: beeBar.netSpeed; color: BeeTheme.accent; font { pixelSize: 12; bold: true; family: "monospace" } }
                    }
                }

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        BeeSound.playEvent("dash.open")
                        Hyprland.dispatch("exec kitty btop")
                    }
                }
            }

            // DISK
            RowLayout {
                visible: BeeConfig.showDisk; spacing: 6
                Rectangle {
                    width: 40; height: 4; radius: 2; Layout.alignment: Qt.AlignVCenter
                    color: BeeTheme.separator
                    Rectangle {
                        width: parent.width * (Math.min(beeBar.diskPercent, 100) / 100)
                        height: parent.height; radius: 2; color: beeBar.diskPercent > 90 ? '#FF4444' : BeeTheme.accent
                    }
                }
                Text { text: (BeeConfig.tr.bar && BeeConfig.tr.bar.tooltip_disk) || 'DISK'; color: BeeTheme.textSecondary; font { pixelSize: 10; bold: true } }
                Text { text: beeBar.diskUsed; color: BeeTheme.accent; font { pixelSize: 12; bold: true; family: "monospace" } }
            }

            // BATTERY
            RowLayout {
                visible: BeeConfig.showBattery; spacing: 6
                Rectangle {
                    width: 40; height: 4; radius: 2; Layout.alignment: Qt.AlignVCenter
                    color: BeeTheme.separator
                    Rectangle {
                        width: parent.width * (Math.min(beeBar.batteryPercent, 100) / 100)
                        height: parent.height; radius: 2; color: beeBar.batteryPercent < 20 ? '#FF4444' : BeeTheme.accent
                    }
                }
                Text { text: beeBar.batteryStatus === "Charging" ? '⚡' : (BeeConfig.tr.bar && BeeConfig.tr.bar.tooltip_battery) || 'BAT'; color: BeeTheme.textSecondary; font { pixelSize: 10; bold: true } }
                Text { text: beeBar.batteryPercent + "%"; color: BeeTheme.accent; font { pixelSize: 12; bold: true; family: "monospace" } }
            }

            Rectangle { width: 1; height: 20; color: BeeTheme.separator; Layout.alignment: Qt.AlignVCenter }

            BeeWeather {
                city: BeeConfig.weatherCity
                lat: BeeConfig.weatherLat
                lon: BeeConfig.weatherLon
                conditionMaxWidth: 110
                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: 180
            }

            Rectangle { width: 1; height: 20; color: BeeTheme.separator; Layout.alignment: Qt.AlignVCenter }

            RowLayout {
                visible: BeeModuleRegistry.beeBarModules.count > 0
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: BeeModuleRegistry.beeBarModules
                    delegate: Rectangle {
                        required property string moduleId
                        required property string title
                        required property string icon
                        required property string action
                        required property bool enabled

                        visible: enabled
                        radius: 6
                        color: moduleHover.containsMouse
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                            : Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.04)
                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.18)
                        border.width: 1
                        implicitWidth: moduleLabel.implicitWidth + 12
                        implicitHeight: 22

                        Text {
                            id: moduleLabel
                            anchors.centerIn: parent
                            text: icon + " " + title
                            color: BeeTheme.textPrimary
                            font.pixelSize: 10
                        }

                        MouseArea {
                            id: moduleHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: beeBar.dispatchModuleAction(action)
                        }
                    }
                }
            }

            Rectangle {
                visible: BeeModuleRegistry.beeBarModules.count > 0
                width: 1; height: 20
                color: BeeTheme.separator
                Layout.alignment: Qt.AlignVCenter
            }

            Column {
                opacity: BeeConfig.analogClock ? 0 : 1
                Layout.alignment: Qt.AlignVCenter
                spacing: -2
                Text {
                    text: beeBar.currentTime
                    color: BeeTheme.textPrimary
                    font { pixelSize: 15; weight: Font.DemiBold; family: "monospace" }
                }
                Text {
                    text: beeBar.currentDate
                    color: BeeTheme.textSecondary
                    font { pixelSize: 9; letterSpacing: 0.5 }
                }
            }

            Rectangle { width: 1; height: 20; color: BeeTheme.separator; Layout.alignment: Qt.AlignVCenter }

            Rectangle {
                width: 28; height: 28; radius: 7; Layout.alignment: Qt.AlignVCenter
                color: powerBtnHover.containsMouse ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.22) : "transparent"
                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.20); border.width: 1
                Text { anchors.centerIn: parent; text: "⏻"; font.pixelSize: 16; color: BeeTheme.accent }
                MouseArea { 
                    id: powerBtnHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        BeeBarState.powerVisible = true 
                        BeeSound.playEvent("dash.open")
                    }
                }
            }
        }
    }
}
