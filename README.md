# 🐝 Bee-Hive OS

> Ambitious desktop environment (*ricing*) based on **Quickshell** (QML/Qt6) for **CachyOS + Hyprland**.
> "Nexus" aesthetic: honey yellow 🍯 on deep black, organic animations, glassmorphism, and "BeeAura" glow.

---

## 🏗️ Architecture

```
beehive_os/
├── shell.qml                 # Main entry point ShellRoot (Global UI)
├── theme.json                # Visual identity centralization
├── user_config.json          # Persistent user configuration
├── assets/                   # 4K wallpapers and graphical assets
└── modules/
    ├── BeeBar.qml            # Status bar (CPU, RAM, NET, DISK) + Stealth Mode
    ├── BeeBarState.qml       # Inter-window communication singleton
    ├── BeeApps.qml           # Application manager (Scan & Favorites)
    ├── BeeConfig.qml         # Config singleton (weather, dashboard, theme, persistence)
    ├── BeeNotify.qml         # "In-Shell" notification system
    ├── BeeWallpaper.qml      # Dynamic wallpaper manager
    ├── BeeWeather.qml        # Universal weather (Open-Meteo, no API key)
    ├── BeeEvents.qml         # Events connector (Calendar/Work)
    ├── BeeCorners.qml        # Organic screen corner rendering
    ├── BeeSettings.qml       # Configuration panel (GUI)
    ├── BeeStudio.qml         # Visual cell editor (Full persistence)
    ├── BeeSearch.qml         # Application launcher (Fuzzy search + Pins)
    ├── BeeVibe.qml           # Discreet audio visualizer (Cava integration)
    ├── BeePower.qml          # Power management (Shutdown, Reboot, Lock, Exit)
    ├── MayaDash.qml          # Hexagonal dashboard (Honeycomb)
    └── Clock.qml             # Analog + digital clock widget
```

---

## 📦 Modules

### BeeWeather — Universal Weather 🌦️ *(v0.6.3)*
- **No API Key**: Uses Open-Meteo for accurate weather data
- **Centralized Coordinates**: `BeeConfig.weatherLat/Lon`
- **Persistence**: City, unit, and language saved in `user_config.json`
- **Synchronized**: No more divergence between the widget and the BeeBar

### BeeAura Notifications & OSD 🔔 *(v1.0.0)*
- **100% Native**: Notification system and OSD (Volume/Brightness) integrated without external dependencies.
- **Zero Mouse Capture**: Uses the official `mask: Region {}` property for full click-through on transparent areas.
- **BeeNotify**: Full support for system notifications via `beenotifier.py`.
- **BeeOSD**: Elegant visual feedback for hardware (Razer Keyboard/Mouse).

### BeePower — Power Management ⚡ *(v1.0.0)*
- **BeeAura Interface**: Dedicated menu accessible via ⚡ in the BeeBar
- **System Actions**: Shutdown, Reboot, Logout, Lock

### BeeSearch — Application Launcher 🔍 *(v1.0.0)*
- **System Scan**: Parses `.desktop` files via Python
- **Favorites 📌**: Up to 4 pinned apps, persistent in `user_config.json`

### BeeVibe — Audio Visualizer 🎵 *(v0.8.4)*
- **Equalizer Bars** integrated at the bottom of each MayaDash cell
- **Cava Engine**: Captures system audio via Pipewire/Pulse

### BeeStudio — Visual Editor 🎨 *(v0.8.4)*
- **Live Editing**: Icons, titles, and cell actions with immediate preview
- **Persistence** directly in `user_config.json`

### Stealth Mode 🫥 *(v0.8.3)*
- **Auto-Hide**: BeeBar fades out after 3 seconds of inactivity
- **Sentinel**: Invisible window at the top detects mouse hover

### BeeMotion — 3D Parallax 🌊 *(v0.8.0)*
- 3D tilting of the MayaDash based on mouse position

### BeeBar — Status Bar ⚡
- CPU, RAM, NET, DISK in real-time
- Progress bars with animations and adaptive glow

### BeeEvents — Events Hub 📅 *(v0.7.0)*
- Centralizes calendar events and professional alerts

---

## 🍯 Honey-Sync — Live Calendar 📅 *(NEW)*

Bee-Hive OS includes **Honey-Sync**, a local script to fetch your Google Calendar events and display them in the MayaDash.

1. **Install `gog` CLI** (Google Workspace CLI):
   ```bash
   # Arch Linux / CachyOS (Recommended)
   yay -S gogcli
   
   # Or via Go
   go install github.com/steipete/gogcli/cmd/gog@latest
   ```
2. **Authorize `gog`** with your Google account:
   ```bash
   gog auth login
   ```
3. **Sync your nectar**:
   ```bash
   python3 scripts/honey_sync.py
   ```
4. (Optional) Add a cron job or systemd timer to sync every hour!

---

## 🎨 Design System — BeeAura (Nexus)

| Element       | Value                               |
|---------------|-------------------------------------|
| Primary Gold  | `#FFB81C` (Honey Gold)             |
| Dark Background| `rgba(0.05, 0.05, 0.07, 0.95)`     |
| Surface       | `rgba(255, 255, 255, 0.03)`         |
| Animations    | `Easing.InOutCubic` / `OutBack`    |

---

## 🚀 Usage

```bash
# Requirements: CachyOS + Hyprland + Quickshell (Qt6) + Cava + Python-DBus
QML_XHR_ALLOW_FILE_READ=1 quickshell -p ~/beehive_os
```

## 🛠️ Installation

For an automatic installation on CachyOS:

```bash
cd ~/beehive_os
chmod +x scripts/install_beehive_os.sh
./scripts/install_beehive_os.sh
```

---

## 📜 License

This project is licensed under the **MIT** license. See the [LICENSE](LICENSE) file for details.

---

### 🐝 Updating the Hive
To update without losing your personal settings (cells, weather, pinned apps):
1. `git pull`
2. `python3 scripts/bee_config_merge.py`
3. Restart the hive: `qs ipc call root restart` (or restart Quickshell)

---

## 📋 Roadmap

### ✅ Completed

- [x] BeeBar — CPU/RAM/NET/DISK + Stealth Mode
- [x] BeeNotify — Stylized notifications
- [x] BeeCorners — Fake Rounding engine
- [x] BeeWallpaper — Fluid transitions + 4K Assets
- [x] BeeSettings — Configuration interface
- [x] BeeWeather — Universal weather without API key (v0.6.1)
- [x] BeeEvents — Calendar connectors (v0.7.0)
- [x] BeeMotion — 3D Parallax (v0.8.0)
- [x] BeeStudio — Full visual editor (v0.8.4)
- [x] BeeSearch — System scan + Favorites 📌 (v0.8.4)
- [x] BeeVibe — Cava audio visualizer (v0.8.4)
- [x] Stealth Mode — Auto-hide with sentinel (v0.8.3)
- [x] BeePower — Power management ⚡ (v0.8.5)
- [x] **BeeAura Notifications & OSD** — 100% native Quickshell system (v0.8.6)
- [x] Nectar Sync 🍯 — Automatic theme adaptation to wallpaper (v0.6.2)

### 🔄 In Progress / Upcoming

- [ ] Bee-Hive sound effects (discreet and elegant)
- [ ] "Focus" Mode vs "Dashboard" Mode
- [ ] Performance optimization (Quickshell profiling)
- [ ] Persistent notifications widget
- [ ] Multilingual Support (i18n)

---

## 🐝 Credits

Developed with love by **Maya** 🐝✨ & **Marc**.

*"The hive never sleeps, it optimizes."* 🍯🚀
