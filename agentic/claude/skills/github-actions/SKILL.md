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

This file covers the generic foundations. For Kubernetes/ArgoCD delivery, two reference files go deeper: `kubernetes-ci.md` (PR-time lint/template/audit) and `cross-repo-promotion.md` (merge-time image-tag promotion into the GitOps repo).

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
| Pin actions to a commit SHA | Pin **every** `uses:` to a full-length commit SHA — never a tag or branch. Tags are mutable and re-pointable (the `tj-actions/changed-files` 2025 supply-chain attack). Keep the version in a trailing comment; let Dependabot/Renovate bump it. See **Pinning actions to digests** below. |
| No credential persistence | `persist-credentials: false` on `actions/checkout` when downstream steps don't need git push |
| No script injection | Never interpolate untrusted inputs (PR titles, branch names) into `run:` commands |
| Avoid `pull_request_target` | Has secret access but can checkout fork code — dangerous combination |
| Environment protection | Use GitHub Environments with required reviewers for production deploys |
| Cross-repo writes | Mint a scoped GitHub App token (`actions/create-github-app-token`) for git/PR ops against another repo — never store a long-lived PAT |

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

## Pinning actions to digests

Tags (`@v4`, `@v4.2.2`) and branches (`@main`) are **mutable** — whoever controls the action's repo can move them to point at new code. A leaked maintainer token or a poisoned tag re-point then runs arbitrary code in your pipeline with your secrets and `GITHUB_TOKEN`. This is not hypothetical: the March 2025 `tj-actions/changed-files` compromise retroactively altered tags and leaked secrets from thousands of workflows. A full-length commit SHA is immutable — it pins the exact tree you reviewed.

```yaml
# ✅ pinned to a digest; version in a trailing comment for readability + Dependabot
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
- uses: jetify-com/devbox-install-action@<full-40-char-commit-sha> # v0.13.0

# ❌ mutable — never in real workflows
- uses: actions/checkout@v4
- uses: actions/checkout@main
```

Rules:
- Pin **every** `uses:` to a 40-character commit SHA — first-party `actions/*` included. "Trusted org" is not the same as "immutable ref".
- Keep the human-readable version in a trailing `# vX.Y.Z` comment so the pin stays reviewable and bumpable.
- Pin Docker-based actions by digest too: `uses: docker://image@sha256:...`.
- **Automate the bumps** so SHA-pinning doesn't mean stale actions — Dependabot or Renovate updates both the SHA and the comment.

Resolve a tag to its SHA, or convert a whole repo in bulk:
```sh
gh api repos/actions/checkout/commits/v4.2.2 --jq .sha   # one action
pinact run          # or: ratchet pin — rewrites every tag in .github/workflows to a SHA
```

Dependabot keeps them current:
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
```

> The `@vX` tags shown elsewhere in this skill and its companion files (`kubernetes-ci.md`, `cross-repo-promotion.md`) are written that way for readability — real workflows must SHA-pin as above.

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

## Kubernetes CI/CD — reference files

For Helm/ArgoCD repos the pipeline splits across two companion files; read the one that matches the task:

| File | Covers | When |
|---|---|---|
| `kubernetes-ci.md` | lint/template/audit matrix over environments, the `.argo/` committed-output diff, canonical `ci.yaml`, branch protection | PR-time checks |
| `cross-repo-promotion.md` | promoting the built image tag into the separate GitOps repo via a scoped GitHub App token and an auto-merged PR | merge-time deploy |

## Companion skills — offer after completing

When the CI workflow is done, check the repo and offer whichever of these are missing or incomplete:

| Skill | Offer when |
|-------|-----------|
| `devbox` | No `devbox.json` in the repo root — CI assumes devbox, so this is a blocker if missing |
| `taskfile` | No `Taskfile.yaml` / `Taskfile.yml` in the repo root — CI calls tasks, so this is a blocker if missing |
| `document` | No `docs/ARCHITECTURE.md`, or existing README doesn't describe the CI/CD pipeline |

Ask as a single grouped question — not mid-task, not separately for each.
