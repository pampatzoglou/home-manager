## 🔧 Git Customization

Home-manager manages `~/.config/git/ignore` (global gitignore). All other git configuration is set manually so that identities can vary per organisation.

### Global Configuration

```ini 
# ~/.gitconfig
[user]
        name = <your-name>
        email = <your-email@example.com>
        signingkey = ~/.ssh/id_ed25519.pub
[gpg]
        format = ssh
[commit]
        gpgsign = true
[tag]
        gpgsign = true
[core]
        excludesFile = ~/.config/git/ignore
        untrackedCache = true
        sshCommand = ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes -o IdentityAgent=none
[init]
        defaultBranch = main
[pull]
        rebase = true
[fetch]
        prune = true
[rerere]
        enabled = true
[diff]
        colorMoved = zebra
[log]
        date = iso
[rebase]
        autosquash = true
[push]
        autoSetupRemote = true
[includeIf "gitdir:~/Projects/work/"]
        path = ~/.config/git/work
```

### Per-Organisation Configuration

```ini
# ~/.config/git/work
[user]
    name = Your Work Name
    email = you@work.com
    signingkey = ~/.ssh/id_ed25519_work.pub
[gpg]
    format = ssh
[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_work -o IdentitiesOnly=yes -o IdentityAgent=none
```

## 🔐 FIDO Key Setup

This configuration assumes you have a YubiKey or compatible FIDO security key for enhanced SSH authentication. The setup uses FIDO keys for passwordless SSH access to personal, Git, and work accounts.

### Assumptions

- You have a YubiKey 5 or later with FIDO2 support
- YubiKey Manager (`ykman`) is installed
- You want resident keys for portability across devices

- **Mac specific**: The OpenSSH bundled with macOS can not work with resident keys, despite being compatible with them. This is due to a compilation flag that disables this option (--disable-security-key). To work around this, we'll install the latest version of OpenSSH using homebrew
```bash
brew install openssh keychain
```

### Key Generation Examples

Generate resident FIDO keys for different purposes:

```bash
# Reset FIDO application (CAUTION: deletes all FIDO credentials)
ykman fido reset

# Change PIN for security
ykman fido access change-pin

# Personal SSH key (resident, requires touch)
ssh-keygen -t ed25519-sk -O resident -O application=ssh:personal -O user=<username> -C "<email>"

# Git signing key (no touch required for automation)
ssh-keygen -t ed25519-sk -O no-touch-required -O application=ssh:git  -O user=<username> -C "<email>"

# List all credentials on YubiKey
ykman fido credentials list

# Load resident keys into SSH agent
ssh-add -K
```

### How They're Used

- **Personal Keys**: Used for general SSH access and Git operations
- **Git Keys**: Dedicated for commit signing (no-touch for CI/CD compatibility)
- **Work Keys**: Isolated for corporate access with touch requirement for security
- **Resident Keys**: Stored on YubiKey for use across multiple devices

The SSH configuration in `modules/security.nix` is pre-configured to use these keys with appropriate security policies.
