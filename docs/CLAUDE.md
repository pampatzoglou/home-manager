# Claude AI Assistant Configuration

This documentation covers the setup, usage, and maintenance of Claude AI Assistant configuration managed through home-manager.

> ⚠️ **Important:** All `home-manager` commands for this flake require the `--impure` flag due to auto-detection of username via `builtins.getEnv "USER"`.
> 
> **Recommended:** `home-manager switch -b backup --impure` (creates backups)  
> **Alternative:** `home-manager switch --flake . --impure` (no backups)

## Overview

The Claude configuration provides a declarative, version-controlled approach to managing AI assistant preferences, coding styles, and reusable skills. All configurations are deployed automatically via Nix home-manager.

## Directory Structure

```
home-manager/
├── agentic/                          # AI assistant configurations
│   ├── README.md                     # Agentic directory overview
│   └── claude/                       # Claude-specific configuration
│       ├── CLAUDE.md                 # Personal coding preferences
│       ├── README.md                 # Claude-specific docs
│       ├── settings.json.template    # Permission rules template
│       └── skills/                   # Reusable skills (auto-discovered)
│           ├── code-review.md
│           ├── debugging.md
│           ├── infrastructure.md
│           ├── kubernetes.md
│           └── terraform.md
│
├── .claude/                          # Project-specific overrides
│   └── CLAUDE.md                     # Home-manager project conventions
│
└── modules/
    └── claude.nix                    # Deployment module (auto-discovery)
```

## Deployment Mapping

Source files are automatically deployed to your home directory:

