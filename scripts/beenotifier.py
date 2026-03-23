#!/usr/bin/env python3
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import subprocess
import os
import json

# ═══════════════════════════════════════════════════════════════
# BeeNotifier.py 🐝🔔
# Intercepte org.freedesktop.Notifications via DBus et
# transmet les données à Bee-Hive OS via Quickshell IPC.
# ═══════════════════════════════════════════════════════════════

class NotificationServer(dbus.service.Object):
    def __init__(self):
        bus_name = dbus.service.BusName('org.freedesktop.Notifications', bus=dbus.SessionBus())
        dbus.service.Object.__init__(self, bus_name, '/org/freedesktop/Notifications')
        print("BeeNotifier: Online and listening! 🐝🔔")

    @dbus.service.method('org.freedesktop.Notifications', in_signature='susssasa{sv}i', out_signature='u')
    def Notify(self, app_name, replaces_id, app_icon, summary, body, actions, hints, expire_timeout):
        # On ignore l'ID de remplacement pour simplifier
        print(f"BeeNotifier: Received from {app_name} -> {summary}")
        
        # On transmet à Quickshell via IPC
        # La commande: qs ipc call root dispatchNotification "Titre" "Message" "Icon"
        try:
            home = os.path.expanduser("~")
            cmd = [
                "quickshell", "-p", f"{home}/beehive_os/shell.qml", 
                "ipc", "call", "root", "dispatchNotification",
                str(summary), str(body), str(app_icon or "🐝")
            ]
            subprocess.run(cmd, check=False)
        except Exception as e:
            print(f"BeeNotifier: IPC Error -> {e}")

        return 0 # Notification ID (bidon ici)

    @dbus.service.method('org.freedesktop.Notifications', out_signature='ssss')
    def GetServerInformation(self):
        return ("BeeNotifier", "Maya", "1.0", "1.2")

    @dbus.service.method('org.freedesktop.Notifications', out_signature='as')
    def GetCapabilities(self):
        return ["body", "actions", "icon-static"]

    @dbus.service.signal('org.freedesktop.Notifications', signature='uu')
    def NotificationClosed(self, id, reason):
        pass

    @dbus.service.signal('org.freedesktop.Notifications', signature='us')
    def ActionInvoked(self, id, action_key):
        pass

if __name__ == '__main__':
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    try:
        server = NotificationServer()
        loop = GLib.MainLoop()
        loop.run()
    except Exception as e:
        print(f"BeeNotifier: Cannot start (another server already running?) -> {e}")
