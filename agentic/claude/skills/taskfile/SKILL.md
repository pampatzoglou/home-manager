---
name: taskfile
description: Standard Taskfile conventions across all projects. Covers the core principle (CI calls tasks not inline commands), standard task naming, variables pattern, and CI integration via devbox.
user-invocable: true
---

# Taskfile

All project automation lives in `Taskfile.yaml` (go-task). CI, local dev, and scripts call the same task commands — no divergence between "how it runs locally" and "how CI runs it."

## Core principle

CI must call project tasks, not contain inline command logic:

```yaml
# BAD — logic lives in CI, can't reproduce locally the same way
- run: helm lint ./charts && kubescape scan framework nsa .argo/

# GOOD — CI delegates to project automation
- run: devbox run task audit ENV=dev
```

Benefits: local/CI parity, portability across CI platforms, single source of truth for how things run.

## Standard task names

Use these names consistently so developers don't re-learn per repo:

| Task | Purpose |
|---|---|
| `default` | `task --list` — show available tasks |
| `fmt` | Format source files |
| `validate` | Validate syntax/schema |
| `lint` | Static analysis (after fmt + validate) |
| `test` | Run tests |
| `build` | Build artifacts |
| `scan` | Security scan |
| `audit` | Full pre-merge gate: fmt → validate → lint → scan |
| `clean` | Remove generated artifacts |
| `docs` | Regenerate documentation |

Domain-specific tasks extend this set (e.g., `template`/`plan`/`apply` for Helm and Terraform).

## Environment task naming convention

Tasks with environment variants follow **`action:env`** ordering — action first, environment as a suffix. The bare action (no suffix) iterates all known environments sequentially:

```bash
task plan         # iterate all environments: dev → staging → prod
task plan:dev     # dev only
task plan:prod    # prod only
```

Implementation pattern — the bare task calls each env variant in order:

```yaml
tasks:
  plan:
    desc: Plan all environments
    cmds:
      - task: plan:dev
      - task: plan:staging
      - task: plan:prod

  plan:dev:
    desc: Plan dev
    cmds:
      - task: _plan
        vars: { ENV: dev }

  plan:staging:
    desc: Plan staging
    cmds:
      - task: _plan
        vars: { ENV: staging }

  plan:prod:
    desc: Plan production
    cmds:
      - task: _plan
        vars: { ENV: prod }

  _plan:
    internal: true
    cmds:
      - <do the work for {{.ENV}}>
```

**Destructive actions (`apply`, `destroy`) do not get a bare all-envs variant** — requiring an explicit `task apply:dev` prevents accidental multi-environment mutations.

`task --list` groups naturally by action, and tab-completion on `task plan:<TAB>` discovers available environments.

## Variables pattern

Additional dimensions (e.g., chart name, region) stay as `KEY=VALUE` variables alongside the `action:env` suffix:

```bash
task template:dev                          # all charts, dev
task template:dev CHART_NAME=api           # one chart, dev
task template:prod CHART_NAME=api          # one chart, prod
```

Declare variables with defaults at the top of each task:

```yaml
tasks:
  template:dev:
    vars:
      CHART_NAME: '{{.CHART_NAME | default ""}}'
    cmds:
      - task: _template
        vars: { ENV: dev, CHART_NAME: "{{.CHART_NAME}}" }
```

## Canonical Taskfile skeleton

```yaml
version: "3"

tasks:
  default:
    desc: List available tasks
    cmds:
      - task --list

  fmt:
    desc: Format all source files
    cmds:
      - <formatter>

  validate:
    desc: Validate configuration syntax
    deps: [fmt]
    cmds:
      - <validator>

  lint:
    desc: Run static analysis
    deps: [fmt, validate]
    cmds:
      - <linter>

  test:
    desc: Run tests
    cmds:
      - <test-runner>

  scan:
    desc: Security scan
    cmds:
      - <scanner>

  audit:
    desc: Full pre-merge check — fmt, validate, lint, scan
    cmds:
      - task: fmt
      - task: validate
      - task: lint
      - task: scan

  clean:
    desc: Remove generated artifacts
    cmds:
      - rm -rf <output-dirs>
```

## Task dependencies

`deps:` runs tasks in parallel before the current task's `cmds`. Explicit `task:` calls within `cmds` run sequentially:

```yaml
audit:
  cmds:
    - task: fmt         # sequential — each waits for the previous
    - task: validate
    - task: lint
    - task: scan
```

Use `deps:` when order doesn't matter and parallel execution is safe. Use sequential `task:` calls when ordering is required.

## CI integration

```yaml
- uses: jetify-com/devbox-install-action@v0.13.0
  with:
    enable-cache: true
- run: devbox run task audit
```

See the `github-actions` skill for the full workflow structure.

## Destructive tasks — always use `prompt:`

go-task's `prompt:` field blocks execution until the user confirms. Required on any task that deletes data, applies infrastructure changes, or is hard to reverse:

```yaml
tasks:
  destroy:prod:
    desc: Destroy production infrastructure
    prompt: Destroy ALL resources in prod. Are you absolutely sure?
    cmds:
      - task: _destroy
        vars: { ENV: prod }

  db:drop:
    desc: Drop and recreate the local database
    prompt: This will delete all local data. Continue?
    cmds:
      - psql -c "DROP DATABASE IF EXISTS myapp_dev"
      - psql -c "CREATE DATABASE myapp_dev"
```

`prompt:` fires even when called as a dependency of another task. Bare all-envs variants of destructive actions must not exist — require an explicit `task destroy:prod`, never `task destroy`.

## What not to add

- **Per-environment task names** (`lint-dev:`, `lint-prod:`) — use variables for targeting.
- **Inline logic that belongs in the build system** — if `npm build` exists, call it; don't rewrite it in shell.
- **Destructive tasks without `prompt:`** — see above.

## Companion skills — offer after completing

When Taskfile setup is done, check the repo and offer whichever of these are missing or incomplete:

| Skill | Offer when |
|-------|-----------|
| `devbox` | No `devbox.json` in the repo root — tasks won't have pinned tools without it |
| `github-actions` | No `.github/workflows/` directory, or existing workflows don't call tasks |
| `document` | No `docs/ARCHITECTURE.md` or README doesn't document the available tasks |

Ask as a single grouped question — not mid-task, not separately for each.
