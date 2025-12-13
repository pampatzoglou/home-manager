{ config, pkgs, lib, ... }:

{
  programs.helix = {
    enable = true;

    settings = {
      theme = "solarized_dark";

      editor = {
        line-number = "relative";
        cursorline = true;
        auto-format = true;
        auto-save = false;
        completion-trigger-len = 1;
        idle-timeout = 200;
        bufferline = "multiple";

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        soft-wrap = {
          enable = false;
        };

        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };
      };
    };

    languages = {
      language = [
      {
        name = "terraform";
        language-servers = [ "terraform-ls" ];
        auto-format = true;
        formatter.command = "terraform";
        formatter.args = [ "fmt" "-" ];
        indent = {
          tab-width = 2;
          unit = "  ";
        };
      }
      {
        name = "bash";
        language-servers = [ "bash-language-server" ];
        auto-format = true;
        formatter.command = "shfmt";
        formatter.args = [ "-i" "2" "-bn" "-ci" "-sr" ];
        indent = {
          tab-width = 2;
          unit = "  ";
        };
      }
      {
        name = "go";
        language-servers = [ "gopls" ];
        auto-format = true;
        formatter.command = "gofmt";
        indent = {
          tab-width = 4;
          unit = "\t";
        };
      }
      {
        name = "rust";
        language-servers = [ "rust-analyzer" ];
        auto-format = true;
        formatter.command = "rustfmt";
        indent = {
          tab-width = 4;
          unit = "    ";
        };
      }
      {
        name = "nix";
        language-servers = [ "nil" ];
        auto-format = true;
        formatter.command = "nixfmt";
        indent = {
          tab-width = 2;
          unit = "  ";
        };
      }
      {
        name = "toml";
        language-servers = [ "taplo" ];
        auto-format = true;
        indent = {
          tab-width = 2;
          unit = "  ";
        };
      }
      {
        name = "kubernetes";
        scope = "yaml";
        file-types = [ "*.yaml" "*.yml" ];
        language-servers = [ "yaml-language-server" "kubernetes-lsp" ];
        comment-token = "#";
        auto-format = true;
        indent = {
          tab-width = 2;
          unit = "  ";
        };
      }
      {
        name = "json";
        language-servers = [ "vscode-langservers-extracted" ];
        auto-format = true;
        indent = {
          tab-width = 2;
          unit = "  ";
        };
      }
      {
        name = "markdown";
        language-servers = [ "vscode-langservers-extracted" ];
        auto-format = true;
        indent = {
          tab-width = 2;
          unit = "  ";
        };
      }
      ];
    };
  };
}
