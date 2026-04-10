pragma Singleton
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

// ═══════════════════════════════════════════════════════════
// BeeBarState.qml — Shared Stealth Mode state
// v2.1 : Persistent History + OSD/Notify integration 🐝📜
// ═══════════════════════════════════════════════════════════
QtObject {
    id: root

    // true  = sentinel detected mouse → force display
    // false = normal state (handled by BeeBar)
    property bool forceVisible: false
    // Mirrors the current visual state of BeeBar to drive reserved top space.
    property bool barShown: true

    // Inter-window signals to open Settings/Studio from BeeSearch
    property bool openSettingsRequested: false
    property bool openStudioRequested:   false

    // Synchronized states between BeeSettings (Layer Top) and widgets (Background)
    property bool cornersActive: true
    property bool motionActive:  true
    property bool vibeActive:    false

    // Mode Focus 🎯 (masque Dashboard, Events, Horloge)
    property bool focusActive: false

    // BeePower menu visibility
    property bool powerVisible: false


    // ─── Window Tracking ──────────────────────
    property string activeWindowClass: "none"

    Process {
        id: windowProc
        command: ["python3", "/home/node/.openclaw/workspace/projects/beehive_os/scripts/get_active_window.py"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                root.activeWindowClass = line.trim()
                windowTimer.start()
            }
        }
    }

    Timer { id: windowTimer; interval: 2000; onTriggered: windowProc.running = true }
    signal notificationReceived(string title, string body, string icon)

    property var historyModel: []
    readonly property int maxHistorySize: 50
    
    readonly property string historyPath: StandardPaths.writableLocation(StandardPaths.CacheLocation) + "/beehive_os/history.json"
    
    Process {
        id: _saveProc
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                // Ignore output, just process completion
                console.log("[BeeBarState] History saved")
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

    function saveHistory() {
        var jsonStr = JSON.stringify(historyModel, null, 2)
        _saveProc.running = false
        _saveProc.command = ["bash", "-c", "mkdir -p $(dirname " + historyPath + ") && cat << 'BEEEOF' > " + historyPath + "\n" + jsonStr + "\nBEEEOF"]
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
