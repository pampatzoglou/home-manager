# Agentic AI Configuration

Source files for AI assistant configuration, deployed declaratively via home-manager.

## Deployment

| Source | Deployed To | Purpose |
|--------|-------------|---------|
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Personal coding preferences |
| `claude/skills/*/` | `~/.claude/skills/*/` | Auto-discovered skills |
| `claude/settings.json.template` | _(manual merge)_ | Permission rules template |

Skills are auto-discovered — add a directory under `claude/skills/`, stage it in git, and run `task switch`.

See [docs/CLAUDE.md](../docs/CLAUDE.md) for full skill management documentation.
