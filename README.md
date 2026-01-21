# Claude Team Starter

Replicate a Claude Code development environment for a team of 5.

## Setup Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  ADMIN                                                          │
│  1. Create Ubuntu Server VM in VirtualBox                       │
│  2. Run: sudo ./scripts/pre-setup.sh <username>                 │
│  3. Clone VM for each team member                               │
│  4. Distribute SSH access                                       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  USER                                                           │
│  1. SSH into your VM                                            │
│  2. Run: ./post-setup.sh                                        │
│  3. Follow prompts (Claude login, GitHub auth, etc.)            │
│  4. Start working: claude                                       │
└─────────────────────────────────────────────────────────────────┘
```

## What Gets Installed

**pre-setup.sh** installs everything (idempotent, re-run to update):
- build-essential, cmake, git, tmux, jq, htop
- nvm + Node.js (latest), Bun
- Rust, Clarinet (Stacks/Clarity development)
- Claude Code CLI
- GitHub CLI, cloudflared
- Clones: claude-knowledge, claude-rpg
- Bash aliases, tmux config

**post-setup.sh** handles credentials only:
- Claude Code login (Anthropic account)
- Git name/email
- SSH key generation
- GitHub CLI authentication

**setup-tunnel.sh** (optional) sets up Cloudflare tunnel:
- Uses GitHub username as subdomain
- Exposes claude-rpg web UI (port 4011)

## Admin Guide

### 1. Create Base VM

- Ubuntu Server 24.04 LTS
- 4GB+ RAM, 40GB disk, 2+ CPU cores
- VirtualBox: NAT + Host-only networking

### 2. Prepare the Image

```bash
git clone https://github.com/whoabuddy/claude-team-starter.git
cd claude-team-starter
sudo ./scripts/pre-setup.sh teamuser
```

Re-run anytime to update packages.

### 3. Clone for Team

1. Shut down VM
2. VirtualBox → Clone → Full Clone → Generate new MAC
3. Boot clone, set hostname: `sudo hostnamectl set-hostname name-dev`
4. Give user their SSH credentials

## User Guide

### First Login

```bash
./post-setup.sh
```

Follow the prompts. You'll need:
- Your Anthropic account (for Claude Code)
- Your GitHub account

### Daily Use

| Command | What it does |
|---------|-------------|
| `claude` | Start Claude Code |
| `clauded` | Claude with auto-approve |
| `ta` | Attach to tmux |
| `gs` | Git status |
| `./scripts/verify.sh` | Check setup status |

### Getting Help

Just ask Claude. Examples:
- "Clone the xyz repo for me"
- "What's wrong with this error?"
- "Push my changes"

## Web UI Access

Each user can access their environment via browser using Cloudflare Tunnel.

After completing post-setup, run:
```bash
./setup-tunnel.sh
```

This creates a tunnel with their GitHub username as subdomain (e.g., `alice.yourdomain.com`).

To start the web UI:
```bash
cd ~/dev/whoabuddy/claude-rpg
npm run dev
```

## Files

```
scripts/
  pre-setup.sh     ← Admin runs (installs everything)
  post-setup.sh    ← User runs (account setup)
  setup-tunnel.sh  ← User runs (cloudflare tunnel)
  verify.sh        ← Check status

templates/.claude/
  CLAUDE.md        ← Context for Claude Code
  settings.json    ← Default settings
```
