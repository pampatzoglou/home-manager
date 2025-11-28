{ config, pkgs, lib, ... }:

{
  programs.vscode = {
    enable = true;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        ms-python.python
        ms-toolsai.jupyter
        hashicorp.terraform
        golang.go
        redhat.vscode-yaml
        ms-vscode-remote.remote-ssh
        jnoortheen.nix-ide
        arrterian.nix-env-selector
      ];
    };
  };
}
