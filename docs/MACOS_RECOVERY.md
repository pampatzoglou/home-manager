# Fixing `nix-shell` and `home-manager` After macOS Updates

macOS updates frequently break parts of the Nix environment because they modify system SDK paths, developer tools, or daemon permissions. This guide covers the most common causes and fixes.

---

## 0. `command not found: nix-shell` After Update

**⏱️ Time Estimate: 3-5 minutes**

If `nix-shell` or other Nix commands are not found after a macOS update, follow these steps:

**🔍 Step 1: Check if Nix is still installed**

```sh
ls /nix
```

If you see directories like `store`, `var`, etc., Nix is still installed.  
If `/nix` is missing → you'll need to reinstall (skip to Section 5).

**🔍 Step 2: Try loading Nix manually**

```sh
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

Then test:

```sh
nix-shell --version
```

If this works → the issue is just that your shell config isn't loading Nix anymore.

**🛠️ Step 3: Fix your shell config (most common issue)**

macOS updates often reset or change shells (e.g. bash → zsh), or overwrite config files.

**If you're using zsh (default on macOS):**

Edit `~/.zshrc` and add:

```sh
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
```

Then reload:

```sh
source ~/.zshrc
```

**If you're using bash:**

Edit `~/.bashrc` or `~/.bash_profile` and add the same snippet.

**🔍 Step 4: Confirm PATH**

```sh
echo $PATH
```

You should see something like:

```
/nix/var/nix/profiles/default/bin
```

If not → the profile script isn't being sourced correctly.

**Verify it worked:**

```sh
nix-shell --version
# Should output the Nix version
```

---

## 1. Reinstall Xcode Command Line Tools (Most Common Issue)

**⏱️ Time Estimate: 5-10 minutes**

macOS updates often remove or invalidate the Command Line Tools required by Nix builds.

Check the current path:

```sh
xcode-select -p
```

If it errors or points somewhere incorrect, reinstall:

```sh
xcode-select --install
sudo xcode-select --switch /Library/Developer/CommandLineTools
```

**Verify it worked:**

```sh
xcode-select -p
# Should output: /Library/Developer/CommandLineTools
```

Test that Nix can build:

```sh
nix-shell -p hello
```

---

## 2. Restart the Nix Daemon

**⏱️ Time Estimate: 1-2 minutes**

macOS upgrades sometimes leave the Nix daemon in a broken state.

Restart it:

```sh
sudo launchctl kickstart -k system/org.nixos.nix-daemon
```

Alternative (if the above fails):

```sh
sudo launchctl stop org.nixos.nix-daemon
sudo launchctl start org.nixos.nix-daemon
```

**Verify it worked:**

```sh
sudo launchctl list | grep nix-daemon
# Should show the daemon is running
```

---

## 3. Check That Shell Initialization Still Loads Nix

**⏱️ Time Estimate: 2-3 minutes**

macOS updates sometimes overwrite `/etc/zprofile` or `/etc/zshrc`.

**For login shells (default on macOS):**

```sh
grep nix /etc/zprofile
```

**For interactive shells:**

```sh
grep nix /etc/zshrc
```

You should see something like:

```sh
# Nix
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
# End Nix
```

If it's missing from both files, repair the installation:

```sh
sh <(curl -L https://nixos.org/nix/install)
```

This will repair the shell configuration without deleting the Nix store.

**Verify it worked:**

```sh
# Open a new terminal and check:
echo $NIX_PATH
# Should output something like: /nix/var/nix/profiles/per-user/root/channels
```

---

## 4. Update Channels or Flakes

**⏱️ Time Estimate: 2-5 minutes**

If using channels:

```sh
nix-channel --update
```

If using flakes:

```sh
# Navigate to your flake directory first
cd ~/.config/home-manager
nix flake update
```

**Verify it worked:**

```sh
# For channels:
nix-channel --list

# For flakes:
nix flake metadata
```

---

## 5. Upgrade Nix After Major macOS Updates

**⏱️ Time Estimate: 3-5 minutes**

Large macOS upgrades can require a newer Nix version.

```sh
sudo nix upgrade-nix
```

> **Note:** `nix upgrade-nix` was removed in Nix 2.18+ (released September 2023). If this command fails, re-run the installer instead — it will upgrade Nix in place without touching the store:
>
> ```sh
> sh <(curl -L https://nixos.org/nix/install)
> ```
>
> If you installed via the [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer) (an alternative Nix installer with better macOS support), upgrade with:
>
> ```sh
> /nix/nix-installer self-update
> ```

**Verify it worked:**

```sh
nix --version
```

---

## 6. Garbage Collect Old or Broken Paths

**⏱️ Time Estimate: 2-10 minutes (depending on cache size)**

Sometimes cached paths become invalid after system updates.

```sh
nix-collect-garbage -d
```

This removes all old generations and unused store paths.

**For a less aggressive cleanup (keeps current generation):**

```sh
nix-collect-garbage --delete-older-than 30d
```

Then rebuild your environment (see section 7).

---

## 7. Rebuild Home Manager

**⏱️ Time Estimate: 5-15 minutes**

If you use home-manager:

```sh
home-manager switch
```

If using flakes (recommended approach for this configuration):

```sh
# Navigate to your configuration directory
cd ~/.config/home-manager
home-manager switch --flake .
```

If using nix-darwin:

```sh
# Navigate to your darwin configuration directory
cd ~/.config/home-manager  # or wherever your flake.nix is located
darwin-rebuild switch --flake .
```

**Verify it worked:**

```sh
home-manager generations
# Should show your new generation at the top
```

---

## 8. Check /nix Volume Permissions

**⏱️ Time Estimate: 2-3 minutes**

After macOS updates, the `/nix` volume might have incorrect ownership or permissions.

**Check ownership:**

```sh
ls -la / | grep nix
```

You should see something like:

```
lrwxr-xr-x   1 root  wheel    11 Jan  1 12:00 nix -> /nix/store
```

**Fix if needed (APFS volume):**

```sh
sudo chown -R root:wheel /nix
```

**For multi-user installations, also check the store:**

```sh
sudo chown -R root:nixbld /nix/store
sudo chmod 1775 /nix/store
```

**Verify it worked:**

```sh
ls -ld /nix/store
# Should show: drwxrwxr-t root nixbld
```

---

## 9. Rosetta Issues (Apple Silicon Only)

**⏱️ Time Estimate: 2-3 minutes**

macOS updates on Apple Silicon sometimes remove Rosetta, which is needed for running x86_64 binaries.

Reinstall it:

```sh
softwareupdate --install-rosetta --agree-to-license
```

**Verify it worked:**

```sh
# Check if Rosetta is installed
pgrep oahd
# Should return a process ID if Rosetta is running
```

---

## 10. Useful Diagnostics

**⏱️ Time Estimate: 1-2 minutes**

Run Nix's built-in diagnostic tool:

```sh
nix doctor
```

**What to look for in the output:**

- ✅ **Store path writable**: Store should be writable by the Nix daemon
- ✅ **Daemon connection**: Should successfully connect to the Nix daemon
- ⚠️ **NIX_PATH warnings**: May indicate channel or profile issues
- ❌ **Store corruption**: Indicates serious problems requiring repair

**Show detailed errors during builds:**

```sh
nix-shell -p hello --show-trace
```

This provides a full stack trace of any errors encountered.

---

## 11. Prefer the Modern Nix CLI

Instead of the legacy `nix-shell`, consider using the modern Nix CLI:

```sh
# Instead of: nix-shell -p hello
nix shell nixpkgs#hello

# Instead of: nix-shell default.nix
nix develop
```

The newer CLI tends to be more reliable on macOS and provides better error messages.

---

## Recommended Workflow Before macOS Updates

**Create a recovery point before updating:**

List available home-manager generations so you can roll back if needed:

```sh
home-manager generations
```

**Rollback if needed after the update:**

```sh
# Rollback to previous generation
home-manager switch --rollback

# Or switch to a specific generation
home-manager switch --switch-generation <generation-id>
```

**Export your current Nix configuration (optional):**

```sh
# Backup your flake lock
cp ~/.config/home-manager/flake.lock ~/.config/home-manager/flake.lock.backup
```

---

## Quick Post-Update Recovery Checklist

> **⚠️ Important:** `xcode-select --install` opens an interactive GUI dialog. Run it first and complete the prompt before continuing with the remaining commands.

```sh
# Step 1 — Interactive, opens a GUI dialog (5-10 minutes):
xcode-select --install

# Wait for installation to complete, then continue...

# Step 2 — Restart Nix daemon (1 minute):
sudo launchctl kickstart -k system/org.nixos.nix-daemon

# Step 3 — Update your configuration (2-5 minutes):
# Choose ONE based on your setup:

# Option A: If using channels
nix-channel --update

# Option B: If using flakes (recommended)
cd ~/.config/home-manager && nix flake update

# Step 4 — Clean up old paths (2-10 minutes):
nix-collect-garbage -d

# Step 5 — Rebuild your environment (5-15 minutes):
home-manager switch --flake ~/.config/home-manager
```

**Total time estimate: 15-45 minutes**

This resolves the majority of Nix breakages on macOS.

---

## Common Error Messages

Here's a quick reference for common errors and which section to check:

| Error Message | Most Likely Fix | Section |
|---------------|----------------|---------|
| `error: cannot build derivation: clang: error: SDK not found` | Reinstall Xcode Command Line Tools | [Section 1](#1-reinstall-xcode-command-line-tools-most-common-issue) |
| `error: could not connect to Nix daemon` | Restart Nix daemon | [Section 2](#2-restart-the-nix-daemon) |
| `error: file 'nixpkgs' was not found in the Nix search path` | Check shell initialization or update channels | [Section 3](#3-check-that-shell-initialization-still-loads-nix) |
| `error: hash mismatch` | Update flakes/channels and garbage collect | [Sections 4](#4-update-channels-or-flakes) & [6](#6-garbage-collect-old-or-broken-paths) |
| `error: permission denied` | Check /nix permissions | [Section 8](#8-check-nix-volume-permissions) |
| `error: cannot execute binary file` (Apple Silicon) | Install Rosetta | [Section 9](#9-rosetta-issues-apple-silicon-only) |
| `error: experimental feature 'nix-command' is disabled` | Enable experimental features in nix.conf | [README](../README.md#installation) |

---

## Nuclear Option

**⏱️ Time Estimate: 30-60 minutes**

If everything fails and you want to start fresh, see [PURGE.md](./PURGE.md) for complete uninstallation and reinstallation instructions.

The beauty of declarative configuration is that you will end up with the exact same installation after following the purge and reinstall process—all your packages, settings, and configurations will be restored.

**When to consider this option:**

- Multiple fixes have failed
- Store corruption is detected
- Migration from an old Nix version (pre-2.4)
- Switching between single-user and multi-user installations

---

**💡 Pro Tip:** Join the [Nix community on Discourse](https://discourse.nixos.org/) if you encounter persistent issues. The community is helpful and responsive to macOS-specific problems.
