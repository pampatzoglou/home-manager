# 🚀 Continuous Integration (CI)

This repository uses GitHub Actions for automated testing and validation of the Home-Manager configuration.

## 📋 CI Pipeline Overview

The CI pipeline runs automatically on:
- **Push** to `main` or `master` branches
- **Pull Requests** targeting `main` or `master`
- **Manual trigger** via GitHub Actions UI
- **Weekly schedule** (Sundays at midnight UTC)

## 🔍 CI Jobs

### 1. License Compliance
- ✅ Validates LICENSE file exists
- ✅ Ensures LICENSE is not empty
- 🎯 **Purpose**: Maintain proper licensing

### 2. Lint & Format Check
- ✅ Nix code formatting (`nixpkgs-fmt`)
- ✅ Dead code detection (`deadnix`)
- 🎯 **Purpose**: Code quality and consistency

### 3. Flake Validation (Multi-Platform)
Tests on all supported architectures:
- Linux x86_64 (`ubuntu-latest`)
- macOS Intel (`macos-13`)
- macOS Apple Silicon (`macos-14`)

Each platform runs:
- `nix flake metadata` - Show flake info
- `nix flake show` - Display outputs
- `nix flake check` - Validate flake structure
- Dry-run build test

### 4. Build Test (Multi-Platform)
Full build verification on all platforms:
- Builds the complete home-manager configuration
- Validates all modules load correctly
- Catches evaluation and syntax errors

### 5. CI Summary
- Aggregates results from all jobs
- Provides clear pass/fail status
- Reports which checks succeeded or failed

## 🛠️ Local Development

### Pre-commit Hooks (Optional)

Install pre-commit hooks for automatic validation before commits:

```bash
# Install pre-commit
nix-shell -p pre-commit --run "pre-commit install"

# Run manually on all files
nix-shell -p pre-commit --run "pre-commit run --all-files"
```

### Manual Validation

Run the same checks locally before pushing:

```bash
# Check flake
nix flake check --impure

# Format Nix files
nix run nixpkgs#nixpkgs-fmt -- .

# Check for dead code
nix run nixpkgs#deadnix -- .

# Test build
nix build .#homeConfigurations.${USER}.activationPackage --impure --dry-run
```

## 🔧 CI Configuration

The CI workflow is defined in `.github/workflows/default.yaml`:
- Uses Determinate Systems' Nix installer for faster setup
- Leverages Magic Nix Cache for build acceleration
- Fails fast is disabled to see all platform results
- Includes detailed trace output for debugging

## 📊 CI Status Badge

The README displays the CI status:

```markdown
[![CI](https://github.com/pampatzoglou/home-manager/actions/workflows/default.yaml/badge.svg)](https://github.com/pampatzoglou/home-manager/actions/workflows/default.yaml)
```

## 🐛 Troubleshooting

### CI Failure on Formatting
```bash
# Fix locally
nix run nixpkgs#nixpkgs-fmt -- .
git add -u
git commit -m "fix: format nix files"
```

### CI Failure on Dead Code
```bash
# Check dead code
nix run nixpkgs#deadnix -- .

# Remove dead code
nix run nixpkgs#deadnix -- -e .
```

### CI Failure on Build
```bash
# Test locally with verbose output
nix build .#homeConfigurations.${USER}.activationPackage \
  --impure \
  --show-trace \
  --print-build-logs
```

## 🔐 Security

- All CI jobs run in isolated GitHub-hosted runners
- No secrets or credentials are stored in the workflow
- Impure evaluation is used only for username detection
- Weekly runs catch upstream dependency issues

## 📈 Future Enhancements

Potential improvements:
- [ ] Add Cachix for faster builds across platforms
- [ ] Implement dependency update automation (Dependabot/Renovate)
- [ ] Add security scanning for dependencies
- [ ] Create release automation workflow
- [ ] Add documentation build/deploy step

---

**💡 Tip**: The weekly scheduled run helps catch issues from upstream Nixpkgs changes early!
