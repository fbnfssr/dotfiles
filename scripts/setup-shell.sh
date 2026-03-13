#!/usr/bin/env bash
set -euo pipefail

OH_MY_ZSH_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
CLAUDE_CODE_INSTALL_URL="https://claude.ai/install.sh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

clone_if_missing() {
  local repo="$1"
  local target="$2"
  if [ ! -d "$target" ]; then
    git clone --depth=1 "$repo" "$target"
  fi
}

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL "$OH_MY_ZSH_INSTALL_URL")"
fi

mkdir -p "$ZSH_CUSTOM/themes" "$ZSH_CUSTOM/plugins" "$NVM_DIR"

clone_if_missing "https://github.com/romkatv/powerlevel10k.git" "$ZSH_CUSTOM/themes/powerlevel10k"
clone_if_missing "https://github.com/zsh-users/zsh-autosuggestions" "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_if_missing "https://github.com/MichaelAquilina/zsh-you-should-use.git" "$ZSH_CUSTOM/plugins/you-should-use"

if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"
elif command -v brew >/dev/null 2>&1 && [ -s "$(brew --prefix nvm)/nvm.sh" ]; then
  . "$(brew --prefix nvm)/nvm.sh"
else
  echo "nvm is not available. Run brew bundle first." >&2
  exit 1
fi

nvm install --lts --latest-npm
nvm alias default 'lts/*'
nvm use default

corepack enable
corepack prepare yarn@stable --activate

if ! command -v claude >/dev/null 2>&1; then
  curl -fsSL "$CLAUDE_CODE_INSTALL_URL" | bash
fi

