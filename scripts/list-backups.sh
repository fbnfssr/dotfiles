#!/usr/bin/env bash
# Lists available dotfile backup snapshots.
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup}"

if [ ! -d "$BACKUP_DIR" ]; then
  echo "No backup directory found at $BACKUP_DIR"
  exit 0
fi

snapshots=()
for d in "$BACKUP_DIR"/*/; do
  [ -d "$d" ] && snapshots+=("$d")
done

if [ ${#snapshots[@]} -eq 0 ]; then
  echo "No backup snapshots found in $BACKUP_DIR"
  exit 0
fi

echo "Available backup snapshots:"
echo ""
for d in "${snapshots[@]}"; do
  name="$(basename "$d")"
  count="$(find "$d" -type f | wc -l | tr -d ' ')"
  echo "  $name  ($count files)"
done
echo ""
echo "Backups are stored in: $BACKUP_DIR"
echo "Each snapshot preserves the original directory structure relative to \$HOME."
