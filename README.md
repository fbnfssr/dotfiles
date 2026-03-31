# dotfiles

Personal macOS baseline. This repository is the **personal layer only** — it does not include work tooling, work credentials, or employer-specific configuration.

Work setup is handled separately by an external work bootstrap (see [Work setup](#work-setup)).

## Files managed by this repository

- `Brewfile`
- `.zshrc`
- `.p10k.zsh`
- `.gitconfig`
- `.gitignore_global`
- `.ssh/config`
- `claude/settings.json`
- `claude/skills/`
- `vscode/settings.json`
- `vscode/keybindings.json`
- `vscode/extensions.txt`
- `gh/config.yml`
- `symlinks.conf`
- `scripts/bootstrap.sh`
- `scripts/link-dotfiles.sh`
- `scripts/setup-shell.sh`
- `scripts/setup-react-native.sh`
- `scripts/verify.sh`
- `scripts/list-backups.sh`
- `scripts/setup-personal-secrets.sh`
- `scripts/macos.sh`

## Full setup (new machine)

Run every step in order.

### 1) Install Xcode Command Line Tools
```bash
xcode-select --install
```

### 2) Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 3) Clone this repository
Clone via HTTPS — SSH keys are not available yet on a fresh machine.
```bash
git clone https://github.com/fbnfssr/dotfiles.git ~/dotfiles
```

### 4) Run bootstrap
```bash
bash ~/dotfiles/scripts/bootstrap.sh
```

### 5) Configure Bitwarden
Bitwarden Desktop is installed by the Brewfile (via Homebrew cask, not the Mac App Store — the two use different SSH agent socket paths; this repo is configured for the Homebrew install). Open it, then:
- If using the EU vault: `bw config server https://vault.bitwarden.eu`
- Sign in to your personal account
- Go to **Settings → SSH Agent → Enable**

Personal SSH keys must be stored in your Bitwarden vault as SSH Key items. The `.ssh/config` is configured to use the Bitwarden SSH agent at `~/.bitwarden-ssh-agent.sock` — no key files on disk needed.

### 6) Restore personal secrets
```bash
bash ~/dotfiles/scripts/setup-personal-secrets.sh
```
This script:
- Unlocks the Bitwarden vault via `bw`
- Generates `~/.aws/config` with the personal `ff-digital` profile
- Fetches AWS credentials from Bitwarden and writes `~/.aws/credentials`
- Validates the Bitwarden SSH agent and tests `github-perso` SSH connectivity

### 7) Authenticate GitHub CLI
```bash
gh auth login
```

### 8) Switch remote to SSH
```bash
git -C ~/dotfiles remote set-url origin git@github-perso:fbnfssr/dotfiles.git
```

### 9) Restart shell and verify
```bash
exec zsh
bash ~/dotfiles/scripts/verify.sh
```

## 10) macOS preferences

Apply system preferences (Dock, Finder, keyboard, trackpad, screenshots, Mission Control):

```bash
bash ~/dotfiles/scripts/macos.sh
```

Review the script before running — it sets opinionated defaults. Some changes require a logout/restart.

## Local overlay files

These files are unversioned and machine-specific. They are sourced/included automatically when present:

| File | Purpose | Who manages it |
|------|---------|----------------|
| `~/.zshrc.local` | Shell aliases, env vars, functions | Work bootstrap or manual |
| `~/.gitconfig.local` | Git identity override (e.g. work email) | Work bootstrap |
| `~/.ssh/config.local` | Work SSH host entries | Work bootstrap |

## Work setup

Work-specific tooling, credentials, and SSH identities are managed by a separate external bootstrap. It lives outside this repository and is employer-independent from the personal dotfiles perspective.

## Secrets management

All personal secrets are stored in Bitwarden. Nothing sensitive is committed to this repository.

### What lives in Bitwarden

- SSH private keys (served via Bitwarden SSH agent — never written to disk)
- AWS access keys for `ff-digital` (fetched by `setup-personal-secrets.sh`)

### Required Bitwarden vault items

| Item name | Type | Username field | Password field |
|-----------|------|----------------|---------------|
| `SSH - GitHub Personal` | SSH Key | — | Private key |
| `AWS ff-digital` | Login | AWS Access Key ID | AWS Secret Access Key |

### How it works

- **SSH**: `.ssh/config` sets `IdentityAgent` per host to the Bitwarden SSH agent socket. Keys are stored in the vault and offered on demand. No private key files on disk.
- **AWS**: `setup-personal-secrets.sh` fetches credentials from Bitwarden using `bw` and writes `~/.aws/credentials`.

## VS Code setup

Settings and keybindings are symlinked by `link-dotfiles.sh`. Extensions must be installed separately.

### 1) Add `code` to PATH
Open VS Code → `Cmd+Shift+P` → **Shell Command: Install 'code' command in PATH**

### 2) Install extensions
```bash
bash ~/dotfiles/scripts/setup-vscode.sh
```

Extensions are listed in `vscode/extensions.txt`.

## React Native (iOS) setup

Run after the main bootstrap. Xcode must be installed first.

### 1) Install Xcode
```bash
xcodes install --latest --experimental-unxip
```

### 2) Finalise the environment
```bash
bash ~/dotfiles/scripts/setup-react-native.sh
```

## Dotfile backups

When `link-dotfiles.sh` replaces existing files, they are backed up to `~/.dotfiles-backup/<timestamp>/` preserving directory structure.

```bash
bash ~/dotfiles/scripts/list-backups.sh
```

To restore a file:
```bash
cp ~/.dotfiles-backup/<timestamp>/.ssh/config ~/.ssh/config
```

## Git ignore files

- **`.gitignore`** (this repo only): prevents committing secrets or macOS junk.
- **`.gitignore_global`** (all repos): suppresses editor artifacts and `.DS_Store` globally.

## Brewfile maintenance

```bash
brew bundle dump --force --file=~/dotfiles/Brewfile
```

## Troubleshooting

### `bash ~/dotfiles/scripts/bootstrap.sh` fails
```bash
brew update && brew doctor
bash ~/dotfiles/scripts/bootstrap.sh
```

### `yarn --version` is not Berry / shell plugins missing / `claude` not found
```bash
bash ~/dotfiles/scripts/setup-shell.sh
exec zsh
```

### Wrong git identity in dotfiles repo
```bash
git -C ~/dotfiles config user.name "Fabien Fouassier"
git -C ~/dotfiles config user.email "fab.fouassier@gmail.com"
```
