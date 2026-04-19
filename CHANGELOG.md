# Changelog — Bee-Hive OS 🐝

All notable changes to Bee-Hive OS will be documented in this file.

---

## [0.8.8] — 2026-04-19

### Housekeeping & API Documentation 🧹

- **i18n autoThemeHint**: Replaced 8 hardcoded French strings in `BeeStudio.qml` with proper i18n keys (`autotheme_ok`, `autotheme_running`, `autotheme_error`, `autotheme_warn`, `autotheme_busy`, `autotheme_dedup`, `autotheme_disabled`, `autotheme_invalid`) in both `fr.json` and `en.json`. `refreshAutoThemeHint()` now uses dynamic key lookup.
- **Dev artefacts removed**: Deleted `BeeStudio.qml.backup` (76KB) and `BeeStudio.qml.fixed` (3KB) from `modules/`.
- **`.gitignore` hardened**: Added `*.backup`, `*.fixed`, `*.orig`, `*.rej`, `__pycache__/`, `*.pyc`, `*.pyo`, `user_config.json`, `data/events.json`, `data/notes.txt`, and private data patterns.
- **`docs/MODULE_API.md` completed**: Added full model roles reference tables, versioning policy (patch/minor/breaking), step-by-step external module registration guide, action contract table, and extensibility notes.
- **`CONTRIBUTING.md` enriched**: Added full repository layout with all 25+ modules documented, module creation checklist, i18n guidelines, debugging tips, code style conventions, and PR checklist.
- **VERSION bump**: `0.8.7` → `0.8.8`

---

## [0.8.7] — 2026-04-18

### Critical Bug Fix 🚨

- **BeePresets Crash Fix**: Fixed `Cannot assign to non-existent default property` error in `BeePresets.qml` that prevented the entire Bee-Hive OS shell from loading. The issue was `Connections` and `Component.onCompleted` child elements inside a `QtObject` singleton without a default property. Fixed by adding `pragma Singleton` directive and converting child elements to property declarations (`property Timer _initTimer`, `property Connections _configConn`).

### Alvéoles Drag & Drop Reorder 🎯

- **Long-press drag**: Long-press (500ms) on any alvéole in MayaDash to initiate drag mode. The source cell scales up with glow feedback.
- **Visual swap target**: Drop target cells highlight with an animated accent border and pulse effect during drag.
- **Opacity feedback**: Non-target cells dim during drag; target cell brightens.
- **Swap on drop**: Releasing over another alvéole swaps the two cells via `BeePresets.swapCells()`, persisted immediately to `user_config.json`.
- **BeePresets.moveCell() / swapCells()**: New API methods for programmatic cell reordering with automatic config persistence.
- **Drag hint**: Added "Maintenir appuyé sur une alvéole pour la déplacer" hint in BeeStudio Presets tab (i18n FR/EN).

### i18n
- Added `drag_hint` key to French and English locale files.

---

## [2.1.1] — 2026-04-16

### BeeNotes — Quick Notes Widget 📝

- **PanelWindow Migration**: BeeNotes migrated to a dedicated `PanelWindow` with `focusable: true` and `WlrLayer.Top`, providing proper keyboard focus and overlay behavior.
- **Close Button (✕)**: Added a close button in the header with hover animation (red highlight on hover).
- **Click-Outside-to-Close**: Semi-transparent overlay captures clicks outside the notes panel to dismiss it.
- **Text File Persistence**: Notes are persisted to `data/notes.txt` using a `Process`-based I/O approach (compatible with Qt6 XHR restrictions). Format: `timestamp|color|text` (one line per note).
- **UI Fix**: Corrected "Add Note" button overflow in the input area by adjusting layout constraints.
- **i18n**: All user-facing strings now use `BeeConfig.tr` for English/French localization.

### BeeBar

- **Icon Fallback Fix**: Improved `currentIcon` logic in `BeeBar.qml` to handle error states from the window tracker, ensuring the default bee icon 🐝 is shown instead of error text.

---

## [2.1.0] — 2026-03-25

### Persistence & Stability

- **Bug Fix**: Import `QtCore` to resolve `StandardPaths` reference error in `BeeConfig.qml`.
- **History Persistence**: Notification history (`BeeBarState.historyModel`) saved to `~/.cache/beehive_os/history.json`.
- **Framework Stability**: Improved singleton architecture and I/O error handling.

---

## [2.0.0] — 2026-03-21

### Multilingual Support (i18n)

- Full French/English localization via `i18n/fr.json` and `i18n/en.json`.
- `BeeConfig.tr` API for QML components with fallback strings.
- Language selector in BeeSettings.

### Public Launch (v1.3.7)

- Security & Privacy: `.gitignore` hardened, private data removed from tracking.
- Public template: `user_config.example.json` for new users.
- Nectar Sync v2: Decoupled data sync, live daemon + IPC.

---

## [1.0.0] — 2026-03-21

### Initial Release 🚀🍯

- BeeBar — CPU/RAM/NET/DISK + Stealth Mode
- BeeNotify — Stylized notifications
- BeeCorners — Fake Rounding engine
- BeeWallpaper — Fluid transitions + 4K Assets
- BeeSettings — Configuration interface
- BeeWeather — Universal weather without API key
- BeeEvents — Calendar connectors
- BeeMotion — 3D Parallax
- BeeStudio — Full visual editor
- BeeSearch — System scan + Favorites 📌
- BeeVibe — Cava audio visualizer
- BeePower — Power management ⚡
- BeeAura Notifications & OSD — 100% native Quickshell system
- Bee-Hive SDDM — Animated login screen