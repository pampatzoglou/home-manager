# Changelog

#### LLM Module (`modules/llm.nix`)
- **Ollama Installation**: Local LLM inference support
- **ollama-helper Script**: Comprehensive model management CLI tool
  - Pull default models (llama3.2, codellama, mistral, deepseek-coder)
  - List, remove, and query installed models
  - Test models with prompts
  - Interactive chat sessions
  - Service status checking
- **Shell Aliases**: Quick access commands (ol, olls, llm, llm-chat, llm-status)
- **Configuration Scaffolding**:
  - `~/.config/llm/config.json` - General LLM settings
  - `~/.config/llm/openrouter.json` - OpenRouter API placeholder
- **Documentation**: Complete usage guide in `modules/LLM_README.md`
- **Future-Ready Structure**: Extensible for OpenRouter, model management, and additional LLM tools

#### Helix Editor Enhancements (`modules/helix.nix`)
- **Python Support**: Added pylsp LSP + black formatter with 4-space indentation
- **HCL Support**: Added terraform-ls for Packer/Vault/Nomad files
- **YAML Schema Validation**: Automatic schema detection for:
  - GitHub Actions workflows and actions
  - Ansible playbooks
  - Kustomization files
  - Helm Charts
  - Docker Compose files
  - GitLab CI pipelines
  - Google Cloud Build configs
- **Language Server Configuration**: Enhanced yaml-language-server with schema mappings

#### Zed Editor Configuration (`modules/zed.nix`)
- **Complete Language Support**: Mirrored all Helix language configurations
  - Terraform, HCL, Bash, Python, Go, Rust, Nix, TOML, YAML, JSON, Markdown
- **External Formatters**: Configured for all languages matching Helix setup
  - terraform fmt, shfmt, black, gofmt, rustfmt, nixfmt
- **YAML Schema Validation**: Same schema mappings as Helix
- **Editor Settings**:
  - Relative line numbers
  - Format on save enabled
  - Auto-save disabled
  - LSP path lookup for all language servers
  - Cursor blink disabled
- **Consistent Indentation**: Matches Helix (tabs for Go, spaces for others)

### Changed

#### Base Configuration (`base.nix`)
- Added `modules/llm.nix` to imports list
- Improved code formatting for username detection logic

### Infrastructure

#### Documentation
- Created comprehensive LLM module documentation with:
  - Quick start guide
  - Command reference
  - Model recommendations
  - Future expansion plans
  - Troubleshooting guide

#### Code Quality
- Consistent formatting across all configuration files
- Improved array/list formatting in Nix configurations
- Better separation of concerns in editor configs

### Dependencies Required

For full functionality, ensure these tools are available:

#### Python/HCL Support
- `pylsp` or `python-lsp-server` (Python LSP)
- `black` (Python formatter)
- `terraform-ls` (Terraform/HCL LSP)

#### Existing Dependencies
- `shfmt` (Bash formatter)
- `gopls` (Go LSP)
- `rust-analyzer` (Rust LSP)
- `nil` (Nix LSP)
- `nixfmt` (Nix formatter)
- `taplo` (TOML LSP)
- `yaml-language-server` (YAML LSP with schemas)
- `marksman` (Markdown LSP)

#### LLM Tools
- `ollama` (Local LLM runtime)

### Notes

#### Editor Parity
- Helix and Zed now have matching language configurations
- Both editors support the same formatters and LSPs
- Consistent indentation rules across both editors

#### LLM Module Design
- Started minimal with Ollama only
- Structured for easy expansion with:
  - OpenRouter API integration
  - Additional LLM CLI tools (aichat, fabric, llm)
  - Model management and versioning
  - Prompt templates and context management

#### YAML Schema Validation
- Provides real-time validation in editors
- Autocomplete for known YAML fields
- Hover documentation for properties
- Schema-aware suggestions for common file types

### Migration Guide

To apply these changes:

```bash
# Review changes
git diff

# Apply configuration
home-manager switch

# For LLM setup
ollama serve &           # Start Ollama service
ollama-helper pull-defaults  # Pull default models
ollama-helper chat       # Start chatting

# Test editors
hx test.py              # Test Helix with Python
zed test.py             # Test Zed with Python
```

### Future Roadmap

#### LLM Module
- [ ] OpenRouter API integration with secrets management
- [ ] Automatic model updates and version pinning
- [ ] Additional CLI tools (aichat, fabric, llm)
- [ ] Prompt template management
- [ ] Usage tracking and cost monitoring
- [ ] Integration with code editors for AI assistance

#### Editor Enhancements
- [ ] Custom LSP configurations per language
- [ ] Additional language support (Zig, V, etc.)
- [ ] Editor-specific plugins/extensions
- [ ] Shared snippets across editors

#### Infrastructure
- [ ] Secrets management integration
- [ ] Automated testing for configurations
- [ ] CI/CD validation
- [ ] Configuration templates for common setups
