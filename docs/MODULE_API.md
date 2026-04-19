# Bee-Hive OS Internal Module API (BeeBar / MayaDash)

This document defines the **stable internal registration API** used by external or future modules.

**API Version:** 1  
**Singleton:** `modules/BeeModuleRegistry.qml`  
**Since:** v0.8.4 (March 2026)

---

## API Surface

| Method | Description |
|--------|-------------|
| `registerBeeBarModule(spec)` | Register a BeeBar module (icon in top bar) |
| `registerMayaDashModule(spec)` | Register a MayaDash alvéole (hex cell on dashboard) |
| `unregisterModule(id)` | Remove a module from both registries |
| `clearAll()` | Reset all registrations |
| `mayaDashCellAt(slot)` | Get the enabled cell at a given slot (0–7) |

| Property | Type | Description |
|----------|------|-------------|
| `apiVersion` | `int` (readonly) | Always `1` — bump on breaking changes |
| `mayaDashSlots` | `int` (readonly) | Total MayaDash slots (`8`) |
| `beeBarModules` | `ListModel` | All registered BeeBar entries |
| `mayaDashModules` | `ListModel` | All registered MayaDash entries |

---

## BeeBar Registration

**Required field:**
- `id` (unique string)

**Optional fields:**
- `title` (default: `id`)
- `icon` (default: `🐝`)
- `action` (default: `none`)
- `order` (default: `100`)
- `enabled` (default: `true`)
- `source` (default: `internal`)

**Example:**
```qml
BeeModuleRegistry.registerBeeBarModule({
    id: "docs.quicklink",
    title: "Docs",
    icon: "📘",
    action: "url:https://github.com/marcchabot/beehive_os",
    order: 40,
    source: "community"
})
```

---

## MayaDash Registration

**Required fields:**
- `id` (unique string)
- `slot` (`0..7`)

**Optional fields:**
- `title` (default: `id`)
- `subtitle` (default: `""`)
- `icon` (default: `🐝`)
- `detail` (default: `""`)
- `action` (default: `none`)
- `highlighted` (default: `false`)
- `order` (default: same as `slot`)
- `enabled` (default: `true`)
- `source` (default: `internal`)

**Example:**
```qml
BeeModuleRegistry.registerMayaDashModule({
    id: "ops.status",
    slot: 6,
    icon: "🛰",
    title: "Ops",
    subtitle: "Health",
    detail: "Cluster nominal",
    action: "app:kitty",
    highlighted: true,
    source: "community"
})
```

---

## Action Contract

All actions follow a `type:value` pattern. Both registries share the same contract.

| Action | Format | Description |
|--------|--------|-------------|
| No-op | `none` | Clicking does nothing |
| Toggle | `toggle:<target>` | Toggle UI panel (`settings`, `studio`, `dash`, `power`, `theme`, `focus`, `notes`) |
| Launch app | `app:<desktop-id>` | Launch via `gtk-launch` or `.desktop` file ID |
| Run shell | `shell:<command>` | Execute a shell command (use sparingly) |
| Open URL | `url:<https://...>` | Open in default browser |

**Extensibility:** Custom action prefixes can be added by extending the `IpcHandler` in `core/BeeHiveShell.qml`. New prefixes MUST be documented here.

---

## How to Register an External Module

### Step 1: Create your QML module

Place it under `modules/` and add the singleton entry to `modules/qmldir`:

```
MyModule    1.0 MyModule.qml
```

### Step 2: Register with BeeModuleRegistry

In `Component.onCompleted`, call the appropriate registration:

```qml
// modules/MyModule.qml
pragma Singleton
import QtQuick

QtObject {
    Component.onCompleted: {
        BeeModuleRegistry.registerBeeBarModule({
            id: "mymodule.entry",
            title: "My Module",
            icon: "🧩",
            action: "toggle:mymodule",
            order: 50,
            source: "community"
        })
    }
}
```

### Step 3: Import in shell

Add `import './modules'` (already done) — Quickshell auto-discovers singletons via `qmldir`.

### Step 4: Handle the action (if custom)

Add a case in `core/BeeHiveShell.qml` → `IpcHandler` or `BeePower.onActionRequested` for your custom action prefix.

---

## Versioning Policy

- **Patch changes** (non-breaking): New optional fields, new action types → no `apiVersion` bump.
- **Minor changes** (backward-compatible): New registration methods, new model roles → bump `apiVersion`.
- **Breaking changes** (incompatible): Remove/rename required fields, change defaults → major version bump + migration guide.

When `apiVersion` is bumped, `BeeModuleRegistry` will emit a `console.warn` if a module registers with an older expected version.

---

## Stability Guarantees

- Re-registering the same `id` updates in place (no duplicates).
- Ordering is deterministic (`order` ascending, then `moduleId` alphabetically).
- Invalid MayaDash slots (outside 0–7) are rejected with a `console.warn`.
- Unknown actions are ignored with a warning (no crash).
- `mayaDashCellAt()` returns `null` for empty/disabled slots.
- All text fields are sanitized (null → empty string, trimmed).

---

## Model Roles Reference

### `beeBarModules` ListModel roles

| Role | Type | Default |
|------|------|---------|
| `moduleId` | string | (required) |
| `title` | string | `moduleId` |
| `icon` | string | `🐝` |
| `action` | string | `none` |
| `order` | int | `100` |
| `enabled` | bool | `true` |
| `source` | string | `internal` |

### `mayaDashModules` ListModel roles

| Role | Type | Default |
|------|------|---------|
| `moduleId` | string | (required) |
| `slot` | int | (required, 0–7) |
| `title` | string | `moduleId` |
| `subtitle` | string | `""` |
| `icon` | string | `🐝` |
| `detail` | string | `""` |
| `action` | string | `none` |
| `highlighted` | bool | `false` |
| `order` | int | same as `slot` |
| `enabled` | bool | `true` |
| `source` | string | `internal` |