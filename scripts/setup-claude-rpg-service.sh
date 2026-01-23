#!/bin/bash
# Setup claude-rpg client + server as systemd services
# Run as: sudo ./setup-claude-rpg-service.sh <username>

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Run as root: sudo ./setup-claude-rpg-service.sh <username>"
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: sudo ./setup-claude-rpg-service.sh <username>"
    exit 1
fi

TARGET_USER="$1"
TARGET_HOME="/home/$TARGET_USER"
RPG_DIR="$TARGET_HOME/dev/whoabuddy/claude-rpg"

echo "[+] Setting up claude-rpg services for $TARGET_USER"

# Detect node version installed via nvm
NODE_VERSION=$(ls "$TARGET_HOME/.nvm/versions/node/" 2>/dev/null | sort -V | tail -1)
if [ -z "$NODE_VERSION" ]; then
    echo "[x] No node version found in $TARGET_HOME/.nvm/versions/node/"
    exit 1
fi
echo "[+] Detected node version: $NODE_VERSION"
NODE_PATH="$TARGET_HOME/.nvm/versions/node/$NODE_VERSION/bin"

# Create server start script
cat > "$TARGET_HOME/start-claude-rpg-server.sh" << 'STARTSCRIPT'
#!/bin/bash
# Start claude-rpg API server (port 4011)

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

RPG_DIR="$HOME/dev/whoabuddy/claude-rpg"
cd "$RPG_DIR"
exec node dist/server/server/index.js
STARTSCRIPT

chmod +x "$TARGET_HOME/start-claude-rpg-server.sh"
chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/start-claude-rpg-server.sh"

# Generate HTTPS certs for vite (if not present)
CERTS_DIR="$TARGET_HOME/.claude-rpg/certs"
if [ ! -f "$CERTS_DIR/cert.pem" ]; then
    echo "[+] Generating HTTPS certificates"
    mkdir -p "$CERTS_DIR"
    openssl req -x509 -newkey rsa:2048 -keyout "$CERTS_DIR/key.pem" -out "$CERTS_DIR/cert.pem" \
        -days 365 -nodes -subj '/CN=localhost' 2>/dev/null
    chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.claude-rpg"
fi

# Create client start script
# Uses vite dev server (HTTPS + proxy for /api and /ws to server)
cat > "$TARGET_HOME/start-claude-rpg-client.sh" << 'STARTSCRIPT'
#!/bin/bash
# Start claude-rpg web client (port 4010, HTTPS with proxy)

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

RPG_DIR="$HOME/dev/whoabuddy/claude-rpg"
cd "$RPG_DIR"
exec npx vite --port 4010 --host
STARTSCRIPT

chmod +x "$TARGET_HOME/start-claude-rpg-client.sh"
chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/start-claude-rpg-client.sh"

# Create server systemd service (port 4011)
cat > /etc/systemd/system/claude-rpg-server.service << EOF
[Unit]
Description=Claude RPG API Server (port 4011)
After=network.target

[Service]
Type=simple
User=$TARGET_USER
Group=$TARGET_USER
WorkingDirectory=$RPG_DIR
Environment="HOME=$TARGET_HOME"
Environment="NVM_DIR=$TARGET_HOME/.nvm"
Environment="PATH=$NODE_PATH:$TARGET_HOME/.local/bin:$TARGET_HOME/.bun/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=$TARGET_HOME/start-claude-rpg-server.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Create client systemd service (port 4010)
cat > /etc/systemd/system/claude-rpg-client.service << EOF
[Unit]
Description=Claude RPG Web Client (port 4010)
After=network.target claude-rpg-server.service

[Service]
Type=simple
User=$TARGET_USER
Group=$TARGET_USER
WorkingDirectory=$RPG_DIR
Environment="HOME=$TARGET_HOME"
Environment="NVM_DIR=$TARGET_HOME/.nvm"
Environment="PATH=$NODE_PATH:$TARGET_HOME/.local/bin:$TARGET_HOME/.bun/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=$TARGET_HOME/start-claude-rpg-client.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Create tmux session service (for user convenience)
cat > /etc/systemd/system/claude-tmux.service << EOF
[Unit]
Description=Claude Tmux Session
After=network.target

[Service]
Type=forking
User=$TARGET_USER
Group=$TARGET_USER
Environment="HOME=$TARGET_HOME"
ExecStart=/usr/bin/tmux new-session -d -s main -c $TARGET_HOME
ExecStop=/usr/bin/tmux kill-session -t main
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Remove old claude-rpg.service if it exists
if [ -f /etc/systemd/system/claude-rpg.service ]; then
    echo "[+] Removing old claude-rpg.service"
    systemctl stop claude-rpg.service 2>/dev/null || true
    systemctl disable claude-rpg.service 2>/dev/null || true
    rm /etc/systemd/system/claude-rpg.service
fi

# Reload and enable services
systemctl daemon-reload
systemctl enable claude-tmux.service
systemctl enable claude-rpg-server.service
systemctl enable claude-rpg-client.service

echo "[+] Services created and enabled"
echo ""
echo "To start now:"
echo "  sudo systemctl start claude-tmux"
echo "  sudo systemctl start claude-rpg-server"
echo "  sudo systemctl start claude-rpg-client"
echo ""
echo "To check status:"
echo "  sudo systemctl status claude-rpg-server claude-rpg-client"
echo ""
echo "Ports:"
echo "  Client (Web UI): http://localhost:4010"
echo "  Server (API):    http://localhost:4011"
