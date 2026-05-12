---
name: devbox
description: Reproducible developer environments via pinned Nix packages. Covers .envrc setup with direnv, devbox.json structure, pinning strategy, and CI integration via devbox-install-action.
user-invocable: true
---

# Devbox

Devbox pins CLI tool versions via Nix so every developer and CI run gets the exact same environment. It is the single source of truth for tool versions — not GitHub Actions setup steps, not global installs, not brew.

## .envrc — the project entry point

Every project using devbox gets this `.envrc` at the root:

```bash
eval "$(devbox generate direnv --print-envrc)"
```

Commit it. Each developer runs `direnv allow` once; from then on `cd`-ing into the project activates the environment automatically, `cd`-ing out deactivates it.

**Why this form** over `use devbox`: `devbox generate direnv --print-envrc` renders the activation script inline and works without a separate direnv devbox plugin. It is more portable and more explicit about what's happening.

## devbox.json structure

```json
{
  "$schema": "https://raw.githubusercontent.com/jetify-com/devbox/main/.schema/devbox.schema.json",
  "packages": [
    "go-task@3.40",
    "jq@1.7",
    "yq-go@4.45"
  ],
  "shell": {
    "init_hook": [],
    "scripts": {}
  }
}
```

`shell.scripts` are shortcuts runnable via `devbox run <name>` — useful for multi-step setup commands that don't belong in the Taskfile (e.g., cluster lifecycle management).

**Commit both `devbox.json` and `devbox.lock`.** The lockfile captures the exact resolved Nix store path; without it the same `devbox.json` can resolve to different package versions on different days.

## Pinning strategy

Use major-or-minor constraints, not exact patch versions:

- ✅ `helm@3.16` — flexible on patch, locked on minor
- ❌ `helm@3.16.4` — over-pinned; breaks when Nix removes that exact revision

`devbox.lock` provides the actual reproducibility — `devbox.json` is the constraint, the lockfile is the truth.

## Common packages by domain

| Domain | Packages |
|---|---|
| Always | `go-task`, `jq`, `yq-go` |
| Kubernetes | `helm`, `kubectl`, `kind`, `skaffold`, `kubeconform`, `kubescape` |
| Terraform | `terraform`, `tflint`, `tfsec`, `terraform-docs` |
| Go | `go` |
| Python | `python311`, `uv` |
| Node | `nodejs_22` |
| Rust | `rustup` |
| Containers | `hadolint`, `trivy` |
| Cloud CLIs | `awscli2`, `google-cloud-sdk` |

Don't add packages the project doesn't use — each is a download and PATH entry. A bloated shell is slow to enter and obscures actual dependencies.

## Common usage

```bash
devbox shell                  # enter pinned-tools shell
devbox run task lint          # run one command without entering the shell
devbox update                 # update all to latest within pinned constraints
devbox add <package>          # add a package and update devbox.lock
devbox info                   # show installed packages and versions
devbox doctor                 # diagnose environment issues (missing Nix, broken PATH, direnv not hooked)
```

## CI integration

```yaml
- uses: jetify-com/devbox-install-action@v0.13.0
  with:
    enable-cache: true    # caches Nix store — saves 60-120s per job
```

Then invoke tasks with `devbox run task <name>`. See the `github-actions` skill for the full workflow structure.

## Gotchas

- **`yq` vs `yq-go`**: `yq` in nixpkgs is a Python/xq wrapper; `yq-go` is Mike Farah's Go implementation that most platform tooling expects. Always pin `yq-go`.
- **Not a container.** Devbox uses the host kernel — OS-level differences (macOS vs Linux glibc) can still matter for system-call-heavy tools.
- **Language dependency versions** (npm packages, go modules, cargo crates) are the language's own lockfile's job. Devbox pins the toolchain, not project deps.

## Kubernetes tooling

When the project deploys to Kubernetes, pin these additional packages:

```json
{
  "packages": [
    "go-task@3.40",
    "helm@3.16",
    "kubectl@1.33",
    "kind@0.27",
    "skaffold@2.16",
    "kubeconform@0.7",
    "kubescape@3",
    "yq-go@4.45",
    "jq@1.7"
  ]
}
```

Versions are illustrative — pick the latest stable at repo creation, then update deliberately via `devbox update`.

### Cluster lifecycle scripts

Add kind cluster management to `devbox.json` `shell.scripts`:

```json
"shell": {
  "init_hook": [
    "echo \"devbox ready — helm $(helm version --short 2>/dev/null), kubectl $(kubectl version --client --short 2>/dev/null | head -1)\""
  ],
  "scripts": {
    "cluster:up":    "kind create cluster --name dev --config kind.yaml",
    "cluster:down":  "kind delete cluster --name dev",
    "cluster:reset": "devbox run cluster:down && devbox run cluster:up"
  }
}
```

Usage:
```bash
devbox run cluster:up     # create the kind cluster (once per machine)
devbox run cluster:reset  # tear down and recreate
```

## When devbox isn't right

| Need | Use instead |
|---|---|
| Strict OS/glibc isolation | Dev container or VM |
| Long-running services in dev (postgres, kafka) | Run in local cluster via skaffold/helm |
| Project dependency pinning | Language lockfiles (`go.sum`, `Cargo.lock`, `package-lock.json`) |

## Companion skills — offer after completing

When devbox setup is done, check the repo and offer whichever of these are missing or incomplete:

| Skill | Offer when |
|-------|-----------|
| `taskfile` | No `Taskfile.yaml` / `Taskfile.yml` in the repo root |
| `github-actions` | No `.github/workflows/` directory, or existing workflows don't use `devbox-install-action` |
| `document` | No `docs/ARCHITECTURE.md` or README doesn't mention devbox in the quick start |

Ask as a single grouped question — not mid-task, not separately for each.
