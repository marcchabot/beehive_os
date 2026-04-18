import QtQuick
import Quickshell.Io

// ═══════════════════════════════════════════════════════════════
// BeeNetwork.qml — Network Monitor & Speed Test 🐝🌐
// v1.0: Real-time network stats + integrated speed test
//
// ─── Architecture ─────────────────────────────────────────────
//   • Real-time: interface type (WiFi/Ethernet), SSID,
//     download/upload rates, local IP, latency
//   • Detail view: expanded panel in MayaDash (detail:network)
//     with throughput chart, full details, speed test & history
//   • Speed Test: curl-based download/upload + ping
//   • Polling: 3s for throughput, 10s for latency, 30s for details
// ═══════════════════════════════════════════════════════════════

Item {
    id: beeNet

    // ─── Public properties (consumed by MayaDash cells) ───────
    property string connectionType: "ethernet"     // "ethernet" | "wifi"
    property string networkIcon:    "🔌"           // Dynamic: 📶/🔌
    property string ssid:           "Ethernet"
    property string downloadRate:   "0 K/s"
    property string uploadRate:     "0 K/s"
    property string localIp:        "—"
    property string publicIp:       "—"
    property string gateway:        "—"
    property string dns:            "—"
    property string macAddress:     "—"
    property string latency:        "— ms"
    property bool   loading:        true
    property bool   speedTestRunning: false
    property real   speedTestProgress: 0.0
    property string speedTestStatus: ""
    property var    speedTestHistory: []  // Array of {download, upload, ping, timestamp}

    // ─── Throughput chart data ────────────────────────────────
    property var dlHistory: []   // Last 30 download samples (bytes/sec)
    property var ulHistory: []   // Last 30 upload samples (bytes/sec)
    readonly property int chartMaxPoints: 30

    // ─── i18n helper ──────────────────────────────────────────
    function tr(key) {
        if (BeeConfig.tr && BeeConfig.tr.network && BeeConfig.tr.network[key])
            return BeeConfig.tr.network[key]
        // English fallback
        var fallbacks = {
            "title": "Network",
            "ethernet": "Ethernet",
            "wifi": "WiFi",
            "download": "↓ Down",
            "upload": "↑ Up",
            "latency": "Latency",
            "local_ip": "Local IP",
            "public_ip": "Public IP",
            "gateway": "Gateway",
            "dns": "DNS",
            "mac": "MAC",
            "speed_test": "⚡ Speed Test",
            "speed_test_running": "Testing…",
            "speed_test_done": "Done!",
            "speed_test_error": "Error",
            "history": "History",
            "no_history": "No tests yet",
            "detail_label": "Details",
            "chart_label": "Throughput"
        }
        return fallbacks[key] || key
    }

    // ─── Detect connection type ───────────────────────────────
    Process {
        id: _detectProc
        running: true
        command: ["bash", "-c",
            "IFACE=$(ip route list default 2>/dev/null | head -1 | awk '{print $5}'); " +
            "if [ -z \"$IFACE\" ]; then echo 'none|No route'; exit 0; fi; " +
            "if echo \"$IFACE\" | grep -q '^wl'; then " +
            "  SSID=$(iwgetid -r 2>/dev/null || echo 'WiFi'); " +
            "  echo \"wifi|$SSID\"; " +
            "else " +
            "  echo 'ethernet|Ethernet'; " +
            "fi"
        ]
        stdout: SplitParser {
            onRead: (line) => {
                var parts = line.trim().split("|")
                if (parts.length >= 2) {
                    beeNet.connectionType = parts[0]
                    beeNet.ssid = parts[1]
                    beeNet.networkIcon = (parts[0] === "wifi") ? "📶" : "🔌"
                }
            }
        }
    }

    // ─── Network details (IP, gateway, DNS, MAC) ──────────────
    Process {
        id: _detailsProc
        running: false
        command: ["bash", "-c",
            "IFACE=$(ip route list default 2>/dev/null | head -1 | awk '{print $5}'); " +
            "IP=$(ip -4 addr show $IFACE 2>/dev/null | grep inet | head -1 | awk '{print $2}' | cut -d/ -f1); " +
            "GW=$(ip route list default 2>/dev/null | head -1 | awk '{print $3}'); " +
            "DNS=$(grep nameserver /etc/resolv.conf 2>/dev/null | head -1 | awk '{print $2}'); " +
            "MAC=$(cat /sys/class/net/$IFACE/address 2>/dev/null || echo '—'); " +
            "echo \"$IP|$GW|$DNS|$MAC\""
        ]
        stdout: SplitParser {
            onRead: (line) => {
                var parts = line.trim().split("|")
                if (parts.length >= 4) {
                    beeNet.localIp    = parts[0] || "—"
                    beeNet.gateway    = parts[1] || "—"
                    beeNet.dns        = parts[2] || "—"
                    beeNet.macAddress = parts[3] || "—"
                }
            }
        }
    }

    // ─── Public IP (fetched once, then every 5 min) ───────────
    Process {
        id: _publicIpProc
        running: false
        command: ["bash", "-c", "curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo '—'"]
        stdout: SplitParser {
            onRead: (line) => {
                var v = line.trim()
                if (v && v !== "") beeNet.publicIp = v
            }
        }
    }

    // ─── Throughput measurement (read /proc/net/dev) ─────────
    Process {
        id: _throughputProc
        running: false
        command: ["bash", "-c",
            "IFACE=$(ip route list default 2>/dev/null | head -1 | awk '{print $5}'); " +
            "if [ -z \"$IFACE\" ]; then echo '0|0|0|0'; exit 0; fi; " +
            "RX1=$(awk -v iface=\"$IFACE\" '$1==iface\":\" {print $2}' /proc/net/dev); " +
            "TX1=$(awk -v iface=\"$IFACE\" '$1==iface\":\" {print $10}' /proc/net/dev); " +
            "sleep 1; " +
            "RX2=$(awk -v iface=\"$IFACE\" '$1==iface\":\" {print $2}' /proc/net/dev); " +
            "TX2=$(awk -v iface=\"$IFACE\" '$1==iface\":\" {print $10}' /proc/net/dev); " +
            "echo \"${RX2:-0}|${TX2:-0}|$(( ${RX2:-0} - ${RX1:-0} ))|$(( ${TX2:-0} - ${TX1:-0} ))\""
        ]
        stdout: SplitParser {
            onRead: (line) => {
                var parts = line.trim().split("|")
                if (parts.length < 4) return

                var rxDiff = parseInt(parts[2]) || 0
                var txDiff = parseInt(parts[3]) || 0

                var dlBps = Math.max(0, rxDiff)
                var ulBps = Math.max(0, txDiff)

                beeNet.downloadRate = formatRate(dlBps)
                beeNet.uploadRate   = formatRate(ulBps)

                // Update chart history
                var newDl = beeNet.dlHistory.slice()
                var newUl = beeNet.ulHistory.slice()
                newDl.push(dlBps)
                newUl.push(ulBps)
                if (newDl.length > beeNet.chartMaxPoints) newDl.shift()
                if (newUl.length > beeNet.chartMaxPoints) newUl.shift()
                beeNet.dlHistory = newDl
                beeNet.ulHistory = newUl

                beeNet.loading = false
            }
        }
    }

    // ─── Latency (ping 1.1.1.1) ───────────────────────────────
    Process {
        id: _latencyProc
        running: false
        command: ["bash", "-c",
            "ping -c 1 -W 2 1.1.1.1 2>/dev/null | grep 'time=' | sed 's/.*time=\\([0-9.]*\\).*/\\1/' || echo 'timeout'"
        ]
        stdout: SplitParser {
            onRead: (line) => {
                var v = line.trim()
                if (v === "timeout" || v === "") {
                    beeNet.latency = "— ms"
                } else {
                    beeNet.latency = parseFloat(v).toFixed(1) + " ms"
                }
            }
        }
    }

    // ─── Speed Test ───────────────────────────────────────────
    // 3 phases: ping → download → upload
    property string _stDlResult: ""
    property string _stUlResult: ""
    property string _stPingResult: ""

    Process {
        id: _stPingProc
        running: false
        command: ["bash", "-c",
            "ping -c 3 -W 2 1.1.1.1 2>/dev/null | tail -1 | awk -F '/' '{print $5}' || echo 'timeout'"
        ]
        stdout: SplitParser {
            onRead: (line) => {
                var v = line.trim()
                beeNet._stPingResult = (v === "timeout" || v === "") ? "—" : parseFloat(v).toFixed(1) + " ms"
            }
        }
        onExited: (code, status) => {
            beeNet.speedTestStatus = beeNet.tr("download")
            beeNet.speedTestProgress = 0.33
            _stDlProc.running = true
        }
    }

    Process {
        id: _stDlProc
        running: false
        command: ["bash", "-c",
            "SPEED=$(curl -o /dev/null -s -w '%{speed_download}' --max-time 10 http://speedtest.tele2.net/10MB.zip 2>/dev/null); " +
            "echo \"$SPEED\""
        ]
        stdout: SplitParser {
            onRead: (line) => {
                var v = parseFloat(line.trim()) || 0
                beeNet._stDlResult = formatSpeed(v)
            }
        }
        onExited: (code, status) => {
            beeNet.speedTestStatus = beeNet.tr("upload")
            beeNet.speedTestProgress = 0.66
            _stUlProc.running = true
        }
    }

    Process {
        id: _stUlProc
        running: false
        command: ["bash", "-c",
            "TMPF=$(mktemp /tmp/beenet_ul_XXXXXX); " +
            "dd if=/dev/urandom of=$TMPF bs=1M count=2 2>/dev/null; " +
            "SPEED=$(curl -s -w '%{speed_upload}' -T $TMPF --max-time 10 http://speedtest.tele2.net/upload.php 2>/dev/null || echo '0'); " +
            "rm -f $TMPF; " +
            "echo \"$SPEED\""
        ]
        stdout: SplitParser {
            onRead: (line) => {
                var v = parseFloat(line.trim()) || 0
                beeNet._stUlResult = formatSpeed(v)
            }
        }
        onExited: (code, status) => {
            beeNet.speedTestProgress = 1.0
            beeNet.speedTestRunning = false
            beeNet.speedTestStatus = beeNet.tr("speed_test_done")

            // Save to history
            var entry = {
                download: beeNet._stDlResult,
                upload: beeNet._stUlResult,
                ping: beeNet._stPingResult,
                timestamp: new Date().toLocaleString(Qt.locale(), Locale.ShortFormat)
            }
            var hist = beeNet.speedTestHistory.slice()
            hist.unshift(entry)
            if (hist.length > 5) hist.pop()
            beeNet.speedTestHistory = hist

            _stResetTimer.start()
        }
    }

    Timer {
        id: _stResetTimer
        interval: 3000
        onTriggered: {
            beeNet.speedTestStatus = ""
            beeNet.speedTestProgress = 0.0
        }
    }

    function runSpeedTest() {
        if (speedTestRunning) return
        speedTestRunning = true
        speedTestProgress = 0.0
        speedTestStatus = tr("latency") + "…"
        _stPingResult = ""
        _stDlResult = ""
        _stUlResult = ""
        _stPingProc.running = true
    }

    // ─── Format helpers ───────────────────────────────────────
    function formatRate(bps) {
        if (bps <= 0) return "0 B/s"
        if (bps < 1024) return bps.toFixed(0) + " B/s"
        if (bps < 1048576) return (bps / 1024).toFixed(1) + " K/s"
        return (bps / 1048576).toFixed(1) + " M/s"
    }

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec <= 0) return "—"
        var mbps = (bytesPerSec * 8) / 1000000
        if (mbps < 1) return (mbps * 1000).toFixed(0) + " Kbps"
        return mbps.toFixed(1) + " Mbps"
    }

    // ─── Initialization ──────────────────────────────────────
    Component.onCompleted: {
        _detailsProc.running = true
        _publicIpProc.running = true
        _latencyProc.running = true
        _throughputProc.running = true
        statsTimer.start()
        latencyTimer.start()
        publicIpTimer.start()
        detailsTimer.start()

        // Register in BeeModuleRegistry
        BeeModuleRegistry.registerMayaDashModule({
            id: "network",
            slot: 6,
            title: tr("title"),
            subtitle: ssid,
            icon: networkIcon,
            detail: downloadRate + " / " + uploadRate,
            action: "detail:network",
            highlighted: true,
            order: 6
        })
    }

    // ─── Polling timers ──────────────────────────────────────
    Timer {
        id: statsTimer
        interval: 3000
        repeat: true
        onTriggered: { _throughputProc.running = true }
    }

    Timer {
        id: latencyTimer
        interval: 10000
        repeat: true
        onTriggered: { _latencyProc.running = true }
    }

    Timer {
        id: publicIpTimer
        interval: 300000   // 5 minutes
        repeat: true
        onTriggered: { _publicIpProc.running = true }
    }

    Timer {
        id: detailsTimer
        interval: 30000   // 30 seconds
        repeat: true
        onTriggered: { _detailsProc.running = true }
    }

    // ─── Re-detect connection type ────────────────────────────
    Timer {
        id: reDetectTimer
        interval: 60000
        repeat: true
        running: true
        onTriggered: { _detectProc.running = true }
    }
}