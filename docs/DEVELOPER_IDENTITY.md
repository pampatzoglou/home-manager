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

# Remove the generic files left over from generation
# CAUTION: name them explicitly — a glob like `rm id_ed25519_sk*` would also
# delete the freshly exported `_sk_rk_` files
rm ~/.ssh/id_ed25519_sk ~/.ssh/id_ed25519_sk.pub

# Verify credentials on the YubiKey
ykman fido credentials list
```

### Recovering Keys on a New Device

Resident keys are stored on the YubiKey itself. On a new machine you do not re-generate — you export the existing credentials. The filenames produced are identical to those from the initial setup above.

#### Prerequisites

```bash
# macOS: the bundled ssh-keygen cannot enumerate resident keys — install
# upstream OpenSSH first and verify it is the one on PATH
brew install openssh
which ssh-keygen   # must be /opt/homebrew/bin/ssh-keygen, not /usr/bin/ssh-keygen

# Fresh machines won't have ~/.ssh yet
mkdir -p ~/.ssh && chmod 700 ~/.ssh
```

#### Export

```bash
cd ~/.ssh && $(brew --prefix openssh)/bin/ssh-keygen -K
# Prompts, in order:
#   1. FIDO PIN
#   2. A touch on the YubiKey per credential
#   3. An optional passphrase for each exported key handle file
#
# Writes all resident keys found on the YubiKey:
#   id_ed25519_sk_rk_git_<username>      id_ed25519_sk_rk_git_<username>.pub
#   id_ed25519_sk_rk_access_<username>   id_ed25519_sk_rk_access_<username>.pub
```

No server-side changes are needed: the public keys are unchanged, so existing
GitHub keys, `authorized_keys` entries, and allowed signers all keep working.
Just recreate `~/.gitconfig`, `~/.config/git/work`, and `~/.ssh/config` from the
templates in this document and you're done.

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
    sshCommand = ssh -i ~/.ssh/id_ed25519_sk_rk_git_<username> -o IdentitiesOnly=yes -o IdentityAgent=none
```

**Key flags explained:**
- `-i ~/.ssh/id_ed25519_sk_rk_git_<username>`: Explicitly specify which key reference to use
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

## GPG/OpenPGP Setup

### Overview

A YubiKey 5 has multiple independent applets:

| Applet | Purpose | Managed By |
|--------|---------|------------|
| FIDO2 | SSH authentication, git signing | `ssh-keygen`, `ssh-agent` |
| OpenPGP | GPG encryption, signing, `pass` | `gpg`, `gpg-agent`, `scdaemon` |

These applets do not share keys or interfere with each other. The FIDO setup above handles SSH. This section covers the OpenPGP applet for GPG and `pass`.

Home-manager configures `gpg`, `gpg-agent`, and `scdaemon` automatically via `modules/security.nix`. The steps below cover key generation and YubiKey provisioning, which must be done manually.

### GPG Master Key Generation

Generate a certify-only master key. This key stays offline after subkeys are created — it is only used to issue and revoke subkeys.

> Do this on a trusted machine. For maximum security, use an air-gapped machine or a live USB.

```bash
# Generate master key (Certify only)
gpg --full-generate-key --expert

# When prompted:
#   Key type: (8) RSA (set your own capabilities)
#   Toggle off Sign, Encrypt, keep only Certify
#   Key size: 4096
#   Expiry: 2y (can be extended later without re-provisioning YubiKeys)
#   Real name: <your-name>
#   Email: <your-email>
#   Passphrase: strong, unique passphrase (store securely)

# Note your key ID
gpg --list-keys --keyid-format 0xlong
```

### Subkey Creation

Add three subkeys for sign, encrypt, and authenticate. These are the keys that will live on the YubiKey.

```bash
gpg --expert --edit-key <KEY_ID>

# For each subkey:
#   addkey
#   (8) RSA (set your own capabilities)
#   Toggle to the desired capability, then confirm
#   Key size: 4096
#   Expiry: 1y

# Create these three subkeys:
#   1. Sign only (S)
#   2. Encrypt only (E)
#   3. Authenticate only (A)

# Save
save
```

After creation, verify:
```bash
gpg --list-keys --keyid-format 0xlong <KEY_ID>
# Should show:
#   pub   rsa4096/0x... [C]        (master, certify only)
#   sub   rsa4096/0x... [S]        (sign)
#   sub   rsa4096/0x... [E]        (encrypt)
#   sub   rsa4096/0x... [A]        (authenticate)
```

### Backup Procedures

Back up keys **before** moving them to the YubiKey. `keytocard` is destructive — it removes the local copy.

```bash
# Export master key (store offline, encrypted USB or similar)
gpg --export-secret-keys --armor <KEY_ID> > master-key-backup.asc

# Export subkeys separately
gpg --export-secret-subkeys --armor <KEY_ID> > subkeys-backup.asc

# Export public key (safe to distribute)
gpg --export --armor <KEY_ID> > public-key.asc

# Create paperkey backup (compact printable format for offline storage)
gpg --export-secret-keys <KEY_ID> | paperkey --output paperkey-backup.txt

# Generate revocation certificate
gpg --gen-revoke --armor <KEY_ID> > revocation-cert.asc
```

