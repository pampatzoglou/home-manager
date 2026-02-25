{ pkgs, ... }:

{
  home.packages = with pkgs; [
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

    # Automation and configuration management
    ansible
    ansible-lint
    molecule
    salt
    salt-lint
  ];
}
