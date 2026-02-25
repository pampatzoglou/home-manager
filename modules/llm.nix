{ pkgs
, lib
, ...
}:

{
  # LLM Tools Configuration Module
  # Ollama is commented out due to build issues - install manually if needed
  # OpenCode is installed via Nix

  # Install AI coding tools
  home.packages = with pkgs; [
    # ollama  # Commented out - install manually: curl -fsSL https://ollama.com/install.sh | sh
    opencode # AI coding agent
  ];

  # Environment variables for LLM tools
  home.sessionVariables = {
    OLLAMA_HOST = "http://localhost:11434";
  };

  # Create configuration directories
  home.file.".config/llm/.keep".text = "";
  home.file.".ollama/.keep".text = "";

  # LLM configuration file
  home.file.".config/llm/config.json".text = builtins.toJSON {
    _comment = "LLM tooling configuration";
    providers = {
      ollama = {
        enabled = true;
        endpoint = "http://localhost:11434";
        note = "Install manually - Nix package is broken";
      };
      opencode = {
        enabled = true;
        type = "coding-agent";
        installed_via = "nix";
      };
      openrouter = {
        enabled = false;
        note = "Set via: export OPENROUTER_API_KEY=your_key";
      };
    };
    defaults = {
      local_model = "llama3.2";
      temperature = 0.7;
      max_tokens = 2048;
    };
  };

  # OpenRouter configuration placeholder
  home.file.".config/llm/openrouter.json".text = builtins.toJSON {
    _comment = "OpenRouter API configuration - Add your API key via environment variable OPENROUTER_API_KEY";
    api_url = "https://openrouter.ai/api/v1";
    models = {
      recommended = [
        "anthropic/claude-3.5-sonnet"
        "openai/gpt-4-turbo"
        "meta-llama/llama-3.1-70b-instruct"
        "google/gemini-pro-1.5"
        "mistralai/mistral-large"
      ];
    };
  };

  # Ollama model management helper
  home.file.".local/bin/ollama-helper".text = ''
    #!/bin/bash

    # Ollama Model Management Helper

    # Default models to pull
    DEFAULT_MODELS=(
      "llama3.2"
      "codellama"
      "mistral"
      "deepseek-coder"
    )

    # Check if ollama is installed
    check_ollama() {
      if ! command -v ollama &> /dev/null; then
        echo "❌ Ollama is not installed"
        echo ""
        echo "Install manually:"
        echo "  curl -fsSL https://ollama.com/install.sh | sh"
        return 1
      fi
      return 0
    }

    # Pull a model
    pull_model() {
      check_ollama || return 1
      if [ $# -eq 0 ]; then
        echo "Usage: ollama-helper pull <model-name>"
        return 1
      fi
      echo "Pulling model: $1"
      ollama pull "$1"
    }

    # Pull all default models
    pull_defaults() {
      check_ollama || return 1
      echo "Pulling default models..."
      for model in "''${DEFAULT_MODELS[@]}"; do
        echo "Pulling $model..."
        ollama pull "$model" || echo "Failed to pull $model"
      done
      echo "Default models pull complete"
    }

    # List installed models
    list_models() {
      check_ollama || return 1
      echo "Installed Ollama models:"
      ollama list
    }

    # Remove a model
    remove_model() {
      check_ollama || return 1
      if [ $# -eq 0 ]; then
        echo "Usage: ollama-helper remove <model-name>"
        return 1
      fi
      echo "Removing model: $1"
      ollama rm "$1"
    }

    # Show model info
    info_model() {
      check_ollama || return 1
      if [ $# -eq 0 ]; then
        echo "Usage: ollama-helper info <model-name>"
        return 1
      fi
      ollama show "$1"
    }

    # Test a model
    test_model() {
      check_ollama || return 1
      if [ $# -lt 2 ]; then
        echo "Usage: ollama-helper test <model-name> <prompt>"
        return 1
      fi
      local model="$1"
      shift
      local prompt="$*"
      echo "Testing $model with prompt: $prompt"
      echo "---"
      ollama run "$model" "$prompt"
    }

    # Interactive chat
    chat_model() {
      check_ollama || return 1
      local model="''${1:-llama3.2}"
      echo "Starting chat with $model (Ctrl+D to exit)"
      ollama run "$model"
    }

    # Check status
    check_status() {
      echo "=== LLM Tools Status ==="
      echo ""

      # Check Ollama
      if command -v ollama &> /dev/null; then
        echo "✓ Ollama is installed"
        ollama --version
        echo ""

        if pgrep -x "ollama" > /dev/null; then
          echo "✓ Ollama service is running"
          echo ""
          echo "Installed models:"
          ollama list
        else
          echo "⚠ Ollama service is not running"
          echo "Start it with: ollama serve &"
        fi
      else
        echo "❌ Ollama is not installed"
        echo "Install manually: curl -fsSL https://ollama.com/install.sh | sh"
      fi

      echo ""

      # Check OpenCode
      if command -v opencode &> /dev/null; then
        echo "✓ OpenCode is installed (via Nix)"
        opencode --version 2>/dev/null || echo "(version: installed)"
      else
        echo "⚠ OpenCode not found in PATH"
      fi
    }

    # Main dispatcher
    case "$1" in
      pull) shift; pull_model "$@" ;;
      pull-defaults) pull_defaults ;;
      list|ls) list_models ;;
      remove|rm) shift; remove_model "$@" ;;
      info) shift; info_model "$@" ;;
      test) shift; test_model "$@" ;;
      chat) shift; chat_model "$@" ;;
      status) check_status ;;
      *)
        echo "Ollama Model Management Helper"
        echo ""
        echo "Usage: ollama-helper <command> [options]"
        echo ""
        echo "Commands:"
        echo "  pull <model>           - Pull a specific model"
        echo "  pull-defaults          - Pull all default models"
        echo "  list                   - List installed models"
        echo "  remove <model>         - Remove a model"
        echo "  info <model>           - Show model information"
        echo "  test <model> <prompt>  - Test a model with a prompt"
        echo "  chat [model]           - Start interactive chat (default: llama3.2)"
        echo "  status                 - Check Ollama and OpenCode status"
        echo ""
        echo "Default models: ''${DEFAULT_MODELS[*]}"
        ;;
    esac
  '';

  home.file.".local/bin/ollama-helper".executable = true;

  # Setup instructions on activation
  home.activation.setupLLMTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo ""
    echo "=== LLM Tools Configuration ==="
    echo ""
    echo "📦 Packages:"
    echo "  ✓ OpenCode installed (via Nix)"
    echo "  ⚠ Ollama not installed (install manually)"
    echo ""
    echo "📝 Configuration files created:"
    echo "  ~/.config/llm/config.json"
    echo "  ~/.config/llm/openrouter.json"
    echo ""
    echo "🚀 To install Ollama manually:"
    echo "  curl -fsSL https://ollama.com/install.sh | sh"
    echo ""
    echo "🚀 Quick start (after installing Ollama):"
    echo "  1. Start Ollama: ollama serve &"
    echo "  2. Pull models: ollama-helper pull-defaults"
    echo "  3. Test chat: ollama-helper chat"
    echo "  4. Use OpenCode: opencode"
    echo "  5. Check status: ollama-helper status"
    echo ""
  '';

  # ZSH aliases for LLM tools
  programs.zsh.shellAliases = {
    # Ollama shortcuts
    ol = "ollama";
    olls = "ollama list";
    olpull = "ollama pull";
    olrm = "ollama rm";
    olrun = "ollama run";

    # Helper shortcuts
    llm = "ollama-helper";
    llm-chat = "ollama-helper chat";
    llm-status = "ollama-helper status";

    # OpenCode shortcut
    oc = "opencode";
  };
}
