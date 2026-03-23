#!/usr/bin/env python3
# Bee-Hive OS Notification Daemon 🐝
# Sends notifications via DBus to the Bee-Hive notification system

import argparse
import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib
import sys
import json

# Bee-Hive notification interface
BEEHIVE_BUS_NAME = "com.beehive.Notification"
BEEHIVE_OBJ_PATH = "/com/beehive/Notification"

class BeeNotifier(dbus.service.Object):
    def __init__(self):
        bus_name = dbus.service.BusName(BEEHIVE_BUS_NAME, bus=dbus.SessionBus())
        dbus.service.Object.__init__(self, bus_name, BEEHIVE_OBJ_PATH)

    @dbus.service.method(BEEHIVE_BUS_NAME, in_signature='ssss', out_signature='u')
    def Notify(self, title, body, icon, urgency):
        """Send a notification to Bee-Hive
        
        Args:
            title: Notification title
            body: Notification body text
            icon: Icon emoji or name
            urgency: urgency level (low, normal, critical)
        """
        try:
            # Read current config to get user prefs
            import os
            config_path = os.path.expanduser("~/beehive_os/user_config.json")
            
            # Create notification JSON for IPC
            notification = {
                "title": title,
                "body": body,
                "icon": icon,
                "urgency": urgency,
                "timestamp": json.dumps(None)  # Will be set by receiver
            }
            
            # Write to a pipe or socket that Quickshell can read
            # For now, we use a simple file-based IPC
            ipc_path = os.path.expanduser("~/.cache/beehive/notifications.json")
            os.makedirs(os.path.dirname(ipc_path), exist_ok=True)
            
            # Append to notifications list
            notifications = []
            if os.path.exists(ipc_path):
                try:
                    with open(ipc_path, 'r') as f:
                        notifications = json.load(f)
                except:
                    pass
            
            notifications.insert(0, notification)
            
            # Keep only last 50
            notifications = notifications[:50]
            
            with open(ipc_path, 'w') as f:
                json.dump(notifications, f)
            
            return 0  # Success
        except Exception as e:
            print(f"Error sending notification: {e}")
            return 1

def send_notification(title, body, icon="🐝", urgency="normal"):
    """Simple function to send a notification"""
    try:
        bus = dbus.SessionBus()
        obj = bus.get_object(BEEHIVE_BUS_NAME, BEEHIVE_OBJ_PATH)
        iface = dbus.Interface(obj, BEEHIVE_BUS_NAME)
        return iface.Notify(title, body, icon, urgency)
    except:
        # Fallback: write directly to IPC file
        import os
        import json
        ipc_path = os.path.expanduser("~/.cache/beehive/notifications.json")
        os.makedirs(os.path.dirname(ipc_path), exist_ok=True)
        
        notification = {
            "title": title,
            "body": body,
            "icon": icon,
            "urgency": urgency
        }
        
        notifications = []
        if os.path.exists(ipc_path):
            try:
                with open(ipc_path, 'r') as f:
                    notifications = json.load(f)
            except:
                pass
        
        notifications.insert(0, notification)
        notifications = notifications[:50]
        
        with open(ipc_path, 'w') as f:
            json.dump(notifications, f)
        return 0

def main():
    parser = argparse.ArgumentParser(description='Bee-Hive OS Notification Tool 🐝')
    parser.add_argument('title', help='Notification title')
    parser.add_argument('body', nargs='?', default='', help='Notification body')
    parser.add_argument('--icon', '-i', default='🐝', help='Icon emoji')
    parser.add_argument('--urgency', '-u', default='normal', 
                       choices=['low', 'normal', 'critical'],
                       help='Urgency level')
    parser.add_argument('--daemon', '-d', action='store_true',
                       help='Run as daemon')
    
    args = parser.parse_args()
    
    if args.daemon:
        # Run as notification daemon
        DBusGMainLoop(set_as_default=True)
        notifier = BeeNotifier()
        print("🐝 Bee-Hive Notification daemon started...")
        GLib.MainLoop().run()
    else:
        # Send single notification
        result = send_notification(args.title, args.body, args.icon, args.urgency)
        if result == 0:
            print(f"✅ Notification sent: {args.title}")
        else:
            print(f"❌ Failed to send notification")
            sys.exit(1)

if __name__ == "__main__":
    main()