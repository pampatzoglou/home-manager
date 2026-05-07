# GitHub Actions (services repo CI)

This file documents the CI workflows for services repos. Read this when:

- The user is creating a new services repo and needs CI set up
- The user is updating, debugging, or extending an existing workflow
- A PR is failing CI and Claude needs to understand what the workflow expects

## What CI does (and doesn't)

A services repo's CI runs four things on every PR:

1. **Lint** every chart with `helm lint` (matrix per env)
2. **Render** every chart with `helm template` (matrix per env)
3. **Audit** the rendered manifests with kubescape (matrix per env)
4. **Test** the application source under `src/` with the language's test runner

CI does **not** deploy. Deployments happen via ArgoCD off `main` after merge — there's no `kubectl apply` step in CI, and a green CI run is not the same thing as a successful deploy.

## Mental model

```
PR opened/updated
  ├── lint-charts (matrix: env=dev,prod)        [task lint ENV=…]
  ├── template-charts (matrix: env=dev,prod)    [task template ENV=…]
  ├── audit-charts (matrix: env=dev,prod)       [task audit ENV=…]    ← kubescape
  └── test (mixed runner per repo's language)   [task test or repo-specific]
```

All four run in parallel. Each runs in a `devbox shell` so tool versions match local dev (see `devbox.md`).

## Canonical workflow file

`.github/workflows/ci.yaml`:

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint-charts:
    name: lint (${{ matrix.env }})
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        env: [dev, prod]
    steps:
      - uses: actions/checkout@v4
      - uses: jetify-com/devbox-install-action@v0.13.0
        with:
          enable-cache: true
      - name: Lint charts
        run: devbox run task lint ENV=${{ matrix.env }}

  template-charts:
    name: template (${{ matrix.env }})
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        env: [dev, prod]
    steps:
      - uses: actions/checkout@v4
      - uses: jetify-com/devbox-install-action@v0.13.0
        with:
          enable-cache: true
      - name: Template charts
        run: devbox run task template ENV=${{ matrix.env }}
      - name: Verify rendered output is committed
        run: |
          if ! git diff --quiet .argo/; then
            echo "::error::Rendered output in .argo/ differs from committed version."
            echo "Run 'task template ENV=${{ matrix.env }}' locally and commit the result."
            git diff --stat .argo/
            exit 1
          fi

  audit-charts:
    name: audit (${{ matrix.env }})
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        env: [dev, prod]
    steps:
      - uses: actions/checkout@v4
      - uses: jetify-com/devbox-install-action@v0.13.0
        with:
          enable-cache: true
      - name: Audit rendered manifests
        run: devbox run task audit ENV=${{ matrix.env }}

  test:
    name: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: jetify-com/devbox-install-action@v0.13.0
        with:
          enable-cache: true
      - name: Run unit tests
        run: devbox run task test
```

## Conventions baked into this workflow

- **`devbox` is the single source of truth for tool versions.** No `setup-helm`, `setup-kubectl`, etc. — devbox brings them. This guarantees CI uses the same versions as local dev.
- **Matrix uses `env: [dev, prod]`.** No `testing` env. Add one only if the repo introduces a new cluster.
- **`fail-fast: false`** so devs see all environment failures at once instead of fixing one and then learning about the other.
- **`cancel-in-progress: true`** on the concurrency group — pushing twice cancels the older run.
- **`permissions: contents: read`** — minimum needed. Don't grant `write` unless the workflow does something that requires it (release tagging, PR comments).
- **The `.argo/` diff check** ensures rendered output is committed. ArgoCD reads from `.argo/`, so an out-of-date render means dev and prod are running different config than what's in the chart.

## Handling a third-axis matrix (when the repo has one)

The default matrix is `env: [dev, prod]`. If the Taskfile defines a third-axis overlay (per-region, per-tenant, per-chain — see "Optional extensions" in `taskfile.md`), add the same axis to the matrix:

```yaml
template-charts:
  strategy:
    fail-fast: false
    matrix:
      env: [dev, prod]
      region: [us, eu]      # whatever the team's third axis is named
  steps:
    - uses: actions/checkout@v4
    - uses: jetify-com/devbox-install-action@v0.13.0
    - run: devbox run task template ENV=${{ matrix.env }} REGION=${{ matrix.region }}
