#!/bin/bash
# Setup Cloudflare Tunnel for Web UI Access
# Creates a tunnel with subdomain = GitHub username
# Exposes claude-rpg web UI (port 4010)

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[x]${NC} $1"; }

# Get GitHub username
get_github_user() {
    # Try gh cli first
    if gh auth status &>/dev/null 2>&1; then
        gh api user -q .login 2>/dev/null && return
    fi

    # Fall back to git config
    local email=$(git config --global user.email 2>/dev/null)
    if [ -n "$email" ]; then
        # Extract username from github email (user@users.noreply.github.com)
        if [[ "$email" == *"@users.noreply.github.com" ]]; then
            echo "$email" | sed 's/@users.noreply.github.com//' | sed 's/^[0-9]*+//'
            return
        fi
    fi

    return 1
}

# Check requirements
if ! command -v cloudflared &>/dev/null; then
    err "cloudflared not installed. Run pre-setup.sh first."
    exit 1
fi

if ! gh auth status &>/dev/null 2>&1; then
    err "GitHub CLI not authenticated. Run post-setup.sh first."
    exit 1
fi

GITHUB_USER=$(get_github_user)
if [ -z "$GITHUB_USER" ]; then
    err "Could not determine GitHub username"
    read -p "Enter your GitHub username: " GITHUB_USER
fi

log "GitHub user: $GITHUB_USER"

# Configuration
TUNNEL_NAME="${GITHUB_USER}-dev"
SERVICE_PORT=4010
DOMAIN="team.aibtc.com"
HOSTNAME="${GITHUB_USER}.${DOMAIN}"

echo ""
log "This will create a Cloudflare tunnel:"
echo "  Tunnel name: $TUNNEL_NAME"
echo "  Hostname:    $HOSTNAME"
echo "  Service:     localhost:$SERVICE_PORT (claude-rpg)"
echo ""

read -p "Continue? (y/N): " confirm
[[ ! "$confirm" =~ ^[Yy] ]] && exit 0

# Check if tunnel already exists
if cloudflared tunnel list 2>/dev/null | grep -q "$TUNNEL_NAME"; then
    warn "Tunnel '$TUNNEL_NAME' already exists"
    read -p "Delete and recreate? (y/N): " recreate
    if [[ "$recreate" =~ ^[Yy] ]]; then
        log "Deleting existing tunnel..."
        cloudflared tunnel delete "$TUNNEL_NAME" 2>/dev/null || true
    else
        exit 0
    fi
fi

# Login if needed
if [ ! -f "$HOME/.cloudflared/cert.pem" ]; then
    log "Authenticating with Cloudflare..."
    cloudflared tunnel login
fi

# Create tunnel
log "Creating tunnel: $TUNNEL_NAME"
cloudflared tunnel create "$TUNNEL_NAME"

# Get tunnel ID
TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
log "Tunnel ID: $TUNNEL_ID"

# Create config
CONFIG_DIR="$HOME/.cloudflared"
CONFIG_FILE="$CONFIG_DIR/config.yml"

log "Writing config to $CONFIG_FILE"
cat > "$CONFIG_FILE" << EOF
tunnel: $TUNNEL_ID
credentials-file: $CONFIG_DIR/$TUNNEL_ID.json

ingress:
  - hostname: $HOSTNAME
    service: http://localhost:$SERVICE_PORT
  - service: http_status:404
EOF

echo ""
log "=========================================="
log "Tunnel created!"
log "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Add DNS record in Cloudflare dashboard:"
echo "   Type: CNAME"
echo "   Name: $GITHUB_USER"
echo "   Target: $TUNNEL_ID.cfargotunnel.com"
echo "   (in the $DOMAIN zone)"
echo ""
echo "2. Start the tunnel:"
echo "   cloudflared tunnel run $TUNNEL_NAME"
echo ""
echo "3. (Optional) Install as service:"
echo "   sudo cloudflared service install"
echo ""
echo "Your URL: https://$HOSTNAME"
echo ""
