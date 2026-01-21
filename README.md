# Claude Team Starter

Set up a team of 5 with identical Claude Code development environments on VirtualBox VMs.

## Quick Start (Admin)

### 1. Create Base VM

1. Download Ubuntu Server 24.04 LTS ISO
2. Create new VirtualBox VM:
   - 4GB RAM minimum (8GB recommended)
   - 40GB disk
   - 2+ CPU cores
   - NAT + Host-only networking
3. Install Ubuntu Server (minimal install is fine)
4. Install VirtualBox Guest Additions

### 2. Run Pre-Setup

SSH into the VM and run:

```bash
# Clone this repo
git clone https://github.com/whoabuddy/claude-team-starter.git
cd claude-team-starter

# Run pre-setup for a user
sudo ./scripts/pre-setup.sh username
```

This installs all packages and configures the base environment.

### 3. Clone VMs

1. Shut down the base VM
2. Clone it 5 times (Full Clone, generate new MAC addresses)
3. Name each VM for the team member
4. Boot each VM and set the hostname: `sudo hostnamectl set-hostname name-dev`

### 4. Distribute Access

Give each team member:
- VM IP address or hostname
- Their username/password
- Link to the User Guide below

---

## User Guide

Welcome to your development environment! This guide will help you get set up.

### First Time Setup

1. **Connect to your VM** (your admin will give you connection details)

2. **Run the setup wizard:**
   ```
   ./post-setup.sh
   ```

3. **Follow the prompts** to:
   - Log into Claude Code (you'll need your Anthropic account)
   - Set up your Git identity
   - Create an SSH key for GitHub
   - (Optional) Configure Cloudflare access

### Using Claude Code

Once setup is complete, you can start Claude Code:

```bash
# Start Claude Code
cc

# Start with auto-approve mode (careful!)
ccd

# Resume your last session
ccr
```

### Quick Commands

| Command | What it does |
|---------|-------------|
| `cc` | Start Claude Code |
| `ccd` | Claude Code (auto-approves actions) |
| `ta` | Open/attach tmux session |
| `gs` | Git status |
| `verify.sh` | Check if everything is set up |

### Getting Help

Claude Code is designed to help you with development tasks. Just ask! For example:

- "Help me clone a repository from GitHub"
- "Create a new project for me"
- "What's wrong with this error?"
- "Push my changes to GitHub"

If you're stuck, Claude will help you through it.

### Troubleshooting

**"claude: command not found"**
- Run: `source ~/.bashrc` then try again

**Can't push to GitHub**
- Run `verify.sh` to check your setup
- Make sure your SSH key is added to GitHub

**Need to reconfigure something**
- Run `./post-setup.sh` again

---

## Architecture

```
Ubuntu Server VM
├── System packages (build-essential, cmake, tmux, etc.)
├── Node.js (via nvm)
├── Bun
├── Claude Code CLI
├── cloudflared (optional)
├── GitHub CLI
└── ~/.claude/
    ├── CLAUDE.md (context for Claude)
    └── settings.json
```

## Files

```
claude-team-starter/
├── scripts/
│   ├── pre-setup.sh    # Admin runs before user connects
│   ├── post-setup.sh   # User runs for account setup
│   └── verify.sh       # Check environment status
├── templates/
│   └── .claude/
│       ├── CLAUDE.md   # Copied to user's ~/.claude/
│       └── settings.json
├── CLAUDE.md           # Project documentation
└── README.md           # This file
```

## Phase 2 (Future)

- Docker-based deployment for scaling
- Stacks wallet integration for identity/payments
- Web UI layer for tmux
- Cloudflare tunnel automation
