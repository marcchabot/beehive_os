import QtQuick
import Quickshell.Io

// ═══════════════════════════════════════════════════════════════
// BeeMonitor.qml — System Monitor Avancé 🐝🖥️
// v1.1: Added RAM tracker (process VmRSS) with historical graph
//       and visual alert when idle > 200MB
// v1.0: Real-time system metrics for MayaDash
//
// ─── Architecture ─────────────────────────────────────────────
//   • Cell view: CPU temp, GPU temp, RAM%, uptime in MayaDash
//   • Detail view: expanded overlay with full metrics,
//     top processes, fan speeds, swap usage, RAM graph
//   • Backend: bee_monitor.py (JSON stdout via Process)
//   • CPU%: delta calculation between successive snapshots
//   • Polling: 5s for stats, 2s for CPU delta
// ═══════════════════════════════════════════════════════════════

Item {
    id: beeMon

    // ─── Public properties (consumed by MayaDash cells) ───────
    property real   cpuTemp:      0.0       // °C
    property real   gpuTemp:      0.0       // °C
    property real   cpuPct:       0.0       // %
    property real   ramPct:       0.0       // %
    property string ramUsed:      "0.0 GB"
    property string ramTotal:     "0.0 GB"
    property real   swapPct:      0.0       // %
    property string swapUsed:     "0.0 GB"
    property string swapTotal:    "0.0 GB"
    property string uptime:       "0m"
    property var    fans:         []        // [{label, rpm}]
    property var    topProcesses: []        // [{name, cpu, mem, pid}]
    property bool   loading:      true
    property bool   gpuIsIgu:    false     // true when GPU shares CPU die (Intel iGPU)

    // ─── RAM tracker (process VmRSS) ──────────────────────────
    property real   processRss:   0.0       // MB — current process RSS
    property bool   rssAlert:     false     // true if RSS > 200 MB idle
    property var    rssHistory:   []        // last 60 data points

    // ─── CPU% delta calculation ────────────────────────────────
    property int _prevIdle: 0
    property int _prevTotal: 0

    // ─── Temperature color coding ────────────────────────────
    property color cpuTempColor: tempColor(cpuTemp)
    property color gpuTempColor: tempColor(gpuTemp)

    function tempColor(temp) {
        if (temp <= 50) return BeeTheme.accent
        if (temp <= 70) return Qt.rgba(1.0, 0.75, 0.2, 1.0)   // amber
        if (temp <= 85) return Qt.rgba(1.0, 0.45, 0.1, 1.0)   // orange
        return Qt.rgba(1.0, 0.2, 0.2, 1.0)                     // red
    }

    // ─── i18n helper ──────────────────────────────────────────
    function tr(key) {
        if (BeeConfig.tr && BeeConfig.tr.monitor && BeeConfig.tr.monitor[key])
            return BeeConfig.tr.monitor[key]
        var fallbacks = {
            "title": "System Monitor",
            "cpu": "CPU",
            "gpu": "GPU",
            "ram": "RAM",
            "swap": "Swap",
            "uptime": "Uptime",
            "fans": "Fans",
            "processes": "Top Processes",
            "temp_unit": "°C",
            "no_fans": "No fans detected",
            "no_processes": "No data",
            "detail_label": "Details",
            "igpu": "iGPU",
            "process_memory": "Process Memory",
            "rss_mb": "MB",
            "rss_alert": "⚠ High memory usage",
            "rss_graph_label": "Memory History (60 pts)"
        }
        return fallbacks[key] || key
    }

    // ─── Backend Process ──────────────────────────────────────
    Process {
        id: _monitorProc
        running: false
        command: ["python3", Qt.resolvedUrl("../scripts/bee_monitor.py").toString().replace("file://", "")]

        onExited: (code, status) => {
            if (code !== 0)
                console.warn("BeeMonitor: Process exited with code", code)
            // Restart after brief pause (one-shot script pattern)
            restartTimer.start()
        }

        stdout: SplitParser {
            onRead: (line) => {
                try {
                    var d = JSON.parse(line.trim())

                    // Temperatures
                    if (d.cpu_temp !== null && d.cpu_temp !== undefined)
                        beeMon.cpuTemp = d.cpu_temp
                    if (d.gpu_temp !== null && d.gpu_temp !== undefined)
                        beeMon.gpuTemp = d.gpu_temp

                    // iGPU flag (Intel integrated shares CPU die)
                    if (d.gpu_is_igpu !== undefined)
                        beeMon.gpuIsIgu = d.gpu_is_igpu

                    // RAM
                    if (d.ram) {
                        beeMon.ramPct   = d.ram.pct || 0
                        beeMon.ramUsed  = (d.ram.used_gb || 0).toFixed(1) + " GB"
                        beeMon.ramTotal = (d.ram.total_gb || 0).toFixed(1) + " GB"
                    }

                    // Swap
                    if (d.swap) {
                        beeMon.swapPct   = d.swap.pct || 0
                        beeMon.swapUsed  = (d.swap.used_gb || 0).toFixed(1) + " GB"
                        beeMon.swapTotal = (d.swap.total_gb || 0).toFixed(1) + " GB"
                    }

                    // Uptime
                    if (d.uptime_str)
                        beeMon.uptime = d.uptime_str

                    // Fans
                    if (d.fans)
                        beeMon.fans = d.fans

                    // Top processes
                    if (d.top_processes)
                        beeMon.topProcesses = d.top_processes

                    // Process RSS (VmRSS from /proc/self/status)
                    if (d.process_rss_mb !== undefined && d.process_rss_mb !== null) {
                        beeMon.processRss = d.process_rss_mb
                        beeMon.rssAlert = d.process_rss_mb > 200

                        // Append to history (keep 60 points)
                        var hist = beeMon.rssHistory.slice()
                        hist.push(d.process_rss_mb)
                        if (hist.length > 60)
                            hist = hist.slice(hist.length - 60)
                        beeMon.rssHistory = hist
                    }

                    // CPU% — prefer server-calculated delta (0.2s), fall back to QML delta
                    if (d.cpu_usage !== undefined && d.cpu_usage !== null && d.cpu_usage > 0)
                        beeMon.cpuPct = d.cpu_usage
                    else if (d.cpu_snapshot) {
                        var idle  = d.cpu_snapshot.idle  || 0
                        var total = d.cpu_snapshot.total || 0

                        if (beeMon._prevTotal > 0) {
                            var diffIdle  = idle - beeMon._prevIdle
                            var diffTotal = total - beeMon._prevTotal
                            if (diffTotal > 0) {
                                beeMon.cpuPct = Math.max(0, Math.min(100,
                                    (1.0 - diffIdle / diffTotal) * 100
                                )).toFixed(1) * 1.0
                            }
                        }
                        beeMon._prevIdle  = idle
                        beeMon._prevTotal = total
                    }

                    beeMon.loading = false
                } catch (e) {
                    console.warn("BeeMonitor: Parse error:", e)
                }
            }
        }
    }

    // ─── Initialization ──────────────────────────────────────
    Component.onCompleted: {
        // Register in BeeModuleRegistry immediately (lightweight)
        BeeModuleRegistry.registerMayaDashModule({
            id: "monitor",
            slot: 4,
            title: tr("title"),
            subtitle: "CachyOS",
            icon: "🖥️",
            detail: beeMon.cpuTemp.toFixed(0) + "°C / " + beeMon.gpuTemp.toFixed(0) + "°C",
            action: "detail:monitor",
            highlighted: true,
            order: 4
        })
    }

    // ─── Lazy start: backend Process starts on first detail open ──
    property bool _backendStarted: false
    function startBackend() {
        if (beeMon._backendStarted) return
        beeMon._backendStarted = true
        _monitorProc.running = true
        pollTimer.start()
    }

    // ─── Restart timer (one-shot script re-launch) ────────
    Timer {
        id: restartTimer
        interval: 2000
        repeat: false
        onTriggered: { _monitorProc.running = true }
    }

    // ─── Polling timer (5s fallback) ──────────────────────────
    Timer {
        id: pollTimer
        interval: 5000
        repeat: true
        onTriggered: { _monitorProc.running = true }
    }
}