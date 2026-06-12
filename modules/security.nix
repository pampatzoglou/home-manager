{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Security Configuration
  # Includes SSH hardening, FIDO2/YubiKey support, and GPG/OpenPGP
  # Manual setup required - see docs/DEVELOPER_IDENTITY.md

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

    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        Compression = "yes";
        ControlMaster = "no";
        ControlPath = "none";
        ForwardAgent = "no";
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
        TCPKeepAlive = "yes";
      };
    };
  };

  # GPG Configuration
  # Uses YubiKey OpenPGP applet for encryption/signing (separate from FIDO SSH keys)
  # Manual setup required - see docs/DEVELOPER_IDENTITY.md for GPG key generation
  programs.gpg = {
    enable = true;
    mutableKeys = true;
    mutableTrust = true;

    settings = {
      use-agent = true;
      armor = true;
    };

    scdaemonSettings = {
      # Disable CCID to avoid conflicts with macOS CryptoTokenKit / system PCSC
      # Safe on Linux too (falls back to PCSC)
      disable-ccid = true;
    };
  };

  # GPG Agent - manages passphrase caching and smartcard access
  # Linux: systemd socket activation / macOS: launchd agent
  services.gpg-agent = {
    enable = true;
    enableSshSupport = false; # SSH uses FIDO keys, not GPG
    enableScDaemon = true; # required for YubiKey OpenPGP applet
    enableZshIntegration = true;

    pinentry.package = if pkgs.stdenv.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses;

    # Cache passphrases for 2 hours, max 4 hours
    defaultCacheTtl = 7200;
    maxCacheTtl = 14400;
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
    echo "📚 See docs/DEVELOPER_IDENTITY.md for complete setup guide"
    echo ""
    echo "=== GPG/OpenPGP Configuration ==="
    echo ""
    echo "✓ GPG agent configured with YubiKey smartcard support"
    echo "✓ Pinentry configured for passphrase entry"
    echo ""
    echo "⚠️  Manual GPG key setup required:"
    echo "  See docs/DEVELOPER_IDENTITY.md for GPG key generation and YubiKey setup"
    echo ""
  '';
}
