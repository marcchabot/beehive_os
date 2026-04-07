import re

path = './core/BeeHiveShell.qml'
with open(path, 'r') as f:
    content = f.read()

new_reserve = '''    // ─── Réserve d'espace pour la BeeBar ─────────────
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            required property var modelData
            screen: modelData
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "beehive-bar-reserve"
            exclusiveZone: 45
            focusable: false
            anchors { top: true; left: true; right: true }
            implicitHeight: 45
            color: "transparent"
        }
    }

    // Widgets Background'''

content = content.replace('    // Widgets Background', new_reserve)

with open(path, 'w') as f:
    f.write(content)
