#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required. Install Homebrew first." >&2
  exit 1
fi

brew bundle --file="$DOTFILES_DIR/Brewfile"
"$DOTFILES_DIR/scripts/link-dotfiles.sh"
"$DOTFILES_DIR/scripts/setup-shell.sh"

echo "Bootstrap completed. Restart your shell with: exec zsh"
