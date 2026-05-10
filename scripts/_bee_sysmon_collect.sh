#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# _bee_sysmon_collect.sh — System Metrics Collector for BeeSystemMonitor 🐝
# Outputs JSON on stdout for QML Process consumption.
# Called every 2 seconds by BeeSystemMonitor.qml
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# ─── Collect raw data ──────────────────────────────────────────
TMPDIR=$(mktemp -d /tmp/bee_sysmon.XXXXXX)

# CPU snapshots (0.2s apart for delta calculation)
head -1 /proc/stat > "$TMPDIR/cpu1"
sleep 0.2
head -1 /proc/stat > "$TMPDIR/cpu2"
cat /proc/cpuinfo > "$TMPDIR/cpuinfo"
cat /proc/meminfo > "$TMPDIR/meminfo"
awk '{printf "%.0f", $1}' /proc/uptime > "$TMPDIR/uptime"
ps aux --sort=-%cpu 2>/dev/null | head -6 > "$TMPDIR/ps_aux"
sensors -j > "$TMPDIR/sensors.json" 2>/dev/null || echo '{}' > "$TMPDIR/sensors.json"

# ─── Process everything in python3 ─────────────────────────────
python3 - "$TMPDIR" << 'PYEOF'
import json, os, sys

tmpdir = sys.argv[1]

# ─── CPU Usage ─────────────────────────────────────────────
def parse_cpu_line(path):
    with open(path) as f:
        line = f.read().strip()
    parts = line.split()
    vals = [int(x) for x in parts[2:12]]
    idle = vals[3] + vals[4]  # idle + iowait
    total = sum(vals)
    return idle, total

cpu_usage = 0.0
cpu_freq = 0
try:
    idle1, total1 = parse_cpu_line(os.path.join(tmpdir, 'cpu1'))
    idle2, total2 = parse_cpu_line(os.path.join(tmpdir, 'cpu2'))
    diff_idle = idle2 - idle1
    diff_total = total2 - total1
    if diff_total > 0:
        cpu_usage = round((1 - diff_idle / diff_total) * 100, 1)
except Exception as e:
    pass

# CPU frequency (average across cores)
try:
    freqs = []
    with open(os.path.join(tmpdir, 'cpuinfo')) as f:
        for line in f:
            if 'cpu MHz' in line:
                val = float(line.split(':')[1].strip())
                freqs.append(val)
    if freqs:
        cpu_freq = int(sum(freqs) / len(freqs))
except:
    pass

# ─── Memory ────────────────────────────────────────────────
mem_total = mem_available = swap_total = swap_free = 0
mem_total_gb = mem_used_gb = swap_total_gb = swap_used_gb = 0.0
mem_pct = swap_pct = 0.0
try:
    with open(os.path.join(tmpdir, 'meminfo')) as f:
        for line in f:
            if ':' not in line:
                continue
            key, val = line.split(':', 1)
            val_kb = int(val.strip().split()[0])
            if key.strip() == 'MemTotal':
                mem_total = val_kb
            elif key.strip() == 'MemAvailable':
                mem_available = val_kb
            elif key.strip() == 'SwapTotal':
                swap_total = val_kb
            elif key.strip() == 'SwapFree':
                swap_free = val_kb
    mem_used = mem_total - mem_available
    swap_used = swap_total - swap_free
    KB = 1048576
    mem_total_gb = round(mem_total / KB, 1)
    mem_used_gb = round(mem_used / KB, 1)
    swap_total_gb = round(swap_total / KB, 1)
    swap_used_gb = round(swap_used / KB, 1)
    mem_pct = round(mem_used * 100 / mem_total, 1) if mem_total > 0 else 0
    swap_pct = round(swap_used * 100 / swap_total, 1) if swap_total > 0 else 0
except:
    pass

