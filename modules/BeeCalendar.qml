import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Quickshell.Io
import "."

// ═══════════════════════════════════════════════════════════════
// BeeCalendar.qml — Universal Calendar Widget 🐝📅
// Sprint v0.8.21 — Reminder system, snooze/dismiss, time-aware Nectar Sync
// Réutilise les données de bee_sync.py → data/events_live.json
// Bi-directionnel avec Google Calendar via gog CLI
// ═══════════════════════════════════════════════════════════════

Rectangle {
    id: beeCalendar

    width: 760
    height: 620
    color: Qt.rgba(BeeTheme.glassBg.r, BeeTheme.glassBg.g, BeeTheme.glassBg.b, 0.97)
    radius: 16
    border.color: BeeTheme.glassBorder
    border.width: 1.5

    // ─── Close Button (✕) — Top Right, BeeHive Style ──────────
    Rectangle {
        id: calCloseBtn
        anchors { right: parent.right; top: parent.top; rightMargin: 14; topMargin: 10 }
        z: 200
        width: 32; height: 32; radius: 16
        color: calCloseHov.containsMouse
            ? Qt.rgba(1.0, 0.3, 0.3, 0.2)
            : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
        border.color: calCloseHov.containsMouse
            ? Qt.rgba(1.0, 0.3, 0.3, 0.5)
            : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Text {
            text: "✕"; anchors.centerIn: parent
            color: calCloseHov.containsMouse ? "#ff5555" : BeeTheme.accent
            font.pixelSize: 14; font.bold: true
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        MouseArea {
            id: calCloseHov; anchors.fill: parent
            cursorShape: Qt.PointingHandCursor; hoverEnabled: true
            onClicked: beeCalendar.closeRequested()
        }
    }

    // ─── Signaux ──────────────────────────────────────────────
    signal closeRequested()
    signal eventCreated(string title, string date, string time, string calendarId)

    // ─── Propriétés ───────────────────────────────────────────
    property string viewMode: BeeConfig.calendarView || "month"  // "month" | "week" | "day"
    property date   selectedDate: new Date()
    property var    tr: BeeConfig.tr.calendar || ({})

    onViewModeChanged: {
        BeeConfig.calendarView = viewMode
    }

    // ─── Calendar source colors (by sub/label) ────────────────
    property var calColors: ({
        "Famille":    "#FFB81C",
        "Personnel":  "#4A90D9",
        "Pharmacie":  "#4CAF50",
        "XPS":        "#9C27B0",
        "default":    "#FFB81C"
    })

    // ─── Week helper properties ─────────────────────────────
    property date weekStart: {
        // Monday of the week containing selectedDate
        var d = new Date(selectedDate)
        var day = d.getDay()
        // Adjust for Monday-start (Mon=0, Sun=6)
        var diff = day === 0 ? 6 : day - 1
        d.setDate(d.getDate() - diff)
        d.setHours(0, 0, 0, 0)
        return d
    }
    property date weekEnd: {
        var d = new Date(weekStart)
        d.setDate(d.getDate() + 6)
        d.setHours(23, 59, 59, 999)
        return d
    }

    // ─── Color helper: hex → rgba with alpha ────────────────────
    function hexToRgba(hexStr, alpha) {
        if (!hexStr || typeof hexStr !== 'string' || hexStr.length < 7) {
            return Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, alpha)
        }
        // Strip leading # if present
        var h = hexStr.charAt(0) === '#' ? hexStr.substring(1) : hexStr
        if (h.length < 6) {
            return Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, alpha)
        }
        var r = parseInt(h.substring(0, 2), 16) / 255
        var g = parseInt(h.substring(2, 4), 16) / 255
        var b = parseInt(h.substring(4, 6), 16) / 255
        if (isNaN(r) || isNaN(g) || isNaN(b)) {
            return Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, alpha)
        }
        return Qt.rgba(r, g, b, alpha)
    }

    // ─── i18n helpers ─────────────────────────────────────────
    function t(key, fallback) {
        return (tr && tr[key]) ? tr[key] : fallback
    }

    // ─── Data: Full event list from events_live.json ──────────
    ListModel { id: allEventsModel }

    // ─── Reactive counters — force Repeater re-evaluation when models change ──
    property int allEventCount: allEventsModel.count

    // ─── Data: Filtered events for current view ───────────────
    ListModel { id: dayEventsModel }

    // ─── Reactive counter — forces Repeater re-evaluation when model changes ──
    property int dayEventCount: dayEventsModel.count

    // ─── CalDAV Sync properties 🐝☁️ v0.8.23 ────────────────
    property string caldavSyncStatus: BeeConfig.caldavSyncStatus  // "idle" | "syncing" | "synced" | "error"

    // ─── Create Event Dialog ──────────────────────────────────
    property bool createVisible: false

    // ─── Event Detail Dialog ──────────────────────────────────
    property var   detailEvent: null
    property bool detailVisible: false

    // ─── Notification state ──────────────────────────────────
    property var  snoozeEvent: null
    property bool snoozeVisible: false

    // 🐝 v0.8.21 — Reminder system properties
    signal reminderTriggered(string title, string time, string calendarLabel)
    property bool reminderEnabled: BeeConfig.beeCalendarReminderEnabled
    property int  reminderMinutes: BeeConfig.beeCalendarReminderMinutes
    property int  snoozeDurationMin: BeeConfig.beeCalendarSnoozeDurationMin
    property string reminderSound: BeeConfig.beeCalendarReminderSound

    // Track fired reminders to avoid duplicate notifications
    property var _firedReminders: ({})

    // Snoozed reminders — ListModel for re-scheduling
    ListModel { id: snoozedReminders }

    // ─── Reminder check timer (every 60s) ──────────────────
    Timer {
        id: reminderTimer
        interval: 60000
        running: reminderEnabled && allEventsModel.count > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: beeCalendar.checkReminders()
    }

    // ─── Reminder logic ─────────────────────────────────────
    function checkReminders() {
        if (!reminderEnabled) return

        var now = new Date()
        var nowTs = Math.floor(now.getTime() / 1000)
        var reminderWindow = reminderMinutes * 60  // seconds before event

        // Check allEventsModel for upcoming events
        for (var i = 0; i < allEventsModel.count; i++) {
            var evt = allEventsModel.get(i)
            var evtTs = evt.evtTimestamp
            if (evtTs <= 0) continue

            var diff = evtTs - nowTs
            // Event is within the reminder window (and hasn't started yet)
            if (diff > 0 && diff <= reminderWindow) {
                var key = evt.evtId + "_" + evtTs
                if (!_firedReminders[key]) {
                    _firedReminders[key] = true
                    var timeStr = evt.evtTime || new Date(evtTs * 1000).toLocaleTimeString(Qt.locale("fr_CA"), "HH:mm")
                    beeCalendar.snoozeEvent = {
                        id: evt.evtId,
                        title: evt.evtTitle,
                        time: timeStr,
                        icon: evt.evtIcon || "📅",
                        sub: evt.evtSub || "",
                        timestamp: evtTs
                    }
                    beeCalendar.snoozeVisible = true
                    reminderTriggered(evt.evtTitle, timeStr, evt.evtSub)
                    // Push to BeeNotify via BeeBarState
                    BeeBarState.notificationReceived(
                        "📅 Rappel: " + evt.evtTitle,
                        timeStr + " — " + (evt.evtSub || ""),
                        evt.evtIcon || "📅"
                    )
                    // Play reminder sound
                    BeeSound.playEvent(reminderSound, {})
                }
            }
        }

        // Check snoozed reminders for re-triggering
        var toRemove = []
        for (var j = snoozedReminders.count - 1; j >= 0; j--) {
            var sr = snoozedReminders.get(j)
            var snoozeTs = sr.snoozeTriggerTs
            if (nowTs >= snoozeTs) {
                // Re-trigger this snoozed reminder
                beeCalendar.snoozeEvent = {
                    id: sr.evtId,
                    title: sr.evtTitle,
                    time: sr.evtTime,
                    icon: sr.evtIcon || "📅",
                    sub: sr.evtSub || "",
                    timestamp: sr.evtTimestamp
                }
                beeCalendar.snoozeVisible = true
                BeeBarState.notificationReceived(
                    "📅 Rappel (snooze): " + sr.evtTitle,
                    sr.evtTime + " — " + (sr.evtSub || ""),
                    sr.evtIcon || "📅"
                )
                BeeSound.playEvent(reminderSound, {})
                toRemove.push(j)
            }
        }
        // Remove expired snoozed reminders (iterate reverse)
        for (var k = 0; k < toRemove.length; k++) {
            snoozedReminders.remove(toRemove[k])
        }
    }

    // ─── Snooze action — schedule re-reminder ───────────────
    function snoozeReminder(minutes) {
        if (!beeCalendar.snoozeEvent) return
        var evt = beeCalendar.snoozeEvent
        var nowTs = Math.floor(new Date().getTime() / 1000)
        var snoozeTs = nowTs + (minutes * 60)

        snoozedReminders.append({
            evtId: evt.id || "",
            evtTitle: evt.title,
            evtTime: evt.time,
            evtIcon: evt.icon || "📅",
            evtSub: evt.sub || "",
            evtTimestamp: evt.timestamp || 0,
            snoozeTriggerTs: snoozeTs
        })
        beeCalendar.snoozeVisible = false
    }

    // ─── Dismiss action — close notification ─────────────────
    function dismissReminder() {
        beeCalendar.snoozeVisible = false
        beeCalendar.snoozeEvent = null
    }


    // ═══════════════════════════════════════════════════════════
    // LOAD EVENTS from events_live.json
    // ═══════════════════════════════════════════════════════════
    function loadEvents() {
        var doc = new XMLHttpRequest()
        doc.onreadystatechange = function() {
            if (doc.readyState !== XMLHttpRequest.DONE) return
            if (doc.status !== 200 && doc.status !== 0) return

            var text = doc.responseText.trim()
            if (text === "") return

            try {
                var data = JSON.parse(text)
                var eventsArray = Array.isArray(data) ? data : (data.events || [])

                allEventsModel.clear()
                for (var i = 0; i < eventsArray.length; i++) {
                    allEventsModel.append({
                        evtId:          eventsArray[i].id           || "",
                        evtCalendarId:  eventsArray[i].calendarId   || "",
                        evtIcon:        eventsArray[i].icon          || "📅",
                        evtTitle:       eventsArray[i].title         || "",
                        evtTime:        eventsArray[i].time          || "",
                        evtSub:         eventsArray[i].sub           || "",
                        evtUrgent:      eventsArray[i].urgent        === true,
                        evtTimestamp:   eventsArray[i].timestamp     || 0,
                        evtCanDelete:   eventsArray[i].canDelete     === true,
                        evtSource:      eventsArray[i].source        || ""
                    })
                }
                filterEvents()
                updateLiveCount()
            } catch(e) {
                console.warn("BeeCalendar: JSON parse error:", e)
            }
        }

        var path = BeeConfig.eventsLivePath
        if (!path || path === "") {
            var home = StandardPaths.writableLocation(StandardPaths.HomeLocation).toString()
            path = home + "/beehive_os/data/events_live.json"
        }
        if (!path.startsWith("file://")) path = "file://" + path
        else if (path.startsWith("file://file://")) path = path.replace("file://file://", "file://")

        doc.open("GET", path)
        doc.send()
    }

    function updateLiveCount() {
        var nowTs = new Date().getTime() / 1000
        var count = 0
        for (var i = 0; i < allEventsModel.count; i++) {
            var ts = allEventsModel.get(i).evtTimestamp
            if (ts >= nowTs - 21600) count++
        }
        BeeConfig.liveSyncCount = count
    }

    // ═══════════════════════════════════════════════════════════
    // FILTER EVENTS by date
    // ═══════════════════════════════════════════════════════════
    function filterEvents() {
        dayEventsModel.clear()

        var selDayStart = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), selectedDate.getDate())
        var selDayEnd   = new Date(selDayStart.getTime() + 86400000)

        for (var i = 0; i < allEventsModel.count; i++) {
            var evt  = allEventsModel.get(i)
            var ts   = evt.evtTimestamp
            if (ts <= 0) continue

            var evtDate = new Date(ts * 1000)

            // Day view: events for selected day
            if (evtDate >= selDayStart && evtDate < selDayEnd) {
                dayEventsModel.append({
                    evtId:          evt.evtId,
                    evtCalendarId:  evt.evtCalendarId,
                    evtIcon:        evt.evtIcon,
                    evtTitle:       evt.evtTitle,
                    evtTime:        evt.evtTime,
                    evtSub:         evt.evtSub,
                    evtUrgent:      evt.evtUrgent,
                    evtTimestamp:   evt.evtTimestamp,
                    evtCanDelete:   evt.evtCanDelete,
                    evtSource:      evt.evtSource        || ""
                })
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // CREATE EVENT via gog CLI
    // ═══════════════════════════════════════════════════════════
    function createEvent(title, dateStr, timeStr, calendarId) {
        // Build start/end datetimes with dynamic timezone offset (RFC3339)
        var now = new Date()
        var offset = -now.getTimezoneOffset()  // minutes, negative for west of GMT
        var sign = offset >= 0 ? "+" : "-"
        var hours = Math.abs(Math.floor(offset / 60)).toString().padStart(2, "0")
        var mins = (Math.abs(offset) % 60).toString().padStart(2, "0")
        var tzStr = sign + hours + ":" + mins  // e.g. "-04:00" in EDT

        var calArg = calendarId || "powerland@gmail.com"
        var script

        if (timeStr && timeStr.trim() !== "") {
            // Timed event
            var isoStart = dateStr + "T" + timeStr + ":00" + tzStr
            var parts = timeStr.split(":")
            var endHour = parseInt(parts[0]) + 1
            var isoEnd = dateStr + "T" + String(endHour).padStart(2, '0') + ":" + parts[1] + ":00" + tzStr

            script = 'GOG_KEYRING_PASSWORD=maya '
                + 'gog calendar create "' + calArg + '" '
                + '--summary "' + title + '" '
                + '--from "' + isoStart + '" '
                + '--to "' + isoEnd + '" '
                + '--account powerland@gmail.com '
                + '2>&1'
        } else {
            // All-day event
            script = 'GOG_KEYRING_PASSWORD=maya '
                + 'gog calendar create "' + calArg + '" '
                + '--summary "' + title + '" '
                + '--from "' + dateStr + '" '
                + '--to "' + dateStr + '" '
                + '--all-day '
                + '--account powerland@gmail.com '
                + '2>&1'
        }

        Qt.createQmlObject(
            'import Quickshell.Io; Process { '
            + '  running: true; '
            + '  command: ["bash", "-c", "' + script.replace(/"/g, '\\"') + '"]; '
            + '  onExited: function(code, status) { '
            + '    if (code === 0) { '
            + '      BeeBarState.dispatchNotification("BeeCalendar", "' + t("event_created", "Événement créé") + ': ' + title + '", "✅") '
            + '    } else { '
            + '      BeeBarState.dispatchNotification("BeeCalendar", "' + t("create_error", "Erreur de création") + '", "❌") '
            + '    } '
            + '  } '
            + '}',
            beeCalendar, "createEvt"
        )

        // Re-sync immediately after CRUD
        refreshTimer.interval = 0
        refreshTimer.start()
    }

    // ═══════════════════════════════════════════════════════════
    // DELETE EVENT via gog CLI
    // ═══════════════════════════════════════════════════════════
    function deleteEvent(eventId, calendarId) {
        if (!eventId || !calendarId) return

        var script = 'GOG_KEYRING_PASSWORD=maya '
            + 'gog calendar delete "' + calendarId + '" "' + eventId + '" --force --account powerland@gmail.com 2>&1'

        Qt.createQmlObject(
            'import Quickshell.Io; Process { '
            + '  running: true; '
            + '  command: ["bash", "-c", "' + script.replace(/"/g, '\\"') + '"]; '
            + '  onExited: function(code, status) { '
            + '    if (code === 0) { '
            + '      BeeBarState.dispatchNotification("BeeCalendar", "' + t("event_deleted", "Événement supprimé") + '", "🗑️") '
            + '    } else { '
            + '      BeeBarState.dispatchNotification("BeeCalendar", "' + t("delete_error", "Erreur de suppression") + '", "❌") '
            + '    } '
            + '  } '
            + '}',
            beeCalendar, "deleteEvt"
        )
        refreshTimer.start()
    }

    // ─── Run bee_sync.py ─────────────────────────────────────
    function runSync() {
        var syncPath = Qt.resolvedUrl("../scripts/bee_sync.py").toString().replace("file://", "")
        Qt.createQmlObject(
            'import Quickshell.Io; Process { '
            + '  running: true; '
            + '  command: ["python3", "' + Qt.resolvedUrl("../scripts/bee_sync.py").toString().replace("file://", "") + '"] '
            + '}',
            beeCalendar, "beeCalSync"
        )
    }

    // ─── Run CalDAV sync 🐝☁️ v0.8.23 ────────────────────────
    function runCalDAVSync(forceFull) {
        if (!BeeConfig.caldavEnabled) {
            console.log("BeeCalendar: CalDAV sync disabled")
            return
        }
        caldavSyncStatus = "syncing"
        BeeConfig.caldavSyncStatus = "syncing"

        var caldavPath = Qt.resolvedUrl("../scripts/bee-caldav-sync.py").toString().replace("file://", "")
        var args = ["python3", caldavPath, "--sync"]
        if (forceFull) args.push("--force-full")

        var cmdStr = args.map(function(a) { return '\"' + a.replace(/"/g, '\\\"') + '\"' }).join(' ')

        try {
            var proc = Qt.createQmlObject(
                'import Quickshell.Io; Process { '
                + '  running: true; '
                + '  command: [' + args.map(function(a) { return '\"' + a.replace(/"/g, '\\\"') + '\"' }).join(', ') + ']; '
                + '  onExited: function(code, status) { '
                + '    if (code === 0) { '
                + '      BeeConfig.caldavSyncStatus = "synced" '
                + '      BeeConfig.caldavLastSync = new Date().toISOString() '
                + '      BeeConfig.caldavEventCount = 0 '
                + '      beeCalendar.loadEvents() '
                + '    } else { '
                + '      BeeConfig.caldavSyncStatus = "error" '
                + '    } '
                + '  } '
                + '}',
                beeCalendar, "caldavSyncProc"
            )
        } catch(e) {
            console.warn("BeeCalendar: CalDAV sync error:", e)
            caldavSyncStatus = "error"
            BeeConfig.caldavSyncStatus = "error"
        }

        // Also run the regular sync
        runSync()
    }

    // ─── Auto-refresh timer (15 min) ──────────────────────────
    Timer {
        id: refreshTimer
        interval: 3000
        repeat: false
        onTriggered: {
            runSync()
            reloadAfterSync.restart()
        }
    }

    // ─── CalDAV Auto-sync timer 🐝☁️ v0.8.23 ──────────────────
    Timer {
        id: caldavAutoSyncTimer
        interval: BeeConfig.caldavAutoSyncIntervalMin * 60000
        running: BeeConfig.caldavEnabled && BeeConfig.caldavAutoSync
        repeat: true
        onTriggered: {
            if (BeeConfig.caldavEnabled) {
                runCalDAVSync(false)
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 900000
        running: true
        repeat: true
        onTriggered: {
            runSync()
            reloadAfterSync.restart()
        }
    }

    Timer {
        id: reloadAfterSync
        interval: 2000
        repeat: false
        onTriggered: loadEvents()
    }

    // ─── Connections to BeeConfig ─────────────────────────────
    Connections {
        target: BeeConfig
        function onEventsReloadRequested() { loadEvents() }
        function onConfigLoaded() {
            runSync()
            reloadAfterSync.restart()
        }
    }

    // ─── Date helpers ────────────────────────────────────────
    function dayName(d) {
        var days = (BeeConfig.uiLang === "fr")
            ? ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"]
            : ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[d.getDay()]
    }

    function dayNameShort(d) {
        var days = (BeeConfig.uiLang === "fr")
            ? ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"]
            : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[d.getDay()]
    }

    function monthName(d) {
        var months = (BeeConfig.uiLang === "fr")
            ? ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
               "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"]
            : ["January", "February", "March", "April", "May", "June",
               "July", "August", "September", "October", "November", "December"]
        return months[d.getMonth()]
    }

    function dateKey(d) {
        return d.getFullYear() + "-" + String(d.getMonth()+1).padStart(2,'0') + "-" + String(d.getDate()).padStart(2,'0')
    }

    function calColor(sub) {
        return calColors[sub] || calColors["default"]
    }

    // ─── Parse hour from evtTime string ───
    // Supports: "14:00 – 15:00", "Auj. 10h00", "Dem. 08h30",
    // "Sam. 11h15", "Mer. (Journée)", "10h00 – 11h00"
    function parseStartHour(timeStr) {
        if (!timeStr || timeStr === "") return -1
        // Try "HH:MM" at the start (e.g. "14:00")
        var match = timeStr.match(/^(\d{1,2}):(\d{2})/)
        if (match) return parseInt(match[1])
        // Try French format "HHhMM" anywhere (e.g. "Auj. 10h00", "8h30")
        var frMatch = timeStr.match(/(\d{1,2})h(\d{2})/)
        if (frMatch) return parseInt(frMatch[1])
        // All-day events: "(Journée)" or "(Day)" → return 0 (midnight)
        if (timeStr.indexOf("Journée") >= 0 || timeStr.indexOf("Day") >= 0) return 0
        return -1
    }

    function parseEndHour(timeStr) {
        if (!timeStr || timeStr === "") return -1
        // Try to find end time after "–" or "-" with HH:MM
        var match = timeStr.match(/[–\-]\s*(\d{1,2}):(\d{2})/)
        if (match) return parseInt(match[1])
        // Try to find end time after "–" or "-" with French HHhMM
        var frMatch = timeStr.match(/[–\-]\s*(\d{1,2})h(\d{2})/)
        if (frMatch) return parseInt(frMatch[1])
        // All-day events: return 23 (spans whole day)
        if (timeStr.indexOf("Journée") >= 0 || timeStr.indexOf("Day") >= 0) return 23
        // If only start, assume 1 hour
        var start = parseStartHour(timeStr)
        return start >= 0 ? start + 1 : -1
    }

    // ═══════════════════════════════════════════════════════════
    // HEADER — Navigation + View Toggle + Create
    // ═══════════════════════════════════════════════════════════
    Column {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0
        enabled: !beeCalendar.createVisible && !beeCalendar.detailVisible

        // ─── Top Bar ──────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 52
            radius: 16
            color: Qt.rgba(BeeTheme.glassBg.r, BeeTheme.glassBg.g, BeeTheme.glassBg.b, 0.97)

            // Bottom corners: flat — mask with opaque rectangle
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 16
                color: Qt.rgba(BeeTheme.glassBg.r, BeeTheme.glassBg.g, BeeTheme.glassBg.b, 0.97)
            }

            // Subtle accent line at bottom of header
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 1
                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 10

                // ← Previous
                Text {
                    text: "‹"
                    font.pixelSize: 24
                    font.bold: true
                    color: BeeTheme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (beeCalendar.viewMode === "day")
                                beeCalendar.selectedDate = new Date(beeCalendar.selectedDate.getTime() - 86400000)
                            else if (beeCalendar.viewMode === "week")
                                beeCalendar.selectedDate = new Date(beeCalendar.selectedDate.getTime() - 7 * 86400000)
                            else
                                beeCalendar.selectedDate = new Date(beeCalendar.selectedDate.getFullYear(), beeCalendar.selectedDate.getMonth() - 1, 1)
                            beeCalendar.filterEvents()
                        }
                    }
                }

                // Date title
                Text {
                    id: dateTitle
                    font.pixelSize: 16
                    font.bold: true
                    color: BeeTheme.accent
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if (beeCalendar.viewMode === "day") {
                            return dayName(beeCalendar.selectedDate) + " "
                                + beeCalendar.selectedDate.getDate() + " "
                                + monthName(beeCalendar.selectedDate)
                        } else if (beeCalendar.viewMode === "week") {
                            var ws = beeCalendar.weekStart
                            var we = beeCalendar.weekEnd
                            return dayNameShort(ws) + " " + ws.getDate() + " " + monthName(ws)
                                + " – "
                                + dayNameShort(we) + " " + we.getDate() + " " + monthName(we)
                        } else {
                            return monthName(beeCalendar.selectedDate) + " "
                                + beeCalendar.selectedDate.getFullYear()
                        }
                    }
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                // → Next
                Text {
                    text: "›"
                    font.pixelSize: 24
                    font.bold: true
                    color: BeeTheme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (beeCalendar.viewMode === "day")
                                beeCalendar.selectedDate = new Date(beeCalendar.selectedDate.getTime() + 86400000)
                            else if (beeCalendar.viewMode === "week")
                                beeCalendar.selectedDate = new Date(beeCalendar.selectedDate.getTime() + 7 * 86400000)
                            else
                                beeCalendar.selectedDate = new Date(beeCalendar.selectedDate.getFullYear(), beeCalendar.selectedDate.getMonth() + 1, 1)
                            beeCalendar.filterEvents()
                        }
                    }
                }

                // Today button
                Text {
                    text: t("today", "Auj.")
                    font.pixelSize: 12
                    font.bold: true
                    color: BeeTheme.accent
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 8; rightPadding: 8
                    topPadding: 3; bottomPadding: 3

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.12)
                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.35)
                        border.width: 1
                        z: -1
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: parent.opacity = 0.7
                        onExited:  parent.opacity = 1.0
                        onClicked: {
                            beeCalendar.selectedDate = new Date()
                            beeCalendar.filterEvents()
                        }
                    }
                }

                Item { width: 8; height: 1 } // spacer

                // View toggle: Month | Day
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Component {
                        id: viewBtnComp
                        Rectangle {
                            width: 52; height: 28
                            radius: 6
                            property string mode: "month"
                            property string label: "Mois"
                            color: beeCalendar.viewMode === mode
                                ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.25)
                                : "transparent"
                            border.color: beeCalendar.viewMode === mode
                                ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.5)
                                : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: parent.label
                                font.pixelSize: 11
                                font.bold: beeCalendar.viewMode === parent.mode
                                color: beeCalendar.viewMode === parent.mode ? BeeTheme.accent : BeeTheme.textSecondary
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: beeCalendar.viewMode = parent.mode
                            }
                        }
                    }

                    Loader { active: true; sourceComponent: viewBtnComp; onLoaded: { item.mode = "month"; item.label = t("month", "Mois") } }
                    Loader { active: true; sourceComponent: viewBtnComp; onLoaded: { item.mode = "week"; item.label = t("week", "Sem.") } }
                    Loader { active: true; sourceComponent: viewBtnComp; onLoaded: { item.mode = "day"; item.label = t("day", "Jour") } }
                }

                // Spacer
                Item { width: 1; height: 1; Layout.fillWidth: true }

                // ── CalDAV Sync button 🐝☁️ v0.8.23 ───────────────
                Rectangle {
                    visible: BeeConfig.caldavEnabled
                    width: 32; height: 32
                    radius: 8
                    color: {
                        if (caldavSyncStatus === "syncing") return Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                        if (caldavSyncStatus === "synced") return Qt.rgba(0.3, 0.8, 0.4, 0.2)
                        if (caldavSyncStatus === "error") return Qt.rgba(0.8, 0.2, 0.2, 0.25)
                        return Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.12)
                    }
                    border.color: {
                        if (caldavSyncStatus === "syncing") return BeeTheme.accent
                        if (caldavSyncStatus === "synced") return "#4CAF50"
                        if (caldavSyncStatus === "error") return "#ff5555"
                        return Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                    }
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (caldavSyncStatus === "syncing") return "⏳"
                            if (caldavSyncStatus === "synced") return "☁️"
                            if (caldavSyncStatus === "error") return "⚠️"
                            return "🔄"
                        }
                        font.pixelSize: 16
                    }

                    // Rotation animation when syncing
                    RotationAnimation on rotation {
                        running: caldavSyncStatus === "syncing"
                        from: 0; to: 360
                        duration: 1200
                        loops: Animation.Infinite
                    }

                    MouseArea {
                        id: caldavSyncBtnMa
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: runCalDAVSync(false)
                    }

                    // Status label on hover
                    Text {
                        visible: caldavSyncBtnMa.containsMouse
                        anchors.right: parent.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (caldavSyncStatus === "syncing") return qsTr("Sync…")
                            if (caldavSyncStatus === "synced") return qsTr("☁️ OK")
                            if (caldavSyncStatus === "error") return qsTr("Erreur")
                            return qsTr("CalDAV")
                        }
                        font.pixelSize: 10
                        color: BeeTheme.textSecondary
                    }
                }

                // Create event button (+)
                Rectangle {
                    width: 32; height: 32
                    radius: 8
                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.18)
                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        font.pixelSize: 20
                        font.bold: true
                        color: BeeTheme.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: parent.border.color = BeeTheme.accent
                        onExited:  parent.border.color = Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
                        onClicked: beeCalendar.createVisible = true
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════
        // CONTENT: Month View (full calendar grid)
        // ═══════════════════════════════════════════════════════
        Item {
            width: parent.width
            height: parent.height - 52 - 44
            visible: beeCalendar.viewMode === "month"

            Rectangle {
                anchors.fill: parent
                anchors.margins: 12
                radius: 12
                color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.15)
                border.color: Qt.rgba(BeeTheme.glassBorder.r, BeeTheme.glassBorder.g, BeeTheme.glassBorder.b, 0.2)
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    // Day-of-week header row
                    Row {
                        spacing: 0
                        anchors.horizontalCenter: parent.horizontalCenter

                        Repeater {
                            model: (BeeConfig.uiLang === "fr")
                                ? ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
                                : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                            Text {
                                text: modelData
                                font.pixelSize: 11
                                font.bold: true
                                color: BeeTheme.textSecondary
                                width: 90
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    // Calendar grid — 6 rows × 7 cols
                    Grid {
                        id: calGrid
                        columns: 7
                        spacing: 2
                        anchors.horizontalCenter: parent.horizontalCenter

                        property date gridDate: new Date(beeCalendar.selectedDate.getFullYear(), beeCalendar.selectedDate.getMonth(), 1)
                        property int startDay: {
                            var raw = calGrid.gridDate.getDay()
                            if (BeeConfig.uiLang === "fr") return (raw + 6) % 7
                            return raw
                        }
                        property int daysInMonth: new Date(beeCalendar.selectedDate.getFullYear(), beeCalendar.selectedDate.getMonth() + 1, 0).getDate()
                        property int prevMonthDays: new Date(beeCalendar.selectedDate.getFullYear(), beeCalendar.selectedDate.getMonth(), 0).getDate()

                        Repeater {
                            model: 42

                            Rectangle {
                                width: 90; height: 64
                                radius: 8
                                clip: true

                                property int dayNum: {
                                    var idx = index - calGrid.startDay + 1
                                    if (idx < 1 || idx > calGrid.daysInMonth) return -1
                                    return idx
                                }
                                property bool isToday: {
                                    var now = new Date()
                                    dayNum === now.getDate()
                                    && beeCalendar.selectedDate.getMonth() === now.getMonth()
                                    && beeCalendar.selectedDate.getFullYear() === now.getFullYear()
                                }
                                property bool isSelected: dayNum === beeCalendar.selectedDate.getDate()
                                property bool hasEvents: {
                                    if (dayNum < 1) return false
                                    var _n = beeCalendar.allEventCount
                                    var checkDate = new Date(beeCalendar.selectedDate.getFullYear(), beeCalendar.selectedDate.getMonth(), dayNum)
                                    var ck = dateKey(checkDate)
                                    for (var i = 0; i < _n; i++) {
                                        var evtD = new Date(allEventsModel.get(i).evtTimestamp * 1000)
                                        if (dateKey(evtD) === ck) return true
                                    }
                                    return false
                                }
                                property var dayEvents: {
                                    if (dayNum < 1) return []
                                    var _n = beeCalendar.allEventCount
                                    var checkDate = new Date(beeCalendar.selectedDate.getFullYear(), beeCalendar.selectedDate.getMonth(), dayNum)
                                    var ck = dateKey(checkDate)
                                    var result = []
                                    for (var i = 0; i < _n && result.length < 3; i++) {
                                        var evt = allEventsModel.get(i)
                                        var evtD = new Date(evt.evtTimestamp * 1000)
                                        if (dateKey(evtD) === ck) {
                                            result.push({ title: evt.evtTitle, sub: evt.evtSub, color: calColor(evt.evtSub), source: evt.evtSource || "" })
                                        }
                                    }
                                    return result
                                }

                                color: isSelected
                                    ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                                    : isToday
                                        ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06)
                                        : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.1)

                                border.color: isSelected ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.5) : "transparent"
                                border.width: isSelected ? 1.5 : 0

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                // Day number
                                Text {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.topMargin: 4
                                    anchors.leftMargin: 6
                                    text: dayNum > 0 ? dayNum : ""
                                    font.pixelSize: 13
                                    font.bold: isSelected || isToday
                                    color: dayNum < 1 ? "transparent"
                                        : isSelected ? BeeTheme.accent
                                        : BeeTheme.textPrimary
                                }

                                // Event previews (up to 2)
                                Column {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottomMargin: 2
                                    anchors.leftMargin: 4
                                    anchors.rightMargin: 4
                                    spacing: 1
                                    visible: dayNum > 0 && dayEvents && dayEvents.length > 0

                                    Repeater {
                                        model: dayEvents ? Math.min(dayEvents.length, 2) : 0
                                        Rectangle {
                                            width: parent.width
                                            height: 12
                                            radius: 3
                                            color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.3)
                                            clip: true

                                            Rectangle {
                                                width: 3; height: parent.height
                                                radius: 1.5
                                                color: dayEvents[index] ? dayEvents[index].color : BeeTheme.accent
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
                                                anchors.leftMargin: 6
                                                text: (dayEvents[index] ? dayEvents[index].title : "") + (dayEvents[index] && dayEvents[index].source === "caldav" ? " ☁" : "")
                                                font.pixelSize: 8
                                                color: dayEvents[index] && dayEvents[index].source === "caldav" ? Qt.rgba(0.4, 0.7, 1.0, 1.0) : BeeTheme.textPrimary
                                                elide: Text.ElideRight
                                                width: parent.width - 8
                                            }
                                        }
                                    }

                                    // "+N more" indicator
                                    Text {
                                        visible: dayEvents && dayEvents.length > 2
                                        text: "+" + (dayEvents.length - 2) + "…"
                                        font.pixelSize: 8
                                        color: BeeTheme.textSecondary
                                        anchors.left: parent.left
                                        anchors.leftMargin: 6
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    visible: dayNum > 0
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onEntered: parent.color = Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
                                    onExited: {
                                        if (isSelected) parent.color = Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                                        else if (isToday) parent.color = Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06)
                                        else parent.color = Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.1)
                                    }
                                    onClicked: {
                                        // Set selected date and switch to Day view
                                        beeCalendar.selectedDate = new Date(
                                            beeCalendar.selectedDate.getFullYear(),
                                            beeCalendar.selectedDate.getMonth(),
                                            dayNum
                                        )
                                        beeCalendar.filterEvents()
                                        beeCalendar.viewMode = "day"
                                    }
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 6 }

                    // Legend
                    Row {
                        spacing: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                        Repeater {
                            model: ["Famille", "Personnel", "Pharmacie"]
                            Row {
                                spacing: 4
                                Rectangle {
                                    width: 8; height: 8; radius: 4
                                    color: calColor(modelData)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: modelData
                                    font.pixelSize: 9
                                    color: BeeTheme.textSecondary
                                }
                            }
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════
        // CONTENT: Week View (7-day timeline)
        // ═══════════════════════════════════════════════════════
        Item {
            width: parent.width
            height: parent.height - 52 - 44
            visible: beeCalendar.viewMode === "week"

            Rectangle {
                anchors.fill: parent
                anchors.margins: 12
                radius: 12
                color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.15)
                border.color: Qt.rgba(BeeTheme.glassBorder.r, BeeTheme.glassBorder.g, BeeTheme.glassBorder.b, 0.2)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

                    // Day headers row
                    Row {
                        Layout.fillWidth: true
                        spacing: 2

                        // Time gutter spacer
                        Rectangle { width: 44; height: 28; color: "transparent" }

                        Repeater {
                            model: 7
                            Rectangle {
                                width: (parent.width - 46) / 7
                                height: 28
                                radius: 6
                                color: {
                                    var d = new Date(beeCalendar.weekStart.getTime() + index * 86400000)
                                    var isToday = dateKey(d) === dateKey(new Date())
                                    var isSelected = dateKey(d) === dateKey(beeCalendar.selectedDate)
                                    if (isSelected) return Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                                    if (isToday) return Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08)
                                    return "transparent"
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 0

                                    Text {
                                        text: dayNameShort(new Date(beeCalendar.weekStart.getTime() + index * 86400000))
                                        font.pixelSize: 9
                                        font.bold: false
                                        color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.7)
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    Text {
                                        text: new Date(beeCalendar.weekStart.getTime() + index * 86400000).getDate()
                                        font.pixelSize: 14
                                        font.bold: {
                                            var d = new Date(beeCalendar.weekStart.getTime() + index * 86400000)
                                            dateKey(d) === dateKey(beeCalendar.selectedDate)
                                        }
                                        color: {
                                            var d = new Date(beeCalendar.weekStart.getTime() + index * 86400000)
                                            dateKey(d) === dateKey(beeCalendar.selectedDate) ? BeeTheme.accent : BeeTheme.textPrimary
                                        }
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        beeCalendar.selectedDate = new Date(beeCalendar.weekStart.getTime() + index * 86400000)
                                        beeCalendar.filterEvents()
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 1
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                    }

                    // Scrollable timeline
                    ListView {
                        id: weekHourListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 0

                        model: 16  // 7h to 22h

                        delegate: Rectangle {
                            width: weekHourListView.width
                            height: 52
                            color: "transparent"

                            property int hourSlot: 7 + index

                            // Hour label
                            Text {
                                id: weekHourLabel
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.topMargin: 0
                                text: String(hourSlot).padStart(2, '0') + ":00"
                                font.pixelSize: 9
                                font.bold: true
                                color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.6)
                                width: 40
                            }

                            // Horizontal line across all days
                            Rectangle {
                                anchors.left: weekHourLabel.right
                                anchors.leftMargin: 4
                                anchors.right: parent.right
                                anchors.top: parent.top
                                height: 1
                                color: Qt.rgba(BeeTheme.glassBorder.r, BeeTheme.glassBorder.g, BeeTheme.glassBorder.b, 0.1)
                            }

                            // 7 day columns
                            Row {
                                anchors.left: weekHourLabel.right
                                anchors.leftMargin: 4
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.topMargin: 2
                                height: parent.height - 2
                                spacing: 2

                                Repeater {
                                    model: 7
                                    Rectangle {
                                        width: (parent.width - 6) / 7
                                        height: 48
                                        radius: 4
                                        clip: true
                                        color: {
                                            var d = new Date(beeCalendar.weekStart.getTime() + index * 86400000)
                                            var dk = dateKey(d)
                                            var isToday = dk === dateKey(new Date())
                                            var isSelected = dk === dateKey(beeCalendar.selectedDate)
                                            if (isSelected) return Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06)
                                            if (isToday) return Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.03)
                                            return Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.06)
                                        }

                                        // Find events for this day+hour
                                        property var weekDayEvents: {
                                            var _n = beeCalendar.allEventCount
                                            var d = new Date(beeCalendar.weekStart.getTime() + index * 86400000)
                                            var dk = dateKey(d)
                                            var result = []
                                            for (var i = 0; i < _n; i++) {
                                                var evt = allEventsModel.get(i)
                                                var evtDate = new Date(evt.evtTimestamp * 1000)
                                                if (dateKey(evtDate) === dk) {
                                                    var startH = parseStartHour(evt.evtTime)
                                                    if (startH === 0 && hourSlot === 7) startH = 7
                                                    if (startH === hourSlot) {
                                                        result.push({
                                                            evtId: evt.evtId,
                                                            evtCalendarId: evt.evtCalendarId,
                                                            evtIcon: evt.evtIcon,
                                                            evtTitle: evt.evtTitle,
                                                            evtTime: evt.evtTime,
                                                            evtSub: evt.evtSub,
                                                            evtUrgent: evt.evtUrgent,
                                                            evtTimestamp: evt.evtTimestamp,
                                                            evtCanDelete: evt.evtCanDelete
                                                        })
                                                    }
                                                }
                                            }
                                            return result
                                        }

                                        property int weekEventCount: weekDayEvents ? weekDayEvents.length : 0

                                        // Event pills — high contrast style
                                        Column {
                                            anchors.fill: parent
                                            anchors.margins: 1
                                            spacing: 1
                                            clip: true

                                            Repeater {
                                                model: Math.min(weekEventCount, 2)
                                                Rectangle {
                                                    id: eventPill
                                                    width: parent.width - 2
                                                    height: 18
                                                    radius: 3
                                                    // Outlined pill: transparent bg + colored border
                                                    color: hexToRgba(calColor(weekDayEvents[index] ? weekDayEvents[index].evtSub : "default"), 0.12)
                                                    border.color: calColor(weekDayEvents[index] ? weekDayEvents[index].evtSub : "default")
                                                    border.width: 1.5

                                                    Row {
                                                        id: eventPillCol
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        anchors.left: parent.left
                                                        anchors.leftMargin: 4
                                                        spacing: 4

                                                        Text {
                                                            text: weekDayEvents[index] ? weekDayEvents[index].evtTitle : ""
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: BeeTheme.textPrimary
                                                            elide: Text.ElideRight
                                                            width: eventPill.width - 12
                                                        }
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (weekDayEvents && weekDayEvents[index]) {
                                                                var evtData = weekDayEvents[index]
                                                                beeCalendar.detailEvent = {
                                                                    id: evtData.evtId,
                                                                    calendarId: evtData.evtCalendarId,
                                                                    icon: evtData.evtIcon,
                                                                    title: evtData.evtTitle,
                                                                    time: evtData.evtTime,
                                                                    sub: evtData.evtSub,
                                                                    timestamp: evtData.evtTimestamp,
                                                                    urgent: evtData.evtUrgent,
                                                                    canDelete: evtData.evtCanDelete
                                                                }
                                                                beeCalendar.detailVisible = true
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            // +N more indicator
                                            Text {
                                                visible: weekEventCount > 2
                                                text: "+" + (weekEventCount - 2)
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: BeeTheme.accent
                                            }
                                        }

                                        // Click to switch to day view
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                beeCalendar.selectedDate = new Date(beeCalendar.weekStart.getTime() + index * 86400000)
                                                beeCalendar.viewMode = "day"
                                                beeCalendar.filterEvents()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Scroll to current hour
                        Component.onCompleted: {
                            var currentHour = new Date().getHours()
                            if (currentHour >= 7 && currentHour <= 22) {
                                weekHourListView.positionViewAtIndex(currentHour - 7, ListView.Center)
                            }
                        }

                        // Empty state overlay
                        Text {
                            visible: allEventsModel.count === 0
                            text: t("no_events_week", "Aucun événement cette semaine 🍯")
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
                            font.pixelSize: 12
                            font.italic: true
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 80
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════
        // CONTENT: Day View (hourly timeline 7h–23h)
        // ═══════════════════════════════════════════════════════
        Item {
            width: parent.width
            height: parent.height - 52 - 44
            visible: beeCalendar.viewMode === "day"

            Rectangle {
                anchors.fill: parent
                anchors.margins: 12
                radius: 12
                color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.15)
                border.color: Qt.rgba(BeeTheme.glassBorder.r, BeeTheme.glassBorder.g, BeeTheme.glassBorder.b, 0.2)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    // Section header with day info + back to month button
                    Row {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: dayName(beeCalendar.selectedDate) + " "
                                + beeCalendar.selectedDate.getDate() + " "
                                + monthName(beeCalendar.selectedDate)
                            color: BeeTheme.accent
                            font.pixelSize: 15
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item { width: 10; height: 1 }

                        // Back to month button
                        Text {
                            text: "📅 " + t("month", "Mois")
                            font.pixelSize: 11
                            color: BeeTheme.accent
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: 8; rightPadding: 8
                            topPadding: 3; bottomPadding: 3

                            Rectangle {
                                anchors.fill: parent
                                radius: 4
                                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
                                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                                border.width: 1
                                z: -1
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: parent.opacity = 0.7
                                onExited:  parent.opacity = 1.0
                                onClicked: beeCalendar.viewMode = "month"
                            }
                        }

                        Item { width: 1; height: 1; Layout.fillWidth: true }

                        // Event count badge
                        Text {
                            visible: dayEventsModel.count > 0
                            text: dayEventsModel.count + " " + t("total_events", "événements")
                            font.pixelSize: 10
                            color: BeeTheme.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 1
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.18)
                    }

                    // Hourly timeline — scrollable
                    ListView {
                        id: hourListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 0

                        model: 16  // 7h to 22h (16 hour slots)

                        delegate: Rectangle {
                            width: hourListView.width
                            height: 52
                            color: "transparent"

                            property int hourSlot: 7 + index  // 7, 8, 9, ... 22

                            // Hour label
                            Text {
                                id: hourLabel
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.topMargin: 0
                                text: String(hourSlot).padStart(2, '0') + ":00"
                                font.pixelSize: 11
                                font.bold: true
                                color: BeeTheme.textSecondary
                                width: 44
                            }

                            // Horizontal line
                            Rectangle {
                                anchors.left: hourLabel.right
                                anchors.leftMargin: 8
                                anchors.right: parent.right
                                anchors.top: parent.top
                                height: 1
                                color: Qt.rgba(BeeTheme.glassBorder.r, BeeTheme.glassBorder.g, BeeTheme.glassBorder.b, 0.15)
                            }

                            // Events at this hour
                            Row {
                                id: hourEventsRow
                                anchors.left: hourLabel.right
                                anchors.leftMargin: 8
                                anchors.top: parent.top
                                anchors.topMargin: 4
                                anchors.right: parent.right
                                spacing: 4
                                clip: true

                                Repeater {
                                    model: {
                                        // dayEventCount forces re-evaluation when dayEventsModel changes
                                        var _count = beeCalendar.dayEventCount
                                        var result = []
                                        for (var i = 0; i < _count; i++) {
                                            var evt = dayEventsModel.get(i)
                                            var startH = parseStartHour(evt.evtTime)
                                            // All-day events (Journée) appear at first visible slot (7h)
                                            if (startH === 0 && hourSlot === 7) startH = 7
                                            if (startH === hourSlot) {
                                                result.push({
                                                    idx: i,
                                                    evtId: evt.evtId,
                                                    evtCalendarId: evt.evtCalendarId,
                                                    evtIcon: evt.evtIcon,
                                                    evtTitle: evt.evtTitle,
                                                    evtTime: evt.evtTime,
                                                    evtSub: evt.evtSub,
                                                    evtUrgent: evt.evtUrgent,
                                                    evtTimestamp: evt.evtTimestamp,
                                                    evtCanDelete: evt.evtCanDelete,
                                                    evtSource: evt.evtSource || ""
                                                })
                                            }
                                        }
                                        return result
                                    }

                                    Rectangle {
                                        height: 42
                                        width: Math.max(120, hourEventsRow.width / (hourEventsRow.children.length || 1) - 6)
                                        radius: 8
                                        color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.3)
                                        clip: true

                                        // Calendar color bar (left)
                                        Rectangle {
                                            width: 3
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            anchors.topMargin: 4
                                            anchors.bottomMargin: 4
                                            radius: 1.5
                                            color: calColor(modelData.evtSub)
                                        }

                                        Row {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 6
                                            anchors.topMargin: 2
                                            anchors.bottomMargin: 2
                                            spacing: 6

                                            Text {
                                                text: modelData.evtIcon
                                                font.pixelSize: 16
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Column {
                                                width: parent.width - 32
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 1

                                                Text {
                                                    text: modelData.evtTitle + (modelData.evtSource === "caldav" ? " ☁️" : "")
                                                    font.pixelSize: 11
                                                    font.bold: modelData.evtUrgent
                                                    color: modelData.evtUrgent ? BeeTheme.accent : (modelData.evtSource === "caldav" ? Qt.rgba(0.4, 0.7, 1.0, 1.0) : BeeTheme.textPrimary)
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }

                                                Text {
                                                    text: modelData.evtTime
                                                    font.pixelSize: 9
                                                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.7)
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onEntered: parent.color = Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
                                            onExited:  parent.color = Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.3)
                                            onClicked: {
                                                beeCalendar.detailEvent = {
                                                    id: modelData.evtId,
                                                    calendarId: modelData.evtCalendarId,
                                                    icon: modelData.evtIcon,
                                                    title: modelData.evtTitle,
                                                    time: modelData.evtTime,
                                                    sub: modelData.evtSub,
                                                    timestamp: modelData.evtTimestamp,
                                                    urgent: modelData.evtUrgent,
                                                    canDelete: modelData.evtCanDelete
                                                }
                                                beeCalendar.detailVisible = true
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Scroll to current hour
                        Component.onCompleted: {
                            var currentHour = new Date().getHours()
                            if (currentHour >= 7 && currentHour <= 22) {
                                hourListView.positionViewAtIndex(currentHour - 7, ListView.Center)
                            }
                        }

                        // Empty state overlay
                        Text {
                            visible: dayEventsModel.count === 0
                            text: t("no_events_day", "Aucun événement ce jour 🍯")
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
                            font.pixelSize: 12
                            font.italic: true
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 80
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════
        // FOOTER — Sync status + Reminder config
        // ═══════════════════════════════════════════════════════
        Rectangle {
            width: parent.width
            height: 44
            color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.15)

            // Top corners flat (overlap with content)
            Rectangle {
                anchors.top: parent.top
                width: parent.width; height: 12
                color: Qt.rgba(BeeTheme.glassBg.r, BeeTheme.glassBg.g, BeeTheme.glassBg.b, 0.97)
            }

            // Subtle accent line at top of footer
            Rectangle {
                anchors.top: parent.top
                width: parent.width; height: 1
                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 10

                Text {
                    text: "📅"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: allEventsModel.count + " " + t("total_events", "événements")
                    font.pixelSize: 11
                    color: BeeTheme.textSecondary
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Sync status
                Text {
                    text: pollTimer.running ? "🔄 15min" : "⏸"
                    font.pixelSize: 10
                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.6)
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: 1; height: 1; Layout.fillWidth: true }

                // Reminder selector
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        text: "🔔"
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: t("reminder", "Rappel") + ":"
                        font.pixelSize: 10
                        color: BeeTheme.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        spacing: 2
                        Repeater {
                            model: [5, 15, 30]
                            Rectangle {
                                width: 32; height: 22
                                radius: 4
                                color: (BeeConfig.beeCalendarReminderMinutes || 5) === modelData
                                    ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                                    : "transparent"
                                border.color: (BeeConfig.beeCalendarReminderMinutes || 5) === modelData
                                    ? BeeTheme.accent
                                    : Qt.rgba(BeeTheme.glassBorder.r, BeeTheme.glassBorder.g, BeeTheme.glassBorder.b, 0.3)
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData + "min"
                                    font.pixelSize: 9
                                    color: (BeeConfig.beeCalendarReminderMinutes || 5) === modelData
                                        ? BeeTheme.accent
                                        : BeeTheme.textSecondary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        BeeConfig.beeCalendarReminderMinutes = modelData
                                        BeeConfig.saveConfig()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // OVERLAY: Create Event Dialog
    // ═══════════════════════════════════════════════════════════
    Item {
        visible: beeCalendar.createVisible
        anchors.fill: parent
        z: 100
        focus: false

        // Backdrop: dark overlay + click to close
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.5)
            z: 0
            focus: false

            MouseArea {
                anchors.fill: parent
                z: 0
                onClicked: beeCalendar.createVisible = false
                hoverEnabled: false
                preventStealing: true
            }
        }

        // Dialog box (above backdrop)
        Rectangle {
            width: 360; height: 340
            anchors.centerIn: parent
            radius: 14
            color: Qt.rgba(BeeTheme.glassBg.r, BeeTheme.glassBg.g, BeeTheme.glassBg.b, 0.98)
            border.color: BeeTheme.accent
            border.width: 1.5
            z: 1
            focus: false

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Text {
                    text: "➕ " + t("new_event", "Nouvel événement")
                    color: BeeTheme.accent
                    font.pixelSize: 16
                    font.bold: true
                }

                // Title
                Column {
                    width: parent.width
                    spacing: 4
                    Text { text: t("event_title", "Titre"); font.pixelSize: 10; color: BeeTheme.textSecondary }
                    TextField {
                        id: createTitle
                        width: parent.width
                        placeholderText: t("title_placeholder", "Ex: Rendez-vous dentiste")
                        color: BeeTheme.textPrimary
                        font.pixelSize: 13
                        focus: beeCalendar.createVisible
                        placeholderTextColor: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.5)
                        selectedTextColor: BeeTheme.textPrimary
                        selectionColor: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                        background: Rectangle {
                            color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.25)
                            radius: 6
                            border.color: createTitle.activeFocus ? BeeTheme.accent : Qt.rgba(BeeTheme.glassBorder.r, BeeTheme.glassBorder.g, BeeTheme.glassBorder.b, 0.3)
                            border.width: createTitle.activeFocus ? 1.5 : 1
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            Behavior on border.width { NumberAnimation { duration: 150 } }
                        }
                    }
                }

                // Date
                Column {
                    width: parent.width
                    spacing: 4
                    Text { text: t("event_date", "Date"); font.pixelSize: 10; color: BeeTheme.textSecondary }
                    TextField {
                        id: createDate
                        width: parent.width
                        text: {
                            var d = beeCalendar.selectedDate
                            return d.getFullYear() + "-"
                                + String(d.getMonth()+1).padStart(2,'0') + "-"
                                + String(d.getDate()).padStart(2,'0')
                        }
                        placeholderText: "YYYY-MM-DD"
                        color: BeeTheme.textPrimary
                        font.pixelSize: 13
                        focus: beeCalendar.createVisible
                        placeholderTextColor: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.5)
                        selectedTextColor: BeeTheme.textPrimary
                        selectionColor: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                        background: Rectangle {
                            color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.25)
                            radius: 6
                            border.color: createDate.activeFocus ? BeeTheme.accent : Qt.rgba(BeeTheme.glassBorder.r, BeeTheme.glassBorder.g, BeeTheme.glassBorder.b, 0.3)
                            border.width: createDate.activeFocus ? 1.5 : 1
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            Behavior on border.width { NumberAnimation { duration: 150 } }
                        }
                    }
                }

                // Time
                Column {
                    width: parent.width
                    spacing: 4
                    Text { text: t("event_time", "Heure"); font.pixelSize: 10; color: BeeTheme.textSecondary }
                    TextField {
                        id: createTime
                        width: parent.width
                        placeholderText: "14:00"
                        color: BeeTheme.textPrimary
                        font.pixelSize: 13
                        focus: beeCalendar.createVisible
                        placeholderTextColor: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.5)
                        selectedTextColor: BeeTheme.textPrimary
                        selectionColor: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                        background: Rectangle {
                            color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.25)
                            radius: 6
                            border.color: createTime.activeFocus ? BeeTheme.accent : Qt.rgba(BeeTheme.glassBorder.r, BeeTheme.glassBorder.g, BeeTheme.glassBorder.b, 0.3)
                            border.width: createTime.activeFocus ? 1.5 : 1
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            Behavior on border.width { NumberAnimation { duration: 150 } }
                        }
                    }
                }

                // Calendar selector
                Column {
                    width: parent.width
                    spacing: 4
                    Text { text: t("calendar", "Calendrier"); font.pixelSize: 10; color: BeeTheme.textSecondary }
                    Row {
                        spacing: 6
                        Repeater {
                            model: [
                                { id: "powerland@gmail.com", label: "Personnel", color: "#4A90D9" },
                                { id: "family01761025763253819175@group.calendar.google.com", label: "Famille", color: "#FFB81C" },
                                { id: "e2vcp5c26oqp0aobdfpoceg687mr8h4h@import.calendar.google.com", label: "Pharmacie", color: "#10B981" }
                            ]
                            Rectangle {
                                width: 90; height: 26
                                radius: 6
                                property bool isSelected: createCalendar.selectedId === modelData.id
                                color: isSelected
                                    ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                                    : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.2)
                                border.color: isSelected ? modelData.color : "transparent"
                                border.width: isSelected ? 2 : 0

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Rectangle { width: 8; height: 8; radius: 4; color: modelData.color; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: modelData.label; font.pixelSize: 11; color: BeeTheme.textPrimary }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: createCalendar.selectedId = modelData.id
                                }
                            }
                        }

                        property string selectedId: "powerland@gmail.com"
                        id: createCalendar
                    }
                }

                // Buttons
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Rectangle {
                        width: 100; height: 34
                        radius: 8
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                        border.color: BeeTheme.accent
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: t("create", "Créer")
                            font.pixelSize: 12
                            font.bold: true
                            color: BeeTheme.accent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (createTitle.text.trim()) {
                                    beeCalendar.createEvent(
                                        createTitle.text.trim(),
                                        createDate.text,
                                        createTime.text,
                                        createCalendar.selectedId
                                    )
                                    beeCalendar.createVisible = false
                                    createTitle.text = ""
                                    createTime.text = ""
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 80; height: 34
                        radius: 8
                        color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.2)
                        border.color: Qt.rgba(BeeTheme.glassBorder.r, BeeTheme.glassBorder.g, BeeTheme.glassBorder.b, 0.3)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: t("cancel", "Annuler")
                            font.pixelSize: 12
                            color: BeeTheme.textSecondary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: beeCalendar.createVisible = false
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // OVERLAY: Event Detail Dialog
    // ═══════════════════════════════════════════════════════════
    Item {
        visible: beeCalendar.detailVisible && beeCalendar.detailEvent !== null
        anchors.fill: parent
        z: 100
        focus: false

        // Backdrop: dark overlay + click to close
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.5)
            z: 0
            focus: false

            MouseArea {
                anchors.fill: parent
                z: 0
                onClicked: beeCalendar.detailVisible = false
            }
        }

        // Dialog box (above backdrop)
        Rectangle {
            width: 380; height: 310
            anchors.centerIn: parent
            radius: 14
            color: Qt.rgba(BeeTheme.glassBg.r, BeeTheme.glassBg.g, BeeTheme.glassBg.b, 0.98)
            border.color: calColor(beeCalendar.detailEvent ? beeCalendar.detailEvent.sub : "")
            border.width: 2
            z: 1
            focus: false

            // Close Button (✕) — BeeHive Style
            Rectangle {
                width: 28; height: 28; radius: 14
                anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 10
                color: detailCloseHov.containsMouse
                    ? Qt.rgba(1.0, 0.3, 0.3, 0.2)
                    : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
                border.color: detailCloseHov.containsMouse
                    ? Qt.rgba(1.0, 0.3, 0.3, 0.5)
                    : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    text: "✕"; anchors.centerIn: parent
                    color: detailCloseHov.containsMouse ? "#ff5555" : BeeTheme.accent
                    font.pixelSize: 12; font.bold: true
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                MouseArea {
                    id: detailCloseHov; anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                    onClicked: beeCalendar.detailVisible = false
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                anchors.topMargin: 20
                spacing: 8

                // Icon + Title
                Row {
                    spacing: 10
                    width: parent.width

                    Text {
                        text: beeCalendar.detailEvent ? beeCalendar.detailEvent.icon : ""
                        font.pixelSize: 28
                    }

                    Text {
                        text: beeCalendar.detailEvent ? beeCalendar.detailEvent.title : ""
                        font.pixelSize: 16
                        font.bold: true
                        color: BeeTheme.textPrimary
                        wrapMode: Text.WordWrap
                        width: parent.width - 45
                    }
                }

                Rectangle {
                    width: parent.width; height: 1
                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.18)
                }

                // Details
                Column {
                    width: parent.width
                    spacing: 5

                    Row {
                        spacing: 8
                        Text { text: "🕐"; font.pixelSize: 13 }
                        Text {
                            text: beeCalendar.detailEvent ? beeCalendar.detailEvent.time : ""
                            font.pixelSize: 13
                            color: BeeTheme.accent
                        }
                    }

                    Row {
                        spacing: 8
                        visible: beeCalendar.detailEvent && beeCalendar.detailEvent.sub !== ""
                        Text { text: "📋"; font.pixelSize: 13 }
                        Rectangle {
                            width: 10; height: 10; radius: 5
                            color: calColor(beeCalendar.detailEvent ? beeCalendar.detailEvent.sub : "")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: beeCalendar.detailEvent ? beeCalendar.detailEvent.sub : ""
                            font.pixelSize: 13
                            color: BeeTheme.textSecondary
                        }
                    }

                    Row {
                        spacing: 8
                        Text { text: "📅"; font.pixelSize: 13 }
                        Text {
                            text: {
                                if (!beeCalendar.detailEvent) return ""
                                var d = new Date(beeCalendar.detailEvent.timestamp * 1000)
                                return dayName(d) + " " + d.getDate() + " " + monthName(d) + " " + d.getFullYear()
                            }
                            font.pixelSize: 12
                            color: BeeTheme.textSecondary
                        }
                    }
                }

                Item { width: 1; height: 6 }

                // Delete button — only for Google Calendar events
                Rectangle {
                    visible: beeCalendar.detailEvent && beeCalendar.detailEvent.canDelete
                    width: 130; height: 32
                    radius: 8
                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08)
                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                    border.width: 1
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "🗑 " + t("delete_event", "Supprimer")
                        font.pixelSize: 13
                        color: BeeTheme.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            if (beeCalendar.detailEvent && beeCalendar.detailEvent.id && beeCalendar.detailEvent.calendarId) {
                                beeCalendar.deleteEvent(beeCalendar.detailEvent.id, beeCalendar.detailEvent.calendarId)
                                beeCalendar.detailVisible = false
                            }
                        }
                    }
                }

                // ICS event note — cannot be deleted from here
                Text {
                    visible: beeCalendar.detailEvent && !beeCalendar.detailEvent.canDelete
                    text: "🔗 " + (BeeConfig.uiLang === "fr" ? "Événement externe (ICS)" : "External event (ICS)")
                    font.pixelSize: 11
                    font.italic: true
                    color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.6)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Action buttons: Snooze
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Repeater {
                        model: [
                            { label: "5 min", value: 5 },
                            { label: "15 min", value: 15 },
                            { label: "30 min", value: 30 }
                        ]
                        Rectangle {
                            width: 72; height: 28
                            radius: 6
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "⏰ " + t("snooze_" + modelData.value, modelData.label + " min")
                                font.pixelSize: 10
                                color: BeeTheme.accent
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    // Schedule snooze notification
                                    var evt = beeCalendar.detailEvent
                                    if (evt) {
                                        var snoozeCmd = 'sleep ' + (modelData.value * 60) + ' && '
                                            + 'GOG_KEYRING_PASSWORD=maya '
                                            + 'python3 ' + Qt.resolvedUrl("../scripts/beenotifier.py").toString().replace("file://", "")
                                            + ' "' + evt.title + '" "' + evt.time + '" --icon "' + evt.icon + '"'
                                        Qt.createQmlObject(
                                            'import Quickshell.Io; Process { '
                                            + '  running: true; '
                                            + '  command: ["bash", "-c", "' + snoozeCmd.replace(/"/g, '\\"') + ' &"] '
                                            + '}',
                                            beeCalendar, "snoozeEvt"
                                        )
                                        BeeBarState.dispatchNotification(
                                            "⏰ " + t("snooze", "Rappel"),
                                            evt.title + " — " + modelData.label,
                                            evt.icon
                                        )
                                    }
                                    beeCalendar.detailVisible = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // OVERLAY: Snooze Notification Popup
    // ═══════════════════════════════════════════════════════════
    Rectangle {
        visible: beeCalendar.snoozeVisible
        width: 280; height: 80
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        radius: 10
        color: Qt.rgba(BeeTheme.glassBg.r, BeeTheme.glassBg.g, BeeTheme.glassBg.b, 0.95)
        border.color: BeeTheme.accent
        border.width: 1
        z: 200

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4

            Row {
                spacing: 8
                Text { text: beeCalendar.snoozeEvent ? beeCalendar.snoozeEvent.icon : "📅"; font.pixelSize: 18 }
                Text {
                    text: beeCalendar.snoozeEvent ? beeCalendar.snoozeEvent.title : ""
                    font.pixelSize: 12; font.bold: true; color: BeeTheme.textPrimary
                    elide: Text.ElideRight; width: 200
                }
            }

            Row {
                spacing: 6
                Repeater {
                    model: [5, 15, 30]
                    Rectangle {
                        width: 50; height: 22
                        radius: 4
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "+" + modelData + "min"
                            font.pixelSize: 9
                            color: BeeTheme.accent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // 🐝 v0.8.21 — Use QML-native snooze (no external process)
                                beeCalendar.snoozeReminder(modelData)
                            }
                        }
                    }
                }

                // Dismiss (✕) — BeeHive Style
                Rectangle {
                    width: 22; height: 22; radius: 11
                    anchors.verticalCenter: parent.verticalCenter
                    color: snoozeDismissHov.containsMouse
                        ? Qt.rgba(1.0, 0.3, 0.3, 0.2)
                        : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
                    border.color: snoozeDismissHov.containsMouse
                        ? Qt.rgba(1.0, 0.3, 0.3, 0.5)
                        : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        text: "✕"; anchors.centerIn: parent
                        color: snoozeDismissHov.containsMouse ? "#ff5555" : BeeTheme.accent
                        font.pixelSize: 10; font.bold: true
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    MouseArea {
                        id: snoozeDismissHov; anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                        onClicked: beeCalendar.dismissReminder()
                    }
                }
            }
        }

        // Auto-dismiss after 15s (increased from 10s for reminder readability)
        Timer {
            interval: 15000
            running: beeCalendar.snoozeVisible
            repeat: false
            onTriggered: beeCalendar.dismissReminder()
        }
    }

    // ─── Init ─────────────────────────────────────────────────
    Component.onCompleted: {
        selectedDate = new Date()
        viewMode = BeeConfig.calendarView || "month"
        loadEvents()
    }
}