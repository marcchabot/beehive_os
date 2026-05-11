import QtQuick
import Quickshell.Io

// ═══════════════════════════════════════════════════════════════
// BeeVibe.qml — Moteur de visualisation audio 🐝🎵
// v2.2 : cava-bg integration — Native Wayland audio visualizer
//   - Respects BeeConfig.vibeBackend choice ("auto" | "cava-bg" | "cava")
//   - Uses Python merge script to patch cava-bg config (preserves all fields)
//   - X-Ray hot-reload when settings change
//   - cava-bg daemon management with PID monitoring
// ═══════════════════════════════════════════════════════════════

Item {
    id: beeVibe
    visible: false   // pure data component, no visual rendering

    // ─── API publique ───────────────────────────────────────────
    property bool active: false
    // 8 normalized values 0.0–1.0, one per cell (for MayaDash equalizer)
    property var barValues: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

    // ─── cava-bg integration state ──────────────────────────────
    // "cava-bg" | "cava" | "simulation" | "inactive"
    property string backend: "inactive"

    // ─── État interne ───────────────────────────────────────────
    property bool _cavaLive: false
    property bool _cavaBgAvailable: false
    property bool _cavaAvailable: false

    // ─── Detection Process ───────────────────────────────────────
    Process {
        id: _detectCavaBg
        running: false
        command: ["bash", "-c", "which cava-bg 2>/dev/null && echo 'CAVA_BG_OK' || echo 'CAVA_BG_MISSING'"]
        stdout: SplitParser {
            onRead: (line) => {
                if (line.trim() === "CAVA_BG_OK") {
                    beeVibe._cavaBgAvailable = true
                    console.log("[BeeVibe] cava-bg detected ✓")
                }
            }
        }
        onExited: (code, status) => {
            // Now check for plain cava
            _detectCava.running = true
        }
    }

    Process {
        id: _detectCava
        running: false
        command: ["bash", "-c", "which cava 2>/dev/null && echo 'CAVA_OK' || echo 'CAVA_MISSING'"]
        stdout: SplitParser {
            onRead: (line) => {
                if (line.trim() === "CAVA_OK") {
                    beeVibe._cavaAvailable = true
                    console.log("[BeeVibe] cava detected ✓")
                }
            }
        }
        onExited: (code, status) => {
            // Detection complete, start appropriate backend
            _startBackend()
        }
    }

    // ─── Start appropriate backend ──────────────────────────────
    // v2.2: Respects BeeConfig.vibeBackend ("auto" | "cava-bg" | "cava")
    function _startBackend() {
        if (!active) {
            backend = "inactive"
            return
        }

        var choice = BeeConfig.vibeBackend || "auto"
        console.log("[BeeVibe] Backend choice: " + choice + " (cava-bg=" + _cavaBgAvailable + " cava=" + _cavaAvailable + ")")

        if (choice === "cava-bg") {
            if (_cavaBgAvailable) {
                _startCavaBg()
            } else {
                console.warn("[BeeVibe] cava-bg requested but not detected, trying anyway...")
                _cavaBgAvailable = true
                _startCavaBg()
            }
        } else if (choice === "cava") {
            if (_cavaAvailable) {
                backend = "cava"
                console.log("[BeeVibe] Using cava (raw ASCII) backend (forced)")
            } else {
                console.warn("[BeeVibe] cava requested but not found, trying anyway...")
                backend = "cava"
            }
        } else {
            // "auto" — detect best available
            if (_cavaBgAvailable) {
                _startCavaBg()
            } else if (_cavaAvailable) {
                backend = "cava"
                console.log("[BeeVibe] Using cava (raw ASCII) backend")
            } else {
                backend = "simulation"
                console.log("[BeeVibe] Neither cava-bg nor cava found, using simulation")
            }
        }
    }

    // ─── Backend change handler ─────────────────────────────────
    Connections {
        target: BeeConfig
        function onVibeBackendChanged() {
            if (beeVibe.active) {
                console.log("[BeeVibe] Backend preference changed to: " + BeeConfig.vibeBackend + ", restarting...")
                _stopAll()
                _startBackend()
            }
        }
    }

    function _stopAll() {
        _cavaProc.running = false
        _cavaBgLauncher.running = false
        _daemonMonitor.running = false
        _cavaReader.running = false
        _monitorTimer.stop()
        _restartTimer.stop()
        _cavaReaderRestart.stop()
        _cavaBgDaemonRunning = false
        _cavaBgRestartAttempts = 0
        _cavaBgNeedConfigWrite = false

        if (backend === "cava-bg") {
            _stopCavaBg()
        }

        _cavaLive = false
        barValues = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    }

    // ═══════════════════════════════════════════════════════════
    // CAVA-BG MODE — Native Wayland overlay
    // ═══════════════════════════════════════════════════════════

    Process {
        id: _cavaBgLauncher
        running: false
        command: ["bash", "-c", "cava-bg off 2>/dev/null; cava-bg kill 2>/dev/null; sleep 0.5; cava-bg on 2>&1"]
        stdout: SplitParser {
            onRead: (line) => { console.log("[BeeVibe] cava-bg launch:", line) }
        }
        stderr: SplitParser {
            onRead: (line) => { console.warn("[BeeVibe] cava-bg launch stderr:", line) }
        }
        onExited: (code, status) => {
            if (active && backend === "cava-bg") {
                console.log("[BeeVibe] cava-bg launcher exited (code:" + code + "), waiting 2s before first daemon check...")
                _firstMonitorTimer.start()
            }
        }
    }

    // Delay before first daemon check — gives cava-bg time to write PID and start
    Timer { id: _firstMonitorTimer; interval: 2000; repeat: false
        onTriggered: { if (active && backend === "cava-bg") _daemonMonitor.running = true }
    }

    // Daemon monitor — checks PID file periodically, captures error log on failure
    // Also detects persistent Wayland surface errors (Timeout) to break the cycle early
    Process {
        id: _daemonMonitor
        running: false
        command: ["bash", "-c",
            "pidfile=\"$HOME/.config/cava-bg/daemon.pid\"; " +
            "logfile=\"$HOME/.config/cava-bg/daemon.log\"; " +
            "# Check by PID file first\n" +
            "if [ -f \"$pidfile\" ]; then " +
            "  pid=$(cat \"$pidfile\"); " +
            "  if kill -0 \"$pid\" 2>/dev/null; then " +
            "    # Daemon alive — check for surface errors in recent log\n" +
            "    surface_errors=$(tail -30 \"$logfile\" 2>/dev/null | grep -c 'Surface error: Timeout' || true); " +
            "    if [ \"$surface_errors\" -ge 5 ]; then " +
            "      echo 'SURFACE_ERRORS'; " +
            "    else echo 'ALIVE'; fi; " +
            "  else echo 'DEAD'; tail -20 \"$logfile\" 2>/dev/null | sed 's/^/DAEMON_LOG: /'; fi; " +
            "# Fallback: check if any cava-bg process is running\n" +
            "elif pgrep -x cava-bg >/dev/null 2>&1; then " +
            "  echo 'ALIVE_NO_PIDFILE'; " +
            "else echo 'NO_PID_FILE'; fi"
        ]
        stdout: SplitParser {
            onRead: (line) => {
                var trimmed = line.trim()
                if (trimmed === "ALIVE" || trimmed === "ALIVE_NO_PIDFILE") {
                    _cavaBgDaemonRunning = true
                    _cavaBgRestartAttempts = 0  // Reset on success
                    if (trimmed === "ALIVE_NO_PIDFILE") {
                        console.log("[BeeVibe] cava-bg daemon alive (no PID file, process found via pgrep)")
                    }
                    // First time daemon is alive after start — write config and SIGHUP
                    if (_cavaBgNeedConfigWrite) {
                        _cavaBgNeedConfigWrite = false
                        _onDaemonAlive()
                    }
                } else if (trimmed === "SURFACE_ERRORS") {
                    // Daemon alive but has surface timeout errors — this is TRANSIENT (wgpu::SurfaceError::Timeout)
                    // cava-bg handles these internally with continue/retry, NOT a reason to restart.
                    _cavaBgDaemonRunning = true
                    _cavaBgRestartAttempts = 0
                    console.warn("[BeeVibe] cava-bg daemon alive but has Wayland surface timeout errors — monitoring (transient, not restarting)")
                    if (_cavaBgNeedConfigWrite) {
                        _cavaBgNeedConfigWrite = false
                        _onDaemonAlive()
                    }
                } else if (trimmed.startsWith("DAEMON_LOG: ")) {
                    console.warn("[BeeVibe] cava-bg log: " + trimmed.substring(12))
                } else if (trimmed === "DEAD" || trimmed === "NO_PID_FILE") {
                    _cavaBgDaemonRunning = false
                    if (active && backend === "cava-bg") {
                        console.log("[BeeVibe] cava-bg daemon not running (" + trimmed + "), restarting in 5s...")
                        _restartTimer.start()
                    }
                } else {
                    // Other output from tail, skip
                }
            }
        }
        onExited: (code, status) => {
            if (active && backend === "cava-bg" && _cavaBgDaemonRunning) {
                _monitorTimer.start()
            }
        }
    }

    property bool _cavaBgDaemonRunning: false
    property int _cavaBgRestartAttempts: 0
    readonly property int _cavaBgMaxRestarts: 3
    property bool _cavaBgNeedConfigWrite: false  // Set true on start, triggers config write when daemon goes ALIVE

    Timer { id: _monitorTimer; interval: 5000; repeat: false
        onTriggered: { if (active && backend === "cava-bg") _daemonMonitor.running = true }
    }
    Timer { id: _restartTimer; interval: 5000
        onTriggered: {
            if (active && backend === "cava-bg") {
                if (_cavaBgRestartAttempts < _cavaBgMaxRestarts) {
                    _cavaBgRestartAttempts++
                    console.log("[BeeVibe] Restarting cava-bg daemon (attempt " + _cavaBgRestartAttempts + "/" + _cavaBgMaxRestarts + ")...")
                    _cavaBgLauncher.running = true
                } else {
                    console.warn("[BeeVibe] cava-bg daemon failed " + _cavaBgMaxRestarts + " times, falling back to simulation mode")
                    _stopCavaBg()
                    backend = "simulation"
                    _cavaLive = false
                }
            }
        }
    }

    function _startCavaBg() {
        backend = "cava-bg"
        _cavaBgRestartAttempts = 0  // Reset on fresh start
        _cavaBgNeedConfigWrite = true  // Will write config once daemon is confirmed alive

        // Add Hyprland layerrule for cava-bg
        _hyprRuleProc.command = ["bash", "-c",
            "hyprctl layerrule 2>/dev/null | grep -q 'cava-bg' && echo 'rule exists' || hyprctl layerrule add noanim cava-bg 2>/dev/null; echo 'done'"
        ]
        _hyprRuleProc.running = true

        // Start cava-bg daemon FIRST (clean kill + launch)
        _cavaBgLauncher.running = true

        // Start the bar value reader (for MayaDash equalizer display)
        _cavaReader.running = true

        console.log("[BeeVibe] cava-bg starting with xray=" + BeeConfig.vibeXray)
    }

    // ─── Write config AFTER daemon is alive ───────────────────────
    // Called by _firstMonitorTimer when daemon status is confirmed ALIVE.
    // This avoids the race where SIGHUP is sent before the daemon exists.
    function _onDaemonAlive() {
        console.log("[BeeVibe] cava-bg daemon alive, writing config...")
        _writeCavaBgConfig(true)  // skipSIGHUP = true: daemon just started with current config
    }

    // ─── Write cava-bg config via Python merge script ────────────
    // v2.2: Uses scripts/cava-bg-merge.py to patch the existing
    // cava-bg config.toml instead of overwriting it completely.
    // This preserves ALL cava-bg fields (parallax, idle_mode, etc.)
    // that cava-bg requires and would otherwise reject.
    function _writeCavaBgConfig(skipSIGHUP) {
        var enableXray = BeeConfig.vibeXray
        var xrayIntensity = BeeConfig.vibeXrayIntensity
        var xrayBlend = BeeConfig.vibeXrayBlend
        var dynamicColors = enableXray ? "false" : "true"

        _cavaBgSkipSIGHUP = (skipSIGHUP === true)

        console.log("[BeeVibe] Merging cava-bg config: xray=" + enableXray + " blend=" + xrayBlend + " intensity=" + xrayIntensity)

        // Resolve script path relative to BeeVibe.qml (modules/../scripts/cava-bg-merge.py)
        var scriptPath = Qt.resolvedUrl("../scripts/cava-bg-merge.py").toString().replace("file://", "")

        // Call Python merge script — preserves existing cava-bg config fields
        _writeConfigProc.command = ["bash", "-c",
            "python3 '" + scriptPath + "' " +
            (enableXray ? "--xray" : "--no-xray") +
            " --intensity " + xrayIntensity.toFixed(4) +
            " --blend '" + xrayBlend + "'" +
            " --dynamic-colors " + dynamicColors +
            " 2>&1"
        ]
        _writeConfigProc.running = true
    }

    function _stopCavaBg() {
        _cavaBgLauncher.running = false
        _daemonMonitor.running = false
        _monitorTimer.stop()
        _restartTimer.stop()
        _cavaBgDaemonRunning = false
        _cavaReader.running = false
        // Stop cava-bg daemon — use both off/kill and pkill for robustness
        _stopCavaBgProc.command = ["bash", "-c", "cava-bg off 2>/dev/null; cava-bg kill 2>/dev/null; pkill -f 'cava-bg' 2>/dev/null; sleep 0.3; echo 'stopped'"]
        _stopCavaBgProc.running = true
        // Remove Hyprland layerrule
        _hyprRuleRemoveProc.running = true
    }

    property bool _cavaBgSkipSIGHUP: false

    Process { id: _writeConfigProc; running: false; stdout: SplitParser { onRead: (line) => {
        if (line.trim() === "CONFIG_WRITTEN") {
            console.log("[BeeVibe] config.toml merged ✓")
            if (!_cavaBgSkipSIGHUP) {
                // Signal cava-bg daemon to reload config (SIGHUP)
                _cavaBgReload.running = true
            } else {
                console.log("[BeeVibe] SIGHUP skipped (daemon just started with fresh config)")
            }
        } else if (line.trim() === "CONFIG_PATCHED_SED") {
            console.log("[BeeVibe] config.toml patched (sed fallback) ✓")
            if (!_cavaBgSkipSIGHUP) {
                _cavaBgReload.running = true
            }
        } else {
            console.log("[BeeVibe] merge:", line)
        }
    } } stderr: SplitParser { onRead: (line) => console.warn("[BeeVibe] merge error:", line) } }

    // ─── Reload cava-bg after config change ───────────────────
    // Sends SIGHUP to the daemon (PID from pidfile) to hot-reload config.
    // Falls back to full restart if SIGHUP is not supported.
    Process {
        id: _cavaBgReload
        running: false
        command: ["bash", "-c",
            "pidfile=\"$HOME/.config/cava-bg/daemon.pid\"; " +
            "if [ -f \"$pidfile\" ]; then " +
            "  pid=$(cat \"$pidfile\"); " +
            "  if kill -0 \"$pid\" 2>/dev/null; then " +
            "    kill -HUP \"$pid\" 2>/dev/null && echo 'SIGHUP_SENT' || echo 'SIGHUP_FAILED'; " +
            "  else echo 'DAEMON_DEAD'; fi; " +
            "else echo 'NO_PID_FILE'; fi"
        ]
        stdout: SplitParser {
            onRead: (line) => {
                var status = line.trim()
                if (status === "SIGHUP_SENT") {
                    console.log("[BeeVibe] cava-bg hot-reload (SIGHUP) ✓")
                } else if (status === "SIGHUP_FAILED") {
                    console.warn("[BeeVibe] SIGHUP failed, restarting cava-bg daemon...")
                    // Fallback: restart cava-bg daemon entirely
                    _stopCavaBg()
                    _restartTimer.interval = 1000
                    _restartTimer.start()
                } else if (status === "DAEMON_DEAD" || status === "NO_PID_FILE") {
                    console.warn("[BeeVibe] cava-bg daemon not running, restarting...")
                    _restartTimer.start()
                } else {
                    console.log("[BeeVibe] cava-bg reload:", status)
                }
            }
        }
    }
    Process { id: _hyprRuleProc; running: false; stdout: SplitParser { onRead: (line) => console.log("[BeeVibe] layerrule:", line) } stderr: SplitParser {} }
    Process { id: _stopCavaBgProc; running: false; stdout: SplitParser {} stderr: SplitParser {} }
    Process { id: _hyprRuleRemoveProc; running: false; command: ["bash", "-c", "hyprctl layerrule remove cava-bg 2>/dev/null; echo 'removed'"]; stdout: SplitParser { onRead: (line) => {} } stderr: SplitParser {} }

    // ─── Bar value reader for MayaDash (uses cava for equalizer data) ──
    Process {
        id: _cavaReader
        running: false
        command: [
            "bash", "-c",
            "tmp=$(mktemp /tmp/.beevibe_XXXXXX.conf); " +
            "printf '[general]\\nbars = 8\\nframerate = 20\\n\\n" +
            "[output]\\nmethod = raw\\nraw_target = /dev/stdout\\n" +
            "data_format = ascii\\nascii_max_range = 100\\n" +
            "bar_delimiter = 32\\nframe_delimiter = 10\\n' > \"$tmp\"; " +
            "exec cava -p \"$tmp\""
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                var parts = line.trim().split(" ")
                if (parts.length < 8) return
                var vals = []
                for (var i = 0; i < 8; i++) {
                    var v = parseInt(parts[i])
                    vals.push(isNaN(v) ? 0.0 : Math.max(0.0, Math.min(1.0, v / 100.0)))
                }
                beeVibe.barValues = vals
                beeVibe._cavaLive = true
            }
        }

        onExited: (code, status) => {
            beeVibe._cavaLive = false
            if (active && backend === "cava-bg") {
                _cavaReaderRestart.start()
            }
        }
    }

    Timer {
        id: _cavaReaderRestart
        interval: 2000
        onTriggered: {
            if (active && backend === "cava-bg") {
                _cavaReader.running = true
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // CAVA-ONLY MODE — Legacy raw ASCII fallback
    // ═══════════════════════════════════════════════════════════
    property Process cavaProc: Process {
        id: _cavaProc
        running: beeVibe.active && beeVibe.backend === "cava"

        command: [
            "bash", "-c",
            "tmp=$(mktemp /tmp/.beevibe_XXXXXX.conf); " +
            "printf '[general]\\nbars = 8\\nframerate = 20\\n\\n" +
            "[output]\\nmethod = raw\\nraw_target = /dev/stdout\\n" +
            "data_format = ascii\\nascii_max_range = 100\\n" +
            "bar_delimiter = 32\\nframe_delimiter = 10\\n' > \"$tmp\"; " +
            "exec cava -p \"$tmp\""
        ]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                var parts = line.trim().split(" ")
                if (parts.length < 8) return
                var vals = []
                for (var i = 0; i < 8; i++) {
                    var v = parseInt(parts[i])
                    vals.push(isNaN(v) ? 0.0 : Math.max(0.0, Math.min(1.0, v / 100.0)))
                }
                beeVibe.barValues = vals
                if (!beeVibe._cavaLive) beeVibe._cavaLive = true
            }
        }

        onExited: (code, status) => {
            beeVibe._cavaLive = false
            beeVibe.barValues = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        }
    }

    // ═══════════════════════════════════════════════════════════
    // SIMULATION — repli si Cava est absent ou inactif
    // ═══════════════════════════════════════════════════════════
    property real _simPhase: 0.0

    Timer {
        interval: 80
        repeat: true
        running: beeVibe.active && beeVibe.backend === "simulation"

        onTriggered: {
            beeVibe._simPhase += 0.14
            var ph = beeVibe._simPhase
            var vals = []
            for (var i = 0; i < 8; i++) {
                var v = 0.08 + 0.42 * Math.abs(Math.sin(ph + i * 0.85))
                                    * Math.abs(Math.cos(ph * 0.38 + i * 0.6))
                vals.push(Math.max(0.0, Math.min(1.0, v)))
            }
            beeVibe.barValues = vals
        }
    }

    // ─── Lifecycle ─────────────────────────────────────────────
    onActiveChanged: {
        if (active) {
            _detectCavaBg.running = true
        } else {
            _stopAll()
            backend = "inactive"
        }
    }

    // ─── X-Ray settings change handler ───────────────────────────
    Connections {
        target: BeeConfig
        function onVibeXrayChanged() {
            console.log("[BeeVibe] X-Ray changed → " + (beeVibe.backend === "cava-bg" ? "merging config (hot-reload)" : "queued"))
            if (beeVibe.backend === "cava-bg") {
                beeVibe._writeCavaBgConfig()
            }
        }
        function onVibeXrayIntensityChanged() {
            console.log("[BeeVibe] X-Ray intensity changed → " + (beeVibe.backend === "cava-bg" ? "merging config" : "queued"))
            if (beeVibe.backend === "cava-bg") {
                beeVibe._writeCavaBgConfig()
            }
        }
        function onVibeXrayBlendChanged() {
            console.log("[BeeVibe] X-Ray blend changed → " + (beeVibe.backend === "cava-bg" ? "merging config" : "queued"))
            if (beeVibe.backend === "cava-bg") {
                beeVibe._writeCavaBgConfig()
            }
        }
        function onVibeXrayDirChanged() {
            console.log("[BeeVibe] X-Ray dir changed → " + (beeVibe.backend === "cava-bg" ? "merging config" : "queued"))
            if (beeVibe.backend === "cava-bg") {
                beeVibe._writeCavaBgConfig()
            }
        }
    }

    // ─── Toggle cava-bg on/off ──────────────────────────────────
    function toggleCavaBg() {
        if (backend === "cava-bg" && active) {
            _stopCavaBg()
            backend = "simulation"
            _cavaLive = false
            console.log("[BeeVibe] cava-bg stopped, switching to simulation")
        } else if (_cavaBgAvailable && active) {
            _startCavaBg()
            console.log("[BeeVibe] Switching to cava-bg")
        }
    }
}