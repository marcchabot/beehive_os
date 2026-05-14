#!/usr/bin/env python3
"""bee_monitor.py — System Metrics Collector for BeeMonitor.qml

Outputs ONE JSON line on stdout, then exits.
Called every 5 seconds by BeeMonitor Process + restartTimer.
Uses the proven 2-snapshot delta pattern from _bee_sysmon_collect.sh.
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import time


def read_file(path):
    try:
        with open(path) as f:
            return f.read().strip()
    except Exception:
        return ""


def parse_cpu_line(content):
    """Parse 'cpu  ...' line from /proc/stat."""
    parts = content.split()
    vals = [int(x) for x in parts[2:12]]
    idle = vals[3] + vals[4]  # idle + iowait
    total = sum(vals)
    return idle, total


def calc_cpu_usage():
    """Two-snapshot delta method (same as _bee_sysmon_collect.sh)."""
    try:
        snap1 = read_file("/proc/stat").split("\n")[0]
        time.sleep(0.2)
        snap2 = read_file("/proc/stat").split("\n")[0]
        idle1, total1 = parse_cpu_line(snap1)
        idle2, total2 = parse_cpu_line(snap2)
        diff_idle = idle2 - idle1
        diff_total = total2 - total1
        if diff_total > 0:
            return round((1.0 - diff_idle / diff_total) * 100, 1)
    except Exception:
        pass
    return 0.0


def read_sensors():
    """Read lm-sensors JSON output."""
    try:
        result = subprocess.run(
            ["sensors", "-j"],
            capture_output=True, text=True, timeout=3
        )
        return json.loads(result.stdout) if result.stdout.strip() else {}
    except Exception:
        return {}


def get_temps(sensors_data):
    """Extract CPU and GPU temps from sensors JSON.

    Logic (same as _bee_sysmon_collect.sh):
    - CPU: k10temp (AMD) → Tctl, or coretemp (Intel)
    - GPU dedicated: amdgpu WITHOUT pci-7600 (skip iGPU)
    - iGPU flag: set if amdgpu-pci-7600 exists (AMD APU)
    """
    cpu_temp = 0.0
    gpu_temp = 0.0
    gpu_is_igpu = False
    has_igpu = False
    has_dedicated_gpu = False

    if not sensors_data:
        return cpu_temp, gpu_temp, gpu_is_igpu

    # CPU temp
    for chip, chip_data in sensors_data.items():
        if "k10temp" in chip.lower():
            for sub, vals in chip_data.items():
                if isinstance(vals, dict):
                    for k, v in vals.items():
                        if "input" in k.lower():
                            cpu_temp = round(float(v), 1)
                            break
        elif "coretemp" in chip.lower() and cpu_temp == 0:
            for sub, vals in chip_data.items():
                if isinstance(vals, dict):
                    for k, v in vals.items():
                        if "input" in k.lower():
                            cpu_temp = round(float(v), 1)
                            break

    if cpu_temp == 0:
        for chip, chip_data in sensors_data.items():
            if "acpitz" in chip.lower() or "gigabyte" in chip.lower():
                for sub, vals in chip_data.items():
                    if isinstance(vals, dict):
                        for k, v in vals.items():
                            if "input" in k.lower() and float(v) > 0:
                                cpu_temp = round(float(v), 1)
                                break
                if cpu_temp > 0:
                    break

    # GPU temp: dedicated amdgpu (skip iGPU pci-7600)
    for chip, chip_data in sensors_data.items():
        if "amdgpu" in chip.lower() and "pci-7600" not in chip.lower():
            for sub, vals in chip_data.items():
                if isinstance(vals, dict) and "edge" in sub.lower():
                    for k, v in vals.items():
                        if "input" in k.lower():
                            gpu_temp = round(float(v), 1)
                            has_dedicated_gpu = True
                            break

    # iGPU detection: amdgpu-pci-7600 present
    for chip in sensors_data:
        if "amdgpu" in chip.lower() and "pci-7600" in chip.lower():
            has_igpu = True
            break

    # If no dedicated GPU found but iGPU exists, use CPU temp for GPU
    if not has_dedicated_gpu and has_igpu:
        gpu_is_igpu = True
        gpu_temp = cpu_temp

    return cpu_temp, gpu_temp, gpu_is_igpu


def parse_meminfo():
    """Parse /proc/meminfo for RAM/Swap."""
    info = {}
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                if ":" not in line:
                    continue
                key, val = line.split(":", 1)
                kb = int(val.strip().split()[0])
                info[key.strip()] = kb
    except Exception:
        pass

    mem_total = info.get("MemTotal", 0)
    mem_available = info.get("MemAvailable", 0)
    mem_used = mem_total - mem_available
    swap_total = info.get("SwapTotal", 0)
    swap_free = info.get("SwapFree", 0)
    swap_used = swap_total - swap_free

    return {
        "pct": round(mem_used * 100 / mem_total, 1) if mem_total > 0 else 0,
        "used_gb": round(mem_used / 1048576, 1),
        "total_gb": round(mem_total / 1048576, 1),
        "swap_pct": round(swap_used * 100 / swap_total, 1) if swap_total > 0 else 0,
        "swap_used_gb": round(swap_used / 1048576, 1),
        "swap_total_gb": round(swap_total / 1048576, 1),
    }


def get_fans(sensors_data):
    """Extract fan speeds from sensors JSON."""
    fans = []
    if not sensors_data:
        return fans
    for chip, chip_data in sensors_data.items():
        if isinstance(chip_data, dict):
            for sub, vals in chip_data.items():
                if isinstance(vals, dict):
                    for k, v in vals.items():
                        if "fan" in k.lower() and "input" in k.lower():
                            try:
                                rv = float(v)
                                if rv > 0:
                                    label = sub.replace("_", " ").title()
                                    fans.append({"label": label, "rpm": int(rv)})
                            except (ValueError, TypeError):
                                pass
    return fans


def get_top_processes():
    """Get top 5 processes by CPU usage, capped at 100% per process."""
    try:
        result = subprocess.run(
            ["ps", "aux", "--sort=-%cpu"],
            capture_output=True, text=True, timeout=3
        )
        lines = result.stdout.strip().split("\n")
        procs = []
        for line in lines[1:6]:
            parts = line.split(None, 10)
            if len(parts) >= 11:
                try:
                    cpu = float(parts[2])
                    mem = float(parts[3])
                    # Cap at 100% (ps aux shows >100% for multi-thread)
                    cpu = min(cpu, 100.0)
                    procs.append({
                        "pid": int(parts[1]),
                        "name": parts[10][:20],
                        "cpu": cpu,
                        "mem": mem
                    })
                except (ValueError, IndexError):
                    pass
        return procs
    except Exception:
        return []


def get_uptime():
    """Get formatted uptime string."""
    try:
        with open("/proc/uptime") as f:
            secs = int(float(f.read().split()[0]))
        days = secs // 86400
        hours = (secs % 86400) // 3600
        mins = (secs % 3600) // 60
        return f"{days}d {hours}h {mins}m"
    except Exception:
        return "—"


def main():
    sensors_data = read_sensors()
    cpu_usage = calc_cpu_usage()
    cpu_temp, gpu_temp, gpu_is_igpu = get_temps(sensors_data)
    mem = parse_meminfo()
    fans = get_fans(sensors_data)
    top_procs = get_top_processes()
    uptime = get_uptime()

    # Single snapshot for QML delta (QML stores _prevIdle/_prevTotal)
    snap = read_file("/proc/stat").split("\n")[0]
    idle, total = parse_cpu_line(snap) if snap else (0, 0)

    result = {
        "cpu_usage": cpu_usage,
        "cpu_temp": cpu_temp,
        "gpu_temp": gpu_temp,
        "gpu_is_igpu": gpu_is_igpu,
        "ram": {
            "pct": mem["pct"],
            "used_gb": mem["used_gb"],
            "total_gb": mem["total_gb"],
        },
        "swap": {
            "pct": mem["swap_pct"],
            "used_gb": mem["swap_used_gb"],
            "total_gb": mem["swap_total_gb"],
        },
        "fans": fans,
        "top_processes": top_procs,
        "uptime_str": uptime,
        "cpu_snapshot": {"idle": idle, "total": total},
    }

    print(json.dumps(result), flush=True)


if __name__ == "__main__":
    main()