# ─── Temperatures ──────────────────────────────────────────
cpu_temp = 0.0
gpu_temp = 0.0
data = {}
try:
    with open(os.path.join(tmpdir, 'sensors.json')) as f:
        data = json.load(f)
except:
    pass

if data:
    # CPU temp: k10temp (AMD) or coretemp (Intel)
    for chip, chip_data in data.items():
        if 'k10temp' in chip.lower():
            for sub, vals in chip_data.items():
                if isinstance(vals, dict) and 'Tctl' in sub:
                    for k, v in vals.items():
                        if 'input' in k.lower():
                            cpu_temp = round(float(v), 1)
                            break
        elif 'coretemp' in chip.lower() and cpu_temp == 0:
            for sub, vals in chip_data.items():
                if isinstance(vals, dict):
                    for k, v in vals.items():
                        if 'input' in k.lower():
                            cpu_temp = round(float(v), 1)
                            break

    # Fallback: acpitz / gigabyte_wmi
    if cpu_temp == 0:
        for chip, chip_data in data.items():
            if 'acpitz' in chip.lower() or 'gigabyte' in chip.lower():
                for sub, vals in chip_data.items():
                    if isinstance(vals, dict):
                        for k, v in vals.items():
                            if 'input' in k.lower() and float(v) > 0:
                                cpu_temp = round(float(v), 1)
                                break
                        if cpu_temp > 0:
                            break

    # GPU temp: amdgpu (dedicated, skip iGPU pci-7600)
    for chip, chip_data in data.items():
        if 'amdgpu' in chip.lower() and 'pci-7600' not in chip.lower():
            for sub, vals in chip_data.items():
                if isinstance(vals, dict) and 'edge' in sub.lower():
                    for k, v in vals.items():
                        if 'input' in k.lower():
                            gpu_temp = round(float(v), 1)
                            break

# ─── Fans ──────────────────────────────────────────────────
fans = []
if data:
    for chip, chip_data in data.items():
        if isinstance(chip_data, dict):
            for sub, vals in chip_data.items():
                if isinstance(vals, dict):
                    for k, v in vals.items():
                        if 'fan' in k.lower() and 'input' in k.lower():
                            rv = float(v)
                            if rv > 0:
                                label = sub.replace('_', ' ').title()
                                fans.append({'label': label, 'rpm': int(rv)})

# ─── Top Processes ─────────────────────────────────────────
top_procs = []
try:
    with open(os.path.join(tmpdir, 'ps_aux')) as f:
        lines = f.read().strip().split('\n')
    for line in lines[1:6]:  # skip header, top 5
        parts = line.split(None, 10)
        if len(parts) >= 11:
            try:
                top_procs.append({
                    'pid': int(parts[1]),
                    'name': parts[10][:20],
                    'cpu': float(parts[2]),
                    'mem': float(parts[3])
                })
            except:
                pass
except:
    pass

# ─── Uptime ────────────────────────────────────────────────
uptime_secs = 0
try:
    with open(os.path.join(tmpdir, 'uptime')) as f:
        uptime_secs = int(f.read().strip())
except:
    pass
days = uptime_secs // 86400
hours = (uptime_secs % 86400) // 3600
mins = (uptime_secs % 3600) // 60
uptime_str = f"{days}d {hours}h {mins}m"

# ─── Cleanup temp files ────────────────────────────────────
import shutil
try:
    shutil.rmtree(tmpdir)
except:
    pass

# ─── Output JSON ────────────────────────────────────────────
result = {
    'cpu': {'usage': cpu_usage, 'freq': cpu_freq},
    'mem': {
        'used': mem_used_gb, 'total': mem_total_gb, 'pct': mem_pct,
        'swap_used': swap_used_gb, 'swap_total': swap_total_gb, 'swap_pct': swap_pct
    },
    'temps': {'cpu': cpu_temp, 'gpu': gpu_temp},
    'fans': fans,
    'top': top_procs[:5],
    'uptime': uptime_str
}
print(json.dumps(result))
PYEOF