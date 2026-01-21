#!/bin/bash
# Pre-Setup Script (Idempotent)
# Run as root to prepare the base image or update an existing install
# Usage: sudo ./pre-setup.sh <username>
#
# Safe to re-run - will update existing installations

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[x]${NC} $1"; }

# -----------------------------------------------------------------------------
# Checks
# -----------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    err "Run as root: sudo ./pre-setup.sh <username>"
    exit 1
fi

if [ -z "$1" ]; then
    err "Usage: sudo ./pre-setup.sh <username>"
    exit 1
fi

TARGET_USER="$1"
TARGET_HOME="/home/$TARGET_USER"

if ! id "$TARGET_USER" &>/dev/null; then
    log "Creating user: $TARGET_USER"
    adduser --gecos "" "$TARGET_USER"
    usermod -aG sudo "$TARGET_USER"
else
    log "User $TARGET_USER exists"
fi

# -----------------------------------------------------------------------------
# System packages
# -----------------------------------------------------------------------------
log "Updating apt cache..."
apt-get update -qq

log "Installing/updating system packages..."
apt-get install -y -qq \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    unzip \
    tmux \
    htop \
    jq \
    tree

# -----------------------------------------------------------------------------
# GitHub CLI
# -----------------------------------------------------------------------------
if command -v gh &>/dev/null; then
    log "GitHub CLI already installed: $(gh --version | head -1)"
else
    log "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
    apt-get update -qq
    apt-get install -y -qq gh
fi

# -----------------------------------------------------------------------------
# Cloudflared (for tunnel access)
# -----------------------------------------------------------------------------
if command -v cloudflared &>/dev/null; then
    log "cloudflared already installed: $(cloudflared --version 2>&1 | head -1)"
else
    log "Installing cloudflared..."
    curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o /tmp/cloudflared.deb
    dpkg -i /tmp/cloudflared.deb
    rm /tmp/cloudflared.deb
fi

# -----------------------------------------------------------------------------
# nvm + Node (user-level)
# -----------------------------------------------------------------------------
log "Setting up nvm + Node for $TARGET_USER..."
sudo -u "$TARGET_USER" bash << 'EOFNVM'
set -e
export HOME="$HOME"

# Install or update nvm
if [ ! -d "$HOME/.nvm" ]; then
    echo "  Installing nvm..."
    curl -so- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
else
    echo "  nvm already installed"
fi

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install latest node (not LTS)
CURRENT=$(node --version 2>/dev/null || echo "none")
LATEST=$(nvm version-remote node)

if [ "$CURRENT" != "$LATEST" ]; then
    echo "  Installing Node $LATEST (current: $CURRENT)..."
    nvm install node
    nvm alias default node
else
    echo "  Node $CURRENT is latest"
fi
EOFNVM

# -----------------------------------------------------------------------------
# Bun (user-level)
# -----------------------------------------------------------------------------
log "Setting up Bun for $TARGET_USER..."
sudo -u "$TARGET_USER" bash << 'EOFBUN'
set -e
if command -v bun &>/dev/null; then
    echo "  Bun already installed: $(bun --version)"
    echo "  Updating bun..."
    bun upgrade 2>/dev/null || true
else
    echo "  Installing bun..."
    curl -fsSL https://bun.sh/install | bash
fi
EOFBUN

# -----------------------------------------------------------------------------
# Rust (user-level)
# -----------------------------------------------------------------------------
log "Setting up Rust for $TARGET_USER..."
sudo -u "$TARGET_USER" bash << 'EOFRUST'
set -e
if command -v rustc &>/dev/null; then
    echo "  Rust already installed: $(rustc --version)"
    echo "  Updating..."
    rustup update 2>/dev/null || true
else
    echo "  Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
EOFRUST

# -----------------------------------------------------------------------------
# Clarinet (user-level)
# -----------------------------------------------------------------------------
log "Setting up Clarinet for $TARGET_USER..."
sudo -u "$TARGET_USER" bash << 'EOFCLARINET'
set -e
# Source cargo env
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

if command -v clarinet &>/dev/null; then
    echo "  Clarinet already installed: $(clarinet --version)"
else
    echo "  Installing Clarinet..."
    curl -fsSL https://get.clarinet.dev | sh
fi
EOFCLARINET

# -----------------------------------------------------------------------------
# Claude Code CLI (user-level)
# -----------------------------------------------------------------------------
log "Setting up Claude Code for $TARGET_USER..."
sudo -u "$TARGET_USER" bash << 'EOFCLAUDE'
set -e
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if command -v claude &>/dev/null; then
    echo "  Claude Code already installed: $(claude --version 2>/dev/null)"
    echo "  Updating..."
    npm update -g @anthropic-ai/claude-code 2>/dev/null || true
else
    echo "  Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
fi
EOFCLAUDE

# -----------------------------------------------------------------------------
# Git defaults
# -----------------------------------------------------------------------------
log "Setting git defaults for $TARGET_USER..."
sudo -u "$TARGET_USER" git config --global init.defaultBranch main
sudo -u "$TARGET_USER" git config --global pull.rebase true

