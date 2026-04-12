import sys
import subprocess
import json
import time

def get_active_window():
    try:
        # Try hyprctl activewindow
        result = subprocess.check_output(["hyprctl", "activewindow", "-j"], stderr=subprocess.STDOUT)
        data = json.loads(result)
        return data.get("class", "unknown")
    except Exception:
        return "unknown"

if __name__ == "__main__":
    last_window = None
    while True:
        current_window = get_active_window()
        if current_window != last_window:
            print(current_window)
            sys.stdout.flush()
            last_window = current_window
        time.sleep(0.5) # Poll every 500ms for responsiveness
