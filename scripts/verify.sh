#!/usr/bin/env bash
# Personal baseline readiness check.
# Validates tools, authentication, directories, symlinks, and optional overlays.
# Work environment checks are handled by the work bootstrap verify-work.sh.
set -uo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
BW_AGENT="$HOME/.bitwarden-ssh-agent.sock"
PASS=0
FAIL=0

ok()   { echo "  [ok] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [!!] $1"; FAIL=$((FAIL + 1)); }
info() { echo "  [-] $1"; }

check_exists() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd"
  else
    fail "$cmd — not found"
  fi
}

check_run() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    ok "$label"
  else
    fail "$label"
  fi
}

check_dir() {
  local path="$1"
  if [[ -d "$path" ]]; then
    ok "$path"
  else
    fail "$path — missing"
  fi
}

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    ok "$path"
  else
    fail "$path — missing"
  fi
}

check_gitconfig() {
  local key="$1"
  local val
  val="$(git config --global "$key" 2>/dev/null || true)"
  if [[ -n "$val" ]]; then
    ok "git $key = $val"
  else
    fail "git $key — not set"
  fi
}

check_symlink() {
  local dst="$1"
  local src="$2"
  if [[ -L "$dst" ]] && [[ "$(readlink "$dst")" = "$src" ]]; then
    ok "symlink $dst → $src"
  elif [[ -e "$dst" ]]; then
    fail "symlink $dst exists but is not linked to $src"
  else
    fail "symlink $dst — missing"
  fi
}

# Load NVM so node is resolvable in this bash session
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"

# --- Core tools ---
echo ""
echo "==> Core tools"
check_exists brew
check_exists git
check_exists node
check_exists gh
check_exists aws
check_exists python3
check_exists ruby
check_exists bw
check_exists claude
check_exists codex
check_exists code
check_exists pod
check_exists watchman

# --- Git & authentication ---
echo ""
echo "==> Git & authentication"
check_gitconfig user.name
check_gitconfig user.email
check_run "gh auth status" gh auth status

# Verify personal email is configured
personal_email="$(git config --global user.email 2>/dev/null || true)"
if [[ "$personal_email" == "fab.fouassier@gmail.com" ]]; then
  ok "git identity is personal"
else
  fail "git user.email = $personal_email (expected fab.fouassier@gmail.com — check ~/.gitconfig.local override)"
fi

# --- Secrets & directories ---
echo ""
echo "==> Secrets & directories"
check_dir  "$HOME/.ssh"
check_file "$HOME/.ssh/config"
check_dir  "$HOME/.aws"
check_file "$HOME/.aws/config"
check_file "$HOME/.aws/credentials"

# --- Bitwarden SSH agent ---
echo ""
echo "==> Bitwarden SSH agent"
if [[ -S "$BW_AGENT" ]]; then
  ok "SSH agent socket found"
else
  fail "SSH agent not running — open Bitwarden Desktop → Settings → SSH Agent → Enable"
fi

# --- SSH connectivity ---
echo ""
echo "==> SSH connectivity"
if ssh -T github-perso 2>&1 | grep -qi "successfully authenticated"; then
  ok "github-perso"
else
  fail "github-perso — could not authenticate"
fi

# --- iOS toolchain ---
echo ""
echo "==> iOS toolchain"
check_run "xcode-select -p"     xcode-select -p
check_run "xcodebuild -version" xcodebuild -version
check_run "pod --version"       pod --version
check_run "xcrun simctl list"   xcrun simctl list devices

# --- AWS ---
echo ""
echo "==> AWS (personal)"
check_run "aws sts identity (ff-digital)" aws sts get-caller-identity --profile ff-digital

# --- Symlinks ---
echo ""
echo "==> Symlinks"
if [[ -f "$DOTFILES_DIR/symlinks.conf" ]]; then
  while IFS=: read -r rel_src raw_dst || [[ -n "$rel_src" ]]; do
    [[ -z "$rel_src" ]] || [[ "${rel_src#\#}" != "$rel_src" ]] && continue
    src="$DOTFILES_DIR/$rel_src"
    dst="${raw_dst/\$HOME/$HOME}"
    check_symlink "$dst" "$src"
  done < "$DOTFILES_DIR/symlinks.conf"
else
  fail "symlinks.conf not found"
fi

# --- Optional local overlays ---
echo ""
echo "==> Optional local overlays"

if [[ -f "$HOME/.zshrc.local" ]]; then
  if zsh -n "$HOME/.zshrc.local" 2>/dev/null; then
    ok "~/.zshrc.local — present and valid"
  else
    fail "~/.zshrc.local — present but has syntax errors"
  fi
else
  info "~/.zshrc.local — not present (optional)"
fi

if [[ -f "$HOME/.gitconfig.local" ]]; then
  if git config --file "$HOME/.gitconfig.local" --list &>/dev/null; then
    ok "~/.gitconfig.local — present and parseable"
  else
    fail "~/.gitconfig.local — present but not parseable by git"
  fi
else
  info "~/.gitconfig.local — not present (optional)"
fi

if [[ -f "$HOME/.ssh/config.local" ]]; then
  if ssh -G github-perso &>/dev/null; then
    ok "~/.ssh/config.local — present, SSH config resolves"
  else
    fail "~/.ssh/config.local — present but SSH config resolution failed"
  fi
else
  info "~/.ssh/config.local — not present (optional)"
fi

# --- Summary ---
echo ""
echo "==> Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
