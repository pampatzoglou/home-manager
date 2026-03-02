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

      # Performance: Exclude large directories from file scanning to prevent memory bloat
      file_scan_exclusions = [
        # Dependencies
        "**/.git"
        "**/node_modules"
        "**/target"
        "**/vendor"
        "**/.venv"
        "**/venv"
        "**/env"
        "**/__pycache__"

        # Build artifacts
        "**/dist"
        "**/build"
        "**/.next"
        "**/.nuxt"
        "**/out"
        "**/.output"

        # Cache directories
        "**/.cache"
        "**/.pytest_cache"
        "**/.mypy_cache"
        "**/.ruff_cache"
        "**/.terraform"
        "**/.terragrunt-cache"
        "**/node_modules/.cache"
        "**/.go-build"

        # IDE and editor files
        "**/.idea"
        "**/.vscode"
        "**/.DS_Store"
        "**/*.swp"
        "**/*.swo"

        # Test coverage
        "**/coverage"
        "**/.coverage"
        "**/htmlcov"
        "**/.nyc_output"

        # Logs and temporary files
        "**/*.log"
        "**/logs"
        "**/tmp"
        "**/temp"
      ];

      # ==============================================================================
      # LANGUAGE SERVER CONFIGURATION
      # Consolidated LSP settings - all language servers in one place
      # Priority: helm-ls > yaml-language-server for Helm chart contexts
      # ==============================================================================
      lsp = {
        # Helm (Kubernetes chart templating - priority over YAML in chart dirs)
        helm-ls = {
          binary = {
            path_lookup = true;
          };
        };

        # Go
        gopls = {
          binary = {
            path_lookup = true;
          };
        };

        # Terraform
        terraform-ls = {
          binary = {
            path_lookup = true;
          };
        };

        # JSON
        vscode-json-language-server = {
          binary = {
            path_lookup = true;
          };
        };

        # Bash
        bash-language-server = {
          binary = {
            path_lookup = true;
          };
        };

        # Python
        pyright = {
          binary = {
            path_lookup = true;
          };
        };

        # Markdown
        marksman = {
          binary = {
            path_lookup = true;
          };
        };

        # YAML (lower priority than helm-ls for chart files)
        yaml-language-server = {
          binary = {
            path_lookup = true;
          };
        };

        # Rust
        rust-analyzer = {
          binary = {
            path_lookup = true;
          };
        };

        # Nix
        nil = {
          binary = {
            path_lookup = true;
          };
        };

        # TOML
        taplo = {
          binary = {
            path_lookup = true;
          };
        };
      };

      # ==============================================================================
      # LANGUAGE-SPECIFIC SETTINGS
      # Format on save, formatters, and LSP assignments
      # ==============================================================================
      languages = {
        # Go (Cloud-native development)
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

        # Terraform (Infrastructure as Code)
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

        # JSON (Config files, APIs)
        JSON = {
          tab_size = 2;
          format_on_save = "on";
          language_servers = [ "vscode-json-language-server" ];
        };

        # Bash/Shell Scripts
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

        # Python (Scripting, tooling)
        Python = {
          tab_size = 4;
          format_on_save = "on";
          formatter = {
            external = {
              command = "black";
              arguments = [
                "--quiet"
                "-"
              ];
            };
          };
          language_servers = [ "pyright" ];
        };

        # Markdown (Documentation, runbooks, ADRs)
        Markdown = {
          tab_size = 2;
          format_on_save = "off";  # Preserve manual formatting
          language_servers = [ "marksman" ];
        };

        # Dockerfile (Container definitions)
        # Note: Zed has built-in Dockerfile support
        # Linting handled by hadolint (installed in security.nix)
        Dockerfile = {
          tab_size = 2;
          format_on_save = "off";
          language_servers = [ ];
        };

        # YAML (Kubernetes manifests, CI/CD configs)
        # Note: Zed automatically uses helm-ls when Chart.yaml is present
        YAML = {
          tab_size = 2;
          format_on_save = "on";
          language_servers = [ "yaml-language-server" "helm-ls" ];
        };

        # TOML (Config files)
        TOML = {
          tab_size = 2;
          format_on_save = "on";
          language_servers = [ "taplo" ];
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

        # Rust (System programming)
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

        # Rego (OPA / Conftest / Gatekeeper policies)
        Rego = {
          tab_size = 2;
          format_on_save = "on";
        };
      };
    };
  };
}
