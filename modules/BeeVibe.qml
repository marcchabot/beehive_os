import QtQuick
import Quickshell.Io

// ═══════════════════════════════════════════════════════════════
// BeeVibe.qml — Moteur de visualisation audio 🐝🎵
// v2.1 : cava-bg integration — Native Wayland audio visualizer
//   - Respects BeeConfig.vibeBackend choice ("auto" | "cava-bg" | "cava")
//   - Detects and launches cava-bg as a Wayland overlay layer
//   - Falls back to cava raw ASCII if cava-bg is unavailable
//   - Simulation fallback if neither is available
//   - Dynamic colors extracted from wallpaper via cava-bg config
//   - Hyprland layerrule for proper overlay positioning
//   - X-Ray hot-reload when settings change
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

    // cava-bg config path (auto-generated)
    property string _cavaBgConfigPath: ""

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
    // v2.1: Respects BeeConfig.vibeBackend ("auto" | "cava-bg" | "cava")
    // "auto" = detect best available, "cava-bg" = force cava-bg, "cava" = force cava
    function _startBackend() {
        if (!active) {
            backend = "inactive"
            return
        }

        var choice = BeeConfig.vibeBackend || "auto"
        console.log("[BeeVibe] Backend choice: " + choice + " (cava-bg=" + _cavaBgAvailable + " cava=" + _cavaAvailable + ")")

        if (choice === "cava-bg") {
            // User explicitly wants cava-bg
            if (_cavaBgAvailable) {
                _startCavaBg()
            } else {
                console.warn("[BeeVibe] cava-bg requested but not found, trying detection anyway...")
                // Try anyway — might be installed but not in sandbox PATH
                _cavaBgAvailable = true  // Optimistic: let _startCavaBg try
                _startCavaBg()
            }
        } else if (choice === "cava") {
            // User explicitly wants cava
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
                // Fallback to simulation
                backend = "simulation"
                console.log("[BeeVibe] Neither cava-bg nor cava found, using simulation")
            }
        }
    }

    // ─── Backend change handler ─────────────────────────────────
    // When user changes backend in settings, restart with new choice
    Connections {
        target: BeeConfig
        function onVibeBackendChanged() {
            if (beeVibe.active) {
                console.log("[BeeVibe] Backend preference changed to: " + BeeConfig.vibeBackend + ", restarting...")
                // Stop current backend
                _stopAll()
                // Restart with new choice
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

        if (backend === "cava-bg") {
            _stopCavaBg()
        }

        _cavaLive = false
        barValues = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    }

    // ═══════════════════════════════════════════════════════════
    // CAVA-BG MODE — Native Wayland overlay
    // cava-bg runs as a daemon (background process).
    // "cava-bg on" forks and exits immediately — we cannot
    // track it via a Process. Instead we monitor the PID file.
    // ═══════════════════════════════════════════════════════════

    // Fire-and-forget launcher — just starts the daemon, ignores exit
    Process {
        id: _cavaBgLauncher
        running: false
        command: ["bash", "-c", "cava-bg on 2>&1"]
        stdout: SplitParser {
            onRead: (line) => { console.log("[BeeVibe] cava-bg launch:", line) }
        }
        stderr: SplitParser {
            onRead: (line) => { console.warn("[BeeVibe] cava-bg launch stderr:", line) }
        }
        onExited: (code, status) => {
            // "cava-bg on" exits immediately after forking — this is normal.
            // Start monitoring the daemon via PID file instead.
            if (active && backend === "cava-bg") {
                console.log("[BeeVibe] cava-bg launcher exited (code:" + code + "), starting daemon monitor...")
                _daemonMonitor.running = true
            }
        }
    }

    // Daemon monitor — checks PID file periodically
    Process {
        id: _daemonMonitor
        running: false
        command: ["bash", "-c",
            "pidfile=\"$HOME/.config/cava-bg/daemon.pid\"; " +
            "if [ -f \"$pidfile\" ]; then " +
            "  pid=$(cat \"$pidfile\"); " +
            "  if kill -0 \"$pid\" 2>/dev/null; then echo 'ALIVE'; else echo 'DEAD'; fi; " +
            "else echo 'NO_PID_FILE'; fi"
        ]
        stdout: SplitParser {
            onRead: (line) => {
                var status = line.trim()
                if (status === "ALIVE") {
                    _cavaBgDaemonRunning = true
                } else {
                    _cavaBgDaemonRunning = false
                    if (active && backend === "cava-bg") {
                        console.log("[BeeVibe] cava-bg daemon not running (" + status + "), restarting in 5s...")
                        _restartTimer.start()
                    }
                }
            }
        }
        onExited: (code, status) => {
            // Reschedule monitor check
            if (active && backend === "cava-bg" && _cavaBgDaemonRunning) {
                _monitorTimer.start()
            }
        }
    }

    property bool _cavaBgDaemonRunning: false

    Timer {
        id: _monitorTimer
        interval: 5000
        repeat: false
        onTriggered: {
            if (active && backend === "cava-bg") {
                _daemonMonitor.running = true
            }
        }
    }

    Timer {
        id: _restartTimer
        interval: 5000
        onTriggered: {
            if (active && backend === "cava-bg") {
                console.log("[BeeVibe] Restarting cava-bg daemon...")
                _cavaBgLauncher.running = true
            }
        }
    }

    function _startCavaBg() {
        backend = "cava-bg"

        // Write config and launch daemon
        _writeCavaBgConfig()

        // Add Hyprland layerrule for cava-bg
        _hyprRuleProc.command = ["bash", "-c",
            "hyprctl layerrule 2>/dev/null | grep -q 'cava-bg' && echo 'rule exists' || hyprctl layerrule add noanim cava-bg 2>/dev/null; echo 'done'"
        ]
        _hyprRuleProc.running = true

        // Start cava-bg daemon (fire-and-forget)
        _cavaBgLauncher.running = true

        // Start the bar value reader (for MayaDash equalizer display)
        _cavaReader.running = true

        console.log("[BeeVibe] cava-bg started with dynamic_colors=true, xray=" + BeeConfig.vibeXray)
    }

    // ─── Write cava-bg config (hot-reload friendly) ────────────
    // v2.1: Merges Bee-Hive settings into existing cava-bg config
    // instead of overwriting it completely. This preserves any
    // manual tweaks the user made via cava-bg gui or config file.
    // cava-bg watches its config file and applies changes automatically.
    function _writeCavaBgConfig() {
        // X-Ray settings from BeeConfig
        var enableXray = BeeConfig.vibeXray
        var xrayDir = BeeConfig.vibeXrayDir
        var xrayIntensity = BeeConfig.vibeXrayIntensity
        var xrayBlend = BeeConfig.vibeXrayBlend

        // Build the X-Ray section
        var xraySection = ""
        if (enableXray) {
            xraySection = "[xray]\n"
                + (xrayDir ? "images_dir = \"" + xrayDir + "\"\n" : "# images_dir = auto-detected from wallpaper\n")
                + "\n"
                + "[xray_mask]\n"
                + "intensity = " + xrayIntensity.toFixed(2) + "\n"
                + "gamma = 1.2\n"
                + "opacity = 1.0\n"
                + "blend_mode = \"" + xrayBlend + "\"\n"
                + "use_background = false\n\n"
        } else {
            // Explicitly disable xray when toggled off
            xraySection = "# [xray] — disabled by BeeVibe\n"
                + "# images_dir = \"\"\n\n"
        }

        // Build the full Bee-Hive managed config
        // We write our own config because cava-bg needs specific settings
        // for the Bee-Hive integration to work properly.
        var configContent = "# ═══════════════════════════════════════════════════════════\n"
            + "# Bee-Hive OS × cava-bg — Auto-managed config\n"
            + "# Changes to X-Ray, blend, and intensity are hot-reloaded.\n"
            + "# ═══════════════════════════════════════════════════════════\n\n"
            + "[general]\n"
            + "framerate = 60\n"
            + "dynamic_colors = true\n"
            + "corner_radius = 0.0\n"
            + "disable_audio = false\n\n"
            + "[general.background_color]\n"
            + "hex = \"#000000\"\n"
            + "alpha = 0.0\n\n"
            + "[display]\n"
            + "position = \"Fill\"\n"
            + "anchor_top = true\n"
            + "anchor_bottom = true\n"
            + "anchor_left = true\n"
            + "anchor_right = true\n"
            + "width = 0\n"
            + "height = 0\n"
            + "margin_top = 0\n"
            + "margin_bottom = 0\n"
            + "margin_left = 0\n"
            + "margin_right = 0\n"
            + "layer = \"Bottom\"\n"
            + "opacity = 1.0\n"
            + "scale_with_resolution = false\n\n"
            + "[audio]\n"
            + "bar_count = 76\n"
            + "bar_width = 6.0\n"
            + "bar_spacing = 2.0\n"
            + "gap = 0.1\n"
            + "bar_alpha = 0.85\n"
            + "height_scale = 1.0\n"
            + "smoothing = 0.8\n"
            + "max_bar_height = 220.0\n"
            + "min_bar_height = 0.0\n"
            + "bar_shape = \"Rectangle\"\n\n"
            + "[audio.bar_color]\n"
            + "hex = \"#F5A623\"\n"
            + "alpha = 1.0\n\n"
            + "[colors]\n"
            + "use_gradient = true\n"
            + "gradient_direction = \"BottomToTop\"\n"
            + "palette = [[0.98, 0.72, 0.11, 1.0], [0.83, 0.59, 0.04, 1.0]]\n\n"
            + xraySection
            + "[wallpaper]\n"
            + "auto_detect_wallpaper = true\n"
            + "sync_interval_seconds = 10\n\n"
            + "[parallax]\n"
            + "enabled = false\n"
            + "mode = \"Hybrid\"\n"
            + "enable_3d_depth = false\n"
            + "layers = []\n\n"
            + "[performance]\n"
            + "vsync = true\n"
            + "multi_threaded_decode = true\n"
            + "frame_rate_limit = 60\n"
            + "layer_cache_size = 5\n\n"
            + "[advanced]\n"
            + "verbose_logging = false\n"

        console.log("[BeeVibe] Writing cava-bg config: xray=" + enableXray + " blend=" + xrayBlend + " intensity=" + xrayIntensity)

        // Write config file — cava-bg hot-reloads when it changes
        _writeConfigProc.command = ["bash", "-c",
            "mkdir -p ~/.config/cava-bg && cat > ~/.config/cava-bg/config.toml << 'BEEVIBE_EOF'\n"
            + configContent
            + "BEEVIBE_EOF\n"
            + "echo 'CONFIG_WRITTEN'"
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
        // Stop cava-bg daemon
        _stopCavaBgProc.command = ["bash", "-c", "cava-bg off 2>/dev/null; cava-bg kill 2>/dev/null; echo 'stopped'"]
        _stopCavaBgProc.running = true
        // Remove Hyprland layerrule
        _hyprRuleRemoveProc.running = true
    }

    Process { id: _writeConfigProc; running: false; stdout: SplitParser { onRead: (line) => { if (line.trim() === "CONFIG_WRITTEN") console.log("[BeeVibe] config.toml written ✓") } } stderr: SplitParser {} }
    Process { id: _hyprRuleProc; running: false; stdout: SplitParser { onRead: (line) => console.log("[BeeVibe] layerrule:", line) } stderr: SplitParser {} }
    Process { id: _stopCavaBgProc; running: false; stdout: SplitParser {} stderr: SplitParser {} }
    Process { id: _hyprRuleRemoveProc; running: false; command: ["bash", "-c", "hyprctl layerrule remove cava-bg 2>/dev/null; echo 'removed'"]; stdout: SplitParser { onRead: (line) => {} } stderr: SplitParser {} }

    // ─── Bar value reader for MayaDash (uses cava for equalizer data) ──
    // Even in cava-bg mode, we run a lightweight cava instance
    // to get 8-bar data for the hex cell equalizers
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
                // Restart reader if still active
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
            // Start detection sequence
            _detectCavaBg.running = true
        } else {
            // Stop everything
            _stopAll()
            backend = "inactive"
        }
    }

    // ─── X-Ray settings change handler ───────────────────────────
    // When X-Ray settings change, rewrite the config file.
    // cava-bg has hot-reload: it watches config.toml and applies
    // changes automatically without restarting.
    // v2.1: Always write config on change (even if not yet active),
    // so settings are ready when cava-bg starts.
    Connections {
        target: BeeConfig
        function onVibeXrayChanged() {
            console.log("[BeeVibe] X-Ray changed → " + (beeVibe.backend === "cava-bg" ? "rewriting config (hot-reload)" : "queued for next start"))
            if (beeVibe.backend === "cava-bg") {
                beeVibe._writeCavaBgConfig()
            }
        }
        function onVibeXrayIntensityChanged() {
            console.log("[BeeVibe] X-Ray intensity changed → " + (beeVibe.backend === "cava-bg" ? "rewriting config (hot-reload)" : "queued"))
            if (beeVibe.backend === "cava-bg") {
                beeVibe._writeCavaBgConfig()
            }
        }
        function onVibeXrayBlendChanged() {
            console.log("[BeeVibe] X-Ray blend changed")
            if (beeVibe.backend === "cava-bg") {
                beeVibe._writeCavaBgConfig()
            }
        }
        function onVibeXrayDirChanged() {
            console.log("[BeeVibe] X-Ray dir changed → " + (beeVibe.backend === "cava-bg" ? "rewriting config (hot-reload)" : "queued"))
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