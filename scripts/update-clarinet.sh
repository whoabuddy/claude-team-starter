#!/bin/bash
# Update Clarinet to latest release from stx-labs/clarinet
# Run anytime to get the latest version

set -e

GREEN='\033[0;32m'
NC='\033[0m'
log() { echo -e "${GREEN}[+]${NC} $1"; }

CLARINET_BIN="$HOME/.local/bin/clarinet"
mkdir -p "$HOME/.local/bin"

# Get current version
if command -v clarinet &>/dev/null; then
    CURRENT=$(clarinet --version 2>/dev/null | head -1)
    log "Current: $CURRENT"
else
    log "Clarinet not installed"
fi

# Get latest release
log "Checking latest release..."
LATEST=$(curl -fsSL https://api.github.com/repos/stx-labs/clarinet/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
log "Latest: $LATEST"

# Download and extract
log "Downloading..."
curl -fsSL "https://github.com/stx-labs/clarinet/releases/download/${LATEST}/clarinet-linux-x64-glibc.tar.gz" -o /tmp/clarinet.tar.gz
tar -xzf /tmp/clarinet.tar.gz -C "$HOME/.local/bin"
rm /tmp/clarinet.tar.gz
chmod +x "$CLARINET_BIN"

log "Installed: $($CLARINET_BIN --version)"
