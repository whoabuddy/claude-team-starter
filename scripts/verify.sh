#!/bin/bash
# Quick verification script
# Run anytime to check environment status

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok() { echo -e "${GREEN}[✓]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

echo "Checking environment..."
echo ""

# System packages
command -v git &>/dev/null && ok "git" || fail "git"
command -v tmux &>/dev/null && ok "tmux" || fail "tmux"
command -v cmake &>/dev/null && ok "cmake" || fail "cmake"
command -v jq &>/dev/null && ok "jq" || fail "jq"

# Node/Bun
if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    command -v node &>/dev/null && ok "node $(node --version)" || fail "node"
    command -v npm &>/dev/null && ok "npm" || fail "npm"
else
    fail "nvm not installed"
fi

command -v bun &>/dev/null && ok "bun $(bun --version 2>/dev/null)" || fail "bun"

# Claude Code
command -v claude &>/dev/null && ok "claude code cli" || fail "claude code cli"

# Cloudflared
command -v cloudflared &>/dev/null && ok "cloudflared" || fail "cloudflared"

# GitHub CLI
command -v gh &>/dev/null && ok "github cli" || warn "github cli (optional)"

echo ""
echo "Checking configuration..."
echo ""

# Claude login
if claude config list 2>/dev/null | grep -q "primaryEmail"; then
    ok "claude logged in"
else
    fail "claude not logged in (run: claude login)"
fi

# Git config
if git config --global user.name &>/dev/null; then
    ok "git user: $(git config --global user.name)"
else
    fail "git user not set"
fi

if git config --global user.email &>/dev/null; then
    ok "git email: $(git config --global user.email)"
else
    fail "git email not set"
fi

# SSH key
if [ -f "$HOME/.ssh/id_ed25519.pub" ] || [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    ok "ssh key exists"
else
    fail "no ssh key found"
fi

# GitHub CLI auth
if gh auth status &>/dev/null 2>&1; then
    ok "github cli authenticated"
else
    warn "github cli not authenticated (run: gh auth login)"
fi

# Cloudflare tunnel
if [ -f "$HOME/.cloudflared/cert.pem" ] || systemctl is-active --quiet cloudflared 2>/dev/null; then
    ok "cloudflare tunnel configured"
else
    warn "cloudflare tunnel not configured (optional)"
fi

# .claude directory
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
    ok ".claude/CLAUDE.md exists"
else
    warn ".claude/CLAUDE.md not found"
fi

echo ""
