{ config, pkgs, lib, ... }:

let
  # Helper to conditionally include packages only if available on the current platform
  optionalPkg = cond: pkg: lib.optionals cond [ pkg ];
in

{
  home.packages = with pkgs; 
    lib.flatten [
    # Core system utilities
    eza
    tree
    btop
    htop
    fd
    jq
    yq
    dig
    gzip
    wget
    curl
    tldr
    fzf
    starship
    dotenv-cli
    ripgrep
    bat
    delta
    zoxide
    dust
    bottom
    procs

    # Development tools and editors
    helix
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
    
    # bitwarden-cli
    # vault
    # ghostty  # Commented out due to platform compatibility issues

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
    # kube-lsp
    yaml-language-server
    # Terraform / AWS infra
    terraform-ls

    # Core languages
    bash-language-server
    pyright
    gopls
    rust-analyzer

    # Data / configs
    #json-language-server
    taplo
    nil
    # Docs & system
    marksman
    systemd-language-server

    # Linters / diagnostics
    tflint
    shellcheck
    yamllint

    # Kubernetes ecosystem tools
    kubectl
    kubelogin-oidc
    kubernetes-helm
    kubernetes-helmPlugins.helm-unittest
    kubectl-cnpg
    kubectl-linstor
    argocd
    skaffold
    istioctl
    cmctl
    velero
    kind
    krew
    k9s
    kubeshark
    tilt
    lens
    kubent
    kubesec
    testkube
    kuttl
    kyverno-chainsaw

    # Infrastructure as Code tools
    terraform
    opentofu
    pulumi
    pulumictl
    crossplane-cli
    spacectl
    talosctl
    terraform-docs

    # Cloud provider CLIs
    awscli2
    azure-cli
    hcloud

    # Security and compliance tools
    trivy
    trufflehog
    kube-bench
    falcoctl
    kyverno
    datree
    kube-linter
    kubescape
    terrascan
    hadolint
    kics
    checkov
    tfsec
    git-secrets
    gitleaks
    cosign

    # Automation and configuration management
    ansible
    ansible-lint
    molecule
    salt
    salt-lint

    # Monitoring and observability
    grafana-loki
    promql-cli
    atac
    termshark

    # Database and messaging tools
    postgresql
    postgresql_jdbc
    pghero
    go-migrate
    clickhouse-cli
    kcat
    kafkactl

    # Encryption and security tools
    yubikey-manager
    yubikey-personalization
    yubico-piv-tool
    diceware
    pwgen

    paperkey
    pgpdump
    gnupg
    pinentry-curses
    # veracrypt      # Commented out due to platform compatibility issues
    # cryptsetup     # Commented out due to platform compatibility issues

    # Git workflow tools
    gh
    gitlint
    teller
    act
    # commitizen

    # Personal productivity tools
    # taskwarrior3
    rsync
    syncthing
    tmux
    cointop

    # Development and testing tools
    k6
    sonobuoy
    postman
    newman
    mdr
    # vscode
    jetbrains.datagrip
    jetbrains.goland

    # Browsers
    brave

    ]
    ++ lib.optionals (!stdenv.isDarwin) [
      # Packages unavailable on macOS
      bitwarden-cli
    ]
    ++ lib.optionals stdenv.isDarwin [
      # macOS-specific packages
    ];
}