{ pkgs, ... }:

{
  home.packages = with pkgs; [
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
    # openssh via brew for better macOS/FIDO2 integration
    keychain
    yubikey-manager
    yubikey-personalization
    yubico-piv-tool

    # Modern CLI tools
    glow # Markdown renderer
    lazydocker # Docker TUI manager
    duf # Better disk usage viewer
    hyperfine # Command benchmarking

    # Personal productivity tools
    rsync
    syncthing
    tmux
    cointop
  ];
}
