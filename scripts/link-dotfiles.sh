#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup}"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
CONF="$DOTFILES_DIR/symlinks.conf"

if [[ ! -f "$CONF" ]]; then
  echo "symlinks.conf not found at $CONF" >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR" \
  "$HOME/.ssh" "$HOME/.aws" "$HOME/.claude" "$HOME/.config/gh" \
  "$HOME/Library/Application Support/Code/User"

linked=0

while IFS=: read -r rel_src raw_dst || [[ -n "$rel_src" ]]; do
  [[ -z "$rel_src" || "$rel_src" == \#* ]] && continue

  src="$DOTFILES_DIR/$rel_src"
  dst="${raw_dst/\$HOME/$HOME}"

  if [[ ! -e "$src" ]]; then
    echo "Missing source: $src" >&2
    exit 1
  fi

  if [[ -e "$dst" || -L "$dst" ]]; then
    backup_name="${rel_src//\//_}"
    mv "$dst" "$BACKUP_DIR/${backup_name}.${TIMESTAMP}"
  fi

  ln -sfn "$src" "$dst"
  echo "  linked $dst"
  linked=$((linked + 1))
done < "$CONF"

chmod 700 "$HOME/.ssh" "$HOME/.aws"
chmod 600 "$HOME/.ssh/config" "$HOME/.aws/config"

echo ""
echo "$linked symlinks created."
