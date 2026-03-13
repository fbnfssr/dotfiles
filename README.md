# dotfiles
Source of truth for personal macOS setup.

## Files managed by this repository
- `Brewfile`
- `.zshrc`
- `.p10k.zsh`
- `.gitconfig`
- `.gitignore_global`
- `.ssh/config`
- `.aws/config`
- `scripts/bootstrap.sh`
- `scripts/link-dotfiles.sh`
- `scripts/setup-shell.sh`
- `scripts/setup-react-native.sh`
- `scripts/verify.sh`

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
```bash
git clone git@github.com:fbnfssr/dotfiles.git ~/dotfiles
```

### 4) Run bootstrap automation
```bash
bash ~/dotfiles/scripts/bootstrap.sh
```

### 5) Restart shell and verify
```bash
exec zsh
bash ~/dotfiles/scripts/verify.sh
```

What bootstrap does:
- installs all packages from `Brewfile`
- backs up and symlinks all managed dotfiles
- installs Oh-My-Zsh, Powerlevel10k, and shell plugins
- installs Node LTS with `nvm`
- activates Yarn Berry (v4+) through Corepack
- installs Claude Code CLI
- installs Codex (via Homebrew cask)

## Personal GitHub identity (dotfiles repo)
Run after cloning:

```bash
git -C ~/dotfiles config user.name "Fabien Fouassier"
git -C ~/dotfiles config user.email "<your-personal-email>"
git -C ~/dotfiles remote -v
git -C ~/dotfiles config --show-origin --get user.email
```

## Sensitive data handling plan
Secrets are never stored in this repository.

### Secrets stored outside git
- `~/.aws/credentials`
- `~/.ssh/id_*`
- API tokens and private keys

### Storage location
Store secret values in 1Password entries:
- AWS credentials
- SSH private keys
- npm token

### Restore procedure on a new machine
1. Restore values from 1Password.
2. Write them into:
   - `~/.aws/credentials`
   - `~/.ssh/id_*`
3. Apply permissions:
   ```bash
   chmod 700 ~/.ssh ~/.aws
   chmod 600 ~/.aws/credentials ~/.ssh/id_* ~/.ssh/config
   ```
4. Verify nothing sensitive is staged:
   ```bash
   git -C ~/dotfiles status --short
   ```

## React Native (iOS) setup
Run after the main bootstrap. Xcode must be installed first.

### 1) Install Xcode
```bash
xcodes install --latest --experimental-unxip
```
`xcodes` downloads directly from Apple's CDN with parallel connections — significantly faster than the App Store for a 10+ GB install.

### 2) Finalise the environment
```bash
bash ~/dotfiles/scripts/setup-react-native.sh
```

This sets the active Xcode path, accepts the license, and runs the first-launch setup.

### 3) Add iOS Simulators (optional)
```bash
xcodes runtimes install 'iOS 18'
```

### Tools included in Brewfile for React Native
- `cocoapods` — dependency manager for iOS native modules
- `watchman` — file watcher used by Metro bundler
- `xcodes` — Xcode version and runtime manager
- `react-native-debugger` — standalone debugger app

## Git ignore files
Two ignore files serve different purposes:

- **`.gitignore`** (this repo only): prevents accidentally committing secrets (`~/.aws/credentials`, `~/.ssh/id_*`, `.env*`) or macOS junk from the dotfiles repo itself.
- **`.gitignore_global`** (all repos on this machine): symlinked to `~/.gitignore_global` and registered in `.gitconfig`. Suppresses editor artifacts (`.idea/`, `*.swp`) and macOS files (`.DS_Store`) globally so you don't need to add them to every project.

## Brewfile maintenance
Run after app/tool changes:

```bash
brew leaves
brew list --cask
brew bundle dump --force --file=~/dotfiles/Brewfile
```

## Troubleshooting
### `bash ~/dotfiles/scripts/bootstrap.sh` fails
Run:
```bash
brew update
brew doctor
bash ~/dotfiles/scripts/bootstrap.sh
```

### `yarn --version` is not Berry
Run:
```bash
bash ~/dotfiles/scripts/setup-shell.sh
exec zsh
```

### Shell plugins are missing
Run:
```bash
bash ~/dotfiles/scripts/setup-shell.sh
exec zsh
```

### `claude` or `codex` command not found
Run:
```bash
bash ~/dotfiles/scripts/setup-shell.sh
exec zsh
```

### Wrong git identity in dotfiles repo
Run:
```bash
git -C ~/dotfiles config user.name "Fabien Fouassier"
git -C ~/dotfiles config user.email "<your-personal-email>"
```
