# Home Manager Project Configuration

## Project Overview

This is a Nix-based home-manager configuration for managing user environment declaratively.

## Architecture

- **Base Configuration**: `base.nix` - Core settings, imports all modules
- **Modular Design**: `modules/` directory contains feature-specific configurations
- **Flake-based**: Uses Nix flakes for reproducible builds
- **Auto-detection**: Automatically detects username and system type

## Directory Structure

```
.
├── agentic/              # Agentic AI configurations (Claude, skills, etc.)
│   └── claude/           # Claude-specific files
│       ├── CLAUDE.md     # Personal coding preferences
│       ├── skills/       # Reusable skills
│       └── settings.json.template
├── modules/              # Home-manager modules
│   ├── packages.nix      # Package installations
│   ├── zsh.nix          # Shell configuration
│   ├── git.nix          # Git settings
│   ├── helix.nix        # Helix editor config
│   ├── kubernetes.nix   # K8s tools and aliases
│   └── ...
├── base.nix             # Main configuration entry point
└── flake.nix            # Flake definition
```

## Conventions

### Nix Code Style

- **Formatting**: Use `nixpkgs-fmt` or `alejandra` for consistent formatting
- **Indentation**: 2 spaces
- **Line Length**: Aim for 100 characters max
- **Attribute Sets**: Use `{ ... }:` pattern for function arguments
- **Let-In Blocks**: For computed values and intermediate variables
- **Comments**: Explain "why" for non-obvious decisions

### Module Structure

Each module should:
- Be self-contained and focused on one concern
- Export configuration via home-manager options
- Use `config`, `pkgs`, `lib` parameters
- Include descriptive comments for complex logic
- Follow existing module patterns

### File Organization

- One module per file in `modules/`
- Related configurations grouped together
- Separate packages from configuration
- Use `imports` in `base.nix` to load modules

## Development Workflow

### Making Changes

1. Edit the relevant `.nix` file
2. Test with: `home-manager switch --flake . --impure`
3. Verify the change worked as expected
4. Commit with conventional commit message

### Adding New Modules

1. Create new file in `modules/`
2. Follow existing module patterns
3. Add import to `base.nix`
4. Test thoroughly before committing

### Testing

- Test changes in a new terminal session
- Verify programs launch correctly
- Check for any warnings or errors during switch
- Use `nix flake check` to validate flake

### Debugging

- Use `nix repl` to test expressions
- Check `home-manager switch` output for errors
- Review `~/.config/home-manager` for generated configs
- Use `home-manager generations` to see history
- Rollback with `home-manager generations` if needed

## Best Practices

### Nix-Specific

- **Pure Functions**: Prefer pure derivations
- **Pinning**: flake.lock pins all dependencies
- **Caching**: Use cachix for faster builds
- **Evaluation**: Keep evaluation fast (avoid expensive computations)
- **Documentation**: Document non-obvious configurations

### Security

- Never commit secrets to the repository
- Use environment variables or secret managers for sensitive data
- Review permissions in settings.json
- Be cautious with auto-approvals

### Maintainability

- Keep modules focused and single-purpose
- Avoid duplication (use `lib` functions)
- Comment complex or non-obvious code
- Keep dependencies minimal
- Regular updates via `nix flake update`

## Common Tasks

### Update All Packages

```bash
nix flake update
home-manager switch --flake . --impure
```

### Add a New Package

1. Add to `modules/packages.nix` in appropriate category
2. Run `home-manager switch --flake . --impure`

### Add New Configuration File

1. Create source file in appropriate location (e.g., `agentic/`)
2. Add `home.file` entry in relevant module
3. Use `source` for files, `text` for small inline content

### Rollback Changes

```bash
home-manager generations
home-manager switch --switch-generation <number>
```

## Integration Points

### System Dependencies

- Requires Nix package manager installed
- Works on macOS and Linux
- Uses `builtins.currentSystem` for platform detection

### External Tools

- Git for version control
- Home-manager CLI for activation
- Nix flakes for dependency management

## Notes for AI Assistants

- Always use `source` for file content when possible (more maintainable)
- Test changes with `home-manager switch --flake . --impure`
- Follow the existing module patterns in `modules/`
- Keep the modular architecture intact
- Preserve the auto-detection features for username/system
- Use appropriate Nix functions from `lib` and `pkgs`
- Format code with `nixpkgs-fmt` before committing