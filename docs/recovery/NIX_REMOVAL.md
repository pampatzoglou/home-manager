# Nix macOS — Full Purge & Fresh Install

> Tested on macOS with an encrypted APFS Nix volume and Determinate Systems installer. Make sure you are running these commands from the default terminal of your system and not one that might have been installed by nix.

---

## Step 1 — Run the official uninstaller (if available)

```bash
/nix/nix-installer uninstall
```

Skip if the binary doesn't exist.

---

## Step 2 — Remove the Nix APFS volume

```bash
# Find your Nix volume identifier (look for "Nix Store" or /nix)
diskutil list

# Unmount
sudo diskutil unmount force /nix

# Delete the volume — replace disk3s7 with your actual identifier
sudo diskutil apfs deleteVolume disk3s7
```

---

## Step 3 — Remove the /nix mount point from synthetic.conf

```bash
sudo nano /etc/synthetic.conf
# Delete the line that reads: nix
# Save and exit
```

---

## Step 4 — Clean up shell profile backups and Nix injections

```bash
# Remove leftover backup files
sudo rm -f /etc/bashrc.backup-before-nix
sudo rm -f /etc/zshrc.backup-before-nix
sudo rm -f /etc/bash.bashrc.backup-before-nix

# Remove any Nix lines the installer added to shell profiles
sudo nano /etc/bashrc    # delete lines referencing /nix or nix-daemon
sudo nano /etc/zshrc     # same
```

---

## Step 5 — Remove Nix build users and group

> On macOS, Nix build users are prefixed with an underscore: `_nixbld1` … `_nixbld32`

```bash
# Verify users exist before deleting
dscl . -list /Users | grep nixbld

# Remove all 32 build users
for i in $(seq 1 32); do
  sudo dscl . -delete /Users/_nixbld$i 2>/dev/null
done

# Remove the build group
sudo dscl . -delete /Groups/nixbld 2>/dev/null
```

Expected UIDs: `_nixbld1` = 351 through `_nixbld32` = 382
Expected GID: `nixbld` = 350

---

## Step 6 — Unload and remove the Nix daemon

```bash
sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null
sudo rm -f /Library/LaunchDaemons/org.nixos.nix-daemon.plist
sudo rm -f /Library/LaunchDaemons/org.nixos.darwin-store.plist
```

---

## Step 7 — Remove remaining Nix files and config

```bash
sudo rm -rf /etc/nix
sudo rm -rf ~/.nix-profile
sudo rm -rf ~/.nix-defexpr
sudo rm -rf ~/.nix-channels
sudo rm -rf ~/.config/nix
sudo rm -rf ~/.local/state/nix
```

---

## Step 8 — Remove the Nix keychain entry

Replace the UUID below with the one from your own install (check Keychain Access or your installer output):

```bash
sudo security delete-generic-password -s XXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX
```

---

## Step 9 — Reboot

```bash
sudo reboot
```

After reboot, verify the mount point is gone:

```bash
ls /nix
# Expected: No such file or directory
```

---

## Step 10 — Fresh install (Determinate Systems)

If you want to reinstall, see the [Installation section in README.md](../README.md#installation) for complete setup instructions.
