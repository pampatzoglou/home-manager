{ lib
, pkgs
, ...
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
    # Per-host identities live in a plain, unmanaged file so they stay portable to non-Nix machines.
    includes = [ "config.local" ];

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
    # Left false so SSH_AUTH_SOCK isn't taken over: FIDO keys (PIN every use) stay the default.
    # The ssh socket is still enabled below for the git key, which lives on the OpenPGP applet so
    # its PIN is asked once per YubiKey insertion. Git opts in via `gpgconf --list-dirs
    # agent-ssh-socket` in ~/.gitconfig.
    enableSshSupport = false;
    enableScDaemon = true; # required for YubiKey OpenPGP applet
    enableZshIntegration = true;
    extraConfig = ''
      enable-ssh-support
    '';

    pinentry.package =
      if pkgs.stdenv.hostPlatform.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses;

    # Cache passphrases for 2 hours, max 4 hours
    defaultCacheTtl = 7200;
    maxCacheTtl = 14400;
  };

  # FIDO/YubiKey setup reminder
  home.activation.setupFidoKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "YubiKey/SSH/GPG keys are set up manually: see docs/DEVELOPER_IDENTITY.md"
  '';
}
