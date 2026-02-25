{ ... }:

{
  # Import all package category modules
  imports = [
    ./packages/core.nix
    ./packages/development.nix
    ./packages/kubernetes.nix
    ./packages/infrastructure.nix
    ./packages/security.nix
    ./packages/observability.nix
    ./packages/productivity.nix
  ];
}
