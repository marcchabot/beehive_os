import QtQuick
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

        // ─── BeeAura OSD ───────────
        function showOSD(type: string, value: int) {
            BeeBarState.showOSD(type, value)
        }

        // ─── Bee-Live Sync v2 ───────
        function refreshEvents() {
            BeeConfig.reloadLiveEvents()
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
            BeeBar {}

            MayaDash {
                id: mayaDash
                dashShown: root.dashVisible && !BeeBarState.focusActive
                beeMotionEnabled: BeeBarState.motionActive
                beeVibeEnabled:   BeeBarState.vibeActive
                onOpenSettings: { root.controlTab = 3; root.controlVisible = true }
                onOpenStudio:   { root.controlTab = 0; root.controlVisible = true }
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
