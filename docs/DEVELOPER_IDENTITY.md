## 🔧 Git Customization

Home-manager manages `~/.config/git/ignore` (global gitignore). All other git configuration is set manually so that identities can vary per organisation.

### Global Configuration

```ini
# ~/.gitconfig
[user]
        name = <your-name>
        email = <your-email@example.com>
        signingkey = ~/.ssh/id_ed25519_sk_rk_git_<username>.pub
[gpg]
        format = ssh
[commit]
        gpgsign = true
[tag]
        gpgsign = true
[core]
        excludesFile = ~/.config/git/ignore
        untrackedCache = true
        sshCommand = ssh -i ~/.ssh/id_ed25519_sk_rk_git_<username> -o IdentitiesOnly=yes -o IdentityAgent=none
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
    signingkey = ~/.ssh/id_ed25519_sk_rk_git_<username>.pub
[gpg]
    format = ssh
[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_sk_rk_git_<username> -o IdentitiesOnly=yes -o IdentityAgent=none
```

## 🔐 FIDO Key Setup

This configuration assumes you have a YubiKey or compatible FIDO security key for enhanced SSH authentication. The setup uses two resident FIDO keys: a git key (PIN only, no touch) for commit/tag signing and git push, and an access key (PIN + touch) for SSH connections.

### Assumptions

- You have a YubiKey 5 or later with FIDO2 support
- YubiKey Manager (`ykman`) is installed
- You want resident keys for portability across devices

- **Mac specific**: The OpenSSH bundled with macOS cannot work with resident keys due to a compilation flag (`--disable-security-key`). Install the upstream OpenSSH via Homebrew:
```bash
brew install openssh keychain
```

### YubiKey Initialization

Run these steps once per YubiKey before generating any keys.

```bash
# Verify the key is detected and note the serial number for your records
ykman info

# Reset the FIDO2 application
# CAUTION: deletes ALL FIDO2 credentials and clears the PIN
# You must physically touch the key when prompted to confirm
ykman fido reset

# Set the FIDO2 PIN
# This PIN gates all verify-required key operations (signing and access)
# Minimum 4 characters; 8+ alphanumeric recommended
ykman fido access change-pin

# Verify the PIN is configured
ykman fido info
```

> **Lockout:** FIDO2 has no PUK. After 8 consecutive wrong PIN attempts the application locks permanently and requires `ykman fido reset` (losing all credentials). Store the PIN securely.

### Key Generation

Generate resident FIDO keys, then export them all at once via `ssh-keygen -K` to get stable, auto-named key handle files. The `_rk_` names produced by `ssh-keygen -K` are the canonical paths referenced everywhere (gitconfig, ssh config) — identical whether on the original machine or recovering on a new one.

```bash
# Git key — PIN required, no touch (git commit/tag signing and git push)
ssh-keygen -t ed25519-sk -O resident -O verify-required -O no-touch-required \
           -O application=ssh:git -O user=<username> -C "<email>"

# Access key — PIN + touch required (SSH connections)
ssh-keygen -t ed25519-sk -O resident -O verify-required \
           -O application=ssh:access -O user=<username> -C "<email>"

# Export all resident keys from the YubiKey with stable names, then remove the generic files
cd ~/.ssh && ssh-keygen -K
# Produces:
#   id_ed25519_sk_rk_git_<username>      id_ed25519_sk_rk_git_<username>.pub
#   id_ed25519_sk_rk_access_<username>   id_ed25519_sk_rk_access_<username>.pub
rm ~/.ssh/id_ed25519_sk ~/.ssh/id_ed25519_sk.pub

# Verify credentials on the YubiKey
ykman fido credentials list
```

### Recovering Keys on a New Device

Resident keys are stored on the YubiKey itself. On a new machine you do not re-generate — you export the existing credentials. The filenames produced are identical to those from the initial setup above.

```bash
cd ~/.ssh && ssh-keygen -K
# Writes all resident keys found on the YubiKey:
#   id_ed25519_sk_rk_git_<username>      id_ed25519_sk_rk_git_<username>.pub
#   id_ed25519_sk_rk_access_<username>   id_ed25519_sk_rk_access_<username>.pub
```

### How They're Used

| Key | Application | Touch | PIN | Purpose |
|-----|-------------|-------|-----|---------|
| Git | `ssh:git` | No | Yes | Git commit/tag signing and git push |
| Access | `ssh:access` | Yes | Yes | SSH connections |

Resident keys are stored on the YubiKey and recoverable on any machine via `ssh-keygen -K`.

The SSH configuration in `modules/security.nix` is pre-configured to use these keys with appropriate security policies.

### 📚 Lessons Learned: Working with Resident Keys

**Important:** Resident keys stored on FIDO devices (like YubiKeys) are **intermediate references** to the actual cryptographic material on the hardware token, not standalone private keys.

#### SSH Agent Limitations

**The Problem:**
Loading resident keys directly into your SSH agent doesn't work reliably because:

1. The key file (e.g., `~/.ssh/id_ed25519_sk_rk_access_<username>`) is just a reference handle to the FIDO device
2. The actual signing operation must communicate with the physical security key
3. SSH agent caching can interfere with the FIDO authentication flow

**The Solution:**
You must explicitly specify the key file using the `-I` flag when connecting:

```bash
# ❌ WRONG - Relying on agent alone
ssh git@github.com

# ✅ CORRECT - Explicitly specify the key
ssh -i ~/.ssh/id_ed25519_sk_rk_access_<username> git@github.com
```

#### Git Configuration Implications

This is why our git configuration uses explicit SSH commands with `-I` and disables the agent:

```ini
[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_sk_rk_access_<username> -o IdentitiesOnly=yes -o IdentityAgent=none
```

**Key flags explained:**
- `-i ~/.ssh/id_ed25519_sk_rk_access_<username>`: Explicitly specify which key reference to use
- `-o IdentitiesOnly=yes`: Only use the specified key, ignore agent keys
- `-o IdentityAgent=none`: Disable SSH agent entirely for this connection

This ensures Git always communicates directly with the FIDO device through the key reference file, triggering the proper authentication flow (touch requirement, PIN if needed, etc.).

#### SSH Config Pattern

Apply the same pattern in your `~/.ssh/config` for reliable FIDO key usage:

```ssh
Host github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_sk_rk_access_<username>
    IdentitiesOnly yes
    IdentityAgent none

Host *.work.com
    User <username>
    IdentityFile ~/.ssh/id_ed25519_sk_rk_access_<username>
    IdentitiesOnly yes
    IdentityAgent none
```

**TL;DR:** Always use `-i` (IdentityFile) with resident keys and disable the agent (`IdentityAgent=none`) to ensure proper FIDO device communication.
