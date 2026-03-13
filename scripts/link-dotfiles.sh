#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup}"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"

mkdir -p "$BACKUP_DIR" "$HOME/.ssh" "$HOME/.aws"

require_path() {
  local path="$1"
  if [ ! -e "$path" ]; then
    echo "Missing: $path" >&2
    exit 1
  fi
}

backup_and_link() {
  local src="$1"
  local dst="$2"
  local backup_name="$3"

  require_path "$src"

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$BACKUP_DIR/${backup_name}.${TIMESTAMP}"
  fi

  ln -sfn "$src" "$dst"
}

backup_and_link "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc" ".zshrc"
backup_and_link "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh" ".p10k.zsh"
backup_and_link "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig" ".gitconfig"
backup_and_link "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global" ".gitignore_global"
backup_and_link "$DOTFILES_DIR/.ssh/config" "$HOME/.ssh/config" "ssh_config"
backup_and_link "$DOTFILES_DIR/.aws/config" "$HOME/.aws/config" "aws_config"
mkdir -p "$HOME/.claude"
backup_and_link "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json" "claude_settings"
backup_and_link "$DOTFILES_DIR/claude/skills" "$HOME/.claude/skills" "claude_skills"

chmod 700 "$HOME/.ssh" "$HOME/.aws"
chmod 600 "$HOME/.ssh/config" "$HOME/.aws/config"
