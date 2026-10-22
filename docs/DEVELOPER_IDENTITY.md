# Developer Identity: Git, SSH and YubiKey

How git signing, git push/pull and SSH access are set up with a YubiKey 5, and how to redo it
(new YubiKey, new machine, or after a lockout).

## Design

A YubiKey 5 has independent applets. Each key lives on the applet whose PIN behaviour fits it:

| What you do | Key | Applet | PIN | Touch |
|---|---|---|---|---|
| Plug the YubiKey in | — | — | No | No |
| First git push/pull/signed commit after plugging in | git | OpenPGP | **Once per insertion** | Yes |
| Later git actions, key still plugged in | git | OpenPGP | No (cached until unplug) | Yes |
| `ssh` to servers | access | FIDO2 | **Every connection** | Yes |
| Website login with the key (GitHub, Google) | passkey | FIDO2 | Site decides | Yes |

### Key inventory

| Key | Applet | File / ID | Used for | PIN | Touch |
|---|---|---|---|---|---|
| access | FIDO2 `ssh:access_<username>` | `~/.ssh/id_ed25519_sk_rk_access_<username>` | `ssh` to servers | Every use | Every use |
| git (auth subkey `[A]`, ed25519) | OpenPGP | `~/.ssh/id_gpg_git_<username>.pub` | git push/pull **and** commit/tag signing (SSH format) | Once per insertion | Every use |
| sign subkey `[S]`, ed25519 | OpenPGP | primary key `<KEY_ID>` | native GPG signatures (`gpg --sign`); not used by git | Once per insertion | Every use |
| encrypt subkey `[E]`, cv25519 | OpenPGP | `<ENC_KEY_ID>` | GPG encryption/decryption | Once per insertion | No |
| website passkeys | FIDO2 | on the YubiKey only | Login to GitHub, Google, … | Site decides | Every use |

At a glance:

| Requires | Keys |
|---|---|
| **PIN + touch every time** | access |
| **PIN once per insertion, then touch only** | git `[A]`, sign `[S]` |
| **PIN once per insertion, no touch** | encrypt `[E]` (add `ykman openpgp keys set-touch enc on` to change) |
| **Touch, PIN up to the site** | website passkeys |
| **Neither** | plugging the key in |

Git signs with the `[A]` key, not `[S]`: with `gpg.format = ssh`, git signs through gpg-agent's
SSH socket, which only exposes the authentication key. One PIN entry after plugging in covers all
OpenPGP keys; unplugging (or sleep / another smart-card app) clears it.

- FIDO2 has no "unlock once" mode: a key either needs the PIN on every use (`verify-required`) or
  never. OpenPGP (via gpg-agent/scdaemon) keeps the card unlocked until it is removed, which is
  why the git key lives there.
- FIDO2 PIN and OpenPGP PIN are separate (they can be set to the same value).
- Git uses SSH-format signatures (`gpg.format = ssh`) in both cases, so GitHub only needs SSH keys.

### What home-manager does vs. what stays manual

| Piece | Where | Managed by |
|---|---|---|
| PATH order (Nix + Homebrew before `/usr/bin`) | `modules/zsh.nix` `initContent` | home-manager |
| gpg-agent with `enable-ssh-support` (SSH_AUTH_SOCK untouched) | `modules/security.nix` | home-manager |
| `~/.ssh/config` base + `Include config.local` | `modules/security.nix` | home-manager |
| Per-host SSH identities | `~/.ssh/config.local` | manual (portable) |
| Git identity and signing | `~/.gitconfig`, `~/.config/git/*` | manual (portable) |
| Git signing helper | `~/.config/git/gpg-ssh-keygen` | manual (portable) |

Git and SSH identity files are kept out of home-manager on purpose so they can be copied to
machines without Nix.

## Prerequisites

- YubiKey 5 (FIDO2 + OpenPGP), plugged **directly** into the machine. Some hubs/docks don't pass
  it through at all (see Troubleshooting).
