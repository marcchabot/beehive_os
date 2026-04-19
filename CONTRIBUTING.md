# Contributing to Bee-Hive OS 🐝

Thank you for your interest! Bee-Hive OS is an open-source Hyprland desktop environment built with Quickshell (Qt6/QML).

## Prerequisites

- **OS:** CachyOS (Arch Linux) + Hyprland
- **Runtime:** Quickshell (Qt6), Python 3.11+
- **Recommended:** kitty, fish, fastfetch, cava, swww

## One-Line Install (CachyOS)

```bash
git clone https://github.com/marcchabot/beehive_os.git && cd beehive_os && ./scripts/install_beehive_os.sh
```

## Repository Layout

```
beehive_os/
├── shell.qml              # Entry point (loads BeeHiveShell)
├── core/                  # Shell composition & startup wiring
│   └── BeeHiveShell.qml   # Main ShellRoot (panels, IPC, overlays)
├── modules/               # QML modules & singleton APIs
│   ├── qmldir             # Singleton registry (add new modules here)
│   ├── BeeConfig.qml      # Configuration singleton (user_config.json)
│   ├── BeeTheme.qml       # Theme engine (Nectar Sync, palette)
│   ├── BeeModuleRegistry.qml  # Module registration API
│   ├── BeeBar.qml         # Top bar (CPU/RAM/NET/DISK, tray)
│   ├── MayaDash.qml       # Hex-cell dashboard
│   ├── BeeStudio.qml      # Control center (cells, wallpapers, presets)
│   ├── BeeSearch.qml      # App launcher (fuzzy, .desktop scan)
│   ├── BeeNotes.qml       # Quick notes (PanelWindow + persistence)
│   ├── BeeNotify.qml      # Notification daemon
│   ├── BeeOSD.qml         # On-screen display (volume/brightness)
│   ├── BeePower.qml       # Power menu (shutdown/reboot/lock)
│   ├── BeeWeather.qml     # Weather widget (Open-Meteo)
│   ├── BeeNetwork.qml     # Network details
│   ├── BeeEvents.qml      # Calendar connector
│   ├── BeeWallpaper.qml   # Wallpaper engine + transitions
│   ├── BeeMotion2D.qml    # Parallax effect
│   ├── BeeVibe.qml        # Audio visualizer (Cava)
│   ├── BeeCorners.qml     # Fake screen rounding
│   ├── BeeSound.qml       # Sound effects
│   ├── BeeWelcome.qml     # First-run welcome screen
│   ├── BeePresets.qml     # Alvéole presets (Travail/Gaming/Weekend)
│   ├── BeeControl.qml     # Control center container (tabs)
│   ├── BeeApps.qml        # App data helpers
│   ├── BeeBarState.qml    # Bar state management
│   └── Clock.qml          # Analog clock
├── themes/                # Theme source files (JSON palettes)
├── i18n/                  # Localization
│   ├── fr.json            # French translations
│   └── en.json            # English translations
├── docs/                  # Roadmap, references, API specs
│   ├── ROADMAP.md         # Phase-based roadmap
│   ├── ROADMAP_V2.md      # Strategic roadmap (priorities)
│   ├── MODULE_API.md      # Module registration API spec
│   └── SPEC_BEEHIVE_EDITOR_V2.md  # BeeStudio v2 redesign spec
├── scripts/               # Runtime & tooling scripts
│   ├── install_beehive_os.sh   # Installer
│   ├── health-check.sh         # System diagnostic
│   ├── bee_theme_auto.py       # Auto-theme generator
│   └── ...                     # Various helpers
├── config/                # Hyprland, Kitty, Fish configs
├── data/                  # Runtime data (events.json, notes.txt)
├── assets/                # Wallpapers, icons
└── user_config.json       # User configuration (gitignored)
```

## Internal API Rule

Use `BeeModuleRegistry` to register new BeeBar/MayaDash modules.  
**Full specification:** `docs/MODULE_API.md`

Quick example:
```qml
BeeModuleRegistry.registerMayaDashModule({
    id: "my.feature",
    slot: 5,
    icon: "🧩",
    title: "My Feature",
    action: "app:myapp",
    source: "community"
})
```

## Adding a New Module (Checklist)

1. Create `modules/MyFeature.qml`
2. Add entry to `modules/qmldir`: `MyFeature 1.0 MyFeature.qml`
3. Register via `BeeModuleRegistry` in `Component.onCompleted`
4. Handle any new actions in `core/BeeHiveShell.qml` → `IpcHandler`
5. Add i18n keys to `i18n/fr.json` and `i18n/en.json`
6. Test with `QML_XHR_ALLOW_FILE_READ=1 quickshell -p ~/beehive_os`

## Localization (i18n)

All user-facing strings must go through `BeeConfig.tr`:

```qml
// In your module:
function tr(key) {
    if (!BeeConfig.tr || !BeeConfig.tr.myfeature) return ""
    return BeeConfig.tr.myfeature[key] || ""
}

Text { text: tr("welcome_message") }
```

Add corresponding keys to both `i18n/fr.json` and `i18n/en.json` under your module's namespace.

## Guardrails Before Commit

Validate at least one runtime path:

```bash
# Full shell test
QML_XHR_ALLOW_FILE_READ=1 quickshell -p ~/beehive_os

# SDDM theme only
sddm-greeter --test-mode --theme /usr/share/sddm/themes/beehive

# Health check (no launch)
./scripts/health-check.sh
```

## Debugging Tips

- **QML warnings in journal:** `journalctl --user -f | grep quickshell`
- **Reload without restart:** `hyprctl dispatch exit` (Hyprland re-spawns)
- **Theme issues:** Check `BeeTheme.nectarSync` + `BeeConfig.autoThemeStatus`
- **Module not appearing:** Verify `qmldir` entry + `pragma Singleton` in QML
- **i18n missing:** Ensure key exists in BOTH `fr.json` and `en.json`

## Pull Request Checklist

- [ ] Keep user preferences untouched (`user_config.json` compatibility)
- [ ] Update docs if API/paths changed
- [ ] Add i18n keys for all new user-facing strings
- [ ] No `.backup`/`.fixed` files committed
- [ ] Run `./scripts/health-check.sh` — all PASS
- [ ] Include validation command output summary in PR description

## Code Style

- **QML:** PascalCase for components, camelCase for properties/functions
- **Headers:** Each QML file gets a `═══` block header with name, version, description
- **Singletons:** Always use `pragma Singleton` + `QtObject` (not `Item`)
- **Colors:** Use `BeeTheme.*` properties — never hardcode colors
- **Strings:** Always via `tr()` — never hardcode French/English text

## Version Convention

- **Major:** Architecture changes, breaking API changes
- **Minor:** New features, new modules
- **Patch:** Bug fixes, i18n, documentation

---

*Bee-Hive OS is made with 🍯 by Marc & Maya.*