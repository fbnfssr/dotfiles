#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

# --- Preflight checks ---
preflight_ok=true

check_required() {
  local label="$1" path="$2"
  if [ ! -e "$path" ]; then
    echo "  MISSING: $label ($path)" >&2
    preflight_ok=false
  fi
}

echo "==> Preflight checks"
echo "    Dotfiles directory: $DOTFILES_DIR"

check_required "dotfiles directory" "$DOTFILES_DIR"
check_required "Brewfile"           "$DOTFILES_DIR/Brewfile"
check_required "symlinks.conf"      "$DOTFILES_DIR/symlinks.conf"
check_required "link-dotfiles.sh"   "$DOTFILES_DIR/scripts/link-dotfiles.sh"
check_required "setup-shell.sh"     "$DOTFILES_DIR/scripts/setup-shell.sh"

if ! command -v brew >/dev/null 2>&1; then
  echo "  MISSING: Homebrew (install from https://brew.sh)" >&2
  preflight_ok=false
fi

if [ "$preflight_ok" = false ]; then
  echo ""
  echo "Preflight failed. Fix the issues above before running bootstrap." >&2
  exit 1
fi

echo "    All checks passed."
echo ""

# --- Bootstrap ---
brew bundle --file="$DOTFILES_DIR/Brewfile"
"$DOTFILES_DIR/scripts/link-dotfiles.sh"
"$DOTFILES_DIR/scripts/setup-shell.sh"

echo ""
echo "Bootstrap completed. Restart your shell with: exec zsh"
