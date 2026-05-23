pragma Singleton
import QtQuick
import Quickshell.Io

// ═══════════════════════════════════════════════════════════════
// BeePerformance.qml — Startup Benchmark & RAM Tracker 🐝⚡
// v0.8.35: Singleton tracking startup time, RAM usage, and idle state
//
// API:
//   BeePerformance.startupTimeMs   — ms from shell init to BeeBar rendered
//   BeePerformance.ramUsageMb      — current RSS in MB
//   BeePerformance.isIdle          — true if no panel open for >30s
//   BeePerformance.idleSince       — timestamp of last panel close
// ═══════════════════════════════════════════════════════════════

QtObject {
    id: perf

    // ─── Startup Time ──────────────────────────────────────────
    property int startupTimeMs: 0
    property int _shellInitTime: Date.now()

    // ─── RAM Usage ─────────────────────────────────────────────
    property real ramUsageMb: 0.0
    property int _ramCheckInterval: 10000   // 10s idle, 2s active
    property int _lastRamLog: 0             // timestamp of last RAM log

    // ─── Idle State ────────────────────────────────────────────
    property bool isIdle: true
    property int idleSince: 0
    property int _lastActivity: Date.now()

    // ─── Startup Profiling Timestamps ─────────────────────────
    property var _timestamps: ({})

    function markStartup(key) {
        _timestamps[key] = Date.now()
    }

    function getStartupTime(key) {
        return _timestamps[key] || 0
    }

    // ─── Mark shell created ────────────────────────────────────
    Component.onCompleted: {
        _shellInitTime = Date.now()
        _timestamps["perf_init"] = _shellInitTime
        console.log("🐝 BeePerformance: initialized at", _shellInitTime)
    }

    // ─── Called when BeeBar is fully rendered ──────────────────
    function markStartupComplete() {
        var now = Date.now()
        startupTimeMs = now - _shellInitTime
        _timestamps["startup_complete"] = now
        _timestamps["beear_rendered"] = now
        console.log("🐝 Bee-Hive OS started in", startupTimeMs, "ms")
        console.log("🐝 Startup complete. BeeBar rendered in", startupTimeMs, "ms. Lazy modules pending.")

        // Record to profiler script
        _profilerProc.running = false
        _profilerProc.command = [
            "python3",
            Qt.resolvedUrl("../scripts/bee_startup_profiler.py").toString().replace("file://", ""),
            "record",
            "--total", String(startupTimeMs),
            "--notes", "BeePerformance startup_complete"
        ]
        _profilerProc.running = true
    }

    // ─── RAM Monitoring via /proc/self/status ──────────────────
    property Process _ramProc: Process {
        id: _ramProc
        running: true
        command: ["cat", "/proc/self/status"]
        stdout: SplitParser {
            onRead: (line) => {
                if (line.startsWith("VmRSS:")) {
                    var parts = line.trim().split(/\s+/)
                    var kb = parseInt(parts[1]) || 0
                    perf.ramUsageMb = Math.round(kb / 1024 * 10) / 10  // Round to 0.1 MB
                }
            }
        }
    }

    // RAM check timer — every 10s when idle, every 2s when panel is open
    property Timer _ramTimer: Timer {
        interval: perf._ramCheckInterval
        running: true
        repeat: true
        onTriggered: {
            _ramProc.running = false
            _ramProc.running = true
        }
    }

    // ─── Activity tracking ────────────────────────────────────
    // Called by BeeHiveShell when a panel is opened/closed
    function reportActivity() {
        _lastActivity = Date.now()
        isIdle = false
        _idleTimer.restart()
    }

    function reportIdle() {
        _lastActivity = Date.now()
        // Don't immediately mark idle — start countdown
    }

    // After 30s of no activity, mark as idle
    property Timer _idleTimer: Timer {
        interval: 30000
        running: true
        repeat: false
        onTriggered: {
            isIdle = true
            idleSince = Date.now()
            // Switch to slower RAM polling when idle
            perf._ramCheckInterval = 10000
        }
    }

    // ─── Dynamic RAM polling interval ──────────────────────────
    // When a panel opens, check RAM more frequently
    function onPanelOpened() {
        reportActivity()
        perf._ramCheckInterval = 2000
        _ramTimer.interval = 2000
    }

    function onPanelClosed() {
        // Reset timer for idle detection
        _idleTimer.restart()
    }

    // ─── Startup profiler process ─────────────────────────────
    property Process _profilerProc: Process {
        id: _profilerProc
        running: false
        command: ["echo", ""]
        stdout: SplitParser { onRead: (line) => {} }
    }

    // ─── Log RAM before first panel open ──────────────────────
    property bool _firstPanelLogged: false

    function logRamBeforePanel() {
        if (!_firstPanelLogged) {
            _firstPanelLogged = true
            console.log("🐝 RAM before first panel open:", ramUsageMb, "MB")
        }
    }

    function logRamAfterPanel(panelName) {
        console.log("🐝 Lazy-loaded:", panelName, "— RAM now:", ramUsageMb, "MB")
    }
}