```

Skip the `.argo/` diff check on overlay matrix entries if the overlay produces different rendered output per overlay value — otherwise every PR fails on overlays it didn't touch. Either commit per-overlay rendered output to separate dirs, or only diff-check the no-overlay render.

If the repo doesn't have a third axis, skip this section entirely — `env: [dev, prod]` is the whole matrix.

## Test step variations

Repos vary by language. Pick whichever applies and put the actual command behind `task test` so the workflow file doesn't need to change per repo:

```bash
# Go
task test:        go test ./...

# Node/TypeScript
task test:        npm test

# Python
task test:        pytest

# Rust
task test:        cargo test
```

If a repo has multiple test stages (unit, integration, e2e), break them into multiple jobs. Don't pile them all into `task test` — losing the ability to see which stage failed at a glance is a false economy.

## Caching

`devbox-install-action` with `enable-cache: true` caches the resolved Nix store, which dominates cold-start time. Without it, expect each job to spend 60–120s installing tools.

For language-level caching (Go modules, npm, cargo), add the appropriate `actions/cache` step after the devbox setup:

```yaml
# Go example
- uses: actions/cache@v4
  with:
    path: ~/go/pkg/mod
    key: go-${{ runner.os }}-${{ hashFiles('**/go.sum') }}
```

## Common failures and what they mean

| Failure | Likely cause |
|---|---|
| `task: command not found` | devbox didn't install successfully — check the install-action version compatibility |
| `lint failed` on one chart only | values precedence issue — usually a missing required value in `defaults/values.yaml` |
| `template failed` with "no template" | typo in template path, or a `{{- if … }}` block guarding the entire resource |
| `.argo/ diff` check fails | someone edited the chart but didn't run `task template ENV=… ` locally before committing |
| `audit` fails with kubescape findings | a control violation at or above the configured severity threshold — fix the underlying manifest, or add to `.kubescape/exceptions.json` with a written reason |
| `test` passes locally but fails in CI | environment difference — usually missing devbox dependency, or an env var read at runtime |

## Security scanning details

The `audit-charts` job runs `task audit ENV=<env>`, which renders charts and then runs `kubescape scan` on the output. Behavior:

- **Default framework** is `nsa` (configured in the Taskfile). Switch to `mitre` or `allcontrols` only if the team has explicitly agreed — they're noisier.
- **Default fail threshold** is `high`. Findings at `high` or `critical` fail the job; lower severities are reported but don't block.
- **Exceptions** live in `.kubescape/exceptions.json` at the repo root. Every entry must include a `reason` field — entries without rationale should fail review. The file is loaded automatically when present.
- **Future scanners** (trivy, kube-linter, polaris) drop into `task audit` next to kubescape — the job and CI step don't change. Add them to the Taskfile's `audit` task, not as separate jobs, unless the team specifically wants per-tool reporting.

When kubescape flags a finding that's a known and accepted exception (e.g., a workload that needs a specific capability), the right fix is a `.kubescape/exceptions.json` entry with a written reason, not loosening the framework or threshold globally.

## Branch protection

Recommended `main` branch protection:
- Require `lint-charts (dev)`, `lint-charts (prod)`, `template-charts (dev)`, `template-charts (prod)`, `audit-charts (dev)`, `audit-charts (prod)`, `test` to pass
- Require branches to be up-to-date before merging
- Dismiss stale reviews on new commits

The matrix names show up as separate required checks — pick all of them, not just the parent job.

## When CI isn't the right place

If the user wants CI to:
- **Deploy on merge** → that's ArgoCD, not GitHub Actions. The workflow's job ends at "the rendered output is correct and committed."
- **Run integration tests against a real cluster** → consider a separate workflow gated on a label, since it's slow and flaky compared to unit tests
- **Push container images** → that's typically a separate `release.yaml` workflow triggered on tag, not the per-PR `ci.yaml`