Store backups on an encrypted USB drive. Print the paperkey output and store it in a safe. The revocation certificate should be stored separately from the key backups.

### Moving Subkeys to YubiKey

#### Prepare the YubiKey OpenPGP Applet

```bash
# Check that the OpenPGP applet is detected
gpg --card-status

# Set OpenPGP PINs (different from FIDO PIN)
gpg --card-edit
# admin
# passwd
#   1 - Change PIN (default: 123456, set to 6+ digits)
#   3 - Change Admin PIN (default: 12345678, set to 8+ digits)
#   q
# quit
```

> **Lockout:** 3 wrong PIN attempts locks the card. Use the Admin PIN to unlock. 3 wrong Admin PIN attempts bricks the OpenPGP applet (requires `ykman openpgp reset`).

#### Transfer Subkeys

```bash
gpg --edit-key <KEY_ID>

# Move signing subkey
key 1
keytocard
# Select: (1) Signature key
key 1

# Move encryption subkey
key 2
keytocard
# Select: (2) Encryption key
key 2

# Move authentication subkey
key 3
keytocard
# Select: (3) Authentication key

save
```

After transfer, `gpg --list-secret-keys` will show `ssb>` for each subkey, indicating the key is on the card (not local).

### Sharing Identity Across Multiple YubiKeys

To use the same GPG identity on a second (or third) YubiKey, you need to re-import the subkeys from backup and transfer them again.

```bash
# 1. Delete the local key stubs (pointing to first YubiKey)
gpg --delete-secret-keys <KEY_ID>
# Confirm deletion

# 2. Re-import subkeys from backup
gpg --import subkeys-backup.asc

# 3. Prepare the second YubiKey
#    Insert the second YubiKey
gpg --card-status
gpg --card-edit
# admin -> passwd -> set PIN and Admin PIN -> quit

# 4. Transfer subkeys to second YubiKey (same procedure as above)
gpg --edit-key <KEY_ID>
# key 1 -> keytocard -> (1) Signature key -> key 1
# key 2 -> keytocard -> (2) Encryption key -> key 2
# key 3 -> keytocard -> (3) Authentication key
# save

# 5. Repeat steps 1-4 for additional YubiKeys
```

#### Switching Between YubiKeys

GPG stubs reference a specific card serial number. When you switch to a different YubiKey with the same keys, you need to update the stubs:

```bash
# Delete stale stubs
gpg-connect-agent "scd serialno" "learn --force" /bye

# Or if that doesn't work:
gpg --delete-secret-keys <KEY_ID>
gpg --card-status
# This re-creates stubs pointing to the currently inserted card
```

### Configuring pass

`pass` uses GPG for encryption. After setting up your GPG key on a YubiKey:

```bash
# Initialize the password store with your GPG key
pass init <KEY_ID>

# Enable git tracking (optional but recommended)
pass git init
pass git remote add origin <url>

# Basic usage
pass insert email/personal         # add a password
pass show email/personal           # decrypt and display
pass generate web/example.com 32   # generate random password
pass edit email/personal           # edit in $EDITOR
pass rm old/entry                  # remove an entry

# Sync across machines
pass git push
pass git pull
```

### Recovering on a New Machine

After running `home-manager switch --flake . --impure`, GPG tools and agent are already configured. You just need your keys:

```bash
# Import your public key
gpg --import public-key.asc

# Insert YubiKey — this fetches the secret key stubs from the card
gpg --card-status

# Trust your own key
gpg --edit-key <KEY_ID>
# trust -> 5 (ultimate) -> quit

# Verify
gpg --list-secret-keys
# Should show:
#   sec#  rsa4096 [C]        (master key, stub — not on card or local)
#   ssb>  rsa4096 [S]        (signing subkey, on card)
#   ssb>  rsa4096 [E]        (encryption subkey, on card)
#   ssb>  rsa4096 [A]        (authentication subkey, on card)

# Clone your password store
git clone <pass-repo-url> ~/.password-store
# or: pass git clone <url>

# Verify pass works
pass show email/personal
```

### Complete Key Inventory

| Applet | Key Type | Touch | PIN | Purpose |
|--------|----------|-------|-----|---------|
| FIDO2 | ed25519-sk (`ssh:git`) | No | Yes | Git SSH signing and push |
| FIDO2 | ed25519-sk (`ssh:access`) | Yes | Yes | SSH connections |
| OpenPGP | RSA 4096 [S] | Optional | Yes | GPG signing |
| OpenPGP | RSA 4096 [E] | Optional | Yes | Encryption / `pass` |
| OpenPGP | RSA 4096 [A] | Optional | Yes | GPG authentication |
