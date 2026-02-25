{
  # Helix Editor Configuration
  # LLM Integration: OpenCode can be used alongside Helix in terminal
  # For AI assistance, use: opencode (in separate terminal/tmux pane)

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

        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };
      };
    };

    languages.language = [

      # Terraform / AWS
      {
        name = "terraform";
        language-servers = [ "terraform-ls" ];
        auto-format = true;
        formatter.command = "terraform";
        formatter.args = [
          "fmt"
          "-no-color"
          "-"
        ];
        indent = {
          tab-width = 2;
          unit = "  ";
        };
      }

      # Bash
      {
        name = "bash";
        language-servers = [ "bash-language-server" ];
        auto-format = true;
        formatter.command = "shfmt";
        formatter.args = [
          "-i"
          "2"
          "-bn"
          "-ci"
          "-sr"
        ];
        indent = {
          tab-width = 2;
          unit = "  ";
        };
      }

      # Go
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

      # Rust
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

      # Nix / Home Manager
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

      # TOML
      {
        name = "toml";
        language-servers = [ "taplo" ];
        auto-format = true;
        indent = {
          tab-width = 2;
          unit = "  ";
        };
      }

      # Generic YAML (CI/CD, config files)
      {
        name = "yaml";
        language-servers = [ "yaml-language-server" ];
        auto-format = true;
        indent = {
          tab-width = 2;
          unit = "  ";
        };
      }

      # Kubernetes YAML (EKS manifests)
      {
        name = "kubernetes";
        scope = "source.yaml";
        roots = [
          "kustomization.yaml"
          "Chart.yaml"
        ];
        language-servers = [
          "kube-lsp"
          "yaml-language-server"
        ];
        file-types = [
          "yaml"
          "yml"
        ];
        auto-format = true;
        indent = {
          tab-width = 2;
          unit = "  ";
        };
      }

      # Helm
      {
        name = "helm";
        scope = "source.yaml";
        roots = [ "Chart.yaml" ];
        file-types = [
          "yaml"
          "tpl"
        ];
        language-servers = [ "helm-ls" ];
        auto-format = true;
        indent = {
          tab-width = 2;
          unit = "  ";
        };
      }

      # JSON (AWS IAM / CloudFormation)
      {
        name = "json";
        language-servers = [ "json-language-server" ];
        auto-format = true;
        indent = {
          tab-width = 2;
          unit = "  ";
        };
      }

      # Markdown (runbooks, ADRs)
      {
        name = "markdown";
        language-servers = [ "marksman" ];
        auto-format = false;
        indent = {
          tab-width = 2;
          unit = "  ";
        };
      }

      # Rego (OPA / Conftest / Gatekeeper)
      {
        name = "rego";
        scope = "source.rego";
        file-types = [ "rego" ];
        language-servers = [ "rego-language-server" ];
        auto-format = true;
        indent = {
          tab-width = 2;
          unit = "  ";
        };
      }

    ];
  };
}
