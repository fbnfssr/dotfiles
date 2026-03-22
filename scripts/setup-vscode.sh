#!/usr/bin/env bash
# Installs VS Code extensions from vscode/extensions.txt.
#
# Prerequisites:
#   1. VS Code is installed (via brew bundle)
#   2. The 'code' CLI is in PATH:
#      Open VS Code → Cmd+Shift+P → "Shell Command: Install 'code' command in PATH"
#
# Usage:
#   bash ~/dotfiles/scripts/setup-vscode.sh
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

if ! command -v code >/dev/null 2>&1; then
  echo "VS Code CLI 'code' not found in PATH." >&2
  echo "" >&2
  echo "To enable it:" >&2
  echo "  1. VS Code will open now (or open it manually)" >&2
  echo "  2. Press Cmd+Shift+P" >&2
  echo "  3. Type: Shell Command: Install 'code' command in PATH" >&2
  echo "  4. Re-run this script afterwards" >&2
  echo "" >&2
  open -a "Visual Studio Code" 2>/dev/null || true
  exit 1
fi

while IFS= read -r ext || [[ -n "$ext" ]]; do
  [[ -z "$ext" || "$ext" == \#* ]] && continue
  echo "Installing $ext..."
  code --install-extension "$ext" --force
done < "$DOTFILES_DIR/vscode/extensions.txt"

echo ""
echo "VS Code extensions installed."
