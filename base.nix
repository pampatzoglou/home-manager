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
  home.homeDirectory = if pkgs.stdenv.isDarwin 
    then "/Users/${username}" 
    else "/home/${username}";
  home.stateVersion = "25.05"; # Please read the comment before changing.
  home.enableNixpkgsReleaseCheck = false; # Disable version mismatch warning
  
  # Allow unfree packages (VS Code, etc.)
  nixpkgs.config.allowUnfree = true;

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Environment and session configuration
  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    KUBECONFIG = "${config.home.homeDirectory}/.kube/config";
    TALOSCONFIG = "${config.home.homeDirectory}/.talos/config";
    EDITOR = "hx";
    VISUAL = "hx";
    HISTSIZE = "50000";
    SAVEHIST = "50000";
    HISTFILE = "${config.home.homeDirectory}/.zsh_history";
    COMPLETION_WAITING_DOTS = "true";
  };

  # Home Manager files
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Import modular configurations
  imports = [
    ./modules/packages.nix
    ./modules/zsh.nix
    ./modules/starship.nix
    ./modules/git.nix
    ./modules/helix.nix
    ./modules/security.nix
    ./modules/vscode.nix
    ./modules/ghostty.nix
    ./modules/kubernetes.nix
  ];
}
