import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import './modules'

ShellRoot {
    id: root

    property bool dashVisible: false
    property bool searchVisible: false
    property bool osdVisible: false

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
                if (setting === "stealth") {
                    BeeConfig.stealthMode = !BeeConfig.stealthMode
                    BeeConfig.saveConfig()
                } else if (setting === "focus") {
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
    }
    function toggleSearch() { searchVisible = !searchVisible }

    IpcHandler {
        target: "root"
        function toggleDash()   { root.toggleDash() }
        function toggleSearch() { root.toggleSearch() }
        function toggleTheme()  { BeeTheme.toggle() }
        function toggleStealth() {
            BeeConfig.stealthMode = !BeeConfig.stealthMode
            BeeConfig.saveConfig()
        }
        function toggleFocus() {
            BeeConfig.focusMode = !BeeConfig.focusMode
            BeeConfig.saveConfig()
        }
        function testOSD() {
            BeeBarState.showOSD("volume", 50)
        }
        // ─── BeePower Menu ─────────────────────
        function showPower() {
            if (!root._debounce("power")) return
            BeeBarState.powerVisible = !BeeBarState.powerVisible
        }

        // ─── Settings / Studio / Launcher ───────
        function showSettings() { root.settingsVisible = true }
        function showStudio()   { root.studioVisible   = true }
        function showLauncher() { root.searchVisible   = true }
        function showSearch()   { root.searchVisible   = true }
        
        // ─── BeeAura Notifications ──
        function dispatchNotification(title: string, body: string, icon: string) {
            BeeBarState.dispatchNotification(title, body, icon)
        }
        // ─── BeeAura OSD ───────────
        function showOSD(type: string, value: int) {
            BeeBarState.showOSD(type, value)
        }
    }

    // Sentinelle Stealth
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            required property var modelData
            screen: modelData
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "beehive-stealth-trigger"
            exclusiveZone: 0
            focusable: false
            anchors { top: true; left: true; right: true }
            implicitHeight: 4
            color: "transparent"
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: { if (BeeConfig.stealthMode) BeeBarState.forceVisible = true }
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
            BeeBar {}

            MayaDash {
                id: mayaDash
                dashShown: root.dashVisible && !BeeBarState.focusActive
                beeMotionEnabled: BeeBarState.motionActive
                beeVibeEnabled:   BeeBarState.vibeActive
                onOpenSettings: root.settingsVisible = true
                onOpenStudio:   root.studioVisible = true
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
    property bool settingsVisible: false
    property bool studioVisible: false

    Loader {
        active: root.settingsVisible
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                required property var modelData
                screen: modelData
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "beehive-settings"
                focusable: true
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"

                BeeSettings {
                    anchors.centerIn: parent
                    visible: true
                    onVisibleChanged: { if (!visible) root.settingsVisible = false }
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
                    onCloseRequested: BeeBarState.powerVisible = false
                    onActionRequested: (cmd) => {
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
                    onOpenSettings: { root.settingsVisible = true }
                    onOpenStudio:   { root.studioVisible   = true }
                    onLaunchRequested: (cmd) => {
                        root._pendingCmd = cmd
                        root.searchVisible = false
                        launchTimer.restart()
                    }
                    onShownChanged: { if (!shown) root.searchVisible = false }
                }
            }
        }
    }

    Loader {
        active: root.studioVisible
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                required property var modelData
                screen: modelData
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "beehive-studio"
                focusable: true
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"
                BeeStudio { 
                    anchors.fill: parent
                    visible: true
                    onVisibleChanged: { if (!visible) root.studioVisible = false }
                }
            }
        }
    }
}
