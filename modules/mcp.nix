{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Claude Desktop config file location
  claudeConfigPath =
    if pkgs.stdenv.isDarwin then
      "Library/Application Support/Claude/claude_desktop_config.json"
    else
      ".config/Claude/claude_desktop_config.json";

in
{
  # Install Node.js for running MCP servers via npx
  home.packages = with pkgs; [
    nodejs_20
  ];

  # Minimal MCP server configuration - all local, no credentials needed
  home.file."${claudeConfigPath}" = {
    text = builtins.toJSON {
      mcpServers = {
        # 1. Filesystem MCP - Essential for file operations
        filesystem = {
          command = "npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-filesystem"
            config.home.homeDirectory
          ];
        };

        # 2. Git MCP - Version control operations
        git = {
          command = "npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-git"
            "--repository"
            config.home.homeDirectory
          ];
        };

        # 3. Memory MCP - AI memory across sessions
        memory = {
          command = "npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-memory"
          ];
        };

        # 4. Fetch MCP - Read public web pages
        fetch = {
          command = "npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-fetch"
          ];
        };
      };
    };
  };

  # MCP helper script
  home.file.".local/bin/mcp".text = ''
    #!/usr/bin/env bash
    set -euo pipefail

    CONFIG_PATH="${
      if pkgs.stdenv.isDarwin then
        "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
      else
        "$HOME/.config/Claude/claude_desktop_config.json"
    }"

    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m'

    show_status() {
      echo -e "''${BLUE}=== Local MCP Servers ===''${NC}"
      echo ""
      echo -e "''${GREEN}✓''${NC} Filesystem - Read/write files and directories"
      echo -e "''${GREEN}✓''${NC} Git - Version control operations"
      echo -e "''${GREEN}✓''${NC} Memory - AI memory across sessions"
      echo -e "''${GREEN}✓''${NC} Fetch - Read public web pages"
      echo ""
      echo "All servers local, no credentials needed"
      echo ""

      # Check Node.js
      if command -v node &> /dev/null; then
        echo -e "''${GREEN}✓''${NC} Node.js: $(node --version)"
      else
        echo -e "''${RED}✗''${NC} Node.js not found"
      fi

      # Check config file
      if [ -f "$CONFIG_PATH" ]; then
        echo -e "''${GREEN}✓''${NC} Config file exists"
      else
        echo -e "''${RED}✗''${NC} Config file not found"
      fi
    }

    show_config() {
      if [ -f "$CONFIG_PATH" ]; then
        echo -e "''${BLUE}=== Claude Desktop MCP Configuration ===''${NC}"
        echo ""
        ${pkgs.jq}/bin/jq . "$CONFIG_PATH"
      else
        echo -e "''${RED}Configuration file not found:''${NC} $CONFIG_PATH"
        echo "Run: home-manager switch --flake . --impure"
        return 1
      fi
    }

    show_help() {
      echo "MCP Helper - Minimal Local MCP Servers"
      echo ""
      echo "Usage: mcp [command]"
      echo ""
      echo "Commands:"
      echo "  status   - Show MCP server status (default)"
      echo "  config   - Show current configuration"
      echo "  help     - Show this help message"
      echo ""
      echo "MCP Servers:"
      echo "  • Filesystem - File operations in your home directory"
      echo "  • Git - Git status, diff, commits, branches"
      echo "  • Memory - AI remembers context across conversations"
      echo "  • Fetch - Read documentation from the web"
      echo ""
      echo "All servers run locally with zero configuration"
    }

    case "''${1:-status}" in
      status) show_status ;;
      config) show_config ;;
      help|--help|-h) show_help ;;
      *)
        echo -e "''${RED}Unknown command:''${NC} $1"
        echo ""
        show_help
        exit 1
        ;;
    esac
  '';

  home.file.".local/bin/mcp".executable = true;

  # Setup instructions
  home.activation.setupMCPServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo ""
    echo "=== MCP Servers (Minimal Local Setup) ==="
    echo ""
    echo "📦 Configured servers (all local):"
    echo "  1. ✓ Filesystem - File operations"
    echo "  2. ✓ Git - Version control"
    echo "  3. ✓ Memory - AI memory"
    echo "  4. ✓ Fetch - Read web pages"
    echo ""
    echo "🚀 Zero configuration required"
    echo "💡 Restart Claude Desktop to activate"
    echo ""
    echo "📝 Check status: mcp status"
    echo ""
  '';

  # Shell aliases
  programs.zsh.shellAliases = {
    mcp = "mcp status";
    mcp-config = "mcp config";
  };
}
