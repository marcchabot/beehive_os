#!/usr/bin/env python3
import sys
import subprocess
import json

def maya_notify(title, body, icon="🐝"):
    """Envoie une notification au bureau Bee-Hive via Quickshell IPC"""
    try:
        # Commande Quickshell IPC pour appeler mayaTap
        cmd = [
            "quickshell", "-p", "root", "mayaTap",
            f"\"{title}\"",
            f"\"{body}\""
        ]
        # Alternative via dispatchNotification si on veut changer l'icône
        if icon != "🐝":
            cmd = [
                "quickshell", "-p", "root", "dispatchNotification",
                f"\"{title}\"",
                f"\"{body}\"",
                f"\"{icon}\""
            ]
            
        subprocess.run(" ".join(cmd), shell=True, check=True)
        return True
    except Exception as e:
        print(f"Erreur Maya Notify: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: maya-notify <titre> <message> [icone]")
        sys.exit(1)
        
    title = sys.argv[1]
    body = sys.argv[2]
    icon = sys.argv[3] if len(sys.argv) > 3 else "🐝"
    
    if maya_notify(title, body, icon):
        print(f"✅ Message envoyé à Marc sur le bureau.")
    else:
        sys.exit(1)
