# Contributing to Bee-Hive OS

## Prerequisites

- CachyOS + Hyprland
- Quickshell (Qt6), Python 3

## One-Line Install (CachyOS)

```bash
git clone https://github.com/marcchabot/beehive_os.git && cd beehive_os && ./scripts/install_beehive_os.sh
```

## Repository Layout (Phase 2)

- `core/`: shell composition and startup wiring
- `modules/`: QML modules and singleton APIs
- `themes/`: theme source files
- `docs/`: roadmap, references, internal API docs
- `scripts/`: runtime and tooling scripts

## Internal API Rule

Use `BeeModuleRegistry` to register new BeeBar/MayaDash modules.
Specification: `docs/MODULE_API.md`.

## Guardrails Before Commit

Validate at least one runtime path:

```bash
QML_XHR_ALLOW_FILE_READ=1 quickshell -p ~/beehive_os
```

or (SDDM theme work only):

```bash
sddm-greeter --test-mode --theme /usr/share/sddm/themes/beehive
```

## Pull Request Checklist

- Keep user preferences untouched (`user_config.json` compatibility)
- Update docs if API/paths changed
- Include validation command output summary in PR description
