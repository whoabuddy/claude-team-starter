#!/bin/bash
# Quick status check - shows what's installed and configured

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok() { echo -e "${GREEN}[✓]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "=== Tools ==="
command -v git &>/dev/null && ok "git $(git --version | cut -d' ' -f3)" || fail "git"
command -v node &>/dev/null && ok "node $(node --version)" || fail "node"
command -v bun &>/dev/null && ok "bun $(bun --version)" || fail "bun"
command -v claude &>/dev/null && ok "claude $(claude --version 2>/dev/null)" || fail "claude"
command -v gh &>/dev/null && ok "gh $(gh --version | head -1 | cut -d' ' -f3)" || fail "gh"
command -v cloudflared &>/dev/null && ok "cloudflared" || warn "cloudflared (optional)"
command -v tmux &>/dev/null && ok "tmux" || fail "tmux"

echo ""
echo "=== Accounts ==="

if claude config list 2>/dev/null | grep -q "primaryEmail"; then
    ok "Claude: logged in"
else
    fail "Claude: run 'claude login'"
fi

if git config --global user.name &>/dev/null; then
    ok "Git: $(git config --global user.name)"
else
    fail "Git: name not set"
fi

if [ -f "$HOME/.ssh/id_ed25519.pub" ] || [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    ok "SSH key: exists"
else
    fail "SSH key: missing"
fi

if gh auth status &>/dev/null 2>&1; then
    ok "GitHub: authenticated"
else
    fail "GitHub: run 'gh auth login'"
fi

echo ""
echo "=== Repos ==="
[ -d "$HOME/dev/whoabuddy/claude-knowledge" ] && ok "claude-knowledge" || fail "claude-knowledge"
[ -d "$HOME/dev/whoabuddy/claude-rpg" ] && ok "claude-rpg" || fail "claude-rpg"

echo ""
