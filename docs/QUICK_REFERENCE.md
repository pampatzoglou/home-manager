# Quick Reference Guide

Essential commands and workflows for managing this home-manager configuration.

## 🚀 Most Common Commands

### Deploy Changes
```bash
# Specify your username explicitly in the flake reference
home-manager switch --flake .#pantelis --impure

# Or use dynamic substitution
home-manager switch --flake .#$(whoami) --impure
```

### Update Packages
```bash
# Update flake inputs (nixpkgs, home-manager)
nix flake update

# Apply updates
home-manager switch --flake . --impure
```

### Check for Issues
```bash
# Validate flake
nix flake check --impure

# Check home-manager configuration
home-manager switch --flake . --impure --dry-run
```

### Rollback
```bash
# List generations
home-manager generations

# Rollback to previous generation
home-manager switch --switch-generation <number>
```

## 🤖 Claude AI Skills

### Add New Skill
```bash
# 1. Create skill file
vim agentic/claude/skills/my-skill.md

# 2. Stage in git (required!)
git add agentic/claude/skills/my-skill.md

# 3. Deploy
home-manager switch -b backup --impure

# 4. Verify
ls ~/.claude/skills/
```

### Edit Existing Skill
```bash
# 1. Edit
vim agentic/claude/skills/debugging.md

# 2. Deploy (file already tracked)
home-manager switch --flake . --impure
```

### Current Skills
- `code-review.md` - Security, quality, performance checklists
- `debugging.md` - 6-step systematic debugging
- `infrastructure.md` - DevOps, monitoring, CI/CD
- `kubernetes.md` - Platform-aware K8s management
- `terraform.md` - General IaC methodology

## 📦 Package Management

### Add Package
```bash
# Edit appropriate module
vim modules/packages/development.nix

# Add package to list
pkgs.your-package

# Apply
home-manager switch --flake . --impure
```

### Search for Package
```bash
# Search nixpkgs
nix search nixpkgs <package-name>

# Example
nix search nixpkgs terraform
```

## 🐚 Shell Configuration

### Add Alias
```bash
# Edit zsh module
vim modules/zsh.nix

# Add to shellAliases section
k = "kubectl";

# Apply
home-manager switch --flake . --impure
```

### Update Starship Prompt
```bash
# Edit starship module
vim modules/starship.nix

# Apply
home-manager switch --flake . --impure
```

## 🔧 Troubleshooting

### Common Errors

#### "does not provide attribute homeConfigurations"
**Problem:** Forgot `--impure` flag

**Solution:**
```bash
# Wrong - missing --impure
home-manager switch

# Correct
home-manager switch --flake . --impure

# Also correct - with backups (recommended)
home-manager switch -b backup --impure
```

#### "Git tree is dirty"
**Info:** Just a warning, not an error. You have uncommitted changes.

**Solution:** Commit when ready:
```bash
git add -A
git commit -m "Your message"
```

#### Skills Not Deploying
**Problem:** File not tracked in git

**Solution:**
```bash
# Stage the file
git add agentic/claude/skills/new-skill.md

# Deploy
home-manager switch --flake . --impure
```

### Debug Mode
```bash
# Verbose output
home-manager switch --flake . --impure --verbose

# Show trace on errors
home-manager switch --flake . --impure --show-trace
```

## 🧹 Maintenance

### Garbage Collection
```bash
# Manual cleanup (keeps last 7 days)
nix-collect-garbage --delete-older-than 7d

# Aggressive cleanup (keeps only current generation)
nix-collect-garbage -d
```

### View Disk Usage
```bash
# Check Nix store size
du -sh /nix/store

# List generations
home-manager generations
```

### Clean Old Generations
```bash
# Remove old generations
home-manager expire-generations "-7 days"

# Then run garbage collection
nix-collect-garbage
```

## 📝 Git Workflow

### Stage and Deploy
```bash
# Stage all changes
git add -A

# Deploy without committing
home-manager switch -b backup --impure

# Commit when satisfied
git commit -m "Description of changes"
```

### View Changes
```bash
# See what changed
git status

# Diff specific file
git diff modules/claude.nix

# View skill changes
git diff agentic/claude/skills/
```

## 🔍 Inspection

### View Current Configuration
```bash
# Show current generation
home-manager generations | head -1

# List all packages
home-manager packages

# Show specific module output
nix eval .#homeConfigurations.$(whoami).config.programs.zsh.enable --impure
```

### Verify Deployments
```bash
# Check Claude files
ls -la ~/.claude/

# Check skills
ls -la ~/.claude/skills/

# Follow symlinks
readlink ~/.claude/CLAUDE.md
```

## 📚 Documentation Quick Links

- **Main README**: `README.md`
- **Architecture**: `docs/ARCHITECTURE.md`
- **Claude Setup**: `docs/CLAUDE.md`
- **Tools Reference**: `docs/TOOLS.md`
- **Tasks Guide**: `docs/TASKS.md`

## 💡 Pro Tips

1. **Always use `--impure`** - Required for username auto-detection
2. **Stage files in git** - Nix flakes only see tracked/staged files
3. **Test before committing** - Deploy staged changes, verify, then commit
4. **Use dry-run** - Add `--dry-run` to preview changes without applying
5. **Keep generations** - Don't aggressive GC immediately, keep fallback options

## 🎯 Daily Workflow

```bash
# Morning: Update everything
cd ~/.config/home-manager
nix flake update
home-manager switch --flake . --impure

# During day: Add/edit configs
vim modules/packages.nix
git add modules/packages.nix
home-manager switch --flake . --impure
```

# End of day: Commit changes
git add -A
git commit -m "Daily updates: $(date +%Y-%m-%d)"
git push
```

## ⚡ One-Liners

```bash
# Quick deploy
cd ~/.config/home-manager && home-manager switch --flake . --impure

# Update and deploy
cd ~/.config/home-manager && nix flake update && home-manager switch --flake . --impure

# Add skill and deploy
git add agentic/claude/skills/*.md && home-manager switch --flake . --impure

# Emergency rollback
home-manager generations && home-manager switch --switch-generation $(home-manager generations | sed -n '2p' | awk '{print $5}')
```

## 🆘 Emergency Recovery

### Broken Configuration
```bash
# Rollback to last working generation
home-manager generations
home-manager switch --switch-generation <last-good-number>

# Or use git
git log --oneline
git checkout <last-good-commit>
home-manager switch --flake . --impure
```

### Nix Issues (macOS)
See `docs/MACOS_RECOVERY.md` for comprehensive troubleshooting.

---

> **Remember:** `--impure` is required for all `home-manager switch` commands in this flake!  
> **Tip:** Add `-b backup` to create backups of existing files before replacing them (recommended).