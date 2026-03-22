#!/usr/bin/env bash
# Restores personal secrets from Bitwarden.
# Generates ~/.aws/config (personal profile only) and ~/.aws/credentials.
#
# Prerequisites:
#   1. Bitwarden Desktop app installed and SSH agent enabled
#      (Settings → SSH Agent → Enable)
#   2. bitwarden-cli installed: brew install bitwarden-cli
#   3. Logged in to Bitwarden CLI: bw login
#   4. Bitwarden vault items (see README for required item names)
#
# Usage:
#   bash ~/dotfiles/scripts/setup-personal-secrets.sh
set -euo pipefail

BW_AGENT="$HOME/.bitwarden-ssh-agent.sock"
PASS=0
FAIL=0

ok()   { echo "  [ok] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [!!] $1"; FAIL=$((FAIL + 1)); }

# --- Bitwarden CLI ---
echo ""
echo "==> Bitwarden CLI"
if ! command -v bw &>/dev/null; then
  fail "bw not found — run: brew install bitwarden-cli"
  echo ""
  echo "Cannot continue without the Bitwarden CLI."
  exit 1
fi
ok "bw CLI installed"

echo ""
echo "==> Bitwarden vault"
echo "    Unlocking vault (run 'bw login' first if not yet authenticated)..."
BW_SESSION=$(bw unlock --raw)
export BW_SESSION
ok "vault unlocked"

# --- Generate ~/.aws/config ---
echo ""
echo "==> Personal AWS config"
mkdir -p "$HOME/.aws"
cat > "$HOME/.aws/config" << 'EOF'
[profile ff-digital]
region = eu-west-1
output = json
EOF
chmod 600 "$HOME/.aws/config"
ok "~/.aws/config written (ff-digital only)"

# --- AWS credentials ---
echo ""
echo "==> Personal AWS credentials"
AWS_KEY=$(bw get username "AWS ff-digital" --session "$BW_SESSION")
AWS_SECRET=$(bw get password "AWS ff-digital" --session "$BW_SESSION")

cat > "$HOME/.aws/credentials" << EOF
[ff-digital]
aws_access_key_id = ${AWS_KEY}
aws_secret_access_key = ${AWS_SECRET}
EOF
chmod 600 "$HOME/.aws/credentials"
ok "~/.aws/credentials written"

# --- Bitwarden SSH agent ---
echo ""
echo "==> Bitwarden SSH agent"
if [[ -S "$BW_AGENT" ]]; then
  ok "SSH agent socket found"
else
  fail "SSH agent socket not found — open Bitwarden Desktop → Settings → SSH Agent → Enable"
fi

# --- SSH connectivity ---
echo ""
echo "==> SSH connectivity"
if ssh -T github-perso 2>&1 | grep -qi "successfully authenticated"; then
  ok "github-perso"
else
  fail "github-perso — could not authenticate (is 'SSH - GitHub Personal' in Bitwarden vault?)"
fi

# --- Summary ---
echo ""
echo "==> Results: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then
  echo ""
  echo "Fix the failures above. Refer to the README for Bitwarden setup steps."
  exit 1
fi
echo ""
echo "Personal secrets restored."

# Work bootstrap discovery (detect only — never execute automatically)
WORK_BOOTSTRAP="$HOME/.work-bootstrap/bootstrap-work.sh"
if [[ -x "$WORK_BOOTSTRAP" ]]; then
  echo ""
  echo "→ Work bootstrap available: $WORK_BOOTSTRAP"
fi
