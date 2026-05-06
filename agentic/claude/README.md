# Claude AI Assistant Configuration

This directory contains Claude-specific configuration files that are deployed to `~/.claude/` via home-manager.

## Files

### CLAUDE.md
Your personal coding preferences, language choices, and communication style. Claude reads this file to understand how you prefer to work.

**Content includes:**
- Preferred programming languages and tools
- Code style and formatting preferences
- Best practices and development workflow
- Tool preferences (editor, shell, package management)
- Communication style preferences

### settings.json.template
Template for global Claude settings including permissions and preferences.

**⚠️ Note:** This is a template only. Your actual `~/.claude/settings.json` already exists with hooks configuration. Manual merge is required.

**Content includes:**
- Permission rules (auto-approve, require approval, never allow)
- Command allowlists
- File type permissions
- Preferences (verbose mode, file size limits)
- Hook integrations

### skills/
Reusable skills and procedures for common development tasks. These are reference documents that Claude can use to perform structured tasks.

#### code-review.md
Comprehensive code review checklist covering:
- Security vulnerabilities
- Code quality and maintainability
- Performance considerations
- Testing coverage
- Documentation requirements
- Nix-specific considerations

#### debugging.md
Systematic debugging methodology:
- 6-step debugging process (Reproduce, Isolate, Hypothesize, Test, Fix, Verify)
- Common issues checklist (environment, concurrency, resources, data, permissions)
- Tools and techniques for different scenarios
- Nix-specific debugging tips
- Prevention strategies

#### infrastructure.md
Infrastructure and DevOps best practices:
- Core principles (declarative, immutable, version controlled, automated)
- Terraform best practices
- Kubernetes deployment strategies
- Monitoring and observability (metrics, logs, traces)
- Security and compliance
- CI/CD pipelines
- Disaster recovery
- Nix-specific infrastructure patterns

## Deployment

These files are automatically deployed by the `modules/claude.nix` home-manager module:

```nix
# Source files in this directory are copied to ~/.claude/
".claude/CLAUDE.md" = { source = ../agentic/claude/CLAUDE.md; };
".claude/skills/code-review.md" = { source = ../agentic/claude/skills/code-review.md; };
# ... etc
```

## How to Use

### Editing Configuration

1. Edit files in this directory (`agentic/claude/`)
2. Run: `home-manager switch --flake . --impure`
3. Files are automatically deployed to `~/.claude/`

### Adding New Skills

Skills are **automatically discovered** from the `skills/` directory!

1. Create `skills/my-skill.md` in this directory
2. Stage the file in git: `git add agentic/claude/skills/my-skill.md`
3. Run `home-manager switch -b backup --impure`

**Note**: Files must be tracked (or staged) in git for Nix flakes to see them. Untracked files will not be deployed.

**No need to edit `modules/claude.nix`** - all `.md` files in `skills/` are automatically deployed to `~/.claude/skills/`

### Updating settings.json

The settings.json.template shows the recommended structure. To update your actual settings:

1. Review the template
2. Manually edit `~/.claude/settings.json`
3. Merge desired changes while preserving existing hooks
4. Test thoroughly

## Why This Structure?

**Maintainability:**
- Edit markdown/JSON files directly with proper syntax highlighting
- No need to modify Nix code for content changes
- Clear separation of concerns (deployment vs. content)

**Version Control:**
- All changes tracked in git
- Easy to review diffs
- Simple rollback if needed

**Portability:**
- Same configuration across all machines
- Declarative and reproducible
- Easy to share with team members

## Skills Best Practices

When creating new skills:

1. **Clear Purpose**: Define what the skill is for
2. **Structured Format**: Use checklists, steps, or methodologies
3. **Actionable**: Make it easy for Claude to follow
4. **Comprehensive**: Cover edge cases and common pitfalls
5. **Context-Aware**: Include technology-specific tips (Nix, K8s, etc.)
6. **Maintainable**: Keep skills focused and updateable

## Integration with Claude

Claude can:
- Read `CLAUDE.md` to understand your preferences
- Reference skills when performing tasks
- Follow methodologies from skill documents
- Adapt behavior based on your settings

Skills are most effective when:
- Referenced explicitly in conversations
- Matched to the type of task being performed
- Updated regularly based on your evolving practices

## Related

- `../../modules/claude.nix` - Deployment module
- `../../.claude/CLAUDE.md` - Project-specific overrides for this repo
- `~/.claude/` - Deployed configuration directory