#!/bin/bash
# Setup claude-rpg as a systemd service with tmux session
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

echo "[+] Setting up claude-rpg service for $TARGET_USER"

# Create the start script
cat > "$TARGET_HOME/start-claude-rpg.sh" << 'STARTSCRIPT'
#!/bin/bash
# Start claude-rpg server in tmux session

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

SESSION="main"
RPG_DIR="$HOME/dev/whoabuddy/claude-rpg"

# Create tmux session if it doesn't exist
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux new-session -d -s "$SESSION" -c "$HOME"
fi

# Start the server in background (not in tmux, just as a process)
cd "$RPG_DIR"
exec node dist/server/server/index.js
STARTSCRIPT

chmod +x "$TARGET_HOME/start-claude-rpg.sh"
chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/start-claude-rpg.sh"

# Create systemd service
cat > /etc/systemd/system/claude-rpg.service << EOF
[Unit]
Description=Claude RPG Web Interface
After=network.target

[Service]
Type=simple
User=$TARGET_USER
Group=$TARGET_USER
WorkingDirectory=$RPG_DIR
Environment="HOME=$TARGET_HOME"
Environment="NVM_DIR=$TARGET_HOME/.nvm"
Environment="PATH=$TARGET_HOME/.nvm/versions/node/v25.4.0/bin:$TARGET_HOME/.local/bin:$TARGET_HOME/.bun/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=$TARGET_HOME/start-claude-rpg.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Create tmux session service (separate, always running)
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

# Reload and enable services
systemctl daemon-reload
systemctl enable claude-tmux.service
systemctl enable claude-rpg.service

echo "[+] Services created and enabled"
echo ""
echo "To start now:"
echo "  sudo systemctl start claude-tmux"
echo "  sudo systemctl start claude-rpg"
echo ""
echo "To check status:"
echo "  sudo systemctl status claude-rpg"
echo ""
echo "Web UI will be available at: http://<hostname>:4011"
