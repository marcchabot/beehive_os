import sys
import subprocess
import json

def get_active_window():
    try:
        # Try hyprctl activewindow
        result = subprocess.check_output(["hyprctl", "activewindow", "-j"], stderr=subprocess.STDOUT)
        data = json.loads(result)
        return data.get("class", "unknown")
    except Exception as e:
        return f"error: {str(e)}"

if __name__ == "__main__":
    print(get_active_window())
