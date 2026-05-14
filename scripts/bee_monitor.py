#!/usr/bin/env python3
"""bee_monitor.py — System Metrics Collector for BeeMonitor.qml

Outputs one JSON line per cycle on stdout.
Called every 5 seconds by BeeMonitor Process.
Format matches BeeMonitor.qml SplitParser expectations.
"""

import json
import os
import sys
import time
import shutil
import tempfile
import subprocess


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


def parse_cpu_stat():
    """Parse /proc/stat for CPU idle/total (for delta calculation)."""
    try:
        with open("/proc/stat") as f:
            line = f.readline().strip()
        parts = line.split()
        vals = [int(x) for x in parts[2:12]]
        idle = vals[3] + vals[4]  # idle + iowait
        total = sum(vals)
        return {"idle": idle, "total": total}
    except Exception:
        return {"idle": 0, "total": 0}


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

    KB = 1048576  # 1 MB in KB
    GB = KB / 1024

    return {
        "pct": round(mem_used * 100 / mem_total, 1) if mem_total > 0 else 0,
        "used_gb": round(mem_used / 1048576, 1),
        "total_gb": round(mem_total / 1048576, 1),
        "swap_pct": round(swap_used * 100 / swap_total, 1) if swap_total > 0 else 0,
        "swap_used_gb": round(swap_used / 1048576, 1),
        "swap_total_gb": round(swap_total / 1048576, 1),
    }


def get_temps(sensors_data):
    """Extract CPU and GPU temps from sensors JSON."""
    cpu_temp = 0.0
    gpu_temp = 0.0
    gpu_is_igpu = False

    if not sensors_data:
        return cpu_temp, gpu_temp, gpu_is_igpu

    # CPU temp: k10temp (AMD) or coretemp (Intel)
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

    # Fallback: acpitz / gigabyte_wmi
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

    # GPU temp: amdgpu (dedicated, skip iGPU pci-7600)
    for chip, chip_data in sensors_data.items():
        if "amdgpu" in chip.lower() and "pci-7600" not in chip.lower():
            for sub, vals in chip_data.items():
                if isinstance(vals, dict) and "edge" in sub.lower():
                    for k, v in vals.items():
                        if "input" in k.lower():
                            gpu_temp = round(float(v), 1)
                            break

    # Detect iGPU (AMD APU with shared die)
    if gpu_temp == 0 and cpu_temp > 0:
        # Check if amdgpu with pci-7600 (iGPU)
        for chip in sensors_data:
            if "amdgpu" in chip.lower() and "pci-7600" in chip.lower():
                gpu_is_igpu = True
                gpu_temp = cpu_temp  # iGPU shares CPU die
                break

    return cpu_temp, gpu_temp, gpu_is_igpu


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
    """Get top 5 processes by CPU usage."""
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
                    procs.append({
                        "pid": int(parts[1]),
                        "name": parts[10][:20],
                        "cpu": float(parts[2]),
                        "mem": float(parts[3])
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


def get_process_rss():
    """Get current process RSS in MB (VmRSS from /proc/self/status)."""
    try:
        with open("/proc/self/status") as f:
            for line in f:
                if line.startswith("VmRSS:"):
                    return round(int(line.split()[1]) / 1024, 1)
    except Exception:
        pass
    return 0.0


def main():
    """Main loop: output JSON every 5 seconds."""
    prev_idle = 0
    prev_total = 0

    while True:
        try:
            # Collect data
            sensors_data = read_sensors()
            cpu_temp, gpu_temp, gpu_is_igpu = get_temps(sensors_data)
            ram = parse_meminfo()
            fans = get_fans(sensors_data)
            top_procs = get_top_processes()
            uptime = get_uptime()
            process_rss = get_process_rss()

            # CPU snapshot for delta calculation
            cpu_snap = parse_cpu_stat()

            result = {
                "cpu_temp": cpu_temp,
                "gpu_temp": gpu_temp,
                "gpu_is_igpu": gpu_is_igpu,
                "ram": {
                    "pct": ram["pct"],
                    "used_gb": ram["used_gb"],
                    "total_gb": ram["total_gb"],
                    "swap_pct": ram["swap_pct"],
                    "swap_used_gb": ram["swap_used_gb"],
                    "swap_total_gb": ram["swap_total_gb"],
                },
                "fans": fans,
                "top_processes": top_procs,
                "uptime_str": uptime,
                "process_rss_mb": process_rss,
                "cpu_snapshot": cpu_snap,
            }

            print(json.dumps(result), flush=True)

        except Exception as e:
            # Output error JSON so QML knows something went wrong
            print(json.dumps({"error": str(e)}), flush=True)

        time.sleep(5)


if __name__ == "__main__":
    main()