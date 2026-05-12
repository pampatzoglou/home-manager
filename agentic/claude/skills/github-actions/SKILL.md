---
name: github-actions
description: GitHub Actions CI that delegates all job logic to Taskfile via devbox. Covers the core checkout+devbox+task pattern, security hardening, OIDC auth, matrix strategies, environment protection, and workflow split (PR vs merge vs release).
user-invocable: true
---

# GitHub Actions

All CI workflows follow one principle: **the workflow handles infrastructure (checkout, auth, caching); tasks handle logic (`devbox run task X`)**. Workflows with inline commands are harder to reproduce locally, harder to test, and harder to maintain.

## Core pattern

Every job step that does project work:

```yaml
- uses: actions/checkout@v4
- uses: jetify-com/devbox-install-action@v0.13.0
  with:
    enable-cache: true    # caches Nix store — saves 60-120s per job
- run: devbox run task <task-name>
```

No `setup-helm`, `setup-terraform`, `setup-node` — devbox brings all pinned tools. See the `devbox` skill for package setup and the `taskfile` skill for task conventions.

## Standard workflow structure

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read          # minimum — don't grant write unless the job needs it

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true    # cancel older runs on the same ref

jobs:
  audit:
    name: Audit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: jetify-com/devbox-install-action@v0.13.0
        with:
          enable-cache: true
      - run: devbox run task audit
```

## Security hardening

| Practice | How |
|---|---|
| Minimal permissions | `permissions: contents: read` at workflow level; add only what individual jobs actually need |
| OIDC over long-lived tokens | `id-token: write` + cloud OIDC action; never store static credentials in secrets when OIDC is available |
| Pin action versions | Use `@v4` tags (or SHA pins for critical actions) — never `@latest` |
| No credential persistence | `persist-credentials: false` on `actions/checkout` when downstream steps don't need git push |
| No script injection | Never interpolate untrusted inputs (PR titles, branch names) into `run:` commands |
| Avoid `pull_request_target` | Has secret access but can checkout fork code — dangerous combination |
| Environment protection | Use GitHub Environments with required reviewers for production deploys |

OIDC example (AWS):
```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
      aws-region: us-east-1
```

## Matrix strategies

Use matrix for running the same job across environments, platforms, or named dimensions:

```yaml
strategy:
  fail-fast: false         # show all failures, not just the first
  matrix:
    env: [dev, prod]

steps:
  - run: devbox run task audit:${{ matrix.env }}
```

`fail-fast: false` is almost always correct — seeing all failures at once is more useful than stopping at the first.

## Caching

Devbox (Nix store) cache is handled by `enable-cache: true`. For language-level caches, add after the devbox step:

```yaml
# Go modules
- uses: actions/cache@v4
  with:
    path: ~/go/pkg/mod
    key: go-${{ runner.os }}-${{ hashFiles('**/go.sum') }}

# npm
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: node-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}

# Cargo
- uses: actions/cache@v4
  with:
    path: ~/.cargo
    key: cargo-${{ runner.os }}-${{ hashFiles('**/Cargo.lock') }}
```

## Workflow split: PR vs merge vs release

| Trigger | Workflow | Jobs |
|---|---|---|
| Pull request | `ci.yaml` | audit (+ plan for IaC) |
| Push to main | `ci.yaml` | apply/deploy (gated by environment) |
| Tag push | `release.yaml` | build + publish artifacts/images |

Keep release concerns out of the PR workflow — image pushes, package publishes, and environment deploys triggered by tags live in a separate `release.yaml`.

## Uploading artifacts

Upload scan/audit results even on failure so they're available for triage:

```yaml
- uses: actions/upload-artifact@v4
  if: always()
  with:
    name: audit-results
    path: audit-results/
    retention-days: 7
```

## Secrets and fork PRs

Fork PRs cannot access base repo secrets. Use `if: secrets.X != ''` to skip steps that need secrets:

```yaml
- name: Run integration tests
  if: secrets.API_KEY != ''
  run: devbox run task test:integration
  env:
    API_KEY: ${{ secrets.API_KEY }}
