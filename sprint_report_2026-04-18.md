# Sprint Report — 2026-04-18 🐝

**Bee-Hive OS v0.8.7** | Commit: `9ab838b` → `148e686`

---

## 🚨 Critical Bug Fix

### BeePresets Singleton Crash — ENTIRE SHELL BROKEN
- **Issue**: `BeePresets.qml` had `Connections` and `Component.onCompleted` as child elements inside a `QtObject` without `pragma Singleton` or a `default property`. This caused `Cannot assign to non-existent default property` error at QML engine level.
- **Impact**: **The entire Bee-Hive OS shell failed to load.** Every single component (BeeHiveShell → BeeWallpaper → BeeApps → BeeBarState → BeeConfig → BeeModuleRegistry → BeePresets) was unavailable in a cascading chain failure.
- **Fix**: 
  1. Added `pragma Singleton` directive (was declared in `qmldir` but missing from the QML file).
  2. Converted `Connections { target: BeeConfig }` to `property Connections _configConn: Connections { ... }`.
  3. Converted `Component.onCompleted` to `property Timer _initTimer: Timer { interval: 50; running: true; repeat: false }`.
- **Validation**: `quickshell -p` offscreen test now resolves full component chain. Only remaining error is `No PanelWindow backend` (expected: no Wayland compositor in sandbox).

---

## ✨ New Feature: Drag & Drop Alvéole Reorder

### MayaDash — Long-press Drag & Swap
- **Trigger**: Long-press (500ms) on any alvéole cell initiates drag mode.
- **Visual Feedback**:
  - Source cell: scales to 1.10x with full glow intensity.
  - Target cell: animated accent border (3px, pulse animation).
  - Non-target cells: dimmed to 0.45 opacity; target brightens to 0.7.
  - Cursor changes: `ClosedHandCursor` on source, `OpenHandCursor` on targets.
- **Swap Logic**: Releasing over another cell calls `BeePresets.swapCells(from, to)` which swaps all cell properties in-place via `setProperty()`, increments `cellsRevision`, and auto-saves to `user_config.json`.
- **Hit-Testing**: New `cellIndexAt(globalX, globalY)` method maps mouse coordinates through `mapFromItem()` for precise cell identification across the hexagonal grid layout.
- **Cell References**: `hexGrid.cellRefs[0..7]` populated via `Component.onCompleted` on each `HexCell` for O(1) lookup.

### BeePresets — New API
- `swapCells(indexA, indexB)`: Swap two cells in-place with auto-save.
- `moveCell(fromIndex, toIndex)`: Remove and re-insert at target position with auto-save.

### BeeStudio — Presets Tab
- Added drag hint text below "Current Grid" label.
- i18n: `drag_hint` = "Maintenir appuyé sur une alvéole pour la déplacer" (FR) / "Long-press an alvéole to drag and reorder" (EN).

---

## 📋 ROADMAP Update

- **Alvéoles Presets**: 🔧 EN COURS → ✅ Complete (all 6 sub-items done, including drag & drop).
- **Next priorities**: Animations & Transitions Polish (cross-fade wallpapers, dynamic blur BeeStudio, Stealth Mode lissé).

---

## 🔢 Metrics

| Item | Value |
|------|-------|
| Version | 0.8.6 → **0.8.7** |
| Commits | 2 (`9ab838b`, `148e686`) |
| Files Changed | 8 (+.gitignore) |
| Lines Added | +251 |
| Lines Removed | -30 |
| Critical Bugs Fixed | 1 (shell-crashing) |
| New Features | 1 (drag & drop reorder) |
| i18n Keys Added | 1 (`drag_hint`) |

---

## ⏭️ Next Sprint Priorities

1. **Animations & Transitions Polish** (cross-fade wallpapers, dynamic blur BeeStudio, Stealth Mode ultra-lisse)
2. **System Monitor avancé** (temperatures, fans, process list in MayaDash detail)
3. **BeeBarState windowProc re-enablement** (currently commented out — active window class tracking)

---

*Maya l'abeille 🐝✨*