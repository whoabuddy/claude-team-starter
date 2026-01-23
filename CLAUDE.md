# Claude Team Starter

Replicate a Claude Code development environment for a team of 5.

## Phase 1: Team of 5 (Current)

VirtualBox VMs running Ubuntu Server with identical setups.

### Flow

1. Admin: Create base Ubuntu Server VM
2. Admin: Clone VM for each user
3. Admin: Run `sudo ./scripts/pre-setup.sh <username>` on each
4. User: SSH in, run `~/post-setup.sh`
5. User: Optionally run `~/setup-tunnel.sh` for web access

### Scripts

- `scripts/pre-setup.sh` - Installs everything (idempotent)
- `scripts/post-setup.sh` - Account configuration only
- `scripts/setup-tunnel.sh` - Cloudflare tunnel with GitHub username subdomain
- `scripts/verify.sh` - Quick status check

### Installed by pre-setup

- build-essential, cmake, git, tmux, jq
- Node.js (latest via nvm), Bun
- Rust, Clarinet (Stacks/Clarity development)
- Claude Code CLI
- GitHub CLI, cloudflared
- Clones: claude-knowledge, claude-rpg

### User completes in post-setup

- Claude Code login
- Git name/email
- SSH key
- GitHub CLI auth

### claude-rpg Services

Two systemd services run the web interface:

- `claude-rpg-server` - API server on port 4011
- `claude-rpg-client` - Vite dev server on port 4010 (HTTPS + proxy)

The client uses vite dev server which provides:
- HTTPS with auto-generated certs (required for microphone access)
- Proxy for `/api` and `/ws` routes to the server on :4011

Cloudflare tunnel config must use `https://localhost:4010` with **No TLS Verify** enabled (self-signed cert).

**Commands:**
```bash
sudo systemctl status claude-rpg-server claude-rpg-client
sudo systemctl restart claude-rpg-client
sudo journalctl -u claude-rpg-client -f
```

## Phase 2: Scale + Wallet Integration (Future)

- Docker-based deployment
- Stacks wallet authentication (SIWS)
- Agent wallet linked to user wallet via smart contract
- Gamification: keep agent alive, earn reputation
