import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "."

// ═══════════════════════════════════════════════════════════════
// BeeBar.qml — Bee-Hive OS Status Bar 🐝
// v1.7.0 : Contextual Bar — dynamic icons & labels per active app
// ═══════════════════════════════════════════════════════════════

Rectangle {
    id: beeBar
    
    // ─── Style Flottant ───────────────────────────────────
    width: parent.width - 40
    height: 44
    radius: 18
    anchors.horizontalCenter: parent.horizontalCenter

    // ─── Stealth Mode v3 : Slide animation ────────────────
    // When stealth is ON and barShown is false, slide the bar
    // up above the screen edge. When visible, y = 1 (bar fits in 45px panel).
    y: BeeBarState.barShown ? 1 : -50
    opacity: BeeBarState.barShown ? 1.0 : 0.0

    Behavior on y       { NumberAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    Behavior on opacity { NumberAnimation { duration: 300 } }

    // Removed: was breaking the barShown binding in BeeBarState.qml

    // ─── Stealth Mode v3 : Whole-bar hover tracking ─────────
    // When stealth is active, this MouseArea covers the ENTIRE bar
    // and uses containsMouse (which respects child MouseAreas) to
    // keep the bar visible as long as the mouse is anywhere inside it.
    // The timer only triggers after the mouse truly leaves the bar.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        z: -1  // Below all interactive elements
        onContainsMouseChanged: {
            if (BeeBarState.stealthEnabled) {
                BeeBarState.barHovered = containsMouse
            }
        }
    }

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

    // ─── Autostart Scripts ─────────────────────────────────
    property Process bootScanProc: Process {
        id: _bootScanProc
        command: ["bash", "-c", "python3 /home/marc/beehive_os/scripts/update_icons.py"]
        running: false
        stdout: SplitParser { onRead: (line) => console.log("[BeeBar BootScan] " + line) }
        stderr: SplitParser { onRead: (line) => console.error("[BeeBar BootScan ERR] " + line) }
        onExited: {
            console.log("[BeeBar] Icon scan finished. Refreshing config...");
            BeeConfig.loadConfig(); // Force reload of user_config.json
        }
    }

    Timer {
        id: bootTimer
        interval: 10000 // Increased to 10s to ensure system stability after boot
        running: true
        onTriggered: {
            console.log("[BeeBar] Triggering automatic icon scan...");
            _bootScanProc.running = true;
        }
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
        command: ["bash", "-c", "echo \"$(cat /sys/class/power_supply/BAT*/capacity) $(cat /sys/class/power_supply/BAT*/status)\""]
        running: BeeConfig.showBattery
        stdout: SplitParser {
            onRead: (line) => {
                var parts = line.trim().split(" ")
                if (parts.length >= 2) {
                    beeBar.batteryPercent = parseInt(parts[0])
                    beeBar.batteryStatus = parts[1]
                }
                batteryTimer.start()
            }
        }
        stderr: SplitParser {}
    }

    property Process diskProc: Process {
        id: _diskProc
        command: ["bash", "-c", "LC_ALL=C df -h / | awk 'NR==2{print $3, $5}' | sed 's/%//'"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                var parts = line.trim().split(" ")
                if (parts.length >= 2) {
                    beeBar.diskUsed = parts[0]
                    beeBar.diskPercent = parseInt(parts[1])
                }
                diskTimer.start()
            }
        }
        stderr: SplitParser {}
    }

    property Process netProc: Process {
        id: _netProc
        command: ["bash", "-c", "read t1 < <(awk '/eth0|wlan0|enp|wlp/{s+=$2+$10} END{print s}' /proc/net/dev); sleep 1; read t2 < <(awk '/eth0|wlan0|enp|wlp/{s+=$2+$10} END{print s}' /proc/net/dev); bps=$((t2-t1)); if [ $bps -lt 1024 ]; then echo \"${bps}B/s\"; elif [ $bps -lt 1048576 ]; then echo \"$((bps/1024))K/s\"; else awk \"BEGIN {printf \"%.1fM/s\", $bps/1048576}\"; fi"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                beeBar.netSpeed = line.trim()
                netTimer.start()
            }
        }
        stderr: SplitParser {}
    }

    property Process cpuProc: Process {
        id: _cpuProc
        command: ["bash", "-c", "read _ a b c d _ < /proc/stat; s1=$((a+b+c+d)); i1=$d; sleep 1; read _ a b c d _ < /proc/stat; s2=$((a+b+c+d)); i2=$d; dt=$((s2-s1)); di=$((i2-i1)); if [ $dt -gt 0 ]; then echo $(( (dt-di)*100/dt )); else echo 0; fi"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                var val = parseInt(line.trim())
                if (!isNaN(val)) {
                    beeBar.cpuPercent = val
                    beeBar.cpuUsage = val + "%"
                }
                cpuTimer.start()
            }
        }
        stderr: SplitParser {}
    }

    property Process ramProc: Process {
        id: _ramProc
        command: ["bash", "-c", "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"%d %d %d\", (t-a)/1024, t/1024, (t-a)*100/t}' /proc/meminfo"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                var parts = line.trim().split(" ")
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
        stderr: SplitParser {}
    }

    Timer { id: cpuTimer; interval: 3000; onTriggered: cpuProc.running = true }
    Timer { id: ramTimer; interval: 5000; onTriggered: ramProc.running = true }
    Timer { id: netTimer; interval: 2000; onTriggered: netProc.running = true }
    Timer { id: batteryTimer; interval: 10000; onTriggered: batteryProc.running = BeeConfig.showBattery }
    Timer { id: diskTimer; interval: 60000; onTriggered: diskProc.running = true }

    // ─── History Save Helper ───────────────────────────────
    property Process historySaveProc: Process {
        id: _historySaveProc
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                console.log("[BeeBar] History directory created")
            }
        }
        stderr: SplitParser {}
    }

    // Connect to BeeBarState signal
    Connections {
        target: BeeBarState
        function onHistorySaveNeeded(dirPath) {
            _historySaveProc.running = false
            _historySaveProc.command = ["bash", "-c", "mkdir -p " + dirPath]
            _historySaveProc.running = true
        }
    }

    // ─── Window Tracker (moved from BeeBarState singleton) ──────────
    property string _pendingClass: ""
    Timer {
        id: _classDebounce
        interval: 150  // 150ms debounce to let Hyprland stabilize
        onTriggered: {
            if (_pendingClass && BeeBarState.activeWindowClass !== _pendingClass) {
                BeeBarState.activeWindowClass = _pendingClass
                console.log("[BeeBar] Window class updated to:", _pendingClass)
            }
        }
    }
    property Process windowTracker: Process {
        id: _windowTracker
        command: ["python3", "/home/marc/beehive_os/scripts/get_active_window.py"]
        running: false  // <-- Démarré par le timer
        stdout: SplitParser {
            onRead: (line) => {
                var newClass = line.trim();
                // Filter out numeric/PID-like transient values during window transitions
                if (newClass && /^\d+(\.\d+)?$/.test(newClass)) {
                    _windowTracker.running = false
                    _windowTrackerTimer.start()
                    return
                }
                // Debounce: delay update to let Hyprland stabilize the class name
                _pendingClass = newClass
                _classDebounce.start()
                // Arrêter le processus, timer le redémarrera
                _windowTracker.running = false
                _windowTrackerTimer.start()
            }
        }
        stderr: SplitParser {}
    }

    Timer { 
        id: _windowTrackerTimer
        interval: 2000  // Attendre 2 secondes entre les checks
        onTriggered: _windowTracker.running = true 
        Component.onCompleted: start()  // Démarrer au début
    }

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
                
                // ─── Contextual App Detection ───────────────────────────
                property string activeClass: (BeeBarState.activeWindowClass || "").toLowerCase()

                // Dynamic icon loader - handles both emojis and image paths
                property string currentIcon: {
                    var cls = activeClass;
                    var icons = BeeConfig.window_icons || {};
                    
                    // Create a case-insensitive map for lookup
                    var caseInsensitiveIcons = {};
                    for (var key in icons) {
                        caseInsensitiveIcons[key.toLowerCase()] = icons[key];
                    }

                    // 1. If no window is focused, it's unknown, or it's an error state, use the bee
                    if (!cls || cls === "unknown" || cls === "none" || cls.startsWith("error:")) return "🐝";
                    
                    // 2. Get the icon for the current class, or the default icon
                    var icon = caseInsensitiveIcons[cls] || caseInsensitiveIcons["default"];
                    
                    // 3. If the result is empty, whitespace, or error-like, use the bee
                    if (!icon || (typeof icon === 'string' && (icon.trim() === "" || icon.startsWith("error:")))) return "🐝";
                    
                    return icon;
                }
                
                // Determine if current icon is an image file
                property bool isImageIcon: {
                    var icon = currentIcon;
                    return icon && icon.startsWith("/");
                }

                Image {
                    visible: parent.isImageIcon
                    source: parent.isImageIcon ? "file://" + parent.currentIcon : ""
                    width: 18
                    height: 18
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: 18
                    sourceSize.height: 18
                }

                Text {
                    visible: !parent.isImageIcon
                    text: parent.currentIcon
                    font.pixelSize: 18
                }
                Text {
                    // ─── Contextual Bar Label ───────────────────────────
                    // Shows active app name when contextual_bar is enabled,
                    // otherwise shows FOCUS or BEE-HIVE label
                    text: {
                        if (BeeBarState.focusActive)
                            return (BeeConfig.tr.common && BeeConfig.tr.common.focus_label) || 'FOCUS'
                        if (BeeConfig.contextualBar && parent.activeClass !== "unknown" && parent.activeClass !== "" && parent.activeClass !== "none") {
                            // Map common window classes to friendly names
                            var nameMap = ({
                                "firefox": "Firefox", "zen-browser": "Zen", "zen": "Zen",
                                "kitty": "Kitty", "alacritty": "Alacritty", "foot": "Foot",
                                "discord": "Discord", "spotify": "Spotify",
                                "steam": "Steam", "heroic": "Heroic", "lutris": "Lutris",
                                "code": "VS Code", "zeditor": "Zed", "neovim": "Neovim",
                                "dolphin": "Dolphin", "thunar": "Thunar",
                                "obs": "OBS", "gimp": "GIMP",
                                "pavucontrol": "Pavucontrol", "btop": "Btop",
                                "enpass": "Enpass", "meld": "Meld",
                                "thunderbird": "Thunderbird", "helium": "Helium"
                            })
                            var cls = parent.activeClass.toLowerCase()
                            return nameMap[cls] || parent.activeClass.charAt(0).toUpperCase() + parent.activeClass.slice(1)
                        }
                        return (BeeConfig.tr.common && BeeConfig.tr.common.beehive_label) || 'BEE-HIVE'
                    }
                    font.bold: true; font.pixelSize: 13; font.letterSpacing: 2
                    color: BeeBarState.focusActive ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.7) : BeeTheme.accent
                }
                
                MouseArea {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
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

            // ─── Contextual Shortcuts per App 🐝🧭 ─────────────────
            RowLayout {
                id: contextShortcuts
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                // Compute which shortcuts to show based on active app
                property var activeShortcuts: {
                    var cls = (BeeBarState.activeWindowClass || "").toLowerCase()
                    if (!cls || cls === "unknown" || cls === "none" || !BeeConfig.contextualBar) return []
                    var rules = BeeConfig.context_rules || {}
                    // Case-insensitive lookup
                    for (var key in rules) {
                        if (key.toLowerCase() === cls) return rules[key]
                    }
                    return []
                }

                visible: activeShortcuts.length > 0
                opacity: activeShortcuts.length > 0 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                Repeater {
                    model: contextShortcuts.activeShortcuts
                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: ctxLabel.implicitWidth + 14
                        height: 22
                        radius: 6
                        color: ctxHover.containsMouse
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.18)
                            : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06)
                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, ctxHover.containsMouse ? 0.5 : 0.15)
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        scale: ctxHover.containsMouse ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack; easing.overshoot: 0.3 } }

                        Row {
                            id: ctxLabel
                            anchors.centerIn: parent
                            spacing: 3
                            Text { text: modelData.icon; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: modelData.label; color: BeeTheme.textPrimary; font.pixelSize: 9; font.bold: true; font.letterSpacing: 0.5; anchors.verticalCenter: parent.verticalCenter }
                        }

                        MouseArea {
                            id: ctxHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: beeBar.dispatchModuleAction(modelData.action)
                        }
                    }
                }
            }

            Rectangle { width: 1; height: 20; color: BeeTheme.separator; Layout.alignment: Qt.AlignVCenter; visible: contextShortcuts.visible }

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
            spacing: 16
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: beeBar.width - 40

            // Ressources Interactives
            Item {
                implicitWidth: resourceRow.implicitWidth
                implicitHeight: resourceRow.implicitHeight
                Layout.alignment: Qt.AlignVCenter
                
                RowLayout {
                    id: resourceRow
                    spacing: 24
                    anchors.fill: parent
                    
                    // ─── CPU ────────────────────────────
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
                        Text { text: (BeeConfig.tr.bar && BeeConfig.tr.bar.tooltip_cpu) || 'CPU'; color: BeeTheme.textSecondary; font.pixelSize: 10; font.bold: true }
                        Text {
                            text: beeBar.cpuUsage; color: BeeTheme.accent
                            font.pixelSize: 12; font.bold: true; font.family: "monospace"
                            Layout.minimumWidth: 32; Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    // ─── RAM ────────────────────────────
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
                        Text { text: (BeeConfig.tr.bar && BeeConfig.tr.bar.tooltip_ram) || 'RAM'; color: BeeTheme.textSecondary; font.pixelSize: 10; font.bold: true }
                        Text {
                            text: beeBar.ramUsed; color: BeeTheme.accent
                            font.pixelSize: 12; font.bold: true; font.family: "monospace"
                            Layout.minimumWidth: 38; Layout.preferredWidth: 38
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    // ─── NET ────────────────────────────
                    RowLayout {
                        visible: BeeConfig.showNet; spacing: 6
                        Text { text: (BeeConfig.tr.bar && BeeConfig.tr.bar.tooltip_net) || 'NET'; color: BeeTheme.textSecondary; font.pixelSize: 10; font.bold: true }
                        Text {
                            text: beeBar.netSpeed; color: BeeTheme.accent
                            font.pixelSize: 12; font.bold: true; font.family: "monospace"
                            Layout.minimumWidth: 52; Layout.preferredWidth: 52
                            horizontalAlignment: Text.AlignRight
                        }
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

            // ─── DISK ────────────────────────────
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
                Text { text: (BeeConfig.tr.bar && BeeConfig.tr.bar.tooltip_disk) || 'DISK'; color: BeeTheme.textSecondary; font.pixelSize: 10; font.bold: true }
                Text {
                    text: beeBar.diskUsed; color: BeeTheme.accent
                    font.pixelSize: 12; font.bold: true; font.family: "monospace"
                    Layout.minimumWidth: 38; Layout.preferredWidth: 38
                    horizontalAlignment: Text.AlignRight
                }
            }

            // ─── BATTERY ────────────────────────────
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
                Text { text: beeBar.batteryStatus === "Charging" ? '⚡' : (BeeConfig.tr.bar && BeeConfig.tr.bar.tooltip_battery) || 'BAT'; color: BeeTheme.textSecondary; font.pixelSize: 10; font.bold: true }
                Text {
                    text: beeBar.batteryPercent + "%"; color: BeeTheme.accent
                    font.pixelSize: 12; font.bold: true; font.family: "monospace"
                    Layout.minimumWidth: 32; Layout.preferredWidth: 32
                    horizontalAlignment: Text.AlignRight
                }
            }

            Rectangle { width: 1; height: 20; color: BeeTheme.separator; Layout.alignment: Qt.AlignVCenter }

            BeeWeather {
                city: BeeConfig.weatherCity
                lat: BeeConfig.weatherLat
                lon: BeeConfig.weatherLon
                conditionMaxWidth: 70
                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: 140
                Layout.minimumWidth: 60
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
                        opacity: enabled ? 1.0 : 0.0
                        radius: 6
                        color: moduleHover.containsMouse
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                            : Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.04)
                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, moduleHover.containsMouse ? 0.5 : 0.18)
                        border.width: 1
                        implicitWidth: moduleLabel.implicitWidth + 12
                        implicitHeight: 22

                        // ─── Slide/fade entrance animation ────
                        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }

                        // Scale animation on hover
                        scale: moduleHover.containsMouse ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 0.3 } }

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
                    font.pixelSize: 15; font.weight: Font.DemiBold; font.family: "monospace"
                }
                Text {
                    text: beeBar.currentDate
                    color: BeeTheme.textSecondary
                    font.pixelSize: 9; font.letterSpacing: 0.5
                }
            }

            Rectangle { width: 1; height: 20; color: BeeTheme.separator; Layout.alignment: Qt.AlignVCenter }

            Rectangle {
                width: 28; height: 28; radius: 7; Layout.alignment: Qt.AlignVCenter
                Layout.minimumWidth: 28
                Layout.minimumHeight: 28
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
