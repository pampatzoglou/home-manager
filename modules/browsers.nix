{ config, pkgs, lib, ... }:

{
  # Brave Browser Configuration via Enterprise Policies
  # Policies are stored in ~/Library/Application Support/BraveSoftware/Brave-Browser/Policies/managed/
  
  home.file.".config/BraveSoftware/Brave-Browser/Policies/managed/homebrew.json".text = builtins.toJSON {
    # Force install useful extensions
    ExtensionInstallForcelist = [
      # uBlock Origin - Ad blocker
      "cjpalhdlnbpafiamejdnhcphjbkeiagm"
      # Bitwarden - Password manager  
      "nngceckbapebfimnlniiiahkandclblb"
      # Grammarly - Writing assistant
      "kbfnbcaeplbcioakkpcpgfkobkghlhen"
      # JSON Formatter - Pretty print JSON
      "bcjindcccaagfpapjjmafapmmgkkhgoa"
      # React Developer Tools
      "fmkadmapgofadopljbjfkapdkoienihi"
      # Redux DevTools
      "lmhkpmbekcpmknklioeibfkpmmfibljd"
      # Wappalyzer - Technology profiler
      "gppongmhjkpfnbhagpmjfkannfbllamg"
    ];

    # Security and Privacy Settings
    DefaultBrowserSettingEnabled = true;
    HomepageLocation = "brave://newtab";
    BookmarkBarEnabled = true;
    
    # Privacy settings
    DefaultSearchProviderEnabled = true;
    DefaultSearchProviderName = "DuckDuckGo";
    DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
    
    # Security settings
    SafeBrowsingEnabled = true;
    PasswordManagerEnabled = true;
    AutofillAddressEnabled = false;
    AutofillCreditCardEnabled = false;
    
    # Sync and account settings
    SyncDisabled = false;
    BrowserSignin = 1; # Allow browser sign-in
    
    # Development settings
    DeveloperToolsAvailability = 1; # Allow developer tools
    
    # Block known tracking extensions
    ExtensionInstallBlocklist = [
      # Block some potentially unwanted extensions - can be customized
      "*" # This blocks all by default, but the forcelist above overrides for specific extensions
    ];

    # Additional useful settings
    RestoreOnStartup = 1; # Restore the last session
    NewTabPageLocation = "brave://newtab";
    ShowHomeButton = true;
    
    # Downloads
    DownloadRestrictions = 0; # No download restrictions
    
    # Notifications
    DefaultNotificationsSetting = 2; # Block notifications by default
    
    # Location sharing
    DefaultGeolocationSetting = 2; # Block location sharing by default
    
    # Camera and microphone
    DefaultCameraSetting = 2; # Block camera access by default
    DefaultMicrophoneSetting = 2; # Block microphone access by default
  };

  # Create additional policies for development-specific settings if needed
  home.file.".config/BraveSoftware/Brave-Browser/Policies/managed/development.json".text = builtins.toJSON {
    # Additional development-related extensions (optional)
    ExtensionInstallForcelist = [
      # GitHub related extensions
      "hlepfoohegkhhmjieoechaddaejaokhf" # Refined GitHub
      "fmkadmapgofadopljbjfkapdkoienihi" # React Developer Tools (duplicate but ensuring it's there)
    ];
    
    # Allow insecure content for localhost development
    InsecureContentAllowedForUrls = [
      "http://localhost:*"
      "http://127.0.0.1:*"
      "http://[::1]:*"
    ];
    
    # Development-friendly settings
    DefaultWebBluetoothGuardSetting = 3; # Allow Bluetooth for PWA testing
    DefaultWebUsbGuardSetting = 3; # Allow USB for development
  };

  # Optional: Set up Brave as default browser (requires additional macOS configuration)
  # This creates a launch script that can be used to set Brave as default
  home.file.".local/bin/set-brave-default".text = ''
    #!/bin/bash
    # Set Brave as default browser on macOS
    # Run this manually after installation
    open -b com.brave.Browser --args --make-default-browser
  '';

  home.file.".local/bin/set-brave-default".executable = true;
}
