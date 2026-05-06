# Personal Claude Configuration

## Coding Style & Preferences

### Languages
- **Primary**: Nix, Python, Go, Rust
- **Shell**: Prefer `sh` for portability, `zsh` for interactive
- **IaC**: Terraform, Kubernetes manifests, Nix expressions

### Code Style
- **Formatting**: Use language-specific formatters (nixpkgs-fmt, black, gofmt, rustfmt)
- **Line Length**: 100 characters max (except where language conventions differ)
- **Indentation**: 2 spaces for Nix/YAML/JSON, 4 for Python, tabs for Go
- **Comments**: Prefer self-documenting code; use comments for "why" not "what"

### Best Practices
- **Error Handling**: Always handle errors explicitly, no silent failures
- **Logging**: Structured logging with context (JSON when appropriate)
- **Testing**: Write tests for critical paths, prefer integration tests
- **Documentation**: README for projects, inline docs for complex functions
- **Security**: Never hardcode secrets, use environment variables or secret managers

### Development Workflow
- **Version Control**: Conventional commits, feature branches
- **CI/CD**: Automate testing and deployment
- **Code Review**: All changes reviewed before merge
- **Iteration**: Start simple, iterate based on feedback

### Tool Preferences
- **Editor**: Helix (hx) for terminal, Zed for GUI
- **Shell**: zsh with starship prompt
- **Package Management**: Nix/home-manager for reproducibility
- **Containers**: Prefer native binaries via Nix when possible
- **Kubernetes**: Kubectl with k9s for cluster management

### Communication Style
- Be concise and direct
- Provide context and reasoning for decisions
- Ask clarifying questions when requirements are unclear
- Suggest alternatives when appropriate