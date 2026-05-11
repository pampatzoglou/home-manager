# GitHub Actions — Kubernetes CI

See the shared `github-actions` skill for the core workflow structure (checkout + devbox + `devbox run task X`), security hardening, OIDC, matrix patterns, caching, and artifact upload. This file covers Kubernetes-specific CI conventions.

## Standard matrix

Services repos run lint, template, and audit on every PR — each as a matrix over environments:

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

If the repo uses a third-axis overlay (chain, region, tenant — see `conventions.md`), add it to the matrix:

```yaml
matrix:
  env: [dev, prod]
  chain: [variant1, variant2]

steps:
  - run: devbox run task template:${{ matrix.env }} CHAIN=${{ matrix.chain }}
```

Note: the `.argo/` diff check needs adjustment for overlay repos — rendered output will differ per overlay value, so either commit per-overlay output to separate dirs or skip the diff check on overlay dimensions.

## Canonical ci.yaml

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

Require all matrix job names as separate required checks:
- `lint (dev)`, `lint (prod)`
- `template (dev)`, `template (prod)`
- `audit (dev)`, `audit (prod)`
- `test`

## Common failures

| Failure | Cause |
|---|---|
| `task: command not found` | devbox install failed — check action version |
| `lint failed` on one chart | Missing required value in `defaults/values.yaml` |
| `.argo/ diff` fails | Chart changed without running `task template:<env>` before commit |
| `audit` fails with kubescape findings | Fix the manifest or add to `.kubescape/exceptions.json` with a `reason` |
| `test` passes locally, fails in CI | Missing devbox dependency or env var read at runtime |
