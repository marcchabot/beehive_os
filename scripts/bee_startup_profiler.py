#!/usr/bin/env python3
"""
bee_startup_profiler.py — Startup Performance Tracker 🐝⚡
v0.8.35: Records startup timestamps and performance data

Usage:
  bee_startup_profiler.py record --total <ms> --notes <string>
  bee_startup_profiler.py report
"""

import json
import os
import sys
import argparse
from datetime import datetime

PROFILER_DIR = os.path.expanduser("~/.cache/beehive_os")
PROFILER_FILE = os.path.join(PROFILER_DIR, "startup_profiler.json")

def ensure_dir():
    os.makedirs(PROFILER_DIR, exist_ok=True)

def record(total_ms, notes=""):
    ensure_dir()
    data = {
        "timestamp": datetime.now().isoformat(),
        "total_ms": total_ms,
        "notes": notes,
    }
    # Append to history (keep last 50 entries)
    history = []
    if os.path.exists(PROFILER_FILE):
        try:
            with open(PROFILER_FILE, "r") as f:
                history = json.load(f)
                if not isinstance(history, list):
                    history = []
        except (json.JSONDecodeError, IOError):
            history = []
    
    history.append(data)
    history = history[-50:]  # Keep last 50
    
    with open(PROFILER_FILE, "w") as f:
        json.dump(history, f, indent=2)
    
    print(json.dumps({"status": "ok", "total_ms": total_ms}))

def report():
    if not os.path.exists(PROFILER_FILE):
        print(json.dumps({"status": "no_data"}))
        return
    try:
        with open(PROFILER_FILE, "r") as f:
            history = json.load(f)
        if history:
            last = history[-1]
            avg = sum(h.get("total_ms", 0) for h in history) / len(history)
            print(json.dumps({
                "status": "ok",
                "last_ms": last.get("total_ms", 0),
                "avg_ms": round(avg),
                "samples": len(history),
                "last_notes": last.get("notes", "")
            }))
        else:
            print(json.dumps({"status": "empty"}))
    except (json.JSONDecodeError, IOError):
        print(json.dumps({"status": "error"}))

def main():
    parser = argparse.ArgumentParser(description="Bee-Hive OS Startup Profiler")
    subparsers = parser.add_subparsers(dest="command")
    
    rec = subparsers.add_parser("record")
    rec.add_argument("--total", type=int, default=0)
    rec.add_argument("--notes", type=str, default="")
    
    subparsers.add_parser("report")
    
    args = parser.parse_args()
    
    if args.command == "record":
        record(args.total, args.notes)
    elif args.command == "report":
        report()
    else:
        parser.print_help()

if __name__ == "__main__":
    main()