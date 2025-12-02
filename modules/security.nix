{ config, pkgs, lib, ... }:

{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      disable-ccid = true;
      card-timeout = "10";
      debug-level = "basic";
    };
    settings = {
      # Enhanced cryptographic preferences
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
      
      # Strong key generation defaults
      default-new-key-algo = "ed25519/cert,sign+cv25519/encr";
      
      # Algorithm and security settings
      cert-digest-algo = "SHA512";
      s2k-digest-algo = "SHA512";
      s2k-cipher-algo = "AES256";
      min-rsa-length = "3072";
      
      # Disable weak algorithms
      weak-digest = "MD5 SHA1";
      disable-cipher-algo = "IDEA CAST5 3DES";
      
      # Display and behavior settings
      charset = "utf-8";
      fixed-list-mode = true;
      no-comments = true;
      no-emit-version = true;
      no-greeting = true;
      keyid-format = "0xlong";
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      with-fingerprint = true;
      
      # Security policies
      require-cross-certification = true;
      no-symkey-cache = true;
      use-agent = true;
      throw-keyids = true;
      lock-once = true;
      
      # Network security
      auto-key-retrieve = false;
      honor-http-proxy = true;
      
      # Keyserver configuration
      keyserver = "hkps://keys.openpgp.org";
      keyserver-options = "honor-keyserver-url include-revoked no-honor-keyserver-url";
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-curses;
    
    # Enhanced caching configuration
    defaultCacheTtl = 28800;      # 8 hours
    maxCacheTtl = 86400;          # 24 hours  
    defaultCacheTtlSsh = 14400;   # 4 hours for SSH keys
    maxCacheTtlSsh = 28800;       # 8 hours max for SSH
  };

  home.activation.killGpgAgent = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if command -v gpgconf >/dev/null 2>&1; then
      echo "Killing gpg-agent..."
      gpgconf --kill gpg-agent || echo "gpg-agent not running or command failed"
    else
      echo "gpgconf not found, skipping gpg-agent reset"
    fi
  '';

  home.activation.fixGnuPGPerms = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -d "${config.home.homeDirectory}/.gnupg" ]; then
      chmod 700 "${config.home.homeDirectory}/.gnupg"
      chmod 600 "${config.home.homeDirectory}/.gnupg/"* 2>/dev/null || true
      if [ -d "${config.home.homeDirectory}/.gnupg/private-keys-v1.d" ]; then
        chmod 700 "${config.home.homeDirectory}/.gnupg/private-keys-v1.d"
      fi
      echo "GnuPG directory permissions fixed"
    else
      echo "GnuPG directory not found, skipping permission fix"
    fi
  '';

  programs.ssh = {
    enable = true;

    # Disable deprecated defaults
    enableDefaultConfig = false;

    # Minimal valid match block
    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        compression = true;
        controlMaster = "auto";
        controlPath = "${config.home.homeDirectory}/.ssh/master-%r@%n:%p";
        controlPersist = "10m";
      };
    };

    extraConfig = ''
      # Default host-level settings
      Host *
        ServerAliveInterval 60
        ServerAliveCountMax 3
        HashKnownHosts yes
        StrictHostKeyChecking ask
        VerifyHostKeyDNS ask
        TCPKeepAlive yes

      # Hardening
        Protocol 2
        Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
        MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512
        KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
        HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-rsa-cert-v01@openssh.com,ssh-ed25519,ssh-rsa
    '';
  };

  home.activation.fixSshPerms = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -d "$HOME/.ssh" ]; then
      echo "Fixing .ssh permissions..."
      
      # Private keys (ignore errors for files we can't modify)
      find "$HOME/.ssh" -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true

      # Public keys (ignore errors for files we can't modify)
      find "$HOME/.ssh" -type f -name "*.pub" -exec chmod 644 {} \; 2>/dev/null || true

      # Known hosts, config, authorized_keys, etc. (ignore errors)
      for file in config known_hosts authorized_keys; do
        [ -f "$HOME/.ssh/$file" ] && chmod 644 "$HOME/.ssh/$file" 2>/dev/null || true
      done

      echo ".ssh permissions fixed (ignoring protected files)"
    else
      echo ".ssh directory not found, skipping permission fix"
    fi
  '';
}
