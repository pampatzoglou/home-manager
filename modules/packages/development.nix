{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Development tools and editors
    helix
    zed-editor
    git
    pre-commit
    devbox
    just
    go-task
    devenv
    python3
    cobra-cli
    lazygit
    jless
    direnv
    buildkit
    buildkite-cli

    # Go development ecosystem
    go
    golangci-lint
    gotools
    goreleaser
    upx
    entr

    # Language servers and formatters
    # Kubernetes / Helm
    helm-ls
    yaml-language-server

    # Terraform / AWS infra
    terraform-ls

    # Core languages
    bash-language-server
    pyright
    gopls
    rust-analyzer

    # Data / configs
    taplo
    nil
    nodePackages.vscode-langservers-extracted # Provides JSON, HTML, CSS, ESLint LSPs

    # Docs & system
    marksman
    systemd-language-server

    # Formatters
    shfmt # Shell/Bash formatter
    black # Python formatter
    nixfmt-classic # Nix formatter

    # Linters / diagnostics
    tflint
    shellcheck
    yamllint

    # Development and testing tools
    k6
    sonobuoy
    postman
    newman
    mdr
    localstack
    jetbrains.datagrip
    # jetbrains.goland
  ];
}
