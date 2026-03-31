# Bootstrap Evolution

Backlog of improvements for the dotfiles/bootstrap system. Forward-looking only — not a usage guide or setup checklist.

---

## Purpose

This document tracks what is missing from the current bootstrap system and guides its evolution toward a fully reproducible workstation setup.

The goal is incremental improvement based on real friction, not speculative automation. Every item here should solve a problem that has been encountered in practice or that blocks reproducibility.

---

## Medium priority

### VS Code CLI setup

Improve `setup-vscode.sh`:

- Detect whether `code` CLI is available on `$PATH`
- Handle the symlink setup for the CLI tool if missing
- Separate extension installation from CLI setup

---

## Low priority / optional

### Brewfile segmentation

Split `Brewfile` into logical groups:

- `Brewfile.core` — essential tools (git, zsh, coreutils)
- `Brewfile.dev` — development tooling (node, python, docker)
- `Brewfile.personal` — personal apps (browsers, media)
- `Brewfile.optional` — situational installs

### Lightweight Android SDK setup

Install Android SDK components without Android Studio:

- `sdkmanager`, `platform-tools`, `build-tools`
- Set `ANDROID_HOME` in shell config
- Only if React Native / mobile development is active

### Workstation bootstrap layer

Optional personal layer on top of dotfiles bootstrap:

- Create standard directory structure (`~/projects`, `~/sandbox`, etc.)
- Clone frequently used personal repositories
- Keep it separate from core bootstrap and from the work bootstrap

### Backup restore tooling

Add a `restore-backup.sh` script:

- List available snapshots
- Restore a specific snapshot by timestamp
- Dry-run mode before overwriting current files

---

## Non-goals

- **No overengineering.** Do not build frameworks, plugin systems, or abstraction layers.
- **No premature automation.** Do not script something that has only been done once.
- **No tools without usage.** Do not add packages, configs, or integrations that are not actively used.
- **No hypothetical optimization.** Do not optimize workflows that do not yet exist.

If an improvement requires more scaffolding than the problem it solves, it does not belong here.

---

## Evolution rule

An improvement should only be automated when all three conditions are met:

1. **It has been done manually** — the task is understood from direct experience.
2. **It is stable and repeatable** — the steps do not change between runs.
3. **Automation adds real value** — scripting it saves meaningful time or prevents real errors.

If any condition is not met, leave it manual.
