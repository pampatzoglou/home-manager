# Claude Configuration

Files in this directory are deployed to `~/.claude/` via `modules/claude.nix`.

## Structure

| Source | Deployed To | Purpose |
|--------|-------------|---------|
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | Personal coding preferences |
| `skills/*/` | `~/.claude/skills/*/` | Auto-discovered skills |
| `settings.json.template` | _(manual merge)_ | Permission rules template |

## Adding a skill

```bash
mkdir skills/my-skill
vim skills/my-skill/SKILL.md
git add skills/my-skill/
task switch
```

Files must be git-tracked for Nix flakes to see them. See [docs/CLAUDE.md](../../docs/CLAUDE.md) for full documentation.
