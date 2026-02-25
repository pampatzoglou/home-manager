{ lib, ... }:

{
  # Security Configuration
  # Includes SSH hardening and FIDO2/YubiKey support
  # Manual setup required - see DEVELOPER_IDENTITY.md for FIDO key generation

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # SSH agent is managed in zsh.nix for FIDO2 Yubikey support
  services.ssh-agent = {
    enable = false;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        compression = true;
        controlMaster = "no";
        controlPath = "none";
        forwardAgent = false;
        serverAliveInterval = 60;
        serverAliveCountMax = 3;

        extraOptions = {
          TCPKeepAlive = "yes";
        };
      };
    };
  };

  # FIDO/YubiKey setup reminder
  home.activation.setupFidoKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo ""
    echo "=== FIDO/YubiKey Configuration ==="
    echo ""
    echo "✓ SSH configuration created with FIDO2 support"
    echo ""
    echo "⚠️  Manual FIDO key setup required:"
    echo ""
    echo "📦 Prerequisites (macOS):"
    echo "  brew install openssh keychain  # macOS bundled OpenSSH doesn't support resident keys"
    echo ""
    echo "🔑 YubiKey Setup:"
    echo "  # Reset FIDO application (⚠️  CAUTION: deletes all FIDO credentials)"
    echo "  ykman fido reset"
    echo ""
    echo "  # Change PIN for security"
    echo "  ykman fido access change-pin"
    echo ""
    echo "🔐 Generate Keys:"
    echo "  # Personal SSH key (resident, requires touch)"
    echo "  ssh-keygen -t ed25519-sk -O resident -O application=ssh:personal -O user=<username> -C \"<email>\""
    echo ""
    echo "  # Git signing key (no touch required for automation)"
    echo "  ssh-keygen -t ed25519-sk -O no-touch-required -O application=ssh:git -O user=<username> -C \"<email>\""
    echo ""
    echo "  # Work SSH key (resident, requires touch)"
    echo "  ssh-keygen -t ed25519-sk -O resident -O application=ssh:work -O user=<username> -C \"<email>\""
    echo ""
    echo "📋 Manage Keys:"
    echo "  ykman fido credentials list  # List all credentials on YubiKey"
    echo "  ssh-add -K                   # Load resident keys into SSH agent"
    echo ""
    echo "📚 See DEVELOPER_IDENTITY.md for complete setup guide"
    echo ""
  '';
}
