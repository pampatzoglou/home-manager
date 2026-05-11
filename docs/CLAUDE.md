# Claude AI Assistant Configuration

This documentation covers the setup, usage, and maintenance of Claude AI Assistant configuration managed through home-manager.

> ⚠️ **Important:** Always use `task switch` to apply changes — it includes the required `--impure` flag automatically.

## Overview

The Claude configuration provides a declarative, version-controlled approach to managing AI assistant preferences, coding styles, and reusable skills. All configurations are deployed automatically via Nix home-manager.

## Directory Structure

```
home-manager/
├── agentic/
│   └── claude/
│       ├── CLAUDE.md                 # Personal coding preferences
│       ├── settings.json.template    # Permission rules template
│       └── skills/                   # Auto-discovered skill directories
│           ├── argo-applicationset/
│           ├── bootstrap/
│           ├── cicd/
│           ├── code-review/
│           ├── debugging/
│           ├── devbox/
│           ├── document/
│           ├── dockerfile/
│           ├── github-actions/
│           ├── helm/
│           ├── kubernetes/
│           ├── prune/
│           ├── skaffold/
│           ├── taskfile/
│           ├── terraform/
│           └── tidy/
├── .claude/
│   └── CLAUDE.md                     # Project-specific conventions
└── modules/
    └── claude.nix                    # Auto-discovery deployment module
```

## Deployment Mapping

Source files are automatically deployed to your home directory:

| Source | Deployed To | Purpose |
|--------|-------------|---------|
| `agentic/claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Personal coding preferences |
| `agentic/claude/skills/*/` | `~/.claude/skills/*/` | Auto-discovered skill directories |
| `agentic/claude/settings.json.template` | _(manual merge)_ | Permission rules template |

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

### skills/ - Reusable Methodologies

Markdown files or directories containing structured approaches to common development tasks. These are reference documents that Claude can use to perform tasks consistently.

Each skill is a directory under `agentic/claude/skills/` containing a `SKILL.md` entry point and any supporting files. All directories are auto-discovered and deployed recursively.

**Current Skills:**

| Skill | Purpose |
|-------|---------|
| `argo-applicationset` | ArgoCD ApplicationSet authoring |
| `bootstrap` | Scaffold a new project repository |
| `cicd` | Interactive CI/CD workflow generation |
| `code-review` | Security, quality, performance checklists |
| `debugging` | Systematic 6-step debugging methodology |
| `devbox` | Reproducible dev environments via Nix |
| `document` | Generate and update documentation suites |
| `dockerfile` | 3-stage Dockerfile generation |
| `github-actions` | GitHub Actions CI via Taskfile + devbox |
| `helm` | Helm chart authoring and values layering |
| `kubernetes` | Kubernetes manifests, Helm, ArgoCD/GitOps |
| `prune` | Find dead/unused code and AI context bloat |
| `skaffold` | Skaffold + kind local development loop |
| `taskfile` | Standard Taskfile conventions |
| `terraform` | Terraform/HCL review and planning |
| `tidy` | Hunt for mechanical inconsistencies |
| `git` | Conventional commit messages and PR overview descriptions |

### settings.json.template - Permission Rules

Template showing recommended structure for Claude's global settings including:
- Permission rules (auto-approve, require approval, never allow)
- Command allowlists
- File type permissions
- Preferences (verbose mode, file size limits, excluded directories)
- Hook integrations

**Note:** This is a template only. Your actual `~/.claude/settings.json` already exists with hooks configuration. Manual merge is required to preserve existing settings.

## Auto-Discovery System

The `modules/claude.nix` module automatically discovers and deploys all `.md` files and directories from `agentic/claude/skills/`:

### How It Works

1. `modules/claude.nix` reads all non-hidden directories in `agentic/claude/skills/`
2. Each directory is deployed recursively to `~/.claude/skills/<name>/`
3. Symlinks point into the Nix store — atomic, rollback-capable, immutable

```
skills/terraform/     → ~/.claude/skills/terraform/
  ├── SKILL.md
  └── Taskfile.yml
```

Files must be git-tracked (or staged) for Nix flakes to see them.

## Usage

### Adding New Skills

Skills are automatically discovered - no module editing required!

```bash
mkdir agentic/claude/skills/my-skill
vim agentic/claude/skills/my-skill/SKILL.md
git add agentic/claude/skills/my-skill/
task switch
ls ~/.claude/skills/my-skill/
```

Files must be git-tracked or staged before running `task switch`.

### Editing Existing Skills

```bash
vim agentic/claude/skills/debugging/SKILL.md
task switch
```

### Updating Personal Preferences

```bash
vim agentic/claude/CLAUDE.md
task switch
```

### Updating Settings

The `settings.json` is **not** automatically deployed to avoid overwriting existing hooks:

```bash
# 1. Review template
cat agentic/claude/settings.json.template

