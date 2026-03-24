pragma Singleton
import QtQuick
import Quickshell

// ═══════════════════════════════════════════════════════════
// BeeBarState.qml — Shared Stealth Mode state
// Singleton accessible from shell.qml AND BeeBar.qml
// ═══════════════════════════════════════════════════════════
QtObject {
    id: root

    // true  = sentinel detected mouse → force display
    // false = normal state (handled by BeeBar)
    property bool forceVisible: false

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

    // ─── BeeAura History & Notifications 🔔📜 ─────────────────
    // Centralized event bus for the whole hive
    signal notificationReceived(string title, string body, string icon)

    property var historyModel: []
    readonly property int maxHistorySize: 50

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
    }

    // Alias for backward compatibility if needed
    function dispatchNotification(title, body, icon) {
        logAction(title, body, icon)
    }

    function clearHistory() {
        historyModel = []
    }

    function removeHistoryEntry(index) {
        var updated = historyModel.slice()
        updated.splice(index, 1)
        historyModel = updated
    }

    // ─── BeeAura OSD System 🎚️ ────────────────────────────────
    // type: "volume" | "mute" | "brightness" | "kbd"
    // value: 0-100 (ignored if type === "mute")
    signal osdReceived(string type, int value)
    function showOSD(type, value) {
        osdReceived(type, parseInt(value))
    }
}