- `ykman`, `gpg`, `pinentry-mac` (installed by home-manager).
- **macOS:** Apple's OpenSSH is built without FIDO support. Install upstream OpenSSH and make sure
  it wins on PATH:

```sh
brew install openssh
which ssh-keygen   # must be /opt/homebrew/bin/ssh-keygen
```

Check the key is detected and note its model/serial:

```sh
ykman list
```

---

## Part 1: FIDO2 access key (PIN + touch every connection)

### 1.1 Set the FIDO2 PIN (once per YubiKey)

```sh
ykman fido info                # "PIN: Not set" on a fresh key
ykman fido access change-pin
```

> **Lockout:** FIDO2 has no PUK. 8 wrong PINs lock it; the only fix is `ykman fido reset`, which
> erases all FIDO2 credentials, **including website passkeys**.

### 1.2 Generate the key

```sh
ssh-keygen -t ed25519-sk -O resident -O verify-required -O application=ssh:access_<username> \
  -C "access_<username>@yubikey-<serial>" -f ~/.ssh/id_ed25519_sk_rk_access_<username>
```

- Press Enter for no passphrase: the file is only a handle, the key never leaves the YubiKey.
- Re-running with the same `application=` replaces the old credential on the YubiKey.
- Drop `-O verify-required` for touch-only (no PIN).

### 1.3 SSH config (keep it out of the agent)

An agent can't ask for the FIDO PIN, so a `verify-required` key loaded into an agent fails with
`agent refused operation`. In `~/.ssh/config.local`:

```ssh
Host <server>
  User <username>
  IdentityFile ~/.ssh/id_ed25519_sk_rk_access_<username>
  IdentitiesOnly yes
  IdentityAgent none
  AddKeysToAgent no
  # Optional: one PIN per 10 minutes instead of per connection
  # ControlMaster auto
  # ControlPath ~/.ssh/cm-%C
  # ControlPersist 10m
```

`config.local` is included before the home-manager `Host *` block, so its values win.

### 1.4 Register and test

Add `~/.ssh/id_ed25519_sk_rk_access_<username>.pub` to the server's `~/.ssh/authorized_keys`,
then:

```sh
ssh <server>      # FIDO PIN, touch
```

Test locally without a server:

```sh
cd "$(mktemp -d)" && echo test > msg
ssh-keygen -Y sign -f ~/.ssh/id_ed25519_sk_rk_access_<username> -n test msg
echo "me $(cat ~/.ssh/id_ed25519_sk_rk_access_<username>.pub)" > signers
ssh-keygen -Y verify -f signers -I me -n test -s msg.sig < msg   # Good "test" signature
```

---

## Part 2: OpenPGP git key (PIN once per insertion, touch every use)

### 2.1 Start clean (optional)

If the OpenPGP applet has no keys you need, or a PIN is locked:

```sh
ykman openpgp reset   # erases OpenPGP only; FIDO2 is untouched
```

Defaults after reset: PIN `123456`, admin PIN `12345678`.

### 2.2 Change the PINs

```sh
ykman openpgp access change-pin          # user PIN (asked once per insertion)
ykman openpgp access change-admin-pin    # admin PIN (card management only)
```

> **Lockout:** 3 wrong user PINs lock it (the admin PIN can unblock:
> `ykman openpgp access unblock-pin`). 3 wrong admin PINs → `ykman openpgp reset`.
> When gpg prompts, read the title: **"Admin PIN"** vs plain **"PIN"**.

### 2.3 Generate ed25519 keys on the card

```sh
gpg --card-edit
```

```
admin
key-attr      # 3 times: (2) ECC → (1) Curve 25519   → ed25519 / cv25519 / ed25519
generate      # off-card backup: n (see 2.7) · expiry: 0 · name · email · O
quit
```

`key-attr` only sets the slot types; nothing exists until `generate`. Check:

```sh
gpg --card-status | grep -E 'Key attributes|Signature key|Authentication key|PIN retry'
```

All three slots should show fingerprints. Note the new primary key ID:

```sh
gpg -K --keyid-format 0xlong <email>    # the one with "sec>" and "Card serial no."
```

