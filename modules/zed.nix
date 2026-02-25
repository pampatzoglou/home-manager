{ ... }:

{
  # Zed Editor Configuration
  # LLM Integration: Zed has built-in AI assistant support
  # Configure AI providers in Zed's settings or use OpenCode externally
  # Zed editor configuration matching Helix setup
  xdg.configFile."zed/settings.json" = {
    force = true;
    text = builtins.toJSON {
      # Theme
      theme = "One Dark";

      # Editor settings
      buffer_font_size = 14;
      ui_font_size = 14;
      relative_line_numbers = true;
      show_inline_completions = true;
      format_on_save = "on";
      autosave = "off";
      completion_trigger_length = 1;

      # Cursor settings
      cursor_blink = false;

      # Terminal
      terminal = {
        font_size = 13;
        blinking = "off";
        shell = "system";
      };

      # LSP settings
      lsp = {
        rust-analyzer = {
          binary = {
            path_lookup = true;
          };
        };
        gopls = {
          binary = {
            path_lookup = true;
          };
        };
        nil = {
          binary = {
            path_lookup = true;
          };
        };
      };

      # Language-specific settings matching Helix
      languages = {
        # Terraform / AWS
        Terraform = {
          tab_size = 2;
          format_on_save = "on";
          formatter = {
            external = {
              command = "terraform";
              arguments = [
                "fmt"
                "-no-color"
                "-"
              ];
            };
          };
          language_servers = [ "terraform-ls" ];
        };

        # Bash
        Bash = {
          tab_size = 2;
          format_on_save = "on";
          formatter = {
            external = {
              command = "shfmt";
              arguments = [
                "-i"
                "2"
                "-bn"
                "-ci"
                "-sr"
              ];
            };
          };
          language_servers = [ "bash-language-server" ];
        };

        # Go
        Go = {
          tab_size = 4;
          hard_tabs = true;
          format_on_save = "on";
          formatter = {
            external = {
              command = "gofmt";
              arguments = [ ];
            };
          };
          language_servers = [ "gopls" ];
        };

        # Rust
        Rust = {
          tab_size = 4;
          format_on_save = "on";
          formatter = {
            external = {
              command = "rustfmt";
              arguments = [ ];
            };
          };
          language_servers = [ "rust-analyzer" ];
        };

        # Nix / Home Manager
        Nix = {
          tab_size = 2;
          format_on_save = "on";
          formatter = {
            external = {
              command = "nixfmt";
              arguments = [ ];
            };
          };
          language_servers = [ "nil" ];
        };

        # TOML
        TOML = {
          tab_size = 2;
          format_on_save = "on";
          language_servers = [ "taplo" ];
        };

        # YAML (with schema validation)
        YAML = {
          tab_size = 2;
          format_on_save = "on";
          language_servers = [ "yaml-language-server" ];
        };

        # JSON
        JSON = {
          tab_size = 2;
          format_on_save = "on";
          language_servers = [ "vscode-json-language-server" ];
        };

        # Markdown
        Markdown = {
          tab_size = 2;
          format_on_save = "off";
          language_servers = [ "marksman" ];
        };

        # Rego (OPA / Conftest / Gatekeeper)
        Rego = {
          tab_size = 2;
          format_on_save = "on";
        };
      };
    };
  };
}
