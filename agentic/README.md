# Agentic AI Configuration

This directory contains configuration files for AI assistants and agentic systems, managed declaratively through home-manager.

## Directory Structure

```
agentic/
└── claude/                    # Claude AI Assistant configuration
    ├── CLAUDE.md              # Personal coding preferences and style
    ├── settings.json.template # Permission rules and preferences template
    └── skills/                # Reusable skills for common tasks
        ├── code-review.md
        ├── debugging.md
        └── infrastructure.md
```

## How It Works

The files in this directory are **source files** that get deployed to your home directory via the `modules/claude.nix` home-manager module.

### Deployment Mapping

| Source File | Deployed To | Purpose |
|------------|-------------|---------|
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Personal coding style and preferences |
| `claude/skills/*.md` | `~/.claude/skills/*.md` | Reusable skills/prompts for common tasks |
| `claude/settings.json.template` | _(manual merge)_ | Template for global permission rules |

## Usage

### Editing Configuration

1. **Edit source files** in `agentic/claude/` directory
2. **Apply changes** with home-manager:
   ```bash
   home-manager switch -b backup --impure
   ```
3. **Verify** files are deployed to `~/.claude/`

### Adding New Skills

Skills are **automatically discovered** from the `claude/skills/` directory!

1. Create a new markdown file in `claude/skills/`:
   ```bash
   touch agentic/claude/skills/my-new-skill.md
   ```

2. Stage the file in git:
   ```bash
   git add agentic/claude/skills/my-new-skill.md
   ```

3. Apply with home-manager switch:
   ```bash
   home-manager switch -b backup --impure
   ```

**Note**: Files must be tracked (or staged) in git for Nix flakes to see them. Untracked files will not be deployed.

**No manual module editing required** - all `.md` files in `skills/` are automatically deployed!

### Settings Configuration

The `settings.json.template` is a **template only** because:
- Your existing `~/.claude/settings.json` has hooks configuration
- Manual merge is required to preserve existing settings
- Prevents accidental overwrites of working configuration

To update settings:
1. Review `claude/settings.json.template`
2. Manually merge desired changes into `~/.claude/settings.json`
3. Test thoroughly

## Benefits of This Approach

### ✅ Maintainability
- Edit markdown and JSON files directly with proper syntax highlighting
- No need to touch Nix code for content changes
- Clear separation between deployment (Nix) and content (markdown/JSON)

### ✅ Version Control
- All configurations tracked in git
- Easy to see what changed in diffs
- Rollback to previous versions if needed

### ✅ Portability
- Same configuration across all machines
- Declarative and reproducible
- Share configurations with team members

### ✅ Organization
- Centralized location for all agentic configs
- Scales easily to other AI assistants (GPT, etc.)
- Clear structure and purpose

## File Formats

### CLAUDE.md
Contains your personal coding preferences, language choices, tool preferences, and communication style. Claude reads this to understand your preferences.

### Skills (*.md)
Reusable prompts/procedures for common tasks:
- **Code Review**: Security, quality, performance checklist
- **Debugging**: Systematic troubleshooting methodology
- **Infrastructure**: DevOps and IaC best practices

Skills can be referenced in conversations or automatically loaded based on context.

### settings.json
Global configuration for Claude:
- **Permissions**: Auto-approve rules, command allowlists
- **Preferences**: Verbose mode, file size limits, excluded directories
- **Hooks**: Integration with external tools (dot-agent-deck, etc.)

## Future Additions

This structure can be extended to support:
- Additional AI assistants (ChatGPT, Copilot, etc.)
- Team-specific conventions
- Project-specific overrides
- Shared skill libraries
- Custom agents/workflows

Example future structure:
```
agentic/
├── claude/
├── copilot/
├── shared-skills/
└── team-conventions/
```

## Notes

- **Settings are global**: Applied to all Claude sessions on this machine
- **Skills are reusable**: Reference them across different projects
- **Project-specific overrides**: Use `.claude/CLAUDE.md` in project repos for project-specific conventions
- **Template files**: Files ending in `.template` are not deployed automatically

## Related Files

- `modules/claude.nix` - Home-manager module that deploys these files
- `.claude/CLAUDE.md` - Project-specific configuration for this repository
- `~/.claude/` - Deployed configuration directory

## Resources

- [Claude Desktop Documentation](https://www.anthropic.com/claude)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Language Basics](https://nixos.org/manual/nix/stable/language/)