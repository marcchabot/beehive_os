import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import '../modules'

ShellRoot {
    id: root

    property bool dashVisible: false
    property bool searchVisible: false
    property bool osdVisible: false
    property bool welcomeVisible: false
    property bool voiceVisible: false

    // ─── Startup Performance Profiling ⚡ ──────────────────────
    property var _startupTimestamps: ({
        "shell_created": Date.now()
    })

    Component.onCompleted: {
        root._startupTimestamps["shell_completed"] = Date.now()
        var totalMs = root._startupTimestamps["shell_completed"] - root._startupTimestamps["shell_created"]
        console.log("🐝 BeeHiveShell: Component completed in", totalMs, "ms")

        // Record to startup profiler
        var profilerPath = Qt.resolvedUrl("../scripts/bee_startup_profiler.py").toString().replace("file://", "")
        var modulesJson = JSON.stringify(root._startupTimestamps)
        _startupRecorder.running = false
        _startupRecorder.command = ["python3", profilerPath, "record",
            "--total", String(totalMs),
            "--notes", "BeeHiveShell Component.onCompleted"
        ]
        _startupRecorder.running = true
    }

    // ─── Lazy Loading Support ⚡ ──────────────────────────────
    // When battery saver is active, defer non-essential modules
    property bool _deferHeavyModules: BeeConfig.batterySaverActive

    // Track module load timestamps
    function _markStartup(key) {
        root._startupTimestamps[key] = Date.now()
    }

    // Process to record startup data
    Process {
        id: _startupRecorder
        running: false
        command: ["echo", ""]
        stdout: SplitParser { onRead: (line) => {} }
    }

    // ─── First Run Detection ──────────────────────────────────
    Process {
        id: firstRunCheck
        command: ["bash", "-c", "mkdir -p ~/.config/beehive && test -f ~/.config/beehive/.bee_welcomed && echo yes || echo no"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                root.welcomeVisible = (line.trim() === "no")
            }
        }
    }

    // ─── Debounce Logic ──────────────────────────────────────
    property var _lastIpcTimes: ({})
    function _debounce(key) {
        var now = Date.now()
        var last = root._lastIpcTimes[key] || 0
        if (now - last < 250) return false
        var times = root._lastIpcTimes
        times[key] = now
        root._lastIpcTimes = times // Trigger property update
        return true
    }

    // ─── BeePower Action Handler ───────────────────────────────
    Connections {
        target: BeePower
        function onActionRequested(cmd) {
            console.log("BeePower: action requested →", cmd)
            if (cmd.startsWith("app:")) {
                var appName = cmd.substring(4)
                var proc = Qt.createQmlObject('import QtQuick; import Quickshell.Io; Process { command: ["gtk-launch", "' + appName + '"] }', root, "BeePowerAppLauncher")
                proc.start()
            } else if (cmd.startsWith("toggle:")) {
                var setting = cmd.substring(7)
                if (setting === "focus") {
                    BeeConfig.focusMode = !BeeConfig.focusMode
                    BeeConfig.saveConfig()
                } else if (setting === "settings") {
                    toggleDash()
                }
            } else if (cmd.startsWith("shell:")) {
                var shellCmd = cmd.substring(6)
                var proc = Qt.createQmlObject('import QtQuick; import Quickshell.Io; Process { command: ["bash", "-c", "' + shellCmd + '"] }', root, "BeePowerShell")
                proc.start()
            }
        }
    }

    function toggleDash()   { 
        if (!root._debounce("dash")) return
        dashVisible = !dashVisible 
        BeeSound.playEvent(dashVisible ? "dash.open" : "dash.close")
    }
    function toggleSearch() { 
        searchVisible = !searchVisible 
        BeeSound.playEvent(searchVisible ? "dash.open" : "dash.close")
    }

    IpcHandler {
        target: "root"
        function toggleDash()   { root.toggleDash() }
        function toggleSearch() { root.toggleSearch() }
        function toggleTheme()  { 
            BeeTheme.toggle() 
            BeeSound.playEvent("ui.cell.click")
        }
        function toggleFocus() {
            BeeConfig.focusMode = !BeeConfig.focusMode
            BeeConfig.saveConfig()
            BeeSound.playEvent("ui.cell.click")
        }
        function testOSD() {
            BeeBarState.showOSD("volume", 50)
        }
        // ─── BeePower Menu ─────────────────────
        function showPower() {
            if (!root._debounce("power")) return
            BeeBarState.powerVisible = !BeeBarState.powerVisible
            BeeSound.playEvent(BeeBarState.powerVisible ? "dash.open" : "dash.close")
        }

        // ─── Settings / Studio / Launcher ───────
        function showSettings() { 
            root.controlTab = 3; 
            root.controlVisible = true 
            BeeSound.playEvent("dash.open")
        }
        function showStudio()   { 
            root.controlTab = 0; 
            root.controlVisible = true 
            BeeSound.playEvent("dash.open")
        }
        function showLauncher() { 
            root.searchVisible   = true 
            BeeSound.playEvent("dash.open")
        }
        function showSearch()   { 
            root.searchVisible   = true 
            BeeSound.playEvent("dash.open")
        }
        function showNotes()    {
            root.notesVisible = !root.notesVisible
            BeeSound.playEvent(root.notesVisible ? "dash.open" : "dash.close")
        }
        function showWelcome()  { 
            root.welcomeVisible  = true 
            BeeSound.playEvent("dash.open")
        }
        
        // ─── BeeAura Notifications ──
        function dispatchNotification(title: string, body: string, icon: string) {
            BeeBarState.dispatchNotification(title, body, icon)
        }
        
        // ─── Maya Desktop Tap 🐝✨ ──
        function mayaTap(title: string, body: string) {
            BeeBarState.dispatchNotification(title, body, "🐝")
        }

        // ─── BeeVoice — Maya AI Assistant 🐝🎤 ──
        function toggleVoiceAssistant() {
            if (!root._debounce("voice")) return
            root.voiceVisible = !root.voiceVisible
            BeeSound.playEvent(root.voiceVisible ? "dash.open" : "dash.close")
        }

        // ─── BeeAura OSD ───────────
        function showOSD(type: string, value: int) {
            BeeBarState.showOSD(type, value)
        }

        // ─── Bee-Live Sync v2 ───────
        function refreshEvents() {
            BeeConfig.reloadLiveEvents()
        }
    }



    // ─── Plugin System v2 — Loader 🧩 ──────────────────────
    // At startup, load enabled plugins and register their entry points.
    // Plugin state is managed by bee_plugin_manager.py (Python backend).
    // QML plugins are loaded dynamically via Qt.createComponent().
    // Python plugins are launched as subprocesses communicating via IPC.
    Process {
        id: pluginLoader
        property string _output: ""
        command: ["python3", Qt.resolvedUrl("../scripts/bee_plugin_manager.py").toString().replace("file://", ""), "list", "--enabled", "--json"]
        running: BeeConfig.pluginsEnabled
        stdout: SplitParser {
            onRead: (line) => { pluginLoader._output += line + "\n" }
        }
        onExited: (code, status) => {
            if (code !== 0) {
                console.warn("BeeHive Plugin Loader: exited with code", code)
                return
            }
            try {
                var plugins = JSON.parse(pluginLoader._output.trim())
                if (!Array.isArray(plugins)) return
                for (var i = 0; i < plugins.length; i++) {
                    var p = plugins[i]
                    if (!p || !p.id) continue
                    console.log("🐝 Plugin loaded:", p.id, "v" + (p.version || "?"))
                    // Register QML entry points with BeeModuleRegistry
                    if (p.entry_points && Array.isArray(p.entry_points)) {
                        for (var j = 0; j < p.entry_points.length; j++) {
                            var ep = p.entry_points[j]
                            if (ep.type === "beebar" && ep.file) {
                                // QML BeeBar module — will be loaded on demand
                                BeeModuleRegistry.registerBeeBarModule({
                                    id: p.id + "-" + ep.name,
                                    label: ep.label || ep.name,
                                    icon: ep.icon || "🧩",
                                    source: p.path + "/" + ep.file
                                })
                            } else if (ep.type === "mayadash" && ep.file) {
                                // QML MayaDash cell — register slot
                                var slot = ep.slot !== undefined ? ep.slot : 7
                                BeeModuleRegistry.registerMayaDashModule({
                                    id: p.id + "-" + ep.name,
                                    label: ep.label || ep.name,
                                    icon: ep.icon || "🧩",
                                    slot: slot,
                                    source: p.path + "/" + ep.file
                                })
                            }
                            // background and ipc_handler types are launched
                            // by the Python backend, not here.
                        }
                    }
                }
            } catch(e) {
                console.warn("BeeHive Plugin Loader: parse error", e)
            }
        }
    }

    // ─── IPC Server (Plugin REST API) 🐝🔌 ────────────────────
    // Starts the Unix socket IPC server when pluginsEnabled is true.
    // Exposes plugin management via HTTP on /tmp/bee-hive-os/plugin.sock
    Process {
        id: ipcServer
        running: BeeConfig.pluginsEnabled
        command: ["python3", Qt.resolvedUrl("../scripts/bee_plugin_manager.py").toString().replace("file://", ""), "ipc"]
        stdout: SplitParser {
            onRead: (line) => {
                var msg = (line || "").trim()
                if (msg.length > 0) console.log("BeeIPC:", msg)
            }
        }
        onExited: (code, status) => {
            console.warn("BeeIPC: server exited with code", code)
        }
    }

    // ─── BeeBar + Sentinel (unified Top layer) ─────────────
    // Stealth Mode v3: BeeBar and sentinel strip share the same
    // PanelWindow. Hover flows naturally from sentinel to bar.
    // When stealth is ON and bar hidden, exclusiveZone shrinks to 3px
    // and only the sentinel strip is interactable. When shown, full 45px.
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: barPanel
            required property var modelData
            screen: modelData
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "beehive-bar"
            exclusiveZone: BeeBarState.barShown ? 46 : 3
            focusable: false
            anchors { top: true; left: true; right: true }
            implicitHeight: 46
            color: "transparent"

            // Sentinel strip at the very top — 3px tall
            // Detects mouse hover to reveal the BeeBar in stealth mode
            MouseArea {
                id: sentinelArea
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 3
                hoverEnabled: true
                onEntered: {
                    if (BeeBarState.stealthEnabled) {
                        BeeBarState.sentinelHovered = true
                    }
                }
                onExited: {
                    if (BeeBarState.stealthEnabled) {
                        BeeBarState.sentinelHovered = false
                    }
                }
            }

            // The BeeBar itself — slides in/out via y/opacity when stealth toggles
            BeeBar {
                id: beeBarInstance
            }
        }
    }

    // Widgets Background
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: widgetPanel
            required property var modelData
            screen: modelData
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "beehive-bg"
            exclusiveZone: -1
            focusable: false
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            BeeWallpaper { anchors.fill: parent }

            // ─── Profile Transition Overlay 🐝👤 ───
            Rectangle {
                anchors.fill: parent
                color: BeeTheme.mode === "HoneyDark" ? Qt.rgba(0.05, 0.05, 0.07, 1) : Qt.rgba(0.97, 0.95, 0.90, 1)
                opacity: BeeProfiles.transitionOpacity
                visible: BeeProfiles.transitionActive
                z: 50

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 14

                    Text {
                        text: BeeProfiles.currentProfile ? BeeProfiles.currentProfile.icon : "🍯"
                        font.pixelSize: 56
                        Layout.alignment: Qt.AlignHCenter

                        SequentialAnimation on scale {
                            running: BeeProfiles.transitionActive
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.2; duration: 500; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InOutSine }
                        }
                    }

                    Text {
                        text: BeeProfiles.currentProfile ? BeeProfiles.currentProfile.name : ""
                        color: BeeTheme.accent
                        font { bold: true; pixelSize: 22; letterSpacing: 1.0 }
                        Layout.alignment: Qt.AlignHCenter
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }
            }

            MayaDash {
                id: mayaDash
                dashShown: root.dashVisible && !BeeBarState.focusActive
                beeMotionEnabled: BeeBarState.motionActive
                beeVibeEnabled:   BeeBarState.vibeActive
                onOpenSettings: { root.controlTab = 3; root.controlVisible = true }
                onOpenStudio:   { root.controlTab = 0; root.controlVisible = true }
                onOpenNotes:    { root.notesVisible = !root.notesVisible; BeeSound.playEvent(root.notesVisible ? "dash.open" : "dash.close") }
                onOpenCalendar: { root.calendarVisible = !root.calendarVisible; BeeSound.playEvent(root.calendarVisible ? "dash.open" : "dash.close") }
            }

            Clock {
                anchors.right: parent.right; anchors.top: parent.top
                anchors.topMargin: 60; anchors.rightMargin: 20
                visible: BeeConfig.analogClock && !BeeBarState.focusActive
            }

            BeeEvents {
                anchors.left: parent.left; anchors.bottom: parent.bottom
                anchors.leftMargin: 20; anchors.bottomMargin: 20
                visible: BeeConfig.eventsEnabled && !BeeBarState.focusActive
            }
        }
    }

    // Overlay Elements
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            required property var modelData
            screen: modelData
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "beehive-overlay"
            exclusiveZone: -1
            focusable: false
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            mask: Region {} 

            BeeCorners { 
                active: BeeBarState.cornersActive 
                anchors.fill: parent
            }
        }
    }

    // OSD & Notifications
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            required property var modelData
            screen: modelData
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "beehive-aura"
            exclusiveZone: -1
            focusable: false
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            mask: Region {} 

            BeeOSD { 
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 80
            }
            
            BeeNotify { 
                anchors.top: parent.top
                anchors.right: parent.right
            }
        }
    }

    // Timer de lancement
    property string _pendingCmd: ""
    Timer {
        id: launchTimer
        interval: 200
        onTriggered: {
            if (!root._pendingCmd) return
            var proc = Qt.createQmlObject(
                'import Quickshell.Io; Process { running: true; command: ["bash", "-c", "nohup ' + root._pendingCmd.replace(/"/g, '\\"') + ' >/dev/null 2>&1 & disown"] }',
                root, "launchProc"
            )
            root._pendingCmd = ""
        }
    }

    // Panneaux Interactifs
    property bool controlVisible: false
    property int  controlTab: 0

    Loader {
        active: root.controlVisible
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                required property var modelData
                screen: modelData
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "beehive-control"
                focusable: true
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"

                BeeControl {
                    anchors.centerIn: parent
                    visible: true
                    currentTab: root.controlTab
                    onVisibleChanged: { 
                        if (!visible) {
                            root.controlVisible = false
                            BeeSound.playEvent("dash.close")
                        }
                    }
                }
            }
        }
    }

    Loader {
        active: BeeBarState.powerVisible
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                required property var modelData
                screen: modelData
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "beehive-power"
                focusable: true
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"
                BeePower {
                    anchors.fill: parent
                    onCloseRequested: {
                        BeeBarState.powerVisible = false
                        BeeSound.playEvent("dash.close")
                    }
                    onActionRequested: (cmd) => {
                        BeeSound.playEvent("power.action")
                        root._pendingCmd = cmd
                        BeeBarState.powerVisible = false
                        launchTimer.restart()
                    }
                }
            }
        }
    }

    Loader {
        active: root.searchVisible
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                required property var modelData
                screen: modelData
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "beehive-search"
                focusable: true
                WlrLayershell.keyboardFocus: WlrLayershell.Exclusive
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"
                BeeSearch {
                    anchors.fill: parent
                    shown: true
                    onOpenSettings: { 
                        root.controlTab = 3; 
                        root.controlVisible = true 
                        BeeSound.playEvent("dash.open")
                    }
                    onOpenStudio:   { 
                        root.controlTab = 0; 
                        root.controlVisible = true 
                        BeeSound.playEvent("dash.open")
                    }
                    onLaunchRequested: (cmd) => {
                        root._pendingCmd = cmd
                        root.searchVisible = false
                        launchTimer.restart()
                    }
                    onShownChanged: { 
                        if (!shown) {
                            root.searchVisible = false
                            BeeSound.playEvent("dash.close")
                        }
                    }
                }
            }
        }
    }

    // ─── BeeNotes Panel (focusable, own PanelWindow) ─────────────
    property bool notesVisible: false

    Loader {
        active: root.notesVisible
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                required property var modelData
                screen: modelData
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "beehive-notes"
                WlrLayershell.keyboardFocus: WlrLayershell.OnDemand
                focusable: true
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"

                // Overlay semi-transparent (clic dehors → fermer)
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.5)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.notesVisible = false
                            BeeSound.playEvent("dash.close")
                        }
                    }
                }

                // BeeNotes centré dans le panel (par-dessus l'overlay)
                BeeNotes {
                    anchors.centerIn: parent
                    onCloseRequested: {
                        root.notesVisible = false
                        BeeSound.playEvent("dash.close")
                    }
                }
            }
        }
    }

    // ─── BeeCalendar Panel (focusable, own PanelWindow) ──────────
    property bool calendarVisible: false

    Loader {
        active: root.calendarVisible
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                required property var modelData
                screen: modelData
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "beehive-calendar"
                WlrLayershell.keyboardFocus: WlrLayershell.Exclusive
                focusable: true
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"

                // Overlay semi-transparent (clic dehors → fermer)
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.5)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.calendarVisible = false
                            BeeSound.playEvent("dash.close")
                        }
                    }
                }

                // BeeCalendar centré dans le panel (par-dessus l'overlay)
                BeeCalendar {
                    anchors.centerIn: parent
                    onCloseRequested: {
                        root.calendarVisible = false
                        BeeSound.playEvent("dash.close")
                    }
                }
            }
        }
    }

    // ─── BeeVoice — Maya AI Assistant Overlay 🐝🎤 ──────────
    Loader {
        active: root.voiceVisible
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                required property var modelData
                screen: modelData
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "beehive-voice"
                exclusiveZone: -1
                focusable: true
                WlrLayershell.keyboardFocus: WlrLayershell.Exclusive
                anchors { top: true; bottom: true; left: true; right: true }
                color: Qt.rgba(0, 0, 0, 0.5)

                // Semi-transparent backdrop
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.4)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.voiceVisible = false
                            BeeSound.playEvent("dash.close")
                        }
                    }
                }

                BeeVoice {
                    id: voicePanel
                    anchors.centerIn: parent
                    active: root.voiceVisible
                    focus: true
                    onHideRequested: {
                        root.voiceVisible = false
                        BeeSound.playEvent("dash.close")
                    }

                    // Ensure focus when overlay appears
                    Connections {
                        target: root
                        function onVoiceVisibleChanged() {
                            if (root.voiceVisible) voicePanel.forceActiveFocus()
                        }
                    }
                }
            }
        }
    }

    // ─── First Run Welcome Screen ─────────────────────────────
    Loader {
        active: root.welcomeVisible
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                required property var modelData
                screen: modelData
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "beehive-welcome"
                focusable: true
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"
                BeeWelcome {
                    anchors.fill: parent
                    onDismissed: {
                        root.welcomeVisible = false
                        root.controlVisible = true   // Ouvre The Hive après le welcome
                        BeeSound.playEvent("dash.open")
                    }
                }
            }
        }
    }
}
