{ config, pkgs, ... }:

let
  # Auto-detect username from environment with fallback
  username =
    let env_user = builtins.getEnv "USER";
    in if env_user != "" then
      env_user
    else
      builtins.throw
        "Unable to determine username. Please set USER environment variable or use --impure flag.";
in
{
  # Core home-manager configuration - auto-detect username from environment
  home.username = username;
  home.homeDirectory =
    if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${username}" else "/home/${username}";
  # Records which home-manager default behaviours apply — not a value to keep
  # in sync with nixpkgs. Bumped 25.05 -> 26.05 deliberately: the only gated
  # change that affects this config is Darwin app *copying* (>= 25.11) instead
  # of store symlinks, so Spotlight/Launchpad can index GUI apps. The zsh
  # dotfile relocation is gated on xdg.enable, which is false here.
  home.stateVersion = "26.05";
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

  # Import modular configurations
  imports = [
    ./modules/packages.nix
    ./modules/zsh.nix
    ./modules/starship.nix
    ./modules/git.nix
    ./modules/helix.nix
    ./modules/zed.nix
    ./modules/security.nix
    ./modules/kubernetes.nix
    ./modules/kitty.nix
    ./modules/claude.nix
    ./modules/gc.nix
  ];
}
