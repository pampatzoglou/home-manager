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
    checkov
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
