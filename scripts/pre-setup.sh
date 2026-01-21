#!/bin/bash
# Pre-Setup Script
# Run this as root/sudo BEFORE the user connects
# Usage: sudo ./pre-setup.sh <username>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root (sudo ./pre-setup.sh <username>)"
    exit 1
fi

# Check for username argument
if [ -z "$1" ]; then
    log_error "Usage: sudo ./pre-setup.sh <username>"
    exit 1
fi

TARGET_USER="$1"
TARGET_HOME="/home/$TARGET_USER"

# Verify user exists
if ! id "$TARGET_USER" &>/dev/null; then
    log_info "Creating user: $TARGET_USER"
    adduser --gecos "" "$TARGET_USER"
    usermod -aG sudo "$TARGET_USER"
else
    log_info "User $TARGET_USER already exists"
fi

log_info "Starting pre-setup for user: $TARGET_USER"

# =============================================================================
# SYSTEM PACKAGES
# =============================================================================
log_info "Updating system packages..."
apt-get update
apt-get upgrade -y

log_info "Installing build essentials..."
apt-get install -y \
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

# =============================================================================
# CLOUDFLARED
# =============================================================================
log_info "Installing cloudflared..."
if ! command -v cloudflared &> /dev/null; then
    curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    dpkg -i cloudflared.deb
    rm cloudflared.deb
else
    log_info "cloudflared already installed"
fi

# =============================================================================
# NVM + NODE (installed for user, not root)
# =============================================================================
log_info "Installing nvm for $TARGET_USER..."
sudo -u "$TARGET_USER" bash << 'EOFNVM'
export HOME="$HOME"
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
    nvm alias default node
else
    echo "nvm already installed"
fi
EOFNVM

# =============================================================================
# BUN
# =============================================================================
log_info "Installing bun for $TARGET_USER..."
sudo -u "$TARGET_USER" bash << 'EOFBUN'
if ! command -v bun &> /dev/null; then
    curl -fsSL https://bun.sh/install | bash
else
    echo "bun already installed"
fi
EOFBUN

# =============================================================================
# CLAUDE CODE CLI
# =============================================================================
log_info "Installing Claude Code CLI for $TARGET_USER..."
sudo -u "$TARGET_USER" bash << 'EOFCLAUDE'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
if ! command -v claude &> /dev/null; then
    npm install -g @anthropic-ai/claude-code
else
    echo "Claude Code already installed"
fi
EOFCLAUDE

# =============================================================================
# BASH ALIASES
# =============================================================================
log_info "Setting up bash aliases..."
sudo -u "$TARGET_USER" bash << 'EOFBASH'
ALIAS_FILE="$HOME/.bash_aliases"

# Create or append to bash_aliases
cat >> "$ALIAS_FILE" << 'ALIASES'
# Claude Code aliases
alias cc='claude'
alias ccd='claude --dangerously-skip-permissions'
alias ccr='claude --resume'

# Git shortcuts
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline -20'
alias gp='git push'
alias ga='git add'
alias gc='git commit'

# Tmux
alias ta='tmux attach || tmux new -s main'
alias tl='tmux list-sessions'

# System
alias ll='ls -lah'
alias ..='cd ..'
alias ...='cd ../..'
ALIASES

# Source in bashrc if not already
if ! grep -q "bash_aliases" "$HOME/.bashrc" 2>/dev/null; then
    echo '[ -f ~/.bash_aliases ] && . ~/.bash_aliases' >> "$HOME/.bashrc"
fi
EOFBASH

# =============================================================================
# TMUX CONFIG
# =============================================================================
log_info "Setting up tmux config..."
sudo -u "$TARGET_USER" bash << 'EOFTMUX'
cat > "$HOME/.tmux.conf" << 'TMUXCONF'
# Improve colors
set -g default-terminal "screen-256color"

# Increase scrollback
set -g history-limit 50000

# Start window numbering at 1
set -g base-index 1
setw -g pane-base-index 1

# Enable mouse
set -g mouse on

# Easier splits
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Status bar
set -g status-style bg=black,fg=white
set -g status-left '[#S] '
set -g status-right '%Y-%m-%d %H:%M'
TMUXCONF
EOFTMUX

# =============================================================================
# .CLAUDE DIRECTORY SETUP
# =============================================================================
log_info "Setting up .claude directory..."
CLAUDE_DIR="$TARGET_HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")/templates/.claude"

sudo -u "$TARGET_USER" mkdir -p "$CLAUDE_DIR"

# Copy template files if they exist
if [ -d "$TEMPLATE_DIR" ]; then
    cp -r "$TEMPLATE_DIR"/* "$CLAUDE_DIR"/ 2>/dev/null || true
    chown -R "$TARGET_USER:$TARGET_USER" "$CLAUDE_DIR"
fi

# =============================================================================
# GIT CONFIG (basic, user will customize)
# =============================================================================
log_info "Setting up basic git config..."
sudo -u "$TARGET_USER" git config --global init.defaultBranch main
sudo -u "$TARGET_USER" git config --global pull.rebase true

# =============================================================================
# SUMMARY
# =============================================================================
log_info "============================================"
log_info "Pre-setup complete for $TARGET_USER!"
log_info "============================================"
log_info ""
log_info "Installed:"
log_info "  - build-essential, cmake, git, tmux, jq, etc."
log_info "  - cloudflared"
log_info "  - nvm + Node.js LTS"
log_info "  - bun"
log_info "  - Claude Code CLI"
log_info ""
log_info "User still needs to configure:"
log_info "  1. Log into Claude Code (claude login)"
log_info "  2. Set up Cloudflare tunnel token"
log_info "  3. Configure git name/email"
log_info "  4. Add SSH key to GitHub"
log_info ""
log_info "User can run: ~/post-setup.sh for guided configuration"
