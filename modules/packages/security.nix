{ pkgs, ... }:

{
  home.packages = with pkgs; [
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
    # checkov  # fails to build on Apple Silicon (python3.13-av dependency); use: pip install checkov
    tfsec
    git-secrets
    gitleaks
    cosign

    # Encryption and security tools
    diceware
    pwgen

    # Secret management
    vault
    bitwarden-cli
    boundary
    teller
    doppler
  ];
}
