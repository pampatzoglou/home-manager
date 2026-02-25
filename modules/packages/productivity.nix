{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Terminal emulator
    kitty

    # Browsers
    brave

    # Git workflow tools
    gh
    gitlint
    act
  ];
}
