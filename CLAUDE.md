# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal macOS dotfiles for Apple Silicon. Scripts are Bash, targeting macOS with Homebrew. There is no build system, test suite, or linter.

This is the **personal baseline only**. Work-specific tooling, credentials, and SSH identities live in an external work bootstrap (`~/.work-bootstrap/`) and are not part of this repository.

## Architecture

All dotfile symlinks are driven by `symlinks.conf` (format: `relative/source:$HOME/destination`). Scripts read this file — it is the single source of truth for what gets linked and where.

Bootstrap flow: `bootstrap.sh` → `brew bundle` → `link-dotfiles.sh` → `setup-shell.sh`. Each script in `scripts/` can also run independently.

Secrets are stored in Bitwarden (personal). SSH keys are served by the Bitwarden SSH agent (configured in `.ssh/config` via host-specific `IdentityAgent`). AWS credentials for the personal `ff-digital` profile are fetched from Bitwarden by `setup-personal-secrets.sh` using the `bw` CLI.

Backups are timestamped snapshots in `~/.dotfiles-backup/<timestamp>/` preserving the original directory structure relative to `$HOME`.

Local overlay files (`~/.zshrc.local`, `~/.gitconfig.local`, `~/.ssh/config.local`) are unversioned and sourced/included automatically when present. They are managed by the work bootstrap, not this repo.

## Key commands

```bash
# Full bootstrap (new machine)
bash ~/dotfiles/scripts/bootstrap.sh

# Link dotfiles only (re-run after editing symlinks.conf)
bash ~/dotfiles/scripts/link-dotfiles.sh

# Verify personal machine readiness
bash ~/dotfiles/scripts/verify.sh

# Restore personal secrets via Bitwarden
bash ~/dotfiles/scripts/setup-personal-secrets.sh

# List backup snapshots
bash ~/dotfiles/scripts/list-backups.sh

# Install VS Code extensions
bash ~/dotfiles/scripts/setup-vscode.sh

# Finalize iOS/React Native environment (after Xcode install)
bash ~/dotfiles/scripts/setup-react-native.sh
```

## Conventions

- Scripts use `#!/usr/bin/env bash` with `set -euo pipefail`.
- `DOTFILES_DIR` defaults to `$HOME/dotfiles` and can be overridden via environment variable.
- When adding a new dotfile: add the source file to the repo, then add a `source:destination` line to `symlinks.conf`. No script changes needed.
- Homebrew packages go in `Brewfile`. After changes run `brew bundle dump --force --file=~/dotfiles/Brewfile`.
- Scripts must be idempotent — safe to re-run without side effects.
- Keep scripts POSIX-friendly where possible. Avoid clever Bash-isms.
- `.zshrc` uses NVM lazy-loading via function shims (`nvm`, `node`, `npm`, `npx`) to keep shell startup fast.
