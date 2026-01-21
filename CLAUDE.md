# Claude Team Starter

Replicate a working Claude Code development environment for a team.

## Phase 1: Team of 5 (Current)

VirtualBox VMs running Ubuntu Server with identical setups. Users bring their own Anthropic accounts and configure via guided setup.

### Scripts

- `scripts/pre-setup.sh` - Admin runs before user connects (installs packages)
- `scripts/post-setup.sh` - User runs after connecting (account configuration)
- `scripts/verify.sh` - Quick status check

### Templates

- `templates/.claude/CLAUDE.md` - Preloaded context for Claude Code
- `templates/.claude/settings.json` - Default settings

### Installed Packages

- build-essential, cmake, git, tmux, jq
- Node.js LTS via nvm
- Bun
- Claude Code CLI
- cloudflared
- GitHub CLI (installed via post-setup)

### User Configuration Required

1. Claude Code login (Anthropic account)
2. Git name/email
3. SSH key for GitHub
4. GitHub CLI auth
5. Cloudflare tunnel token (optional)

## Phase 2: Scale + Wallet Integration (Future)

- Docker-based deployment for easier scaling
- Stacks wallet authentication (SIWS)
- Agent wallet linked to user wallet via smart contract
- Gamification: keep agent alive, earn reputation
- Web UI layer for tmux access
- Integration with Bitcoin Faces

### Open Questions

- Docker cost scaling analysis
- Revenue model design
- Contract for user<->agent wallet linking
