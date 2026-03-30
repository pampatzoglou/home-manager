{ ... }:

{
  # Automatic garbage collection of old home-manager generations
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
