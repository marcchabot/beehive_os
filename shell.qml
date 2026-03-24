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

    // Initialiser BeeBarState depuis BeeConfig au boot
    Connections {
        target: BeeConfig
        function onVibeModeChanged() {
            BeeBarState.vibeActive = BeeConfig.vibeMode
        }
        function onFocusModeChanged() {
            BeeBarState.focusActive = BeeConfig.focusMode
        }
        function onCornersModeChanged() {
            BeeBarState.cornersActive = BeeConfig.cornersMode
        }
        function onMotionModeChanged() {
            BeeBarState.motionActive = BeeConfig.motionMode
        }
    }

    // ─── BeePower Action Handler ───────────────────────────────
    Connections {
        target: BeePower
        function onActionRequested(cmd) {
            console.log("BeePower: action requested →", cmd)
            // Parse command format: "app:name", "toggle:setting", "shell:command", etc.
            if (cmd.startsWith("app:")) {
                var appName = cmd.substring(4)
                var desktopFile = "/usr/share/applications/" + appName + ".desktop"
                // Try to launch via desktop file
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
                    // Open BeeStudio
                    toggleDash()
                    // TODO: Actually open BeeStudio panel (needs integration)
                    console.log("BeePower: toggle:settings → should open BeeStudio")
                }
            } else if (cmd.startsWith("shell:")) {
                var shellCmd = cmd.substring(6)
                var proc = Qt.createQmlObject('import QtQuick; import Quickshell.Io; Process { command: ["bash", "-c", "' + shellCmd + '"] }', root, "BeePowerShell")
                proc.start()
            } else {
                console.warn("BeePower: Unknown command format →", cmd)
            }
        }
    }
    Component.onCompleted: {
        BeeBarState.vibeActive    = BeeConfig.vibeMode
        BeeBarState.focusActive   = BeeConfig.focusMode
        BeeBarState.cornersActive = BeeConfig.cornersMode
        BeeBarState.motionActive  = BeeConfig.motionMode
    }

    function toggleDash()   { dashVisible   = !dashVisible }
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
            console.log("TEST OSD - Function called!")
            BeeBarState.showOSD("volume", 50)
        }
        // ─── BeeAura Notifications (relayé depuis beenotifier.py) ──
        function dispatchNotification(title: string, body: string, icon: string) {
            BeeBarState.dispatchNotification(title, body, icon)
        }
        // ─── BeeAura OSD (relayé depuis bee-osd-cmd.sh) ───────────
        function showOSD(type: string, value: int) {
            BeeBarState.showOSD(type, value)
        }
    }

    // ═══════════════════════════════════════════════════════
    // Fenêtre Sentinelle : Stealth Trigger — Layer Top
    // ═══════════════════════════════════════════════════════
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            required property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "beehive-stealth-trigger"
            exclusiveZone: 0
            focusable: false
            WlrLayershell.keyboardFocus: WlrLayershell.None
            anchors { top: true; left: true; right: true }
            implicitHeight: 4
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    if (BeeConfig.stealthMode) {
                        BeeBarState.forceVisible = true
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════
    // Fenêtre 1 : Widgets — Layer Background
    // ═══════════════════════════════════════════════════════
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
            WlrLayershell.keyboardFocus: WlrLayershell.None
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

    // ═══════════════════════════════════════════════════════
    // FENÊTRE CORNERS — Layer: Overlay (Par-dessus tout)
    // ═══════════════════════════════════════════════════════
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            required property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "beehive-corners"
            exclusiveZone: -1
            focusable: false
            WlrLayershell.keyboardFocus: WlrLayershell.None
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            mask: Region {} // Click-through total

            BeeCorners { 
                active: BeeBarState.cornersActive 
                anchors.fill: parent
            }
        }
    }

    // ═══════════════════════════════════════════════════════
    // FENÊTRE OSD — Layer: Top, coin bas-centre, taille fixe
    // Petite fenêtre → peu de surface → moins de risque de blocage
    // ═══════════════════════════════════════════════════════
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            required property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "beehive-osd"
            exclusiveZone: -1
            focusable: false
            WlrLayershell.keyboardFocus: WlrLayershell.None
            anchors { bottom: true; left: true; right: true }
            implicitHeight: 150
            color: "transparent"
            mask: Region {}   // ← fenêtre invisible pour la souris (officiel Quickshell)

            BeeOSD { anchors.fill: parent }
        }
    }

    // ═══════════════════════════════════════════════════════
    // FENÊTRE NOTIFY — Layer: Top, coin haut-droit, taille fixe
    // ═══════════════════════════════════════════════════════
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            required property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "beehive-notify"
            exclusiveZone: -1
            focusable: false
            WlrLayershell.keyboardFocus: WlrLayershell.None
            anchors { top: true; right: true }
            implicitWidth: 420
            implicitHeight: 600
            color: "transparent"
            mask: Region {}   // ← fenêtre invisible pour la souris (officiel Quickshell)

            BeeNotify { anchors.fill: parent }
        }
    }

    // ─── Timer de lancement ───
    property string _pendingCmd: ""
    Timer {
        id: launchTimer
        interval: 200
        repeat: false
        onTriggered: {
            if (!root._pendingCmd) return
            console.log("Shell: lancement →", root._pendingCmd)
            var proc = Qt.createQmlObject(
                'import Quickshell.Io; Process { running: true; command: ["bash", "-c", "nohup ' + root._pendingCmd.replace(/"/g, '\\"') + ' >/dev/null 2>&1 & disown"] }',
                root, "launchProc"
            )
            root._pendingCmd = ""
        }
    }

    // ═══════════════════════════════════════════════════════
    // Fenêtre 3 : BeeSettings — Layer Top
    // ═══════════════════════════════════════════════════════
    property bool settingsVisible: false

    Loader {
        active: root.settingsVisible
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                required property var modelData
                screen: modelData

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "beehive-settings"
                exclusiveZone: -1
                focusable: true
                WlrLayershell.keyboardFocus: WlrLayershell.None
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"

                BeeSettings {
                    id: beeSettingsOverlay
                    anchors.centerIn: parent
                    visible: true
                    onCornersToggled: (val) => { BeeBarState.cornersActive = val }
                    onMotionToggled:  (val) => { BeeBarState.motionActive  = val }
                    onVibeToggled:    (val) => {
                        BeeBarState.vibeActive = val
                        BeeConfig.vibeMode = val
                        BeeConfig.saveConfig()
                    }
                    onStealthToggled: (val) => {
                        BeeConfig.stealthMode = val
                        BeeConfig.saveConfig()
                    }
                    onFocusToggled: (val) => {
                        BeeBarState.focusActive = val
                    }
                    // Fermer quand l'utilisateur clique ✕
                    onVisibleChanged: { if (!visible) root.settingsVisible = false }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════
    // Fenêtre 4 : BeePower — Layer Top
    // ═══════════════════════════════════════════════════════
    Loader {
        active: BeeBarState.powerVisible
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                required property var modelData
                screen: modelData

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "beehive-power"
                exclusiveZone: -1
                focusable: true
                WlrLayershell.keyboardFocus: WlrLayershell.None
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

    // ═══════════════════════════════════════════════════════
    // Fenêtre 6 : BeeSearch — Overlay
    // ═══════════════════════════════════════════════════════
    Loader {
        active: root.searchVisible
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                id: searchPanel
                required property var modelData
                screen: modelData

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "beehive-search"
                exclusiveZone: -1
                focusable: true
                WlrLayershell.keyboardFocus: WlrLayershell.Exclusive
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"

                BeeSearch {
                    id: beeSearch
                    anchors.fill: parent
                    shown: true
                    onOpenSettings: { root.settingsVisible = true }
                    onOpenStudio:   { root.studioVisible = true }
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

    // ─── Studio (Isolé) ───
    property bool studioVisible: false
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

    // ─── Réception des requêtes inter-fenêtres (State → Root) ──
    Connections {
        target: BeeBarState
        function onOpenSettingsRequestedChanged() {
            if (BeeBarState.openSettingsRequested) {
                root.settingsVisible = true
                BeeBarState.openSettingsRequested = false
            }
        }
        function onOpenStudioRequestedChanged() {
            if (BeeBarState.openStudioRequested) {
                root.studioVisible = true
                BeeBarState.openStudioRequested = false
            }
        }
    }
}
