#!/bin/bash
# Post-Setup Script
# Run this as the user after first login
# Guides through account configuration step by step

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}${BOLD}  $1${NC}"
    echo -e "${BLUE}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_pending() {
    echo -e "${RED}[✗]${NC} $1"
}

wait_for_enter() {
    echo ""
    read -p "Press ENTER when ready to continue..."
    echo ""
}

# =============================================================================
# STATUS CHECK
# =============================================================================
check_status() {
    print_header "Current Setup Status"

    local all_good=true

    # Check Claude Code
    if command -v claude &> /dev/null; then
        # Check if logged in by trying to get config
        if claude config list 2>/dev/null | grep -q "primaryEmail"; then
            print_success "Claude Code: Installed and logged in"
        else
            print_pending "Claude Code: Installed but NOT logged in"
            all_good=false
        fi
    else
        print_pending "Claude Code: Not installed"
        all_good=false
    fi

    # Check Git config
    if git config --global user.name &> /dev/null && git config --global user.email &> /dev/null; then
        print_success "Git: Configured ($(git config --global user.name))"
    else
        print_pending "Git: Name/email not configured"
        all_good=false
    fi

    # Check SSH key
    if [ -f "$HOME/.ssh/id_ed25519.pub" ] || [ -f "$HOME/.ssh/id_rsa.pub" ]; then
        print_success "SSH Key: Exists"
    else
        print_pending "SSH Key: Not found"
        all_good=false
    fi

    # Check GitHub CLI auth
    if command -v gh &> /dev/null && gh auth status &> /dev/null; then
        print_success "GitHub CLI: Authenticated"
    else
        print_pending "GitHub CLI: Not authenticated"
        all_good=false
    fi

    # Check Cloudflare
    if [ -f "$HOME/.cloudflared/cert.pem" ] || [ -f "$HOME/.cloudflared/config.yml" ]; then
        print_success "Cloudflare Tunnel: Configured"
    else
        print_pending "Cloudflare Tunnel: Not configured"
        all_good=false
    fi

    echo ""
    if $all_good; then
        echo -e "${GREEN}${BOLD}All systems configured! You're ready to go.${NC}"
        return 0
    else
        echo -e "${YELLOW}Some items need configuration. Let's set them up.${NC}"
        return 1
    fi
}

# =============================================================================
# CLAUDE CODE SETUP
# =============================================================================
setup_claude() {
    print_header "Step 1: Claude Code Login"

    if claude config list 2>/dev/null | grep -q "primaryEmail"; then
        print_success "Already logged into Claude Code"
        return 0
    fi

    echo "Claude Code needs to be connected to your Anthropic account."
    echo ""
    echo "This will open a browser window for authentication."
    echo "If you're on a headless server, it will give you a URL to visit."
    echo ""

    wait_for_enter

    claude login

    echo ""
    if claude config list 2>/dev/null | grep -q "primaryEmail"; then
        print_success "Claude Code login successful!"
    else
        print_info "If login didn't complete, you can run 'claude login' again later."
    fi
}

# =============================================================================
# GIT SETUP
# =============================================================================
setup_git() {
    print_header "Step 2: Git Configuration"

    if git config --global user.name &> /dev/null && git config --global user.email &> /dev/null; then
        print_success "Git already configured"
        echo "  Name:  $(git config --global user.name)"
        echo "  Email: $(git config --global user.email)"
        echo ""
        read -p "Keep this configuration? (Y/n): " keep_git
        if [[ "$keep_git" =~ ^[Nn] ]]; then
            git config --global --unset user.name
            git config --global --unset user.email
        else
            return 0
        fi
    fi

    echo "Let's configure your git identity."
    echo ""

    read -p "Enter your full name: " git_name
    read -p "Enter your email (use GitHub email for proper attribution): " git_email

    git config --global user.name "$git_name"
    git config --global user.email "$git_email"

    print_success "Git configured!"
}

