{
  description = "Home Manager configuration";

  # Enable cache for faster builds
  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      # Auto-detect username and system
      # NOTE: Requires --impure flag: home-manager switch --flake . --impure
      username = builtins.getEnv "USER";
      system = builtins.currentSystem;
    in
    {
      homeConfigurations = {
        # Single auto-detected configuration for current user and system
        # Username validation happens in base.nix during actual build
        "${username}" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [ ./base.nix ];
        };
      };
    };
}
