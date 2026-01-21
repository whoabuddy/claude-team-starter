#!/bin/bash
# Post-Setup Script
# Run as the user after first login
# Walks through account configuration that only you can do

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

header() { echo -e "\n${BLUE}${BOLD}=== $1 ===${NC}\n"; }
ok() { echo -e "${GREEN}[✓]${NC} $1"; }
pending() { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${YELLOW}→${NC} $1"; }

wait_enter() {
    echo ""
    read -p "Press ENTER to continue..."
}

# Load nvm for this session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# =============================================================================
# STATUS CHECK
# =============================================================================
check_status() {
    header "Setup Status"

    local complete=true

    # Claude login
    if claude config list 2>/dev/null | grep -q "primaryEmail"; then
        ok "Claude Code: logged in"
    else
        pending "Claude Code: not logged in"
        complete=false
    fi

    # Git config
    if git config --global user.name &>/dev/null && git config --global user.email &>/dev/null; then
        ok "Git: $(git config --global user.name) <$(git config --global user.email)>"
    else
        pending "Git: name/email not set"
        complete=false
    fi

    # SSH key
    if [ -f "$HOME/.ssh/id_ed25519.pub" ] || [ -f "$HOME/.ssh/id_rsa.pub" ]; then
        ok "SSH key: exists"
    else
        pending "SSH key: not found"
        complete=false
    fi

    # GitHub CLI
    if gh auth status &>/dev/null 2>&1; then
        ok "GitHub CLI: authenticated"
    else
        pending "GitHub CLI: not authenticated"
        complete=false
    fi

    if $complete; then
        echo ""
        echo -e "${GREEN}${BOLD}All done! You're ready to go.${NC}"
        echo ""
        echo "Quick start:"
        echo "  claude          - Start Claude Code"
        echo "  clauded         - Claude with auto-approve (careful!)"
        echo "  ta              - Attach to tmux session"
        echo ""
        return 0
    else
        return 1
    fi
}

# =============================================================================
# CLAUDE CODE LOGIN
# =============================================================================
setup_claude() {
    header "Claude Code Login"

    if claude config list 2>/dev/null | grep -q "primaryEmail"; then
        ok "Already logged in"
        return 0
    fi

    info "This will open a browser to log into your Anthropic account."
    info "If on a headless server, you'll get a URL to visit."
    wait_enter

    claude login

    if claude config list 2>/dev/null | grep -q "primaryEmail"; then
        ok "Login successful!"
    else
        info "Login incomplete. Run 'claude login' to try again."
    fi
}

# =============================================================================
# GIT CONFIG
# =============================================================================
setup_git() {
    header "Git Identity"

    if git config --global user.name &>/dev/null && git config --global user.email &>/dev/null; then
        ok "Already configured: $(git config --global user.name)"
        read -p "Keep this? (Y/n): " keep
        [[ ! "$keep" =~ ^[Nn] ]] && return 0
    fi

    read -p "Your name: " git_name
    read -p "Your email (use your GitHub email): " git_email

    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    ok "Git configured"
}

# =============================================================================
# SSH KEY
# =============================================================================
setup_ssh() {
    header "SSH Key for GitHub"

    if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
        ok "SSH key exists"
        echo ""
        echo "Your public key:"
        cat "$HOME/.ssh/id_ed25519.pub"
        echo ""
        info "Make sure this is added at: https://github.com/settings/ssh/new"
        return 0
    fi

    info "Generating SSH key..."

    local email
    email=$(git config --global user.email 2>/dev/null || echo "")
    [ -z "$email" ] && read -p "Email for SSH key: " email

    ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""

    eval "$(ssh-agent -s)" > /dev/null
    ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null

    echo ""
    ok "SSH key generated!"
    echo ""
    echo "Your public key (add this to GitHub):"
    echo ""
    cat "$HOME/.ssh/id_ed25519.pub"
    echo ""
    info "Add at: https://github.com/settings/ssh/new"
    wait_enter
}

# =============================================================================
# GITHUB CLI
# =============================================================================
setup_github() {
    header "GitHub CLI Login"

    if gh auth status &>/dev/null 2>&1; then
        ok "Already authenticated"
        return 0
    fi

    info "This will authenticate you with GitHub."
    info "Choose 'SSH' when asked about preferred protocol."
    wait_enter

    gh auth login

    if gh auth status &>/dev/null 2>&1; then
        ok "GitHub authenticated!"
    fi
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    echo -e "${BOLD}Welcome to your development environment!${NC}"
    echo ""
    echo "This will set up your accounts. It only takes a few minutes."

    if check_status; then
        exit 0
    fi

    wait_enter

    setup_claude
    setup_git
    setup_ssh
    setup_github

    check_status
}

main "$@"