# =============================================================================
# SSH KEY SETUP
# =============================================================================
setup_ssh() {
    print_header "Step 3: SSH Key for GitHub"

    if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
        print_success "SSH key already exists"
        echo ""
        echo "Your public key:"
        echo ""
        cat "$HOME/.ssh/id_ed25519.pub"
        echo ""
        return 0
    elif [ -f "$HOME/.ssh/id_rsa.pub" ]; then
        print_success "SSH key already exists (RSA)"
        echo ""
        echo "Your public key:"
        echo ""
        cat "$HOME/.ssh/id_rsa.pub"
        echo ""
        return 0
    fi

    echo "You need an SSH key to push code to GitHub."
    echo "We'll generate one now."
    echo ""

    local email
    email=$(git config --global user.email 2>/dev/null || echo "")

    if [ -z "$email" ]; then
        read -p "Enter your email for the SSH key: " email
    else
        echo "Using git email: $email"
    fi

    echo ""
    echo "Generating SSH key..."
    ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""

    # Start ssh-agent and add key
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null

    echo ""
    print_success "SSH key generated!"
    echo ""
    echo "Your public key (copy this to GitHub):"
    echo ""
    cat "$HOME/.ssh/id_ed25519.pub"
    echo ""
    echo "Add this key at: https://github.com/settings/ssh/new"

    wait_for_enter
}

# =============================================================================
# GITHUB CLI SETUP
# =============================================================================
setup_github_cli() {
    print_header "Step 4: GitHub CLI Authentication"

    # Install gh if not present
    if ! command -v gh &> /dev/null; then
        echo "Installing GitHub CLI..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update
        sudo apt install gh -y
    fi

    if gh auth status &> /dev/null; then
        print_success "Already authenticated with GitHub CLI"
        return 0
    fi

    echo "The GitHub CLI makes it easy to create PRs, manage issues, etc."
    echo ""
    echo "This will authenticate you with GitHub."
    echo ""

    wait_for_enter

    gh auth login

    if gh auth status &> /dev/null; then
        print_success "GitHub CLI authenticated!"
    fi
}

# =============================================================================
# CLOUDFLARE SETUP
# =============================================================================
setup_cloudflare() {
    print_header "Step 5: Cloudflare Tunnel (Optional)"

    if [ -f "$HOME/.cloudflared/cert.pem" ] || [ -f "$HOME/.cloudflared/config.yml" ]; then
        print_success "Cloudflare already configured"
        return 0
    fi

    echo "Cloudflare Tunnel allows secure web access to this machine."
    echo ""
    echo "If you have a Cloudflare tunnel token, you can set it up now."
    echo "Otherwise, skip this step - you can configure it later."
    echo ""

    read -p "Set up Cloudflare now? (y/N): " setup_cf

    if [[ ! "$setup_cf" =~ ^[Yy] ]]; then
        print_info "Skipping Cloudflare setup"
        return 0
    fi

    echo ""
    echo "You'll need a tunnel token from the Cloudflare dashboard."
    echo "Go to: Zero Trust > Networks > Tunnels > Create a tunnel"
    echo ""
    echo "After creating the tunnel, copy the token and paste it below."
    echo ""

    read -p "Enter your Cloudflare tunnel token (or 'skip'): " cf_token

    if [ "$cf_token" = "skip" ] || [ -z "$cf_token" ]; then
        print_info "Skipping Cloudflare setup"
        return 0
    fi

    # Create service with token
    echo ""
    echo "Setting up cloudflared service..."
    sudo cloudflared service install "$cf_token"

    print_success "Cloudflare tunnel configured!"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    print_header "Welcome to Claude Team Setup"

    echo "This script will help you configure your development environment."
    echo "We'll check what's already set up and guide you through the rest."
    echo ""

    # Show current status
    if check_status; then
        echo ""
        echo "Run this script again anytime to check status or reconfigure."
        exit 0
    fi

    wait_for_enter

    # Run setup steps
    setup_claude
    setup_git
    setup_ssh
    setup_github_cli
    setup_cloudflare

    # Final status
    print_header "Setup Complete!"
    check_status

    echo ""
    echo "You're all set! Here are some quick commands:"
    echo ""
    echo "  cc              - Start Claude Code"
    echo "  ccd             - Start Claude with dangerous mode (auto-approves)"
    echo "  ta              - Attach to tmux session"
    echo "  gs              - Git status"
    echo ""
    echo "Get started with:"
    echo "  cd ~/your-project && cc"
    echo ""
}

main "$@"