```

Document required secrets in the workflow file with setup instructions:

```yaml
# Required secrets:
# AWS_ROLE_ARN — IAM role ARN for OIDC federation
# Create via: gh secret set AWS_ROLE_ARN
```

## Concurrency: cancel vs serialize

`cancel-in-progress: true` — correct for PR checks. Cancel the old run when a new push arrives.

`cancel-in-progress: false` — correct for deploys. Never cancel an in-progress apply or deploy.

```yaml
# For deploy jobs:
concurrency:
  group: deploy-${{ matrix.env }}-${{ github.ref }}
  cancel-in-progress: false
```

## Common failure patterns

| Symptom | Cause |
|---|---|
| `task: command not found` | devbox install failed — check action version compatibility |
| `devbox run task X` hangs | Task waiting for stdin — add `--yes` or non-interactive flags |
| Cache miss every run | Cache key changes each run — check that lockfiles aren't being modified before the cache step |
| Fork PRs skip steps | Expected — forks can't access base secrets; guard with `if: secrets.X != ''` |
| Job slow on first run | Cold Nix store — subsequent runs hit the cache |

## Kubernetes CI

For repos that deploy Helm charts, the CI workflow runs lint, template, and audit as a matrix over environments.

### Standard matrix

```yaml
strategy:
  fail-fast: false    # see all environment failures at once
  matrix:
    env: [dev, prod]
```

### .argo/ diff check

ArgoCD reads from `.argo/<env>/` — if the rendered output isn't committed, what's running in the cluster differs from what's in git. Add after `task template:<env>`:

```yaml
- name: Verify rendered output is committed
  run: |
    if ! git diff --quiet .argo/${{ matrix.env }}/; then
      echo "::error::Rendered output in .argo/${{ matrix.env }}/ differs from committed version."
      echo "Run 'task template:${{ matrix.env }}' locally and commit the result."
      git diff --stat .argo/${{ matrix.env }}/
      exit 1
    fi
```

### Third-axis matrix (when applicable)

If the repo uses a third-axis overlay (chain, region, tenant), add it to the matrix:

```yaml
matrix:
  env: [dev, prod]
  chain: [variant1, variant2]

steps:
  - run: devbox run task template:${{ matrix.env }} CHAIN=${{ matrix.chain }}
```

### Canonical Kubernetes ci.yaml

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
      - run: devbox run task lint:${{ matrix.env }}

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
      - run: devbox run task template:${{ matrix.env }}
      - name: Verify rendered output is committed
        run: |
          if ! git diff --quiet .argo/${{ matrix.env }}/; then
            echo "::error::Rendered output in .argo/${{ matrix.env }}/ differs."
            echo "Run 'task template:${{ matrix.env }}' and commit."
            git diff --stat .argo/${{ matrix.env }}/
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
      - run: devbox run task audit:${{ matrix.env }}

  test:
    name: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: jetify-com/devbox-install-action@v0.13.0
        with:
          enable-cache: true
      - run: devbox run task test
```

### Branch protection

Require all matrix job names as separate required checks: `lint (dev)`, `lint (prod)`, `template (dev)`, `template (prod)`, `audit (dev)`, `audit (prod)`, `test`.

### Common Kubernetes CI failures

| Failure | Cause |
|---|---|
| `lint failed` on one chart | Missing required value in `defaults/values.yaml` |
| `.argo/ diff` fails | Chart changed without running `task template:<env>` before commit |
| `audit` fails with kubescape findings | Fix the manifest or add to `.kubescape/exceptions.json` with a `reason` |

## Companion skills — offer after completing

When the CI workflow is done, check the repo and offer whichever of these are missing or incomplete:

| Skill | Offer when |
|-------|-----------|
| `devbox` | No `devbox.json` in the repo root — CI assumes devbox, so this is a blocker if missing |
| `taskfile` | No `Taskfile.yaml` / `Taskfile.yml` in the repo root — CI calls tasks, so this is a blocker if missing |
| `document` | No `docs/ARCHITECTURE.md`, or existing README doesn't describe the CI/CD pipeline |

Ask as a single grouped question — not mid-task, not separately for each.
