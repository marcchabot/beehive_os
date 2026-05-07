pragma Singleton

import QtQuick
import QtCore
import "."

// ═══════════════════════════════════════════════════════════════
// BeeAlarm.qml — Calendar Notification Push & Snooze ⏰🐝
// Lightweight reminder module: monitors BeeEvents and triggers
// notifications before upcoming events. Supports snooze (10 min).
// ═══════════════════════════════════════════════════════════════

QtObject {
    id: beeAlarm

    // ─── Configuration (bound to BeeConfig) ───────────────────
    property bool enabled: BeeConfig.alarmEnabled
    property int advanceMin: BeeConfig.alarmAdvanceMin    // minutes before event
    property int snoozeMin: BeeConfig.alarmSnoozeMin      // snooze duration

    // ─── Notified events tracker ──────────────────────────────
    // Map of event identifier → timestamp of last notification
    // Prevents duplicate notifications for the same event.
    property var notifiedEvents: ({})

    // ─── Snoozed alarms ───────────────────────────────────────
    // Array of { id: string, reactivateAt: number }
    // When a user snoozes, we push the re-notification forward.
    property var snoozedAlarms: []

    // ─── Alarm check timer (every 60 seconds) ─────────────────
    property Timer alarmTimer: Timer {
        interval: 60000   // 60 seconds
        running: beeAlarm.enabled
        repeat: true
        onTriggered: beeAlarm.checkAlarms()
    }

    // ─── Main alarm check ─────────────────────────────────────
    function checkAlarms() {
        if (!enabled) return

        var nowTs = new Date().getTime() / 1000
        var advanceSec = advanceMin * 60
        var advanceWindow = 120   // 2 min window to catch the right moment

        // Process snoozed alarms first — reactivate if time has come
        var activeSnoozed = []
        for (var s = 0; s < snoozedAlarms.length; s++) {
            var snooze = snoozedAlarms[s]
            if (nowTs >= snooze.reactivateAt) {
                // Re-trigger notification
                fireAlarm(snooze.id, snooze.summary || "Rappel")
                // Don't re-add to activeSnoozed (consumed)
            } else {
                activeSnoozed.push(snooze)
            }
        }
        snoozedAlarms = activeSnoozed

        // Check BeeEvents model for upcoming events
        // We need to access the events data. Since BeeEvents uses
        // a ListModel we can't access it directly from here.
        // Instead, we load the same JSON source.
        checkEventsFromJson(nowTs, advanceSec, advanceWindow)
    }

    // ─── Load and check events from JSON ──────────────────────
    function checkEventsFromJson(nowTs, advanceSec, advanceWindow) {
        var doc = new XMLHttpRequest()
        doc.onreadystatechange = function() {
            if (doc.readyState !== XMLHttpRequest.DONE) return
            if (doc.status !== 200 && doc.status !== 0) return

            var text = doc.responseText.trim()
            if (text === "") return

            try {
                var data = JSON.parse(text)
                var eventsArray = Array.isArray(data) ? data : (data.events || [])

                for (var i = 0; i < eventsArray.length; i++) {
                    var evt = eventsArray[i]
                    if (!evt.timestamp) continue

                    var evtId = evt.title + "_" + evt.timestamp
                    var timeUntil = evt.timestamp - nowTs

                    // Event is within the advance notification window
                    if (timeUntil > 0 && timeUntil <= advanceSec && timeUntil >= (advanceSec - advanceWindow)) {
                        // Check if already notified (not snoozed away)
                        if (!notifiedEvents[evtId]) {
                            fireAlarm(evtId, evt.title || "Rappel")
                            notifiedEvents[evtId] = nowTs
                            console.log("BeeAlarm: Notification pour →", evt.title, "(dans", Math.round(timeUntil / 60), "min)")
                        }
                    }

                    // Also check events that are very close (< 2 min) and not yet notified
                    if (timeUntil > 0 && timeUntil <= 120 && !notifiedEvents[evtId]) {
                        fireAlarm(evtId, evt.title || "Rappel")
                        notifiedEvents[evtId] = nowTs
                        console.log("BeeAlarm: Notification imminente →", evt.title, "(dans", Math.round(timeUntil / 60), "min)")
                    }
                }

                // Cleanup old notifiedEvents entries (older than 24h)
                var cutoff = nowTs - 86400
                var cleaned = {}
                var keys = Object.keys(notifiedEvents)
                for (var k = 0; k < keys.length; k++) {
                    if (notifiedEvents[keys[k]] > cutoff) {
                        cleaned[keys[k]] = notifiedEvents[keys[k]]
                    }
                }
                notifiedEvents = cleaned

            } catch(e) {
                console.warn("BeeAlarm: Erreur parsing events JSON:", e)
            }
        }

        // Build the path same way BeeEvents does
        var path = BeeConfig.eventsLivePath
        if (!path || path === "") {
            var home = StandardPaths.writableLocation(StandardPaths.HomeLocation).toString()
            path = home + "/beehive_os/data/events_live.json"
        }
        if (!path.startsWith("file://")) {
            path = "file://" + path
        } else if (path.startsWith("file://file://")) {
            path = path.replace("file://file://", "file://")
        }

        doc.open("GET", path)
        doc.send()
    }

    // ─── Fire alarm notification ───────────────────────────────
    function fireAlarm(evtId, summary) {
        var isFr = BeeConfig.uiLang === "fr"
        var title = isFr ? "⏰ Rappel" : "⏰ Reminder"
        var body = summary
        if (isFr) {
            body = summary + (advanceMin > 1 ? (" — dans " + advanceMin + " min") : " — maintenant !")
        } else {
            body = summary + (advanceMin > 1 ? (" — in " + advanceMin + " min") : " — now!")
        }

        BeeBarState.dispatchNotification(title, body, "⏰")
        BeeSound.playEvent("notify.info", {})
    }

    // ─── Snooze an alarm ──────────────────────────────────────
    function snooze(evtId, summary) {
        var reactivateAt = (new Date().getTime() / 1000) + (snoozeMin * 60)
        snoozedAlarms.push({
            id: evtId,
            reactivateAt: reactivateAt,
            summary: summary || "Rappel"
        })
        console.log("BeeAlarm: Snooze →", evtId, "(réactivation dans", snoozeMin, "min)")
    }

    // ─── Clear all notified/snoozed state ──────────────────────
    function clearAll() {
        notifiedEvents = ({})
        snoozedAlarms = []
        console.log("BeeAlarm: État réinitialisé")
    }

    Component.onCompleted: {
        console.log("BeeAlarm: Module initialisé (advance:", advanceMin, "min, snooze:", snoozeMin, "min)")
    }
}