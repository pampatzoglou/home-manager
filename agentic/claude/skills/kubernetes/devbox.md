# Devbox (services repo, tool pinning)

This file documents how `devbox.json` pins developer tooling versions in services repos. Read this when:

- The user is creating a new services repo and needs a working `devbox.json`
- The user is adding or updating a CLI tool (helm, kubectl, skaffold, kind, etc.)
- A `devbox shell` is failing or producing unexpected versions

## What it's for

Devbox provides a reproducible developer environment by pinning Nix packages. Every developer who runs `devbox shell` gets the exact same versions of the tools the project needs — no "works on my machine" because someone has helm 3.14 and another has 3.16.

It's the local-dev counterpart to a CI image: same tool versions, no global installs, no sudo.

## Mental model

```
devbox.json    → pins package versions
.envrc         → integrates devbox into direnv (auto-activate on cd)
devbox shell   → opens a sub-shell with all pinned tools on PATH
devbox run X   → runs command X inside that environment
```

A team member clones the repo, runs `direnv allow` once (or `devbox shell` manually), and has the same tools as everyone else.

## Canonical devbox.json

```json
{
  "$schema": "https://raw.githubusercontent.com/jetify-com/devbox/main/.schema/devbox.schema.json",
  "packages": [
    "helm@3.16",
    "kubectl@1.33",
    "kind@0.27",
    "skaffold@2.16",
    "go-task@3.40",
    "kubeconform@0.7",
    "yq-go@4.45",
    "jq@1.7"
  ],
  "shell": {
    "init_hook": [
      "echo \"📦 devbox shell ready — tools: helm $(helm version --short), kubectl $(kubectl version --client --short 2>/dev/null | head -1)\""
    ],
    "scripts": {
      "cluster:up": "kind create cluster --name dev --config kind.yaml",
      "cluster:down": "kind delete cluster --name dev",
      "cluster:reset": "devbox run cluster:down && devbox run cluster:up"
    }
  }
}
```

Versions in the example are illustrative — pick the latest stable at the time of repo creation, then update deliberately.

## What to pin

The project should pin:

- **`helm`** — chart rendering, must match what CI uses
- **`kubectl`** — should match the cluster's kube-version (`task template` uses this)
- **`kind`** — local cluster (skaffold target)
- **`skaffold`** — local dev loop
- **`go-task`** — `task` binary; without it the Taskfile is dead
- **`kubeconform`** — validation in CI and locally
- **`yq-go`** — manipulating YAML without writing python; note this is `yq-go`, not `yq` (which is the Python package)
- **`jq`** — same for JSON

Optionally, language toolchains (`go`, `nodejs`, `python3`, `rustup`) when the repo's app code lives alongside the deployment manifests — devbox can be the single source of truth for both.

## Companion `.envrc`

For automatic activation when entering the directory (requires `direnv`):

```bash
# .envrc
use devbox
```

After committing this file, each developer runs `direnv allow` once. From then on, `cd`-ing into the repo activates the devbox environment automatically and `cd`-ing out deactivates it.

## Common usage

```bash
# Enter the pinned-tools shell
devbox shell

# Run one command without entering the shell
devbox run task template ENV=dev

# Update all packages to latest within their pinned major versions
devbox update

# Add a new package
devbox add <package>

# See what's installed and where
devbox info
```

## Pinning strategy

**Use major-or-minor pins, not exact versions.** `helm@3.16` is right; `helm@3.16.4` is over-pinning that will break the moment Nix removes that exact rev. Devbox's `devbox.lock` captures the exact resolved version for reproducibility — the `devbox.json` is the constraint, the lockfile is the truth.

Commit both `devbox.json` and `devbox.lock`. Without the lockfile, "the same `devbox.json`" can resolve to different versions on different days.

## Gotchas

- **`yq` vs `yq-go`**: `yq` in nixpkgs is the Python wrapper around `xq` and behaves differently. `yq-go` is Mike Farah's Go implementation that most platform tooling expects. Always pin `yq-go`.
- **Some tools have aliases that move.** `kubectl@latest` resolves at install time and won't update unless you run `devbox update`. Pin explicitly.
- **Don't add packages the project doesn't use.** Each package is a download and a PATH entry. A bloated devbox shell takes 30+ seconds to enter and obscures actual dependencies.
- **devbox is not a container.** It uses your host's kernel and (by default) your host's `~/.kube/config`, `~/.docker/`, `~/.cache`, etc. That's intentional — it's lighter weight than a dev container — but it means host-level differences (OS, glibc) can still matter.

## When devbox isn't the right tool

If the user needs:
- **Strict isolation** (different glibc, network namespace, CI parity beyond just CLI versions) → that's a dev container or VM, not devbox
- **A long-running service in dev** (postgres, kafka) → run it in the kind cluster via skaffold/helm, not as a devbox-managed binary
- **Pinning npm/cargo/go module versions** → that's the language's own lockfile (`package-lock.json`, `Cargo.lock`, `go.sum`); devbox pins the toolchain, not project deps

Devbox's job is the binaries on your PATH, nothing more.
