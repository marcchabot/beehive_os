import re

path = '/home/node/.openclaw/workspace/projects/beehive_os/modules/BeeControl.qml'
with open(path, 'r') as f:
    content = f.read()

target = '                    SectionHeader { title: "INDICATORS VISIBILITY" }'
replacement = '''                    SectionHeader { title: "CLOCK STYLE" }

                    SettingRow {
                        label: (BeeConfig.uiLang === "fr" ? "Horloge Analogique 🕰️" : "Analog Clock 🕰️")
                        desc: (BeeConfig.uiLang === "fr" ? "Utiliser le widget horloge sur le bureau (masque l'heure dans la barre)." : "Use the analog widget on the desktop (hides top bar clock).")
                        checked: BeeConfig.analogClock
                        onToggled: (val) => { BeeConfig.analogClock = val; BeeConfig.saveConfig(); BeeBarState.logAction("BeeBar", "Style Horloge: " + (val ? "Analogique" : "Digital"), "🕰️") }
                    }

                    Item { height: 10 }

                    SectionHeader { title: "INDICATORS VISIBILITY" }'''

content = content.replace(target, replacement)

with open(path, 'w') as f:
    f.write(content)
