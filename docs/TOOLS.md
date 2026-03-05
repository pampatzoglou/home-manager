# 🛠️ Tools Reference Guide

A comprehensive reference for all 140+ tools included in this home-manager configuration.

## 📑 Table of Contents

- [Modern CLI Alternatives](#-modern-cli-alternatives)
- [Development Tools](#-development-tools)
- [Kubernetes & Container Tools](#-kubernetes--container-tools)
- [Infrastructure as Code](#️-infrastructure-as-code)
- [Security & Compliance](#-security--compliance)
- [Cloud Provider Tools](#️-cloud-provider-tools)
- [Shell & Terminal](#-shell--terminal)
- [Productivity Tools](#-productivity-tools)
- [Quick Reference Cheatsheet](#-quick-reference-cheatsheet)

---

## 🚀 Modern CLI Alternatives

These modern tools replace traditional Unix utilities with better UX, performance, and features.

| Traditional | Modern Alternative | Description | Key Features |
|-------------|-------------------|-------------|--------------|
| `ls` | `eza` | Better file listing | Icons, git status, colors |
| `cat` | `bat` | Syntax-highlighted cat | Line numbers, git diff |
| `grep` | `ripgrep` (`rg`) | Fast text search | Respects .gitignore, parallel |
| `find` | `fd` | User-friendly find | Intuitive syntax, fast |
| `du` | `dust` | Disk usage | Visual tree, sorted |
| `df` | `duf` | Disk free space | Color-coded, clean output |
| `top`/`htop` | `btop`/`bottom` | System monitor | Beautiful UI, graphs |
| `ps` | `procs` | Process viewer | Tree view, TCP/UDP ports |
| `cd` | `zoxide` (`z`) | Smart directory jump | Frecency-based navigation |
| `diff` | `delta` | Better git diff | Syntax highlighting, side-by-side |

### Usage Examples

```bash
# File listing with eza
ll                    # Detailed list
la                    # Include hidden files
lt                    # Tree view

# Search with ripgrep
rg "pattern"          # Search in current directory
rg -i "case-insensitive"
rg -t go "pattern"    # Search only Go files

# Find files with fd
fd pattern            # Find files/dirs matching pattern
fd -e go main         # Find Go files named 'main'
fd -H .config         # Include hidden files

# Quick navigation
z project-name        # Jump to frequently used directory
zi                    # Interactive directory picker

# View files
bat file.go           # View with syntax highlighting
cat file.go           # Alias to bat

# Disk usage
duf                   # Show disk usage
dust                  # Show directory sizes
```

---

## 💻 Development Tools

### Editors & IDEs

| Tool | Purpose | Config Location |
|------|---------|----------------|
| **Helix** | Terminal-based editor | `modules/helix.nix` |
| **VS Code** | GUI editor (commented) | - |
| **GoLand** | Go IDE (JetBrains) | - |
| **DataGrip** | Database IDE | - |

### Language Servers

```bash
# Installed LSPs for Helix
gopls                 # Go
rust-analyzer         # Rust
pyright               # Python
bash-language-server  # Bash
terraform-ls          # Terraform
yaml-language-server  # YAML
helm-ls              # Helm charts
taplo                # TOML
nil                  # Nix
marksman             # Markdown
```

### Go Development Stack

```bash
# Core Go tools
go                    # Go compiler and tools
gopls                 # Go language server
golangci-lint         # Meta-linter for Go
gotools               # Additional Go tools
goreleaser            # Release automation
upx                   # Binary compressor

# Aliases (see zsh.nix)
gob                   # go build
gor                   # go run
got                   # go test
gotv                  # go test -v
gomt                  # go mod tidy
golint                # golangci-lint run
gorel                 # goreleaser release --snapshot --clean
govuln                # govulncheck ./...
```

### Build & Task Tools

| Tool | Purpose | Usage |
|------|---------|-------|
| **just** | Command runner | `just <task>` |
| **go-task** | Task runner | `task <task>` |
| **make** | Build automation | `make <target>` |
| **entr** | Re-run commands on file change | `ls *.go \| entr go test` |
| **pre-commit** | Git hooks framework | `pre-commit run --all-files` |

### Development Environments

```bash
devbox                # Portable dev environments
devenv                # Nix-powered dev environments
direnv                # Load .envrc automatically
dotenv-cli            # Load .env files

# Usage
devbox init           # Initialize new devbox
devenv init           # Initialize devenv
direnv allow          # Enable direnv in directory
```

---

## ☸️ Kubernetes & Container Tools

### Core Kubernetes Tools

| Tool | Purpose | Key Commands |
|------|---------|--------------|
| **kubectl** | Kubernetes CLI | `k get pods` |
| **helm** | Package manager | `helm install` |
| **k9s** | Terminal UI | `k9s` |
| **lens** | Desktop UI | GUI application |
| **krew** | kubectl plugin manager | `kubectl krew install <plugin>` |

### Installed kubectl Plugins (via krew)

```bash
kubectl-tree          # Show resource ownership tree
kubectl-who-can       # RBAC explorer - check permissions
kubectl-neat          # Clean up kubectl output
kubectl-ctx           # Context switching
kubectl-ns            # Namespace switching
kubectl-outdated      # Find outdated container images
kubectl-resource-capacity  # Resource usage overview
kubectl-cost          # Cost analysis
kubectl-vn            # VPN connectivity
```

### Kubernetes Development Tools

| Tool | Purpose | Usage |
|------|---------|-------|
| **kind** | Local clusters | `kind create cluster` |
| **skaffold** | Dev workflow | `skaffold dev` |
| **tilt** | Local dev orchestration | `tilt up` |
| **argocd** | GitOps CD | `argocd app sync` |
| **istioctl** | Service mesh CLI | `istioctl analyze` |

### Kubernetes Testing & Validation

```bash
kubent                # Find deprecated APIs
kubesec               # Security scanner
kube-bench            # CIS benchmark
kube-linter           # YAML linter
testkube              # Test orchestration
kuttl                 # Kubernetes test tool
kyverno-chainsaw      # Declarative testing
sonobuoy              # Conformance testing
```

### Kubernetes Specialized Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| **cmctl** | cert-manager CLI | Certificate management |
| **velero** | Backup/restore | Disaster recovery |
| **kubeshark** | Traffic viewer | Network debugging |
| **kubectl-cnpg** | CloudNativePG | PostgreSQL on K8s |
| **kubectl-linstor** | Storage management | Persistent volumes |
| **kubelogin-oidc** | OIDC authentication | SSO login |

### Container Tools

```bash
# Docker ecosystem
docker                # Container runtime
docker compose        # Multi-container apps (v2 syntax)
buildkit              # Modern image builder
buildkite-cli         # CI/CD tool

# Aliases
dcu                   # docker compose up -d
dcd                   # docker compose down
dcl                   # docker compose logs -f
dps                   # docker ps
lazydocker            # Docker TUI dashboard
```

---

## 🏗️ Infrastructure as Code

### Terraform Ecosystem

```bash
# Core tools
terraform             # HashiCorp Terraform
opentofu              # OpenTofu (Terraform fork)
terraform-ls          # Language server
terraform-docs        # Generate documentation
tflint                # Terraform linter
tfsec                 # Security scanner
terrascan             # Policy-as-code scanner

# Aliases
tfi                   # terraform init
tfp                   # terraform plan
tfa                   # terraform apply
tfd                   # terraform destroy
tfv                   # terraform validate
tff                   # terraform fmt
```

### Multi-Cloud IaC Tools

| Tool | Best For | Usage |
|------|----------|-------|
| **Pulumi** | Multi-language IaC | `pulumi up` |
| **Crossplane** | K8s-based IaC | `kubectl apply` |
| **Spacectl** | Spacelift CLI | `spacectl stack list` |
| **Ansible** | Configuration mgmt | `ansible-playbook` |

### Platform Engineering

```bash
talosctl              # Talos Linux (K8s OS)
crossplane-cli        # Crossplane management
spacectl              # Spacelift automation

# Usage
talosctl dashboard    # Talos cluster dashboard
crossplane install    # Install Crossplane
```

---

## 🔒 Security & Compliance

### Vulnerability Scanning

| Tool | Purpose | Scans |
|------|---------|-------|
| **trivy** | Container/IaC scanner | Images, repos, K8s |
| **trufflehog** | Secret scanner | Git history |
| **gitleaks** | Git secret scanner | Commits, repos |
| **git-secrets** | Pre-commit hook | Prevents commits |

### Usage Examples

```bash
# Container scanning
trivy image nginx:latest
trivy fs .                    # Scan filesystem
trivy k8s --report summary    # Scan K8s cluster

# Secret scanning
trufflehog git file://. --only-verified
gitleaks detect --source .
git secrets --scan-history
```

### Kubernetes Security

```bash
kube-bench              # CIS Kubernetes benchmark
falcoctl                # Runtime security
kyverno                 # Policy engine
kubescape               # Security posture
datree                  # Policy enforcement

# Usage
kube-bench run          # Run CIS checks
kubescape scan          # Security scan cluster
kyverno apply policy.yaml
```

### IaC Security

```bash
checkov                 # Multi-tool scanner
tfsec                   # Terraform security
kics                    # IaC security scanner
hadolint                # Dockerfile linter

# Usage
checkov -d .            # Scan directory
tfsec .                 # Scan Terraform
hadolint Dockerfile     # Lint Dockerfile
```

### Cryptography & Signing

```bash
# GPG & encryption
gnupg                   # GPG encryption
paperkey                # Backup GPG keys
pgpdump                 # Inspect GPG packets
pinentry-curses         # GPG PIN entry

# Container signing
cosign                  # Sign/verify images

# Password generation
pwgen                   # Password generator
diceware                # Passphrase generator

# Hardware keys
yubikey-manager         # YubiKey management
yubikey-personalization # YubiKey setup
yubico-piv-tool         # PIV operations
```

---

## ☁️ Cloud Provider Tools

### AWS

```bash
awscli2                 # AWS CLI v2

# Common commands
aws s3 ls               # List S3 buckets
aws ec2 describe-instances
aws eks update-kubeconfig --name cluster
```

### Azure

```bash
azure-cli (az)          # Azure CLI

# Common commands
az login                # Authenticate
az account list         # List subscriptions
az aks get-credentials  # Get K8s config
```

### Hetzner Cloud

```bash
hcloud                  # Hetzner Cloud CLI

# Usage
hcloud server list      # List servers
hcloud volume list      # List volumes
```

---

## 🐚 Shell & Terminal

### Shell Configuration

```bash
# Shell: Zsh with plugins
zsh                     # Z shell
zsh-autosuggestions     # Command suggestions
zsh-syntax-highlighting # Syntax coloring

# Prompt
starship                # Cross-shell prompt

# See modules/zsh.nix for 60+ aliases
```

### Terminal Multiplexing

```bash
tmux                    # Terminal multiplexer
kitty                   # GPU terminal emulator

# Note: Kitty has built-in sessions
# tmux not needed if using kitty sessions
```

### Shell Functions

Available custom functions (see `modules/zsh.nix`):

```bash
extract file.tar.gz     # Extract any archive
mkcd newdir             # Make dir and cd into it
fe                      # Fuzzy find and edit file
gwcd                    # Git worktree navigation
_cc                     # Conventional commit helper (alias: cc)
```

### History & Navigation

```bash
# History search
Ctrl+R                  # Search backward
Ctrl+S                  # Search forward

# Smart navigation
z pattern               # Jump to directory
zi                      # Interactive picker

# Directory stack
..                      # cd ..
...                     # cd ../..
....                    # cd ../../..
```

---

## 📊 Productivity Tools

### API Testing & Debugging

```bash
# HTTP clients
curl                    # Transfer data
wget                    # Download files
atac                    # Terminal API client
postman                 # GUI API client
newman                  # CLI Postman runner

# Network analysis
termshark               # Terminal Wireshark
kubeshark               # K8s traffic analyzer
dig                     # DNS lookup

# Usage
atac                    # Launch TUI
newman run collection.json
termshark -i eth0
```

### Database Tools

```bash
postgresql              # PostgreSQL client
clickhouse-cli          # ClickHouse CLI
go-migrate              # Database migrations
pghero                  # PostgreSQL performance

# Usage
psql -U user -d database
clickhouse-client
migrate -path ./migrations -database "postgres://..." up
```

### Messaging & Streaming

```bash
kcat                    # Kafka CLI (kafkacat)
kafkactl                # Kafka management

# Usage
kcat -b localhost:9092 -L      # List topics
kafkactl get topics            # List topics
```

### Monitoring & Observability

```bash
grafana-loki            # Log aggregation
promql-cli              # PromQL queries

# Usage
promql "rate(http_requests[5m])"
```

### Performance Testing

```bash
k6                      # Load testing

# Usage
k6 run script.js
k6 run --vus 10 --duration 30s script.js
```

### Documentation

```bash
glow                    # Markdown renderer
mdr                     # Markdown reader
tldr                    # Simplified man pages
marksman                # Markdown LSP

# Usage
glow README.md          # Render markdown
tldr docker             # Quick reference
mdr docs/               # Browse markdown docs
```

### File Management

```bash
rsync                   # File synchronization
syncthing               # Continuous sync
tree                    # Directory tree

# Usage
rsync -avz src/ dest/   # Sync directories
syncthing              # Start sync daemon
tree -L 2              # Show 2 levels
```

### Git Workflow

```bash
lazygit                 # Git TUI
gh                      # GitHub CLI
gitlint                 # Commit message linter
act                     # Run GitHub Actions locally
pre-commit              # Git hook manager

# Usage
lazygit                 # Launch TUI
gh pr create            # Create PR
gh pr list              # List PRs
act                     # Run actions locally
```

---

## 📝 Quick Reference Cheatsheet

### Daily Workflow

```bash
# Morning routine
duf                     # Check disk space
lazydocker              # Review containers
k9s                     # Check K8s clusters
glow CHANGELOG.md       # Read updates

# Development
hx main.go              # Edit with Helix
got -v                  # Run Go tests
golint                  # Lint code
lazygit                 # Commit changes

# Infrastructure
k get pods              # Check K8s pods
tfp                     # Terraform plan
trivy image myapp:latest # Scan image

# Debugging
kubeshark tap           # Monitor K8s traffic
termshark -i eth0       # Capture packets
kcat -b broker -L       # List Kafka topics
```

### Most Used Aliases

```bash
# Navigation
z project               # Jump to directory
..                      # Up one level
ll                      # List files

# Git
gs                      # git status
gp                      # git push
gc "message"            # git commit
lazygit                 # Git TUI

# Kubernetes
k                       # kubectl
kgp                     # kubectl get pods
k9s                     # K8s TUI

# Docker
dcu                     # docker compose up
dcd                     # docker compose down
dcl                     # docker compose logs -f
lazydocker              # Docker TUI

# Files
bat file.go             # View file
rg "pattern"            # Search
fd filename             # Find file
```

### Performance Comparison

Use `hyperfine` to compare tools:

```bash
# Compare search tools
hyperfine 'rg pattern' 'grep -r pattern'

# Compare list tools
hyperfine 'eza -l' 'ls -l'

# Compare test runs
hyperfine 'go test ./...'

# With warm-up runs
hyperfine --warmup 3 'terraform plan'
```

---

## 🎯 Tool Categories Summary

| Category | Count | Key Tools |
|----------|-------|-----------|
| **Core Utilities** | 30+ | eza, bat, ripgrep, fd, zoxide |
| **Development** | 25+ | Go, Helix, LSPs, git |
| **Kubernetes** | 35+ | kubectl, helm, k9s, argocd |
| **IaC** | 12+ | terraform, pulumi, ansible |
| **Security** | 20+ | trivy, kube-bench, cosign |
| **Cloud** | 3 | awscli2, azure-cli, hcloud |
| **Monitoring** | 8+ | promql, loki, atac |
| **Productivity** | 15+ | glow, lazydocker, duf |

**Total: 140+ tools**

---

## 🔗 Additional Resources

- **Configuration**: See individual modules in `modules/` directory
- **Aliases**: Full list in `modules/zsh.nix`
- **LSPs**: Configuration in `modules/helix.nix`
- **Architecture**: See `./ARCHITECTURE.md`
- **Main README**: See `../README.md`

---

## 💡 Tips & Tricks

### 1. Tool Discovery

```bash
# List all installed packages
nix-env -q

# Search for packages
nix search nixpkgs <package>

# Check which file provides a command
which <command>
type <command>
```

### 2. Performance

```bash
# Benchmark your shell startup
hyperfine 'zsh -i -c exit'

# Profile zsh startup
zsh -xv

# Check tool versions
go version
terraform version
kubectl version
```

### 3. Updates

```bash
# Update flake
nix flake update

# Switch configuration
home-manager switch --flake . --impure

# Rollback if needed
home-manager generations
home-manager switch --switch-generation <id>
```

---


# Language Server Configuration

This document explains the language server setup for Zed editor, including handling of the Helm/YAML edge case and memory optimization.

## Language Servers Configured

### Cloud & Infrastructure
- **Helm** (`helm-ls`) - Kubernetes chart templating, takes priority over YAML for chart directories
- **Go** (`gopls`) - Cloud-native development
- **Terraform** (`terraform-ls`) - Infrastructure as Code

### Data & Configuration
- **JSON** (`vscode-json-language-server`) - Config files and APIs
- **YAML** (`yaml-language-server`) - Kubernetes manifests, CI/CD configs
- **TOML** (`taplo`) - Config files (Cargo.toml, pyproject.toml, etc.)

### Scripting & Shell
- **Bash** (`bash-language-server`) - Shell scripts
- **Python** (`pyright`) - Scripting and tooling

### Documentation
- **Markdown** (`marksman`) - Documentation, runbooks, ADRs

### Container & Deployment
- **Dockerfile** - Built-in Zed support (linting via hadolint)

### System Configuration
- **Nix** (`nil`) - Home Manager and NixOS configs
- **Rust** (`rust-analyzer`) - System programming

## Helm vs YAML Priority

The edge case of Helm templating vs regular YAML is handled through:

1. **Directory Detection**: When `Chart.yaml` exists in a directory, Zed automatically uses `helm-ls` for that context
2. **File Extensions**: 
   - `.tpl` files always use `helm-ls`
   - `.yaml` files use `helm-ls` when in a Helm chart directory
   - `.yaml` files use `yaml-language-server` in non-Helm contexts

3. **LSP Priority**: `helm-ls` is listed before `yaml-language-server` in the LSP configuration
4. **Multiple LSP Support**: The YAML language configuration includes both LSPs: `["yaml-language-server" "helm-ls"]`

## Memory Optimization

To prevent Zed from consuming excessive memory, the following directories are excluded from file scanning:

### Dependencies
- `node_modules`, `vendor`, `.venv`, `venv`, `env`, `__pycache__`

### Build Artifacts
- `dist`, `build`, `.next`, `.nuxt`, `out`, `.output`, `target`

### Cache Directories
- `.cache`, `.pytest_cache`, `.mypy_cache`, `.ruff_cache`
- `.terraform`, `.terragrunt-cache`, `.go-build`

### IDE Files
- `.idea`, `.vscode`, `.DS_Store`, `*.swp`, `*.swo`

### Test Coverage & Logs
- `coverage`, `.coverage`, `htmlcov`, `.nyc_output`
- `*.log`, `logs`, `tmp`, `temp`

## Formatters

All languages have appropriate formatters configured:

- **Go**: `gofmt` (tabs, 4-width)
- **Terraform**: `terraform fmt`
- **Bash**: `shfmt` (2 spaces, simplify, indent switch cases)
- **Python**: `black` (4 spaces)
- **Nix**: `nixfmt`
- **Rust**: `rustfmt`
- **JSON/YAML/TOML**: Handled by respective LSPs

## Package Requirements

The following packages are installed via `modules/packages/development.nix`:

```nix
# Language Servers
helm-ls
gopls
terraform-ls
bash-language-server
pyright
marksman
yaml-language-server
taplo
nil
rust-analyzer
nodePackages.vscode-langservers-extracted  # Provides JSON LSP

# Formatters
shfmt           # Shell/Bash
black           # Python
nixfmt-classic  # Nix
```

## Configuration Structure

The `modules/zed.nix` file is organized into three main sections:

1. **Performance Settings**: `file_scan_exclusions` to prevent memory bloat
2. **LSP Configuration**: Consolidated `lsp` block with all language servers using `path_lookup = true`
3. **Language Settings**: Individual language configurations with formatters and LSP assignments

## Usage Notes

1. **Format on Save**: Enabled for all languages except Markdown (to preserve manual formatting) and Dockerfile
2. **Path Lookup**: All language servers use `path_lookup = true` to find binaries from home-manager/nix
3. **Tab Settings**: Matches Helix editor configuration for consistency
   - Go: Hard tabs (4-width)
   - Python: Spaces (4-width)
   - Others: Spaces (2-width)

## Validation

After applying changes with `home-manager switch`, verify language servers are working:

1. Open a file of each type in Zed
2. Check status bar for LSP connection indicator
3. Test auto-completion (Ctrl+Space or automatic)
4. Test hover documentation (hover over symbols)
5. Verify format-on-save works correctly

### Testing Helm/YAML Edge Case

1. Create a test directory with a `Chart.yaml` file:
   ```bash
   mkdir -p /tmp/test-helm-chart
   cd /tmp/test-helm-chart
   cat > Chart.yaml << EOF
   apiVersion: v2
   name: test-chart
   version: 0.1.0
   EOF
   ```

2. Create a YAML file in the chart directory:
   ```bash
   cat > values.yaml << EOF
   replicaCount: {{ .Values.replicas }}
   image:
     repository: nginx
   EOF
   ```

3. Open the directory in Zed and observe:
   - `values.yaml` should show helm-ls in the status bar
   - Helm template syntax should be recognized
   - Auto-completion should offer Helm-specific suggestions

4. Create a YAML file outside a Helm chart:
   ```bash
   cat > /tmp/regular.yaml << EOF
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: test
   EOF
   ```

5. Open `/tmp/regular.yaml` in Zed:
   - Should use `yaml-language-server`
   - Standard YAML validation applies

## Troubleshooting

### LSP Not Connecting

If a language server doesn't connect:

1. Check if the package is installed:
   ```bash
   which gopls
   which pyright
   which helm-ls
   ```

2. Verify the LSP binary name matches Zed's expectations (check Zed logs)

3. Try restarting Zed or running `home-manager switch` again

### Memory Issues Persist

If Zed still uses too much memory:

1. Check which directories are being indexed: Look at Zed's project panel
2. Add additional exclusions to `file_scan_exclusions` in `modules/zed.nix`
3. Consider excluding specific large files or patterns

### Formatter Not Working

If format-on-save doesn't work:

1. Verify the formatter binary is installed:
   ```bash
   which black
   which shfmt
   which nixfmt
   ```

2. Check Zed logs for formatter errors
3. Try manually formatting (Cmd+Shift+I on macOS, Ctrl+Shift+I on Linux)

### JSON LSP Issues

The JSON language server comes from `nodePackages.vscode-langservers-extracted`. If it's not working:

1. Check if the package is installed:
   ```bash
   ls -la ~/.nix-profile/bin/ | grep json
   ```

2. The binary might be named differently. Check Zed's LSP logs to see what it's looking for

3. You may need to adjust the LSP name in `modules/zed.nix` from `vscode-json-language-server` to `json` or another variant

## References

- [Zed Editor Documentation](https://zed.dev/docs)
- [Zed Language Server Configuration](https://zed.dev/docs/configuring-zed#language-servers)
- [Helm Language Server](https://github.com/mrjosh/helm-ls)
- [Language Server Protocol](https://microsoft.github.io/language-server-protocol/)