### 2.4 Require touch

```sh
ykman openpgp keys set-touch aut on
ykman openpgp keys set-touch sig on
```

### 2.5 Export the SSH public key

Export **by key ID**, not email: with more than one key for the same email, gpg picks the wrong
one.

```sh
gpg --export-ssh-key <KEY_ID> > ~/.ssh/id_gpg_git_<username>.pub
SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)" ssh-add -L \
  | grep -F "$(cut -d' ' -f2 ~/.ssh/id_gpg_git_<username>.pub)"     # must print one line
```

### 2.6 Register on GitHub

```sh
pbcopy < ~/.ssh/id_gpg_git_<username>.pub
```

At https://github.com/settings/ssh/new add it **twice**: once as **Authentication Key**, once as
**Signing Key**.

### 2.7 Git config

Signing helper `~/.config/git/gpg-ssh-keygen` (`chmod 755`):

```sh
#!/bin/sh
# git's gpg.ssh.program: sign through gpg-agent so the git key on the YubiKey's OpenPGP applet is
# used (PIN once per insertion, touch per signature). Plain ssh-keygen + gpgconf keeps it portable.
SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)" exec ssh-keygen "$@"
```

`~/.gitconfig`:

```ini
[user]
	name = <name>
	email = <email>
	signingkey = ~/.ssh/id_gpg_git_<username>.pub
[gpg]
	format = ssh
[gpg "ssh"]
	program = ~/.config/git/gpg-ssh-keygen
[commit]
	gpgsign = true
[tag]
	gpgsign = true
[core]
	excludesFile = ~/.config/git/ignore
	sshCommand = ssh -i ~/.ssh/id_gpg_git_<username>.pub -o IdentitiesOnly=yes -o IdentityAgent=\"$(gpgconf --list-dirs agent-ssh-socket)\"
[includeIf "gitdir:~/Projects/<org>/"]
	path = ~/.config/git/<org>
```

`sshCommand` goes through a shell, so `$(gpgconf ...)` resolves the socket on macOS and Linux.
`~` in `gpg.ssh.program` is expanded by recent git (verified on 2.55); on an old git use an
absolute path.
Per-organisation overrides (`~/.config/git/<org>`) can set their own `user.*`, `signingkey` and
`sshCommand`.

### 2.8 Test

```sh
ssh -i ~/.ssh/id_gpg_git_<username>.pub -o IdentitiesOnly=yes \
  -o IdentityAgent="$(gpgconf --list-dirs agent-ssh-socket)" -T git@github.com
# 1st run: pinentry PIN + touch → "Hi <username>!"   2nd run: touch only

cd "$(mktemp -d)" && git init -q && git commit --allow-empty -m "sign test" \
  && git cat-file -p HEAD | grep -c 'BEGIN SSH SIGNATURE'    # 1 = signed
```

### 2.9 What to back up

Keys generated on the card **cannot be exported or backed up**. If the YubiKey dies, a new one
gets new keys, registered on GitHub alongside the old ones. Keep the old *signing* key registered
on GitHub so past commits stay Verified.

Store offline (password manager / encrypted USB), then delete local copies of secrets:

| Item | How |
|---|---|
| Public key | `gpg --export --armor <KEY_ID> > pub.asc` |
| Revocation certificate | `~/.gnupg/openpgp-revocs.d/<FINGERPRINT>.rev` |
| Encryption key backup (only if you said yes in `generate`) | `~/.gnupg/sk_<ENC_KEY_ID>.gpg` → delete after copying |
| SSH public keys | `~/.ssh/id_gpg_git_<username>.pub`, `~/.ssh/id_ed25519_sk_rk_access_<username>.pub` |
| PINs | FIDO2 PIN, OpenPGP PIN, OpenPGP admin PIN |

