#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
SNAPSHOT_DIR="$BACKUP_DIR/$TIMESTAMP"
CONF="$DOTFILES_DIR/symlinks.conf"

if [[ ! -f "$CONF" ]]; then
  echo "symlinks.conf not found at $CONF" >&2
  exit 1
fi

linked=0
backed_up=0

while IFS=: read -r rel_src raw_dst || [[ -n "$rel_src" ]]; do
  [[ -z "$rel_src" || "$rel_src" == \#* ]] && continue

  src="$DOTFILES_DIR/$rel_src"
  dst="${raw_dst/\$HOME/$HOME}"

  if [[ ! -e "$src" ]]; then
    echo "Missing source: $src" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$dst")"

  if [[ -e "$dst" || -L "$dst" ]]; then
    # Preserve relative path structure inside the snapshot
    rel_path="${dst#$HOME/}"
    backup_target="$SNAPSHOT_DIR/$rel_path"
    mkdir -p "$(dirname "$backup_target")"
    mv "$dst" "$backup_target"
    backed_up=$((backed_up + 1))
  fi

  ln -sfn "$src" "$dst"
  echo "  linked $dst"
  linked=$((linked + 1))
done < "$CONF"

chmod 700 "$HOME/.ssh"
chmod 600 "$HOME/.ssh/config"

echo ""
echo "$linked symlinks created."
if [ "$backed_up" -gt 0 ]; then
  echo "$backed_up files backed up to: $SNAPSHOT_DIR"
fi
