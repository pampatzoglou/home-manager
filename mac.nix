{ config, pkgs, lib, ... }:

let
  # Auto-detect username from environment with fallback
  username = 
    let env_user = builtins.getEnv "USER"; 
    in if env_user != "" then env_user 
       else builtins.throw "Unable to determine username. Please set USER environment variable or use --impure flag.";
in
{
  # Core home-manager configuration - auto-detect username from environment
  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "25.05"; # Please read the comment before changing.
  home.enableNixpkgsReleaseCheck = false; # Disable version mismatch warning
  
  # Allow unfree packages (VS Code, etc.)
  nixpkgs.config.allowUnfree = true;

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Mac-specific packages
  home.packages = with pkgs; [
    karabiner-elements
  ];

  # Mac-specific modules only
  imports = [
    ./modules/karabiner.nix
  ];
}