If you need the **same** key on several YubiKeys, or a full backup (e.g. for encryption/`pass`),
generate the keys off-card instead — see [Alternative: off-card keys](#alternative-off-card-keys).

---

## Part 3: Clean up after replacing a key

```sh
ykman fido credentials list            # FIDO PIN
ykman fido credentials delete <id>     # remove ssh:* entries no longer used
```

Never delete website passkeys (`github.com`, `google.com`, …) unless you mean to.

- GitHub (https://github.com/settings/keys): delete old **authentication** keys; keep old
  **signing** keys. Compare fingerprints with `ssh-keygen -lf <file>.pub`.
- https://github.com/settings/security and other accounts: remove a lost/dead YubiKey under
  Security keys / Passkeys.
- `~/.ssh`: remove handle files of deleted keys.

---

## New machine

1. `home-manager switch` (PATH, gpg-agent, ssh base config).
2. Copy `~/.gitconfig`, `~/.config/git/*`, `~/.ssh/config.local`.
3. FIDO2 access key: `cd ~/.ssh && ssh-keygen -K` (PIN + touch), rename the exported file to
   `id_ed25519_sk_rk_access_<username>` if needed.
4. OpenPGP git key:

```sh
gpg --import pub.asc
gpg --card-status                              # links the card to the key
gpg --export-ssh-key <KEY_ID> > ~/.ssh/id_gpg_git_<username>.pub
```

No GitHub or server changes are needed: the public keys are the same.

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `ykman: No YubiKey detected` and `ioreg -p IOUSB -w0` shows nothing | Not enumerated at USB level: hub/dock/adapter or cable. Plug in directly. On Apple Silicon, also check System Settings → Privacy & Security → Allow accessories to connect. |
| `No FIDO SecurityKeyProvider specified` | Apple's `/usr/bin/ssh-keygen` ran. Fix PATH (`which ssh-keygen`), or open a new shell after `home-manager switch`. |
| `agent refused operation` with an `-sk` key | Key was loaded into an agent that can't prompt for the PIN. `ssh-add -d <key>.pub`; use `IdentityAgent none` + `AddKeysToAgent no` for that host. |
| `Credential Management requires having a PIN` | FIDO2 PIN not set: `ykman fido access change-pin`. |
| OpenPGP `PIN retry counter : 0 …` | User PIN locked. `ykman openpgp access unblock-pin` (admin PIN) or `ykman openpgp reset`. |
| Touching the key types `cccccc…` | Yubico OTP. Harmless (one-time). Disable if unused: `ykman config usb --disable OTP`. |
| PIN asked again while still plugged in | Sleep, `ykman`, or another smart-card app reset the card session. Expected. |
| `gpg --export-ssh-key <email>` exports the wrong key | Several keys share the email. Export by key ID. |

Inspect a FIDO SSH handle's flags (touch / PIN-every-use) without the key: the private handle
file stores them; `0x01` = touch, `0x04` = verify-required, `0x20` = resident.

---

## Alternative: off-card keys

Use this when you need a full backup, the same identity on several YubiKeys, or encryption that
must survive losing a card (e.g. `pass`). The private keys exist on a computer briefly, so use a
trusted, ideally offline, machine.

```sh
gpg --expert --full-generate-key                 # (11) ECC, Certify only, ed25519
gpg --expert --edit-key <KEY_ID>                 # addkey ×3: sign (ed25519), encrypt (cv25519),
                                                 # authenticate (ed25519); save
gpg --export-secret-keys --armor <KEY_ID> > master.asc      # offline backup
gpg --export-secret-subkeys --armor <KEY_ID> > subkeys.asc
gpg --gen-revoke --armor <KEY_ID> > revoke.asc

gpg --edit-key <KEY_ID>                          # key 1 → keytocard → (1); key 1
                                                 # key 2 → keytocard → (2); key 2
                                                 # key 3 → keytocard → (3); save
```

`keytocard` removes the local copy. For a second YubiKey: delete the stubs
(`gpg --delete-secret-keys <KEY_ID>`), `gpg --import subkeys.asc`, repeat `keytocard`. Switching
cards: `gpg-connect-agent "scd serialno" "learn --force" /bye`.

Then continue from [2.4](#24-require-touch).
