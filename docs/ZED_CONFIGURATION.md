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
