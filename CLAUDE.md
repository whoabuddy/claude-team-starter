# Claude Team Starter

Persistent Claude agents tied to Stacks wallet identity.

## Concept

Users get their own Ubuntu Server VM running Claude Code with:
- Consistent packages and configuration across all instances
- Stacks wallet authentication (SIP-018 for stateful identity)
- Gamification: keep agent alive, earn reputation
- Potential integration with Bitcoin Faces

## Architecture

### VM Requirements
- Ubuntu Server base image
- Packages: build-essential, cmake, bun, nvm
- Bash aliases, dangerous mode Claude
- GitHub configured for commits
- Cloudflare configured for deploys
- Stacks wallet tied to agent lifecycle

### Access Methods
- SSH with auto-loaded tmux session
- Web tunnel via Cloudflare (scalable)
- Web UI layer for tmux

### Wallet Integration
- User wallet authenticates via SIWS
- Agent wallet linked to user wallet via smart contract
- If instance dies, user can still withdraw funds
- Contract handles the user<->agent wallet relationship

## Setup Strategy

1. Create base Ubuntu Server image with all packages
2. Bootstrap scripts to automate and verify setup
3. User customization layer on top of base

## Open Questions

- How fast does cost ramp with Docker?
- Revenue model that doesn't violate TOS?
- Exact contract design for wallet linking
