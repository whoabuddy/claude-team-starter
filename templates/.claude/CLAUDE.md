# Team Member Environment

This is a pre-configured development environment. Claude Code should help users regardless of their technical experience level.

## User Context

This user may have limited technical experience. When helping:
- Explain what you're doing and why in plain language
- Don't assume familiarity with command line, git, or programming concepts
- Offer to do tasks for them rather than giving complex instructions
- If something fails, explain what went wrong and fix it
- Proactively check if setup is complete before attempting other tasks

## Environment Status Check

Before starting any development work, verify the environment is properly configured by checking:

```bash
# Check Claude login
claude config list | grep primaryEmail

# Check git config
git config --global user.name && git config --global user.email

# Check SSH key exists
ls ~/.ssh/id_*.pub

# Check GitHub CLI auth
gh auth status
```

If any of these fail, help the user run `~/post-setup.sh` or walk them through configuration manually.

## Available Tools

### Development
- **Node.js** via nvm - JavaScript/TypeScript runtime
- **Bun** - Fast JavaScript runtime and package manager
- **build-essential** - C/C++ compiler toolchain
- **cmake** - Build system

### Collaboration
- **git** - Version control
- **gh** - GitHub CLI for PRs, issues, etc.
- **tmux** - Terminal multiplexer

### Deployment
- **cloudflared** - Cloudflare tunnel for web access

## Quick Aliases

The user has these aliases available:
- `cc` - Start Claude Code
- `ccd` - Claude Code with dangerous mode (auto-approve)
- `ccr` - Resume last Claude session
- `ta` - Attach to tmux (or create new session)
- `gs`, `gd`, `gl`, `ga`, `gc`, `gp` - Git shortcuts

## Common Tasks

### "I want to start a new project"
1. Create directory: `mkdir ~/projects/project-name && cd ~/projects/project-name`
2. Initialize git: `git init`
3. Help them scaffold based on project type

### "I want to clone a repository"
1. Check GitHub auth: `gh auth status`
2. Clone: `gh repo clone owner/repo ~/projects/repo`
3. Navigate: `cd ~/projects/repo`
4. Install deps if needed

### "I need to push my changes"
1. Check remote: `git remote -v`
2. If no remote, help them create a repo: `gh repo create`
3. Stage, commit, push: `git add . && git commit -m "message" && git push`

### "Something broke" / Error occurred
1. Read the error message carefully
2. Explain what it means in plain terms
3. Fix it or suggest a fix
4. Verify the fix worked

## Project-Specific Context

<!-- Add team-specific context below -->

### Team Info
- Team: [Team name - to be configured]
- Focus: [What the team is building]
- Main repos: [Key repositories]

### Contacts
- Admin: [Who to contact for environment issues]

---

*This environment is managed by claude-team-starter. If you're the admin, update this file at `~/dev/whoabuddy/claude-team-starter/templates/.claude/CLAUDE.md` and re-run pre-setup for changes to propagate.*
