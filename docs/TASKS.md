# Task Runner Guide

This project uses [go-task](https://taskfile.dev) for workflow automation and pre-commit validation.

## Quick Start

```sh
# Before committing
task check

# Auto-fix issues
task fix

# Apply configuration
task switch
```

# Task Runner Quick Reference

## 🚀 Most Common Commands

```sh
task check         # Before committing - runs all validation
task fix           # Auto-fix formatting and deadnix issues
task switch        # Apply your configuration changes
task ci            # Full CI validation (same as GitHub Actions)
```

## 📋 Complete Command List

### Pre-Commit Workflow
```sh
task check              # All checks (deadnix, format, syntax, flake, conflicts)
task check:quick        # Fast checks only (syntax + flake)
task fix                # Auto-fix all fixable issues
```

### Build & Deploy
```sh
task build              # Build without switching
task switch             # Build and activate configuration
task switch:trace       # Switch with detailed error output
```

### Maintenance
```sh
task update             # Update all flake inputs
task gc                 # Garbage collect old generations
task gc:safe            # GC keeping last 30 days
task list               # Show all generations
task rollback           # Revert to previous generation
```

### Debugging
```sh
task doctor             # Run Nix diagnostics
task clean              # Clear build cache
task info               # Show flake metadata
task git:check          # Review uncommitted changes
```

## ⚙️ Technical Notes

- All commands use `--impure` flag automatically (required for `builtins.getEnv`)
- Git dirty warnings are normal and expected
- Tasks are defined in `Taskfile.yml`
- Full documentation in `docs/TASKS.md`

## 🆘 Troubleshooting

**Build fails:**
```sh
task clean && task switch:trace
```

**Format/deadnix errors:**
```sh
task fix && task check
```

**Nix daemon issues:**
```sh
sudo launchctl kickstart -k system/org.nixos.nix-daemon
task doctor
```


## Common Commands

### Pre-Commit Checks

| Command | Description |
|---------|-------------|
| `task check` | Run all pre-commit checks (recommended before commit) |
| `task check:quick` | Quick validation (syntax + flake check only) |
| `task check:deadnix` | Check for unused Nix declarations |
| `task check:format` | Check Nix code formatting |
| `task check:syntax` | Validate Nix syntax |
| `task check:flake` | Run `nix flake check` |
| `task check:conflicts` | Check for merge conflicts |

### Auto-Fix

| Command | Description |
|---------|-------------|
| `task fix` | Auto-fix common issues (format + remove deadnix) |
| `task fix:format` | Auto-format Nix files |
| `task fix:deadnix` | Auto-remove unused declarations |

### Build & Deploy

| Command | Description |
|---------|-------------|
| `task build` | Build configuration without switching |
| `task switch` | Build and switch to new configuration |
| `task switch:trace` | Switch with detailed error traces |

### Maintenance

| Command | Description |
|---------|-------------|
| `task update` | Update all flake inputs |
| `task update:input INPUT=nixpkgs` | Update specific flake input |
| `task gc` | Run garbage collection (removes old generations) |
| `task gc:safe` | Safe garbage collection (keeps last 30 days) |
| `task list` | List home-manager generations |
| `task rollback` | Rollback to previous generation |

### Diagnostics

| Command | Description |
|---------|-------------|
| `task info` | Show flake metadata |
| `task clean` | Clean build artifacts and cache |
| `task doctor` | Run nix doctor diagnostics |
| `task git:check` | Git status and diff summary |

### CI/CD

| Command | Description |
|---------|-------------|
| `task ci` | Run full CI checks locally (same as GitHub Actions) |
| `task pre-commit:install` | Install pre-commit hooks |
| `task pre-commit:run` | Run pre-commit hooks manually |

## Recommended Workflow

### Before Committing

```sh
# 1. Check what changed
task git:check

# 2. Run all checks
task check

# 3. Fix any issues
task fix

# 4. Re-run checks to confirm
task check

# 5. Commit changes
git add .
git commit -m "feat: description of changes"
```

### After macOS Update

```sh
# 1. Clean caches
task clean

# 2. Update dependencies
task update

# 3. Rebuild configuration
task switch:trace
```

### Regular Maintenance

```sh
# Weekly: update dependencies
task update

# Monthly: garbage collection
task gc:safe

# Check system health
task doctor
```

## Troubleshooting

### "Command not found: task"

go-task is installed via this configuration. After first install:

```sh
home-manager switch --flake ~/.config/home-manager
```

### "Git tree is dirty" warnings

This is normal and expected when you have uncommitted changes. The checks will still run.

### Check failures

1. **Deadnix warnings**: Run `task fix:deadnix` to auto-remove unused declarations
2. **Format errors**: Run `task fix:format` to auto-format files
3. **Syntax errors**: Fix manually, then run `task check:syntax` to verify
4. **Flake check errors**: Run `task switch:trace` for detailed error messages

### Build fails

```sh
# Clear caches and rebuild
task clean
task switch:trace

# If that fails, check diagnostics
task doctor

# Check Nix daemon
sudo launchctl kickstart -k system/org.nixos.nix-daemon
```

## Integration with CI/CD

The `task ci` command runs the same checks as GitHub Actions:

```.github/workflows/check.yml
name: Check
on: [push, pull_request]
jobs:
  check:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v24
      - name: Run checks
        run: |
          nix run nixpkgs#go-task -- ci
```

## Advanced Usage

### Custom Tasks

You can extend the Taskfile by adding new tasks. Edit `Taskfile.yml`:

```yaml
tasks:
  my-custom-task:
    desc: "My custom task description"
    cmds:
      - echo "Running custom task..."
      - # Your commands here
```

### Environment Variables

```sh
# Override config directory
CONFIG_DIR=/path/to/config task check
```

### Task Dependencies

Tasks can depend on other tasks:

```yaml
tasks:
  deploy:
    deps: [check, build]  # Runs check and build first
    cmds:
      - task: switch
```

## See Also

- [Taskfile.yml](../Taskfile.yml) - Full task definitions
- [MACOS_RECOVERY.md](./MACOS_RECOVERY.md) - Recovery procedures
- [README.md](../README.md) - Project overview
- [go-task documentation](https://taskfile.dev)
