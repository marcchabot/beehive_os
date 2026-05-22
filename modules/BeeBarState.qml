pragma Singleton
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

// ═══════════════════════════════════════════════════════════
// BeeBarState.qml — Shared State & Stealth Mode Engine 🐝
// v3.0 : Stealth Mode v2 — sentinel zone + smooth auto-hide
//        When stealthMode is ON, the BeeBar slides out of view
//        after a grace period. A thin sentinel strip at the top
//        edge detects mouse hover and slides the bar back in.
// ═══════════════════════════════════════════════════════════
QtObject {
    id: root

    // ─── Stealth Mode v2 ───────────────────────────────────
    // stealthEnabled: bound from BeeConfig.stealthMode
    property bool stealthEnabled: false

    // sentinelHovered: true when mouse is in the top sentinel strip
    property bool sentinelHovered: false

    // barHovered: true when mouse is anywhere inside the BeeBar area
    property bool barHovered: false

    // forceVisible: true when mouse is in sentinel/bar or any panel is open
    property bool forceVisible: false

    // barShown: the effective visibility of the BeeBar
    //   - stealth OFF → always true
    //   - stealth ON  → forceVisible (sentinel, bar hover, or panel open)
    property bool barShown: !stealthEnabled || forceVisible

    // ─── Stealth auto-hide timer ──────────────────────────
    // After the mouse leaves BOTH the sentinel and the bar, wait
    // 800ms before hiding. The timer is cancelled if the mouse
    // re-enters either zone during the countdown.
    property Timer _stealthHideTimer: Timer {
        interval: 800
        repeat: false
        onTriggered: {
            if (root.stealthEnabled && !root.sentinelHovered && !root.barHovered) {
                root.forceVisible = false
            }
        }
    }

    // When sentinelHovered changes, update forceVisible and timer
    onSentinelHoveredChanged: {
        if (stealthEnabled) {
            _stealthHideTimer.stop()
            if (sentinelHovered) {
                forceVisible = true
            } else if (!barHovered) {
                // Mouse left sentinel AND is not in the bar → start hide timer
                _stealthHideTimer.start()
            }
        }
    }

    // When barHovered changes, update forceVisible and timer
    onBarHoveredChanged: {
        if (stealthEnabled) {
            _stealthHideTimer.stop()
            if (barHovered) {
                forceVisible = true
            } else if (!sentinelHovered) {
                // Mouse left the bar AND is not in sentinel → start hide timer
                _stealthHideTimer.start()
            }
        }
    }

    // When stealth is toggled OFF, ensure bar is shown
    onStealthEnabledChanged: {
        if (!stealthEnabled) {
            forceVisible = false
            _stealthHideTimer.stop()
        } else {
            // Stealth just enabled — show bar briefly, then auto-hide
            forceVisible = true
            _stealthHideTimer.start()
        }
    }

    // Inter-window signals to open Settings/Studio from BeeSearch
    property bool openSettingsRequested: false
    property bool openStudioRequested:   false

    // Synchronized states between The Hive (Control Panel) and widgets (Background)
    property bool cornersActive: true
    property bool motionActive:  true
    property bool vibeActive:    false

    // Mode Focus 🎯 (masque Dashboard, Events, Horloge)
    property bool focusActive: false

    // BeePower menu visibility
    property bool powerVisible: false

    // ─── Weather Detail Panel ──────────────────
    property bool weatherDetailRequested: false
    signal weatherDetailToggled()────
    property string activeWindowClass: "none"

    // Test: Comment out EVERYTHING Process-related
    /*
    Process {
        id: windowProc
        command: ["python3", "/home/node/.openclaw/workspace/projects/beehive_os/scripts/get_active_window.py"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                root.activeWindowClass = line.trim()
                windowTimer.start()
            }
        }
        stderr: SplitParser {}
    }

    Timer { id: windowTimer; interval: 2000; onTriggered: windowProc.running = true }
    */

    signal notificationReceived(string title, string body, string icon)

    property var historyModel: []
    readonly property int maxHistorySize: 50
    
    readonly property string historyPath: StandardPaths.writableLocation(StandardPaths.CacheLocation) + "/beehive_os/history.json"
    
    // Test: Comment out saveProc too
    property Process _saveProc: Process {
        id: _saveProc
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                // Ignore output, just process completion
            }
        }
        stderr: SplitParser {}
        onExited: (code, status) => {
            if (code === 0) {
                console.log("[BeeBarState] History saved")
            } else {
                console.warn("[BeeBarState] History save failed, code", code)
            }
        }
    }

    function loadHistory() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + historyPath)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status === 200 || xhr.status === 0) {
                try {
                    var data = JSON.parse(xhr.responseText)
                    if (Array.isArray(data)) historyModel = data
                } catch(e) {}
            }
        }
        xhr.send()
    }

    // Signal pour demander la création de dossier à BeeBar
    signal historySaveNeeded(string dirPath)

    function saveHistory() {
        var jsonStr = JSON.stringify(historyModel, null, 2)

        // Use Process like BeeConfig does (avoids QML_XHR_ALLOW_FILE_WRITE warning)
        var filepath = historyPath
        _saveProc.running = false
        _saveProc.command = ["bash", "-c", "mkdir -p " + filepath.substring(0, filepath.lastIndexOf("/")) + " && cat << 'BEEEOF' > " + filepath + "\n" + jsonStr + "\nBEEEOF"]
        _saveProc.running = true
    }

    Component.onCompleted: loadHistory()

    function logAction(category, message, icon = "🐝", type = "info") {
        // 1. Send visual toast (BeeNotify)
        notificationReceived(category, message, icon)

        // 2. Add to permanent history for "The Hive"
        var entry = {
            "category":  category,
            "message":   message,
            "icon":      icon,
            "type":      type,
            "timestamp": new Date().toLocaleTimeString(Qt.locale("fr_CA"), "HH:mm")
        }
        
        var updated = [entry].concat(historyModel)
        if (updated.length > maxHistorySize)
            updated = updated.slice(0, maxHistorySize)
        historyModel = updated
        saveHistory()
    }

    // Alias for backward compatibility if needed
    function dispatchNotification(title, body, icon) {
        logAction(title, body, icon)
    }

    function clearHistory() {
        historyModel = []
        saveHistory()
    }

    function removeHistoryEntry(index) {
        var updated = historyModel.slice()
        updated.splice(index, 1)
        historyModel = updated
        saveHistory()
    }

    // ─── BeeAura OSD System 🎚️ ────────────────────────────────
    // type: "volume" | "mute" | "brightness" | "kbd"
    // value: 0-100 (ignored if type === "mute")
    signal osdReceived(string type, int value)
    function showOSD(type, value) {
        osdReceived(type, parseInt(value))
    }
}
