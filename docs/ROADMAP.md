# Bee-Hive OS Roadmap 🐝🚀

The goal was a mind-blowing launch the weekend of March 20-21, 2026.

## 📅 Production Schedule

### Phase 1: Foundations & UI (March 12 - 14) - COMPLETED
- [x] Git & GitHub Initialization
- [x] Visual Concept (BeeAura, Black/Gold Theme)
- [x] 4K Wallpaper (Dark) - *wallpaper_dark_bee.png*
- [x] Wallpaper Collection (Light & Dark) via nano-banana
- [x] Quickshell Structure (BeeBar, MayaDash)
- [x] Real system widgets (CPU/RAM/Net/Disk) - *BeeBar updated*
- [x] BeeWallpaper Engine: Animated switcher with transition (1.5s)

### Phase 2: Contextual Integration & Framework Modularity (March 15 - 17) - COMPLETED (v0.7.0)
- [x] **BeePalette Engine**: Fluid transitions `lerpColor()` + pulsing BeeAura glow — *BeeTheme.qml v0.5*.
- [x] **BeeConfig System**: `user_config.json` v1.1 — cell customization, transitions, framework metadata — *BeeConfig.qml v0.5*.
- [x] **Universal Weather**: `BeeWeather.qml` module integrated into the `BeeBar`. Open-Meteo support (No Key) — *v0.6.1*.
- [x] **BeeEvents Connectors**: Google Calendar (Noah/Johanne) and Pharmacy integration to MayaDash — *v0.7.0*.
- [x] BeeAura notification system (organic animations) - *BeeNotify.qml operational*.
- [ ] ~~Multi-monitor support~~ (Put on hold March 15 - Unavailable on Marc's setup).

### Phase 3: Refinement & "Wow Factor" (March 18 - 20) - COMPLETED (v1.0.0) 🐝🛡️
- [x] **BeeSettings**: Graphical User Interface (GUI) to configure the OS (Toggles implemented)
- [x] **BeeCorners**: Rounded screen corners (Fake Rounding) - *BeeCorners.qml ready*
- [x] **BeeMotion**: 3D parallax effect on the MayaDash (v0.8.0)
- [x] **BeeStudio Full**: Full visual editor with real saving — *v0.8.4 (March 17)*
- [x] **BeeSearch**: Application launcher (Fuzzy search, real .desktop scan, Favorites 📌) — *v0.8.4 (March 17)*
- [x] **BeeVibe**: Pipewire/Cava audio visualizer integrated into cells — *v0.8.4 (March 17)*
- [x] **Stealth Mode**: Auto-hiding BeeBar with sentinel trigger zone — *v0.8.3 (March 17)*
- [x] **BeePower**: Power management (⚡, Shutdown, Reboot, Lock) — *v0.8.5 (March 17)*
- [x] **BeeAura Notifications & OSD**: 100% native Quickshell notifications and OSD (Volume/Brightness) — *v0.8.6 (March 19)*
- [x] **Bee-Hive SDDM**: Animated login screen (Hexa-Neon and Cyber-Bee variants) — *v0.2.7 (March 19)*
- [ ] **Bee-Hive sound effects** (discreet and elegant) — *Postponed after launch*
- [x] **Performance Optimization & Mouse Fix** (Official `mask: Region {}` solution) — *v1.0.0 (March 20)*
- [x] **Focus Mode 🎯**: Focus/Dashboard toggle via BeeSettings + IPC — *v0.9.0 (March 20)*
- [x] **Final tests on CachyOS (Marc)**: TOTAL STABILITY! 🚀🍯

### Launch: March 21 🚀🍯
- Final presentation and full deployment — **SUCCESSFULLY COMPLETED (v1.0.0)**. 🎉

### Phase 4: Preparation for Public Launch (March 21 Sprint — v1.3.7) 🐝🌍🚀
- [x] **Security & Privacy**: Strict `.gitignore` — `client_secret.json`, `google_access.json`, `GATEWAY_TOKEN.txt`, `pending_messages.json` removed from Git tracking. Private data protected. *(v1.3.7 — March 21)*
- [x] **Public Template**: `user_config.example.json` created — anonymized data (FR/EN), ready for new users. *(v1.3.7 — March 21)*
- [x] **i18n — Core Structure**: `i18n/` folder created with `fr.json` and `en.json` files. `qsTr()` integration plan documented. *(v1.3.7 — March 21)*
- [x] **i18n (Full)**: `qsTr()` integration in all QML files + language selector in BeeSettings.
- [x] **Bee-Live Sync v2**: Decouple data synchronization from the Git flow; implement live daemon + IPC for real-time calendar updates.
- [x] **"General Public" Documentation**: New `README.md` with a one-line installation guide for CachyOS.

---

### 🌱 Post-Launch Ideas (v1.1+)
- **Multilingual Support (i18n)**: Full internationalization (FR/EN) for global distribution. *(Completed in Phase 4!)*
- **BeeVibe Colors**: Customize equalizer bar colors per cell (single color, gradient, or synchronized with the cell theme). Marc's idea — March 17, 2026.
- **BeeStudio Advanced**: Add/remove cells + layout choice.
- **Multi-config**: `my_config.json` file that overrides `user_config.json` to facilitate community updates.

---

### Phase 5: Persistence & Stability (March 25 Sprint — v2.1.0) 🐝🛡️📜
- [x] **Bug Fix**: Import `QtCore` to resolve `StandardPaths` reference error in `BeeConfig.qml`.
- [x] **History Persistence**: Notification history (`BeeBarState.historyModel`) is now saved to `~/.cache/beehive_os/history.json`.
- [x] **Framework Stability**: Improved singleton architecture and I/O error handling.
- [x] **BeeNotes PanelWindow**: Migrated to separate PanelWindow (focusable: true, WlrLayer.Top) with ✕ close button, overlay click-outside-to-close.
- [x] **BeeNotes Persistence**: Notes saved to `data/notes.txt` (timestamp|color|text format, Process-based I/O for Qt6 compatibility).
- [x] **BeeNotes UI Fix**: Corrected "Add Note" button overflow in input area.

---
---
*Maya's Note: Every day at 08:30, I launch a "Reflection Sprint" to evaluate progress and plan the day's tasks. Current version: **v2.1.0** (March 25, 2026).*
