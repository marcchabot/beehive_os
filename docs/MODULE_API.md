# Bee-Hive OS Internal Module API (BeeBar / MayaDash)

This document defines the stable internal registration API used by external or future modules.

## API Surface

`modules/BeeModuleRegistry.qml` (singleton)

- `apiVersion: 1`
- `registerBeeBarModule(spec)`
- `registerMayaDashModule(spec)`
- `unregisterModule(id)`
- `clearAll()`
- `mayaDashCellAt(slot)`

## BeeBar Registration

Required field:
- `id` (unique string)

Optional fields:
- `title` (default: `id`)
- `icon` (default: `🐝`)
- `action` (default: `none`)
- `order` (default: `100`)
- `enabled` (default: `true`)
- `source` (default: `internal`)

Example:

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

## MayaDash Registration

Required fields:
- `id` (unique string)
- `slot` (`0..7`)

Optional fields:
- `title`, `subtitle`, `icon`, `detail`
- `action` (default: `none`)
- `highlighted` (default: `false`)
- `order` (default: `slot`)
- `enabled` (default: `true`)
- `source` (default: `internal`)

Example:

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

## Action Contract

Recognized actions (BeeBar + MayaDash):

- `none`
- `toggle:settings`
- `toggle:studio`
- `toggle:dash`
- `toggle:power`
- `toggle:theme`
- `app:<desktop-id-or-command>`
- `shell:<shell command>`
- `url:<https://...>`

## Stability Guarantees (Phase 2)

- Re-registering the same `id` updates in place (no duplicates).
- Ordering is deterministic (`order`, then `id`).
- Invalid MayaDash slots are rejected.
- Unknown actions are ignored with a warning (no crash).
