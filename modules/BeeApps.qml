pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// ═══════════════════════════════════════════════════════════════
// BeeApps.qml — Application pool scanned at startup
// Shared singleton: launches Python scan once at boot
// BeeSearch reads BeeApps.pool as soon as it's ready.
// ═══════════════════════════════════════════════════════════════
QtObject {
    id: root

    // true during scan, false once finished
    property bool  scanning: false

    // Complete pool once scan is done
    property var   pool: []

    // ─── Favorites (max 4, persisted via BeeConfig) ────────────
    property var pinnedCmds: BeeConfig.pinnedApps
    onPinnedCmdsChanged: console.log("BeeApps: pinnedCmds synced from BeeConfig →", JSON.stringify(pinnedCmds))

    function pin(cmd) {
        if (pinnedCmds.length >= 4) return
        var arr = pinnedCmds.slice()
        arr.push(cmd)
        BeeConfig.pinnedApps = arr
        console.log("BeeApps: pin requested for", cmd)
        BeeConfig.saveConfig()
    }

    function unpin(cmd) {
        var arr = pinnedCmds.filter(function(c) { return c !== cmd })
        BeeConfig.pinnedApps = arr
        console.log("BeeApps: unpin requested for", cmd)
        BeeConfig.saveConfig()
    }

    // Removed redundant local save functions
    // (Centralized in BeeConfig)

    // ─── .desktop category → emoji mapping ────────────────────
    function _iconFor(cat) {
        var c = (cat || "").toLowerCase()
        var rules = [
            [["internet", "web", "browser"],                      "🌐"],
            [["game", "gaming", "emulator"],                      "🎮"],
            [["audio", "music", "sound", "midi", "mixer"],        "🎵"],
            [["video", "multimedia", "dvd", "player"],            "🎬"],
            [["development", "ide", "debugger", "building"],      "📝"],
            [["filemanager", "filetools"],                         "📁"],
            [["graphics", "image", "photography", "viewer"],      "🎨"],
            [["office", "wordprocessor", "spreadsheet", "presentation", "calendar"], "📊"],
            [["security", "password", "encryption"],              "🔐"],
            [["chat", "instantmessaging", "social"],              "💬"],
            [["email", "mail", "news"],                           "📧"],
            [["science", "education", "math"],                    "🔬"],
            [["terminal", "consoleonly"],                          "💻"],
            [["settings", "configuration", "preferences"],        "⚙️"],
            [["cloud", "network", "remote"],                      "☁️"],
            [["system", "monitor", "utility", "archiving"],       "⚙️"]
        ]
        for (var i = 0; i < rules.length; i++) {
            for (var j = 0; j < rules[i][0].length; j++) {
                if (c.indexOf(rules[i][0][j]) !== -1) return rules[i][1]
            }
        }
        return "📦"
    }

    // ─── BeeHive static apps (always at the top) ──────────────
    readonly property var _staticApps: [
        { icon: "🐝", name: "BeeHive Settings", cmd: "__settings__", cat: "BeeHive" },
        { icon: "🎨", name: "BeeStudio",          cmd: "__studio__",   cat: "BeeHive" }
    ]

    // ─── Python script: scan .desktop files ───────────
    readonly property string _scanCmd:
        "python3 << 'PYEOF'\n" +
        "import os,json,glob,configparser,re\n" +
        "apps=[]\n" +
        "seen=set()\n" +
        "dirs=['/usr/share/applications',os.path.expanduser('~/.local/share/applications')]\n" +
        "paths=[p for d in dirs for p in glob.glob(d+'/*.desktop')]\n" +
        "for p in paths:\n" +
        "  try:\n" +
        "    c=configparser.ConfigParser(strict=False,interpolation=None)\n" +
        "    c.read(p,encoding='utf-8')\n" +
        "    if 'Desktop Entry' not in c:continue\n" +
        "    e=c['Desktop Entry']\n" +
        "    n=e.get('name','')\n" +
        "    if not n or n.lower() in seen:continue\n" +
        "    if e.get('nodisplay','false').lower()=='true':continue\n" +
        "    if e.get('hidden','false').lower()=='true':continue\n" +
        "    x=e.get('exec','')\n" +
        "    if not x:continue\n" +
        "    # Smart cleanup of %u, %U, %f, etc. parameters (including --uri= style flags)\n" +
        "    x=re.sub(r' [^ ]*=[uUfFdDnNickvm% ]+', '', x)\n" +
        "    x=re.sub(r' ?%[uUfFdDnNickvm]', '', x).strip()\n" +
        "    # Correction Ozone pour Spotify sur Wayland\n" +
        "    if 'spotify' in p.lower():\n" +
        "        x = 'spotify --enable-features=UseOzonePlatform --ozone-platform=wayland'\n" +
        "    cat=e.get('categories','').split(';')[0]\n" +
        "    if e.get('terminal','false').lower()=='true':x='kitty -e '+x\n" +
        "    apps.append({'name':n,'cmd':x,'cat':cat})\n" +
        "    seen.add(n.lower())\n" +
        "  except:pass\n" +
        "apps.sort(key=lambda a:a['name'].lower())\n" +
        "for a in apps:print(json.dumps(a))\n" +
        "PYEOF"

    property var _scanned: []

    property Process _scanProc: Process {
        id: _proc
        running: false
        command: ["bash", "-c", root._scanCmd]
        stdout: SplitParser {
            onRead: data => {
                var s = (data || "").trim()
                if (!s) return
                try {
                    var o = JSON.parse(s)
                    if (o && o.name && o.cmd)
                        root._scanned.push({
                            icon: root._iconFor(o.cat),
                            name: o.name,
                            cmd:  o.cmd,
                            cat:  o.cat || "Application"
                        })
                } catch(e) {}
            }
        }
        onExited: {
            // Merge: BeeHive apps first, then scanned apps
            var merged = root._staticApps.slice()
            var seen = {}
            root._staticApps.forEach(function(a) { seen[a.name.toLowerCase()] = true })
            root._scanned.forEach(function(a) {
                if (!seen[a.name.toLowerCase()]) {
                    merged.push(a)
                    seen[a.name.toLowerCase()] = true
                }
            })
            root.pool     = merged
            root._scanned = []
            root.scanning = false
            console.log("BeeApps: scan complete —", root.pool.length, "applications found")
        }
    }

    // ─── Start at Quickshell boot ──────────────────────────────
    Component.onCompleted: {
        scanning = true
        pool = _staticApps.slice() // Minimal pool available immediately
        _proc.running = true
    }
}
true
    }
}
}
}

}
}