# -----------------------------------------------------------------------------
# Bash aliases
# -----------------------------------------------------------------------------
log "Setting up bash aliases for $TARGET_USER..."
ALIAS_FILE="$TARGET_HOME/.bash_aliases"

# Create or update aliases (idempotent via marker)
if ! grep -q "# CLAUDE-TEAM-STARTER" "$ALIAS_FILE" 2>/dev/null; then
    sudo -u "$TARGET_USER" bash -c "cat >> '$ALIAS_FILE'" << 'ALIASES'

# CLAUDE-TEAM-STARTER
alias clauded='claude --dangerously-skip-permissions'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline -20'
alias gp='git push'
alias ga='git add'
alias gc='git commit'
alias ta='tmux attach || tmux new -s main'
alias ll='ls -lah'
# END CLAUDE-TEAM-STARTER
ALIASES
    log "Aliases added"
else
    log "Aliases already configured"
fi

# Ensure .bash_aliases is sourced
if ! grep -q "bash_aliases" "$TARGET_HOME/.bashrc" 2>/dev/null; then
    echo '[ -f ~/.bash_aliases ] && . ~/.bash_aliases' >> "$TARGET_HOME/.bashrc"
fi

# -----------------------------------------------------------------------------
# Tmux config
# -----------------------------------------------------------------------------
log "Setting up tmux config for $TARGET_USER..."
TMUX_CONF="$TARGET_HOME/.tmux.conf"
if [ ! -f "$TMUX_CONF" ]; then
    sudo -u "$TARGET_USER" bash -c "cat > '$TMUX_CONF'" << 'TMUXCONF'
set -g default-terminal "screen-256color"
set -g history-limit 50000
set -g base-index 1
setw -g pane-base-index 1
set -g mouse on
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
TMUXCONF
fi

# -----------------------------------------------------------------------------
# .claude directory
# -----------------------------------------------------------------------------
log "Setting up .claude directory for $TARGET_USER..."
CLAUDE_DIR="$TARGET_HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")/templates/.claude"

sudo -u "$TARGET_USER" mkdir -p "$CLAUDE_DIR"

# Copy template if exists and CLAUDE.md not already present
if [ -d "$TEMPLATE_DIR" ] && [ ! -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    cp "$TEMPLATE_DIR"/* "$CLAUDE_DIR"/ 2>/dev/null || true
    chown -R "$TARGET_USER:$TARGET_USER" "$CLAUDE_DIR"
    log "Copied .claude template"
fi

# -----------------------------------------------------------------------------
# Clone shared repos
# -----------------------------------------------------------------------------
log "Setting up shared repositories for $TARGET_USER..."
sudo -u "$TARGET_USER" mkdir -p "$TARGET_HOME/dev/whoabuddy"

# Clone claude-knowledge (shared patterns, runbooks, context)
if [ ! -d "$TARGET_HOME/dev/whoabuddy/claude-knowledge" ]; then
    log "Cloning claude-knowledge..."
    sudo -u "$TARGET_USER" git clone https://github.com/whoabuddy/claude-knowledge.git "$TARGET_HOME/dev/whoabuddy/claude-knowledge" 2>/dev/null || warn "Could not clone claude-knowledge (may need auth)"
else
    log "claude-knowledge already exists"
fi

# Clone claude-rpg (web UI)
if [ ! -d "$TARGET_HOME/dev/whoabuddy/claude-rpg" ]; then
    log "Cloning claude-rpg..."
    sudo -u "$TARGET_USER" git clone https://github.com/whoabuddy/claude-rpg.git "$TARGET_HOME/dev/whoabuddy/claude-rpg" 2>/dev/null || warn "Could not clone claude-rpg (may need auth)"
else
    log "claude-rpg already exists"
fi

# -----------------------------------------------------------------------------
# Copy scripts to user home
# -----------------------------------------------------------------------------
log "Copying scripts to $TARGET_HOME..."
cp "$SCRIPT_DIR/post-setup.sh" "$TARGET_HOME/post-setup.sh"
cp "$SCRIPT_DIR/setup-tunnel.sh" "$TARGET_HOME/setup-tunnel.sh"
cp "$SCRIPT_DIR/verify.sh" "$TARGET_HOME/verify.sh"
chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME"/*.sh
chmod +x "$TARGET_HOME"/*.sh

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
log "=========================================="
log "Pre-setup complete for $TARGET_USER"
log "=========================================="
echo ""
echo "Installed:"
echo "  - build-essential, cmake, git, tmux, jq"
echo "  - gh (GitHub CLI), cloudflared"
echo "  - nvm + Node (latest), Bun"
echo "  - Rust, Clarinet"
echo "  - Claude Code CLI"
echo ""
echo "Repos cloned to ~/dev/whoabuddy/:"
echo "  - claude-knowledge (shared patterns)"
echo "  - claude-rpg (web UI)"
echo ""
echo "User needs to run: ~/post-setup.sh"
echo "  - Log into Claude Code"
echo "  - Authenticate GitHub CLI"
echo "  - Set git name/email"
echo "  - Generate SSH key"
echo ""
echo "Optional: ~/setup-tunnel.sh for Cloudflare tunnel"
echo ""
