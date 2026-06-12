# GitHub Actions — Kubernetes CI

Companion to `SKILL.md` (foundations: core pattern, security, matrix, caching). This file covers **PR-time** CI for repos that deploy Helm charts — lint, template, and audit run as a matrix over environments. For the **merge-time** deploy half (promoting image tags into a GitOps repo) see `cross-repo-promotion.md`.

## Standard matrix

```yaml
strategy:
  fail-fast: false    # see all environment failures at once
  matrix:
    env: [dev, prod]
```

## .argo/ diff check

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

## Third-axis matrix (when applicable)

If the repo uses a third-axis overlay (chain, region, tenant), add it to the matrix:

```yaml
matrix:
  env: [dev, prod]
  chain: [variant1, variant2]

steps:
  - run: devbox run task template:${{ matrix.env }} CHAIN=${{ matrix.chain }}
```

## Canonical Kubernetes ci.yaml

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

## Branch protection

Require all matrix job names as separate required checks: `lint (dev)`, `lint (prod)`, `template (dev)`, `template (prod)`, `audit (dev)`, `audit (prod)`, `test`.

## Common Kubernetes CI failures

| Failure | Cause |
|---|---|
| `lint failed` on one chart | Missing required value in `defaults/values.yaml` |
| `.argo/ diff` fails | Chart changed without running `task template:<env>` before commit |
| `audit` fails with kubescape findings | Fix the manifest or add to `.kubescape/exceptions.json` with a `reason` |
