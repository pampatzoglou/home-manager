# Claude AI Assistant Configuration

This documentation covers the setup, usage, and maintenance of Claude AI Assistant configuration managed through home-manager.

> ⚠️ **Important:** Always use `task switch` to apply changes — it includes the required `--impure` flag automatically.

## Overview

The Claude configuration provides a declarative, version-controlled approach to managing AI assistant preferences and coding styles, deployed via Nix home-manager. Skills and personas are provided by Claude Code plugins (see below).

## Directory Structure

```
home-manager/
├── agentic/
│   └── claude/
│       └── CLAUDE.md                 # Personal coding preferences
├── .claude/
│   └── CLAUDE.md                     # Project-specific conventions
└── modules/
    └── claude.nix                    # Deployment module
```

## Deployment Mapping

| Source | Deployed To | Purpose |
|--------|-------------|---------|
| `agentic/claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Personal coding preferences |
| _(mentor plugins)_ | `~/.claude/plugins/` | Skills and persona slash commands |

## Configuration Files

### CLAUDE.md - Personal Preferences

Contains your personal coding style, language preferences, and communication style. Claude reads this to understand how you prefer to work.

**Key Sections:**
- Programming languages and tools
- Code style and formatting preferences
- Development workflow and best practices
- Tool preferences (editors, shell, package management)
- Communication style

**Location:** `agentic/claude/CLAUDE.md`

**Example:**
```markdown
## Coding Style & Preferences

### Languages
- **Primary**: Nix, Python, Go, Rust
- **Shell**: Prefer `sh` for portability, `zsh` for interactive

### Code Style
- **Line Length**: 100 characters max
- **Indentation**: 2 spaces for Nix/YAML/JSON, 4 for Python
```

### Skills and Personas - Provided by Plugins

Skills and persona slash commands are **not** deployed from this repo. They come from two
Claude Code plugins in the [mentor](https://github.com/pampatzoglou/mentor) marketplace:

| Plugin | Provides | Invoked as |
|--------|----------|------------|
| `mentor@mentor` | Skills (terraform, kubernetes, helm, debugging, ...) | `/mentor:<skill>` |
| `personas@mentor` | Persona slash commands (architect, sre, staff, ...) | `/personas:<name>` |

Install on a new machine:

```
/plugin marketplace add pampatzoglou/mentor
/plugin install mentor@mentor
/plugin install personas@mentor
```

Enablement is stored in `~/.claude/settings.json`, which this repo does not manage. To change a
skill, edit it in the mentor repo and update the plugin.
## Usage

### Updating Personal Preferences

```bash
vim agentic/claude/CLAUDE.md
task switch
```

### Updating Settings

`~/.claude/settings.json` is **not** managed by this repo; edit it directly. It also holds the
plugin enablement for the mentor plugins.

## Project-Specific Configuration

The `.claude/CLAUDE.md` file in the repository root contains project-specific conventions:

```
.claude/CLAUDE.md  # Home-manager project conventions
```

This file documents:
- Project architecture and structure
- Team conventions and standards
- Module patterns and best practices
- Development workflow for this project
- Testing and deployment procedures

**Use Case:** Claude can reference this for project-specific context when working on home-manager code.

## Troubleshooting

### Skills Appear Twice

**Problem:** The same skill is listed both unprefixed and as `mentor:<name>`

**Solution:** A stale copy exists in `~/.claude/skills/` or `~/.claude/commands/`. This repo no
longer deploys anything there; remove hand-placed leftovers manually.
### Symlink Issues

**Problem:** Files are symlinks to Nix store instead of regular files

**Solution:** This is expected behavior! Home-manager creates symlinks to the Nix store for:
- Atomic updates
- Rollback capability
- Deduplication
- Immutability

The symlinks work transparently - applications read them as normal files.

### Dirty Git Tree Warnings

**Problem:** Seeing "warning: Git tree is dirty" during deployment

**Solution:** This is informational, not an error. It means you have:
- Uncommitted changes
- Staged but uncommitted files
- Untracked files

The deployment will still work. Commit changes when ready:
```bash
git add -A
git commit -m "docs: update Claude preferences"
```

### Flake Attribute Error

**Problem:** Error message about `homeConfigurations."pantelis".activationPackage` not found

**Error:**
```
error: flake 'git+file:///Users/pantelis/.config/home-manager' does not provide 
attribute 'packages.aarch64-darwin.homeConfigurations."pantelis".activationPackage'
```

**Solution:** You forgot the `--impure` flag! The flake uses `builtins.getEnv "USER"` to auto-detect your username, which requires `--impure`:

```bash
# Wrong - will fail
home-manager switch

# Correct - use task which includes --impure automatically
task switch
```

**Explanation:** Without `--impure`, `builtins.getEnv "USER"` returns empty string and the flake attribute isn't found.

## Maintenance

### Version Control

```bash
# View history of changes
git log -- agentic/claude/
```

Skill and persona history lives in the [mentor](https://github.com/pampatzoglou/mentor) repo.
The copies that used to live here are in this repo's git history under
`agentic/claude/skills/` and `agentic/claude/commands/`.
```

### Backup and Restore

Since everything is in git, backup is automatic:

```bash
# Push to remote
git push origin main

# Restore on new machine
git clone https://github.com/your-user/home-manager.git ~/.config/home-manager
task switch
```

## Advanced Topics

### Multiple AI Assistants

The `agentic/` directory is designed to support multiple AI assistants:

```
agentic/
├── claude/       # Claude AI configuration
├── copilot/      # GitHub Copilot (future)
└── shared/       # Shared skills (future)
```

Add new directories as needed and create corresponding modules.

## Integration with Claude

### How Claude Uses These Files

1. **CLAUDE.md**: Read at conversation start to understand your preferences
2. **Skills** (from the `mentor` plugin): Applied when a task matches, or invoked as `/mentor:<skill>`
3. **Personas** (from the `personas` plugin): Invoked as `/personas:<name>`
4. **Settings**: Govern permissions and behavior globally
- Infrastructure work → `terraform` or `kubernetes`
- Troubleshooting → `debugging`

## Resources

- [Claude Documentation](https://www.anthropic.com/claude)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Language Basics](https://nixos.org/manual/nix/stable/language/)
## Summary

The Claude AI Assistant configuration provides:

- ✅ **Declarative Preferences**: Version-controlled `CLAUDE.md`
- ✅ **Single Skill Source**: Skills and personas come from the `mentor` plugins, not this repo
- ✅ **Reproducible**: Same preferences across all machines
All managed through the same home-manager workflow you use for packages and dotfiles.