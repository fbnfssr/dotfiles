# Workstation Philosophy

The reasoning behind this dotfiles repository and how it shapes workstation setup decisions.

---

## Purpose of this repository

This repository exists to rebuild a fully working development machine from a clean macOS install with minimal manual intervention. It is not a dotfiles showcase, a community project, or a theoretical exercise. It reflects a real production workflow — the tools, configurations, and scripts here are actively used, not aspirational.

The target audience is one person: the author. The standard for inclusion is daily use, not completeness. If something is in this repo, it is because removing it would break an actual workflow.

---

## Core principles

**Reproducibility over convenience.** The system must produce the same environment every time. A shortcut that works once but cannot be reliably repeated does not belong here. Every configuration is version-controlled and every script is idempotent.

**Clarity over cleverness.** Scripts are readable, not minimal. `symlinks.conf` is a flat file because a flat file is easy to audit. Shell functions are straightforward because the next reader (future self, under pressure, on a new machine) should not need to reverse-engineer intent.

**Explicit over implicit.** Managed files are listed in `symlinks.conf`. Dependencies are declared in `Brewfile`. Secrets are fetched at runtime from a known vault via a known script. Nothing relies on undocumented side effects or assumed state.

**Reliability over speed.** Scripts use `set -euo pipefail` and preflight checks. Existing files are backed up before being replaced. The system fails early with clear messages rather than proceeding into a broken state. A setup that takes five extra minutes but never silently corrupts configuration is better than one that is fast and fragile.

**Real usage over theoretical setups.** No tool, package, or script is added speculatively. Everything here has been used in practice. If a configuration has only been needed once and the workflow is not yet stable, it stays manual.

---

## What this system optimizes for

- **Fast onboarding on a new machine.** A clean macOS install reaches a working development environment through a documented, mostly automated sequence. The manual steps that remain are intentionally manual.
- **Predictable environment.** Every managed file comes from version control. There is one source of truth, and running the setup twice produces the same result.
- **Low cognitive load.** Adding a new dotfile means adding a line to `symlinks.conf`. Installing a package means adding it to `Brewfile`. The system is simple enough that decisions do not require re-reading scripts.
- **Alignment with actual daily workflow.** The tools installed, the shell configuration, the editor settings — all of it reflects what is used day to day. There is no separation between "my setup" and "my real environment."

---

## What this system avoids

- **Over-automation.** Not everything needs a script. macOS system preferences, application-specific settings, and one-time configurations are left manual until the cost of doing them by hand exceeds the cost of maintaining automation.
- **Unnecessary tools.** A smaller toolset is easier to maintain, upgrade, and debug. If two tools serve the same purpose, one is removed. If a tool was installed for a single project that ended, it gets cleaned out.
- **Fragile hacks.** No undocumented `defaults write` commands copied from the internet. No scripts that depend on parsing volatile output formats. No workarounds that break on the next macOS update.
- **Premature abstraction.** There is no plugin system, no templating engine, no multi-OS support layer. The repo targets one platform (macOS on Apple Silicon), one shell (zsh), one package manager (Homebrew). Abstraction would add complexity without solving a real problem.
- **Configuration drift.** Dotfiles live in the repo and are symlinked into place. Editing `~/.gitconfig` directly means editing the repo file. There is no sync mechanism because there is no copy — the symlink is the configuration.

---

## Automation philosophy

Not everything should be automated, and not everything should be automated immediately.

Automation in this repo follows a simple rule: **a task gets automated when it has been done manually enough times to be well understood, is stable enough to not change between runs, and is painful enough to justify the script.** If any of those conditions is missing, the task stays manual.

Manual steps are not a failure — they are a deliberate staging area. Installing Xcode is manual because it requires Apple account authentication and varies between machines. Configuring Bitwarden is manual because it involves biometric and vault setup that cannot be scripted. These are documented, not automated, because documentation is the right tool for steps that require human judgment.

The goal of automation here is to reduce cognitive load, not to achieve zero-touch setup. A bootstrap that handles packages, symlinks, and shell configuration while leaving three well-documented manual steps is better than a fragile script that tries to handle everything and fails unpredictably.

When automation is added, it is added incrementally. A new script starts small, handles one task, and is tested by actual use on a real machine. It is not designed for hypothetical scenarios.

---

## Tooling philosophy

Tools are selected based on how they fit into an existing workflow, not on popularity or novelty. The criteria:

- **Does it solve a problem I actually have?** A tool that addresses a theoretical need is not installed.
- **Does it replace something, or does it add to the pile?** Adding a tool should reduce total complexity, not increase it. If it overlaps with an existing tool, one of them goes.
- **Is it maintainable?** Tools with heavy configuration, frequent breaking changes, or unclear upgrade paths are avoided. Boring and stable beats exciting and volatile.

The CLI is the default interface for development tooling. GUI applications are used where they are genuinely better — a code editor, a password manager, a browser. The split is intentional, not ideological. Where a CLI tool and a GUI tool both work, the CLI is preferred because it is scriptable, composable, and version-controllable.

Consistency matters more than having the best tool in each category. A slightly worse tool that integrates cleanly with the rest of the system is better than an optimal tool that requires special handling.

---

## Evolution approach

This system evolves through use, not through planning sessions.

The cycle is: **set up a new machine → encounter friction → understand the friction → decide whether to fix it → fix it in the simplest way that works.** Most improvements come from real setup attempts, not from reviewing the repo in isolation.

Changes are incremental. A script gets a new check. A package gets added to `Brewfile`. A configuration gets extracted into `symlinks.conf`. There are no rewrites. The system has grown from a handful of files to its current state through small, motivated additions — each one triggered by a real need.

Features are not added speculatively. If a potential improvement has not caused friction yet, it waits. The backlog exists to capture ideas, not to create obligations. Many items on the backlog will never be implemented because the problem they describe will never become painful enough to justify the work.

The test for any change is simple: does this make the next machine setup faster, more reliable, or less error-prone? If the answer is not clearly yes, the change does not get made.
