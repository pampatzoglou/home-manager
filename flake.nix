{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      # Helper function to create configuration for a specific system
      mkConfig = system: modules: extraSpecialArgs: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        inherit modules extraSpecialArgs;
      };
      
      # Common extraSpecialArgs (empty - let modules handle user detection)
      commonArgs = { };
    in {
      homeConfigurations = {
        # Base configuration (cross-platform) - Apple Silicon
        base = mkConfig "aarch64-darwin" [ ./base.nix ] commonArgs;
        
        # Mac configuration (Apple Silicon)
        mac = mkConfig "aarch64-darwin" [ ./mac.nix ] commonArgs;
        
        # Base configuration (Intel Mac)
        "base-intel" = mkConfig "x86_64-darwin" [ ./base.nix ] commonArgs;
        
        # Mac configuration (Intel Mac)  
        "mac-intel" = mkConfig "x86_64-darwin" [ ./mac.nix ] commonArgs;
        
        # Base configuration (Linux x86_64)
        "base-linux" = mkConfig "x86_64-linux" [ ./base.nix ] commonArgs;
        
        # Base configuration (Linux ARM64)
        "base-linux-arm" = mkConfig "aarch64-linux" [ ./base.nix ] commonArgs;
      };
    };
}