| Source | Deployed To | Purpose |
|--------|-------------|---------|
| `agentic/claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Personal coding preferences |
| `agentic/claude/skills/*.md` | `~/.claude/skills/*.md` | Auto-discovered skills |
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

**Organization:** Skills can be organized as:
- **Flat files** - Single `.md` file for simple skills (e.g., `code-review.md`)
- **Directories** - Folder with multiple files for complex skills (e.g., `terraform/`, `kubernetes/`)

**Current Skills:**

#### code-review.md
Comprehensive code review checklist covering:
- Security vulnerabilities and best practices
- Code quality and maintainability standards
- Performance considerations
- Testing coverage requirements
- Documentation completeness
- Language-specific considerations (Nix, etc.)

#### debugging.md (Flat File)
Systematic debugging methodology:
- 6-step process: Reproduce → Isolate → Hypothesize → Test → Fix → Verify
- Common issues checklist (environment, concurrency, resources, data, permissions)
- Tools and techniques for different scenarios
- Language-specific debugging tips (Nix, etc.)
- Prevention strategies

#### infrastructure.md (Flat File)
Infrastructure and DevOps best practices:
- Core principles (declarative, immutable, version controlled, automated)
- Terraform patterns and best practices
- Kubernetes deployment strategies
- Monitoring and observability (metrics, logs, traces)
- Security and compliance guidelines
- CI/CD pipeline design
- Disaster recovery procedures

#### kubernetes/ (Directory Structure)
Kubernetes resource management with multiple focused documents:
- **SKILL.md** - Main Kubernetes skill overview
- **authoring-helm-charts.md** - Helm chart best practices
- **resource-standards.md** - K8s resource standards
- **reviewing-manifests.md** - Manifest review checklist
- **troubleshooting.md** - K8s troubleshooting guide
- **taskfile.md** - Task automation patterns
- **devbox.md** - Devbox configuration
- **skaffold.md** - Skaffold workflows
- **github-actions.md** - CI/CD integration
- **team-conventions.md** - Team-specific patterns

Key topics:
- Repository structure conventions from actual projects
- GitOps with ArgoCD sync wave strategies
- Helm chart best practices and patterns
- Security contexts and RBAC
- High availability configurations
- Operator-based resources (databases, messaging)
- Platform integration (TLS, secrets, DNS, monitoring)

#### terraform/ (Directory Structure)
Terraform infrastructure as code with example configurations:
- **SKILL.md** - Main Terraform methodology
- **devbox.json** - Example devbox configuration
- **Taskfile.yml** - Example task automation
- **github-actions.yml** - Example CI/CD pipeline
- **audit-triage.md** - Security audit procedures
- **.pre-commit-config.yaml** - Pre-commit hooks
- **.gitignore** - Terraform-specific gitignore

Key topics:
- Core principles and best practices
- Project structure and organization
- Variable design and validation
- Module composition patterns
- State management strategies
- Workflow methodology (dev, team, promotion)
- Testing and validation approaches
- Troubleshooting methodology

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

1. **Directory Scan**: Reads all entries in `agentic/claude/skills/`
2. **Filter**: Selects `.md` files and non-hidden directories
3. **Map**: Creates deployment mappings to `~/.claude/skills/`
   - Flat files: Direct copy
   - Directories: Recursive copy (preserves structure)
4. **Deploy**: Symlinks files/directories to Nix store during activation

### Supported Structures

**Flat Files:**
```
skills/code-review.md → ~/.claude/skills/code-review.md
skills/debugging.md   → ~/.claude/skills/debugging.md
```

**Directories:**
```
skills/terraform/     → ~/.claude/skills/terraform/ (recursive)
  ├── SKILL.md
  ├── devbox.json
  └── Taskfile.yml
```

### Benefits

- ✅ **No manual configuration**: Add skills without editing Nix modules
- ✅ **Scalable**: Add 1 or 100 skills with the same workflow
- ✅ **Flexible**: Support both simple and complex skill structures
- ✅ **Maintainable**: Skills are just markdown files or organized folders
- ✅ **Safe**: Git tracking ensures intentional deployments
- ✅ **Clean**: No boilerplate in Nix code

## Usage

### Adding New Skills

Skills are automatically discovered - no module editing required!

**Option 1: Simple Flat File** (for single-topic skills)

```bash
# 1. Create skill file
vim agentic/claude/skills/my-new-skill.md

# 2. Stage in git (required for Nix flakes)
git add agentic/claude/skills/my-new-skill.md

# 3. Deploy (--impure is required!)
home-manager switch --flake . --impure

# 4. Verify deployment
ls -la ~/.claude/skills/
```

**Option 2: Directory Structure** (for complex multi-document skills)

```bash
# 1. Create directory and files
mkdir -p agentic/claude/skills/my-skill
cat > agentic/claude/skills/my-skill/SKILL.md << 'EOF'
# My Skill
Main skill documentation here
EOF

# Add supporting files
vim agentic/claude/skills/my-skill/examples.md
vim agentic/claude/skills/my-skill/devbox.json
vim agentic/claude/skills/my-skill/Taskfile.yml

# 2. Stage all files in git
git add agentic/claude/skills/my-skill/

# 3. Deploy
home-manager switch --flake . --impure

# 4. Verify deployment
ls -la ~/.claude/skills/my-skill/
```

**Important:** Files must be tracked (or staged) in git for Nix flakes to see them. Untracked files will not be deployed.

### Editing Existing Skills

```bash
# 1. Edit the skill
vim agentic/claude/skills/debugging.md

# 2. Changes are already tracked (file exists in git)
# 3. Deploy
home-manager switch --flake . --impure

# 4. View deployed version
cat ~/.claude/skills/debugging.md
```

### Updating Personal Preferences

```bash
# 1. Edit preferences
vim agentic/claude/CLAUDE.md

# 2. Deploy
home-manager switch --flake . --impure

# 3. Verify
cat ~/.claude/CLAUDE.md
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
git add agentic/claude/skills/your-skill.md

# Rebuild (--impure is required!)
home-manager switch --flake . --impure

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

# Correct - will work
home-manager switch --flake . --impure

# Also correct - with backups (recommended)
home-manager switch -b backup --impure
```

**Explanation:** Without `--impure`, `builtins.getEnv "USER"` returns an empty string, so Nix looks for `homeConfigurations.""` which doesn't exist.

**Note:** The `-b backup` flag creates backups of existing files before replacing them, which is recommended for safety.

## Maintenance

### Regular Updates

Keep skills current with your evolving practices:

```bash
# Review and update skills quarterly
vim agentic/claude/skills/terraform.md

# Deploy changes
home-manager switch --flake . --impure
```

### Version Control

All Claude configuration is in git:

```bash
# View history of changes
git log -- agentic/claude/

# See what changed in a skill
git diff agentic/claude/skills/kubernetes.md

# Revert a change
git checkout HEAD~1 -- agentic/claude/skills/debugging.md
```

### Backup and Restore

Since everything is in git, backup is automatic:

```bash
# Push to remote
git push origin main

# Restore on new machine
git clone https://github.com/your-user/home-manager.git ~/.config/home-manager
home-manager switch --flake . --impure
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
- Code review → code-review.md
- Infrastructure work → terraform.md or kubernetes.md
- Troubleshooting → debugging.md

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