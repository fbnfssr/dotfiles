#!/usr/bin/env bash
# Post-bootstrap verification: checks that all expected tools are installed
# and all managed dotfiles are correctly symlinked.
set -uo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
PASS=0
FAIL=0

ok()   { echo "  [ok] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [!!] $1"; FAIL=$((FAIL + 1)); }

check_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd $(command "$cmd" --version 2>&1 | head -1)"
  else
    fail "$cmd — not found"
  fi
}

check_symlink() {
  local dst="$1"
  local src="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    ok "symlink $dst → $src"
  elif [ -e "$dst" ]; then
    fail "symlink $dst exists but is not linked to $src"
  else
    fail "symlink $dst — missing"
  fi
}

# Load NVM so node/npm/npx are resolvable in this bash session
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

echo ""
echo "==> Tools"
check_cmd brew
check_cmd git
check_cmd node
check_cmd yarn
check_cmd gh
check_cmd glab
check_cmd aws
check_cmd python3
check_cmd ruby
check_cmd claude
check_cmd codex

echo ""
echo "==> Symlinks"
while IFS=: read -r rel_src raw_dst || [[ -n "$rel_src" ]]; do
  [[ -z "$rel_src" || "$rel_src" == \#* ]] && continue
  src="$DOTFILES_DIR/$rel_src"
  dst="${raw_dst/\$HOME/$HOME}"
  check_symlink "$dst" "$src"
done < "$DOTFILES_DIR/symlinks.conf"

echo ""
echo "==> Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