# 2. Manually merge desired changes into existing file
vim ~/.claude/settings.json

# 3. No deployment needed (file is manually managed)
```

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

## Skill Development Guidelines

When creating new skills, follow these best practices:

### Structure
- **Clear Purpose**: Define what the skill is for
- **Structured Format**: Use headings, lists, checklists, or steps
- **Actionable**: Make it easy for Claude to follow
- **Comprehensive**: Cover edge cases and common pitfalls
- **Context-Aware**: Include technology-specific tips

### Format

```markdown
# Skill Name

## Purpose
Brief description of what this skill does and when to use it.

## Methodology
Step-by-step approach or structured process.

### Step 1: Action
- Specific actions to take
- Things to check
- Commands to run

### Step 2: Next Action
- More specific steps
- Examples when helpful

## Checklist
- [ ] Item to verify
- [ ] Another checkpoint

## Best Practices
- Key principle 1
- Key principle 2

## Common Pitfalls
- What to avoid
- How to prevent issues
```

### Content Guidelines

1. **Be Specific**: Provide concrete examples and commands
2. **Be General**: Avoid over-fitting to one project/use case
3. **Be Practical**: Focus on real-world scenarios
4. **Be Complete**: Cover the full workflow, not just fragments
5. **Be Maintainable**: Keep skills focused and updateable

## Troubleshooting

### Skills Not Deploying

**Problem:** New skill file not appearing in `~/.claude/skills/`

**Solution:**
```bash
# Check if file is tracked in git
git status agentic/claude/skills/

# If untracked, stage it
git add agentic/claude/skills/your-skill/

# Rebuild
task switch

# Verify
ls -la ~/.claude/skills/
```

**Explanation:** Nix flakes only see tracked or staged files in git. Untracked files are invisible.

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
git commit -m "Update Claude skills"
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

### Regular Updates

Keep skills current with your evolving practices:

```bash
# Review and update skills quarterly
vim agentic/claude/skills/terraform/SKILL.md

# Deploy changes
task switch
```

### Version Control

All Claude configuration is in git:

```bash
# View history of changes
git log -- agentic/claude/

# See what changed in a skill
git diff agentic/claude/skills/kubernetes/

# Revert a change
git checkout HEAD~1 -- agentic/claude/skills/debugging/
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

### Environment-Specific Skills

For different environments (work vs personal):

```bash
# Use git includeIf or separate skills directories
agentic/claude/skills/work/
agentic/claude/skills/personal/
```

Modify `modules/claude.nix` to selectively include based on environment variables.

### Skill Templates

Create skill templates for consistency:

```bash
# Create template
cat > agentic/claude/skills/_template.md << 'EOF'
# Skill Name

## Purpose
What this skill does.

## Methodology
How to use it.

## Best Practices
Key principles.
EOF

# Use as starting point for new skills
cp agentic/claude/skills/_template.md agentic/claude/skills/new-skill.md
```

## Integration with Claude

### How Claude Uses These Files

1. **CLAUDE.md**: Read at conversation start to understand your preferences
2. **Skills**: Referenced when performing specific tasks (code review, debugging, etc.)
3. **Settings**: Govern permissions and behavior globally

### Referencing Skills

You can explicitly reference skills in conversations:

```
"Please review this code using the code-review skill"
"Debug this issue following the debugging methodology"
"Set up this infrastructure following the kubernetes skill"
```

### Contextual Usage

Claude may automatically apply relevant skills based on the task:
- Code review → `code-review`
- Infrastructure work → `terraform` or `kubernetes`
- Troubleshooting → `debugging`

## Resources

- [Claude Documentation](https://www.anthropic.com/claude)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Language Basics](https://nixos.org/manual/nix/stable/language/)
- [Agentic Directory README](../agentic/README.md)
- [Claude Module README](../agentic/claude/README.md)

## Summary

The Claude AI Assistant configuration provides:

- ✅ **Declarative Configuration**: Version-controlled AI preferences
- ✅ **Auto-Discovery**: Automatic skill deployment
- ✅ **Reproducible**: Same setup across all machines
- ✅ **Maintainable**: Edit markdown, not code
- ✅ **Portable**: Share with team or other projects
- ✅ **Scalable**: Add unlimited skills easily

All managed through the same home-manager workflow you use for packages and dotfiles.