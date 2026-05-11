# 🏗️ Home-Manager Configuration Architecture

This document describes the modular architecture of our cross-platform Home-Manager configuration, featuring automatic username detection and complete portability.

## 🎯 System Overview

```mermaid
graph TB
    subgraph "🔧 Configuration Layer"
        flake["`**flake.nix**
        Multi-arch support
        Auto username detection
        System abstraction`"]
        base["`**base.nix**
        Core configuration
        Cross-platform modules
        Environment setup`"]
    end

    subgraph "📦 Module Ecosystem"
        direction TB
        core["`**Core Modules**
        packages.nix (7 categories)
        security.nix
        git.nix
        gc.nix`"]
        shell["`**Shell Environment**
        zsh.nix
        starship.nix
        aliases & functions`"]
        dev["`**Development**
        helix.nix
        zed.nix
        kubernetes.nix`"]
        ai["`**AI Assistant**
        claude.nix
        Auto-discovered skills`"]
        sys["`**System Integration**
        kitty.nix`"]
    end

    subgraph "🎨 User Experience"
        dotfiles["`**Generated Files**
        ~/.zshrc
        ~/.gitconfig
        ~/.config/*`"]
        apps["`**Applications**
        Helix • Zed
        Kitty • Brave
        Git CLI Tools`"]
    end

    flake --> base
    base --> core
    base --> shell
    base --> dev
    base --> sys
    core --> dotfiles
    shell --> dotfiles
    dev --> apps
    sys --> apps
```

## 🔄 Configuration Flow

```mermaid
flowchart TD
    start(["`👤 **User Command**
    home-manager switch --flake . --impure`"])

    subgraph detect["`🔍 **Username Detection**`"]
        env{"`**Environment Check**
        USER variable available?`"}
        auto["`**Auto-Detection**
        builtins.getEnv 'USER'`"]
        error["`❌ **Error**
        Helpful message + --impure hint`"]
    end

    subgraph eval["`📋 **Configuration Evaluation**`"]
        flake_eval["`**Flake Processing**
        System architecture detection
        Module selection`"]
        module_eval["`**Module Evaluation**
        Import and merge configs
        Package selection`"]
    end

    subgraph build["`🔨 **Build Process**`"]
        packages["`**Package Building**
        Nix store preparation
        Dependency resolution`"]
        configs["`**Configuration Generation**
        Template processing
        File creation`"]
    end

    subgraph deploy["`🚀 **Deployment**`"]
        symlinks["`**Symlink Creation**
        ~/.config/ structure
        Application configs`"]
        activation["`**System Activation**
        Service registration
        Permission fixes`"]
    end

    complete(["`✅ **Completion**
    Ready to use!`"])

    start --> detect
    env --> |Yes| auto
    env --> |No| error
    auto --> eval
    error --> complete
    eval --> flake_eval
    flake_eval --> module_eval
    module_eval --> build
    build --> packages
    packages --> configs
    configs --> deploy
    deploy --> symlinks
    symlinks --> activation
    activation --> complete

    style start fill:#e1f5fe
    style complete fill:#c8e6c9
    style error fill:#ffcdd2
    style auto fill:#fff3e0
```

## 📁 Module Architecture

```mermaid
graph LR
    subgraph "🎯 Entry Points"
        flake["`**flake.nix**
        • Multi-architecture
        • Auto username detection
        • System detection`"]
        base["`**base.nix**
        • Cross-platform
        • Core modules
        • Universal settings`"]
    end

    subgraph "🔧 Core Infrastructure"
        packages["`**packages.nix**
        • 147 tools
        • Categorized by function
        • Development stack`"]
        security["`**security.nix**
        • GPG hardening
        • SSH configuration
        • Encryption policies`"]
        git["`**git.nix**
        • Manual config required
        • Advanced features
        • Global gitignore`"]
    end

    subgraph "💻 Development Environment"
        helix["`**helix.nix**
        • LSP configuration
        • Multi-language support
        • Editor optimizations`"]
        zed["`**zed.nix**
        • Modern editor
        • LSP support
        • Format on save`"]
        k8s["`**kubernetes.nix**
        • Kubectl plugins
        • Cluster management
        • DevOps tools`"]
    end

    subgraph "🐚 Shell Experience"
        zsh["`**zsh.nix**
        • 60+ aliases
        • Functions & completions
        • History management`"]
        starship["`**starship.nix**
        • Custom prompt
        • Git integration
        • Context awareness`"]
    end

    subgraph "🤖 AI Assistant"
        claude["`**claude.nix**
        • Auto-discovered skills
        • Personal preferences
        • Methodology-focused`"]
    end

    subgraph "🎨 User Interface"
        kitty["`**kitty.nix**
        • Terminal theming
        • Font configuration
        • Key bindings`"]
    end

    flake --> base
    base --> packages
    base --> security
    base --> git
    base --> helix
    base --> zed
    base --> k8s
    base --> zsh
    base --> starship
    base --> claude
    base --> kitty

    packages -.-> security
    security -.-> git
    zsh -.-> starship
    helix -.-> packages
    zed -.-> packages
    kitty -.-> packages
```

## 🏗️ System Architecture Layers

```mermaid
graph TB
    subgraph L4["`🎨 **Layer 4: User Applications**`"]
        apps["`Helix • Zed • Kitty • Brave • Git Tools`"]
    end

    subgraph L3["`🐚 **Layer 3: Shell Environment**`"]
        shell["`Zsh • Starship • Aliases • Functions • Completions`"]
    end

    subgraph L2["`🛡️ **Layer 2: Security & Development**`"]
        security["`GPG • SSH • Direnv • Git Config • K8s Tools`"]
    end

    subgraph L1["`📦 **Layer 1: Package Management**`"]
        packages["`147 Tools • Development Stack • System Utilities`"]
    end

    subgraph L0["`🔧 **Layer 0: Foundation**`"]
        foundation["`Nix • Home-Manager • Auto Username Detection`"]
    end

    L4 --> L3
    L3 --> L2
    L2 --> L1
    L1 --> L0
```

## 🔀 Configuration Variants

```mermaid
graph LR
    subgraph platforms["`🌐 **Platform Support**`"]
        direction TB
        arm_mac["`**Apple Silicon**
        aarch64-darwin
        Auto-detected`"]
        intel_mac["`**Intel Mac**
        x86_64-darwin
        Auto-detected`"]
        linux_x64["`**Linux x64**
        x86_64-linux
        Auto-detected`"]
        linux_arm["`**Linux ARM**
        aarch64-linux
        Auto-detected`"]
    end

    subgraph configs["`⚙️ **Configuration**`"]
        direction TB
        base_config["`**Single Config**
        • All platforms
        • Cross-platform modules
        • Zero configuration`"]
    end

    subgraph auto["`🤖 **Auto-Detection**`"]
        direction TB
        user_detect["`**Username Detection**
        builtins.getEnv 'USER'
        Requires --impure flag`"]
        sys_detect["`**System Detection**
        builtins.currentSystem
        Path adaptation`"]
    end

    platforms --> configs
    configs --> auto
```

## 🎛️ Module Dependencies

```mermaid
graph TD
    packages["`📦 **packages.nix**
    Foundation packages`"] --> security["`🛡️ **security.nix**
    GPG, SSH, Direnv`"]

    security --> git["`🔧 **git.nix**
    Version control`"]
    security --> development["`💻 **Development**
    Helix, K8s`"]

    packages --> shell_base["`🐚 **Shell Foundation**
    Zsh configuration`"]
    shell_base --> starship["`⭐ **starship.nix**
    Custom prompt`"]

    packages --> ui["`🎨 **User Interface**
    Terminal, Input`"]

    subgraph independent["`🔸 **Independent Modules**`"]
        direction LR
        kitty["`**kitty.nix**
        Terminal`"]
        helix["`**helix.nix**
        Editor`"]
        zed_mod["`**zed.nix**
        Modern Editor`"]
        kubernetes["`**kubernetes.nix**
        DevOps`"]
        gc_mod["`**gc.nix**
        Cleanup`"]
    end

    ui --> independent
    development --> independent

    style packages fill:#e3f2fd
    style security fill:#fff3e0
    style independent fill:#f3e5f5
```

## 🔧 Architecture Benefits

### ✨ **Modularity**

- **Focused Modules**: Each module handles a specific domain
- **Easy Customization**: Enable/disable features independently
- **Clean Separation**: Clear boundaries between components
- **Testing Isolation**: Test modules independently

### 🔄 **Portability**

- **Auto-Detection**: No manual username configuration
- **Cross-Platform**: Works on macOS, Linux (x64, ARM)
- **Zero Config**: Clone and run with minimal setup
- **Reproducible**: Identical environments across machines

### 🚀 **Maintainability**

- **Version Control**: Precise tracking of changes
- **Documentation**: Self-documenting configuration
- **Debugging**: Easy to isolate and fix issues
- **Updates**: Granular package and module updates

### 🏗️ **Scalability**

- **Extensible**: Add modules without affecting existing setup
- **Multi-User**: Easy to fork and customize
- **Multi-System**: Support different architectures seamlessly
- **Future-Proof**: Easy to adapt to new tools and requirements

