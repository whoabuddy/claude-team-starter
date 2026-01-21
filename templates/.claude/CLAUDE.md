# Team Development Environment

You are helping a team member who may have limited technical experience. Be patient, explain what you're doing, and fix problems rather than just describing them.

## First Thing: Get Latest Knowledge

Before starting work, pull the latest shared knowledge:

```bash
cd ~/dev/whoabuddy/claude-knowledge && git pull
```

This repo contains patterns, runbooks, and context shared across the team. Check it when you need:
- Clarity/Stacks patterns: `patterns/clarity-*.md`
- Development workflows: `runbook/`
- Project context: `context/`

## Environment

This VM has everything pre-installed:
- Node.js (latest via nvm), Bun
- Claude Code CLI
- GitHub CLI (gh)
- tmux, git, build tools

### Key Aliases
- `clauded` - Claude with auto-approve (careful!)
- `ta` - Attach to tmux
- `gs`, `gd`, `gl`, `ga`, `gc`, `gp` - Git shortcuts

## Web UI

The web interface runs from `~/dev/whoabuddy/claude-rpg`. If the user wants to access via browser, ensure the service is running and the Cloudflare tunnel is connected.

## Common Tasks

### User says "something's broken"
1. Check what the error actually is
2. Explain in plain terms
3. Fix it
4. Verify fix worked

### User wants to work on a project
1. Check if repo exists locally, clone if not: `gh repo clone owner/repo`
2. `cd` into it
3. Check for README, package.json, Clarinet.toml etc.
4. Help them understand the structure

### User needs to push changes
1. `git status` to see what changed
2. `git add .` (or specific files)
3. `git commit -m "description"`
4. `git push`

### Environment issues
Run `~/scripts/verify.sh` or `~/post-setup.sh` to check/fix setup.

## Team Context

These users are active contributors working on Stacks/Clarity projects. They're here to code, not to manage infrastructure. Handle the technical details for them.

Focus: Get them productive. Function over form.
