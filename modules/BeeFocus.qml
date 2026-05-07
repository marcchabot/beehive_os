pragma Singleton
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "."

// ═══════════════════════════════════════════════════════════════
// BeeFocus.qml — Pomodoro & Health Timer Widget 🍅🐝
// v1.0 : Timer Pomodoro + Health Reminders pour MayaDash
//
// ─── Architecture ─────────────────────────────────────────────
//   • Cell view: Icon dynamique + temps restant dans MayaDash
//   • Detail view: Cercle de progression, stats, contrôles
//   • Health reminders: Hydratation, Posture, Yeux (20-20-20)
//   • Persistence: Timer state sauvegardé dans BeeConfig
// ═══════════════════════════════════════════════════════════════

Item {
    id: beeFocus

    // ─── Public properties (consumed by MayaDash cells) ───────
    property string currentIcon: "🍅"
    property string timeDisplay: "25:00"
    property string modeName: qsTr("Pomodoro")
    property bool isRunning: false
    property bool isPaused: false
    property real progress: 0.0    // 0.0 → 1.0

    // ─── Timer modes ──────────────────────────────────────────
    // 0 = Pomodoro (25/5), 1 = Short (15/3), 2 = Long (50/10), 3 = Custom
    property int currentMode: 0
    property var modes: [
        { name: qsTr("Pomodoro"), work: 25, break: 5, longBreak: 15, icon: "🍅", color: "#E74C3C" },
        { name: qsTr("Short"), work: 15, break: 3, longBreak: 8, icon: "⚡", color: "#F39C12" },
        { name: qsTr("Long"), work: 50, break: 10, longBreak: 20, icon: "🔥", color: "#8E44AD" },
        { name: qsTr("Custom"), work: 25, break: 5, longBreak: 15, icon: "🎯", color: "#3498DB" }
    ]

    // ─── Custom mode durations (minutes) ──────────────────────
    property int customWork: 25
    property int customBreak: 5
    property int customLongBreak: 15

    // ─── Timer state ──────────────────────────────────────────
    property int totalSeconds: modes[currentMode].work * 60
    property int remainingSeconds: totalSeconds
    property int sessionsCompleted: 0
    property int totalFocusMinutes: 0
    property bool isBreakPhase: false

    // ─── Health reminder state ─────────────────────────────────
    property bool hydrationEnabled: true
    property bool postureEnabled: true
    property bool eyesEnabled: true
    property int hydrationInterval: 30  // minutes
    property int postureInterval: 60     // minutes
    property int eyesInterval: 20       // minutes (20-20-20 rule)

    property int hydrationSeconds: hydrationInterval * 60
    property int postureSeconds: postureInterval * 60
    property int eyesSeconds: eyesInterval * 60

    // ─── Health reminder flags (transient, reset after shown) ──
    property bool hydrationReminder: false
    property bool postureReminder: false
    property bool eyesReminder: false

    // ─── Detail panel visibility ──────────────────────────────
    property bool detailVisible: false

    // ─── Accent color per mode ────────────────────────────────
    property color modeAccent: {
        if (isBreakPhase) return "#27AE60"
        var m = modes[currentMode]
        return Qt.color(m.color) || BeeTheme.accent
    }

    // ─── i18n helper ──────────────────────────────────────────
    function tr(key) {
        if (BeeConfig.tr && BeeConfig.tr.focus && BeeConfig.tr.focus[key])
            return BeeConfig.tr.focus[key]
        var fallbacks = {
            "title": "BeeFocus",
            "pomodoro": "Pomodoro",
            "short": "Short",
            "long": "Long",
            "custom": "Custom",
            "work": "Work",
            "break_label": "Break",
            "long_break": "Long Break",
            "start": "Start",
            "pause": "Pause",
            "resume": "Resume",
            "reset": "Reset",
            "skip": "Skip",
            "sessions": "sessions",
            "total_focus": "Total focus",
            "minutes": "min",
            "hydration": "Hydration",
            "hydration_desc": "Drink water reminder every %1 min",
            "posture": "Posture",
            "posture_desc": "Stretch reminder every %1 min",
            "eyes": "Eyes",
            "eyes_desc": "20-20-20 rule: look away every %1 min",
            "health_reminders": "Health Reminders",
            "timer_settings": "Timer Settings",
            "work_duration": "Work duration",
            "break_duration": "Break duration",
            "long_break_duration": "Long break duration",
            "next_break_in": "Next break in",
            "session_complete": "Session complete! Time for a break.",
            "work_complete": "Great focus session!",
            "hydration_alert": "💧 Time to drink water!",
            "posture_alert": "🧍 Time to stretch!",
            "eyes_alert": "👁️ Look 20ft away for 20 seconds!",
            "no_sessions_yet": "No sessions yet",
            "focus_minutes": "focus minutes"
        }
        return fallbacks[key] || key
    }

    // ─── Core Timer ──────────────────────────────────────────
    Timer {
        id: focusTimer
        interval: 1000
        repeat: true
        onTriggered: {
            if (remainingSeconds > 0) {
                remainingSeconds--
                updateTimeDisplay()
                updateProgress()
            } else {
                // Timer completed
                onTimerComplete()
            }

            // Health reminder countdowns (only during work phase)
            if (!isBreakPhase && isRunning) {
                if (hydrationEnabled && hydrationSeconds > 0) {
                    hydrationSeconds--
                    if (hydrationSeconds <= 0) {
                        hydrationReminder = true
                        hydrationSeconds = hydrationInterval * 60
                        BeeBarState.dispatchNotification(
                            tr("hydration"),
                            tr("hydration_alert"),
                            "💧"
                        )
                        BeeSound.playEvent("notify.info", {})
                    }
                }
                if (postureEnabled && postureSeconds > 0) {
                    postureSeconds--
                    if (postureSeconds <= 0) {
                        postureReminder = true
                        postureSeconds = postureInterval * 60
                        BeeBarState.dispatchNotification(
                            tr("posture"),
                            tr("posture_alert"),
                            "🧍"
                        )
                        BeeSound.playEvent("notify.info", {})
                    }
                }
                if (eyesEnabled && eyesSeconds > 0) {
                    eyesSeconds--
                    if (eyesSeconds <= 0) {
                        eyesReminder = true
                        eyesSeconds = eyesInterval * 60
                        BeeBarState.dispatchNotification(
                            tr("eyes"),
                            tr("eyes_alert"),
                            "👁️"
                        )
                        BeeSound.playEvent("notify.info", {})
                    }
                }
            }
        }
    }

    // ─── Timer completion handler ─────────────────────────────
    function onTimerComplete() {
        focusTimer.stop()
        isRunning = false

        if (isBreakPhase) {
            // Break is over → back to work
            isBreakPhase = false
            currentIcon = modes[currentMode].icon
            modeName = modes[currentMode].name
            totalSeconds = getWorkDuration() * 60
            remainingSeconds = totalSeconds
            BeeSound.playEvent("dash.open", {})
            BeeBarState.dispatchNotification(
                tr("title"),
                tr("work_complete"),
                modes[currentMode].icon
            )
        } else {
            // Work session complete → start break
            sessionsCompleted++
            totalFocusMinutes += getWorkDuration()
            isBreakPhase = true

            // Long break every 4 sessions
            var breakDuration
            if (sessionsCompleted % 4 === 0) {
                breakDuration = getLongBreakDuration()
                modeName = tr("long_break")
                currentIcon = "☕"
            } else {
                breakDuration = getBreakDuration()
                modeName = tr("break_label")
                currentIcon = "☕"
            }
            totalSeconds = breakDuration * 60
            remainingSeconds = totalSeconds

            BeeSound.playEvent("dash.close", {})
            BeeBarState.dispatchNotification(
                tr("title"),
                tr("session_complete"),
                "☕"
            )
        }

        updateProgress()
        updateTimeDisplay()
        saveState()
    }

    // ─── Duration helpers ─────────────────────────────────────
    function getWorkDuration() {
        return currentMode === 3 ? customWork : modes[currentMode].work
    }

    function getBreakDuration() {
        return currentMode === 3 ? customBreak : modes[currentMode].break
    }

    function getLongBreakDuration() {
        return currentMode === 3 ? customLongBreak : modes[currentMode].longBreak
    }

    // ─── Timer controls ───────────────────────────────────────
    function startTimer() {
        if (remainingSeconds <= 0) {
            // Reset and start fresh
            resetTimer()
        }
        isRunning = true
        isPaused = false
        focusTimer.start()
        currentIcon = isBreakPhase ? "☕" : modes[currentMode].icon
        saveState()
    }

    function pauseTimer() {
        isRunning = false
        isPaused = true
        focusTimer.stop()
        saveState()
    }

    function resumeTimer() {
        isRunning = true
        isPaused = false
        focusTimer.start()
        saveState()
    }

    function resetTimer() {
        focusTimer.stop()
        isRunning = false
        isPaused = false
        isBreakPhase = false
        sessionsCompleted = 0
        totalFocusMinutes = 0
        currentMode = 0
        currentIcon = modes[0].icon
        modeName = modes[0].name
        totalSeconds = modes[0].work * 60
        remainingSeconds = totalSeconds
        hydrationSeconds = hydrationInterval * 60
        postureSeconds = postureInterval * 60
        eyesSeconds = eyesInterval * 60
        hydrationReminder = false
        postureReminder = false
        eyesReminder = false
        updateProgress()
        updateTimeDisplay()
        saveState()
    }

    function skipPhase() {
        remainingSeconds = 0
        onTimerComplete()
    }

    function setMode(modeIndex) {
        focusTimer.stop()
        isRunning = false
        isPaused = false
        isBreakPhase = false
        currentMode = modeIndex
        var m = modes[modeIndex]
        currentIcon = m.icon
        modeName = m.name
        totalSeconds = getWorkDuration() * 60
        remainingSeconds = totalSeconds
        updateProgress()
        updateTimeDisplay()
        saveState()
    }

    // ─── Update helpers ───────────────────────────────────────
    function updateTimeDisplay() {
        var mins = Math.floor(remainingSeconds / 60)
        var secs = remainingSeconds % 60
        timeDisplay = (mins < 10 ? "0" : "") + mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    function updateProgress() {
        if (totalSeconds > 0) {
            progress = 1.0 - (remainingSeconds / totalSeconds)
        } else {
            progress = 0.0
        }
    }

    // ─── Persistence ──────────────────────────────────────────
    function saveState() {
        var state = {
            currentMode: currentMode,
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            isRunning: isRunning,
            isPaused: isPaused,
            isBreakPhase: isBreakPhase,
            sessionsCompleted: sessionsCompleted,
            totalFocusMinutes: totalFocusMinutes,
            customWork: customWork,
            customBreak: customBreak,
            customLongBreak: customLongBreak,
            hydrationEnabled: hydrationEnabled,
            postureEnabled: postureEnabled,
            eyesEnabled: eyesEnabled,
            hydrationInterval: hydrationInterval,
            postureInterval: postureInterval,
            eyesInterval: eyesInterval
        }
        BeeConfig.setBeeFocusState(JSON.stringify(state))
    }

    function loadState() {
        var saved = BeeConfig.beeFocusState
        if (!saved || saved === "") return
        try {
            var state = JSON.parse(saved)
            if (state.currentMode !== undefined) currentMode = state.currentMode
            if (state.remainingSeconds !== undefined) remainingSeconds = state.remainingSeconds
            if (state.totalSeconds !== undefined) totalSeconds = state.totalSeconds
            if (state.sessionsCompleted !== undefined) sessionsCompleted = state.sessionsCompleted
            if (state.totalFocusMinutes !== undefined) totalFocusMinutes = state.totalFocusMinutes
            if (state.customWork !== undefined) customWork = state.customWork
            if (state.customBreak !== undefined) customBreak = state.customBreak
            if (state.customLongBreak !== undefined) customLongBreak = state.customLongBreak
            if (state.hydrationEnabled !== undefined) hydrationEnabled = state.hydrationEnabled
            if (state.postureEnabled !== undefined) postureEnabled = state.postureEnabled
            if (state.eyesEnabled !== undefined) eyesEnabled = state.eyesEnabled
            if (state.hydrationInterval !== undefined) hydrationInterval = state.hydrationInterval
            if (state.postureInterval !== undefined) postureInterval = state.postureInterval
            if (state.eyesInterval !== undefined) eyesInterval = state.eyesInterval
            if (state.isBreakPhase !== undefined) isBreakPhase = state.isBreakPhase

            // Restore mode display
            var m = modes[currentMode]
            currentIcon = isBreakPhase ? "☕" : m.icon
            modeName = isBreakPhase ? (sessionsCompleted % 4 === 0 ? tr("long_break") : tr("break_label")) : m.name

            // Don't auto-resume; user must click start
            isRunning = false
            isPaused = state.isPaused || false

            updateProgress()
            updateTimeDisplay()
        } catch (e) {
            console.warn("[BeeFocus] Failed to load state:", e)
        }
    }

    Component.onCompleted: {
        loadState()
        // Register in BeeModuleRegistry
        BeeModuleRegistry.registerMayaDashModule({
            id: "beefocus",
            slot: 7,
            title: tr("title"),
            subtitle: isRunning ? timeDisplay : tr("pomodoro"),
            icon: currentIcon,
            detail: timeDisplay,
            action: "detail:focus",
            highlighted: isRunning,
            order: 7
        })
    }

    // ─── Reactive updates for module registry ─────────────────
    onTimeDisplayChanged: {
        BeeModuleRegistry.registerMayaDashModule({
            id: "beefocus",
            slot: 7,
            title: tr("title"),
            subtitle: isRunning ? timeDisplay : (isBreakPhase ? tr("break_label") : tr("pomodoro")),
            icon: currentIcon,
            detail: timeDisplay,
            action: "detail:focus",
            highlighted: isRunning,
            order: 7
        })
    }

    onCurrentIconChanged: {
        BeeModuleRegistry.registerMayaDashModule({
            id: "beefocus",
            slot: 7,
            title: tr("title"),
            subtitle: isRunning ? timeDisplay : (isBreakPhase ? tr("break_label") : tr("pomodoro")),
            icon: currentIcon,
            detail: timeDisplay,
            action: "detail:focus",
            highlighted: isRunning,
            order: 7
        })
    }

    onIsRunningChanged: {
        BeeModuleRegistry.registerMayaDashModule({
            id: "beefocus",
            slot: 7,
            title: tr("title"),
            subtitle: isRunning ? timeDisplay : (isBreakPhase ? tr("break_label") : tr("pomodoro")),
            icon: currentIcon,
            detail: timeDisplay,
            action: "detail:focus",
            highlighted: isRunning,
            order: 7
        })
    }
}