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

## Helm chart tasks

For repos that deploy Helm charts, add `template`, `lint`, and `audit` tasks following the `action:env` naming convention.

### Core variables

| Variable | Effect |
|---|---|
| `CHART_NAME=foo` | Process only `deploy/charts/foo`, not all charts. |

### Task naming

```bash
task template         # iterate all environments: dev → prod
task template:dev     # dev only
task template:prod    # prod only
task lint             # lint for all environments
task lint:dev         # dev only
task audit            # audit for all environments
task audit:dev        # dev only
```

### Output directories

Rendered output is split by environment to support committing both:

```
.argo/
├── dev/
│   └── <chart>/      # output of task template:dev
└── prod/
    └── <chart>/      # output of task template:prod
```

ArgoCD reads from these paths; committing the rendered output is intentional.

### Canonical Helm Taskfile.yaml

```yaml
version: "3"

vars:
  CHARTS_DIR: deploy/charts
  OUTPUT_DIR: .argo
  KUBESCAPE_FRAMEWORK: nsa
  KUBESCAPE_FAIL_THRESHOLD: high

tasks:
  default:
    desc: List available tasks
    cmds:
      - task --list

  # ── Template ─────────────────────────────────────────────────────────────

  template:
    desc: Template all charts for all environments (dev → prod)
    cmds:
      - task: template:dev
      - task: template:prod

  template:dev:
    desc: Template all charts for dev
    vars:
      CHART_NAME: '{{.CHART_NAME | default ""}}'
    cmds:
      - task: _template
        vars: { ENV: dev, CHART_NAME: "{{.CHART_NAME}}" }

  template:prod:
    desc: Template all charts for prod
    vars:
      CHART_NAME: '{{.CHART_NAME | default ""}}'
    cmds:
      - task: _template
        vars: { ENV: prod, CHART_NAME: "{{.CHART_NAME}}" }

  _template:
    internal: true
    vars:
      ENV: '{{.ENV}}'
      CHART_NAME: '{{.CHART_NAME | default ""}}'
    cmds:
      - task: clean
        vars: { ENV: "{{.ENV}}" }
      - task: _process-charts
        vars:
          ENV: "{{.ENV}}"
          CHART_NAME: "{{.CHART_NAME}}"
          MODE: template

  # ── Lint ─────────────────────────────────────────────────────────────────

  lint:
    desc: Lint all charts for all environments (dev → prod)
    cmds:
      - task: lint:dev
      - task: lint:prod

  lint:dev:
    desc: Lint all charts for dev
    vars:
      CHART_NAME: '{{.CHART_NAME | default ""}}'
    cmds:
      - task: _process-charts
        vars: { ENV: dev, CHART_NAME: "{{.CHART_NAME}}", MODE: lint }

  lint:prod:
    desc: Lint all charts for prod
    vars:
      CHART_NAME: '{{.CHART_NAME | default ""}}'
    cmds:
      - task: _process-charts
        vars: { ENV: prod, CHART_NAME: "{{.CHART_NAME}}", MODE: lint }

  # ── Audit ────────────────────────────────────────────────────────────────

  audit:
    desc: Template and audit all environments (dev → prod)
    cmds:
      - task: audit:dev
      - task: audit:prod

  audit:dev:
    desc: Template and audit all charts for dev
    cmds:
      - task: template:dev
      - task: _audit
        vars: { ENV: dev }

  audit:prod:
    desc: Template and audit all charts for prod
    cmds:
      - task: template:prod
      - task: _audit
        vars: { ENV: prod }

  _audit:
    internal: true
    vars:
      ENV: '{{.ENV}}'
    cmds:
      - |
        set -e
        echo "Auditing rendered output: {{.OUTPUT_DIR}}/{{.ENV}}/"
        kubescape scan framework {{.KUBESCAPE_FRAMEWORK}} \
          {{.OUTPUT_DIR}}/{{.ENV}} \
          --severity-threshold {{.KUBESCAPE_FAIL_THRESHOLD}} \
          $([ -f .kubescape/exceptions.json ] && echo "--exceptions .kubescape/exceptions.json")

  _process-charts:
    internal: true
    vars:
      ENV: '{{.ENV | default ""}}'
      CHART_NAME: '{{.CHART_NAME | default ""}}'
      MODE: '{{.MODE | default "template"}}'
    cmds:
      - |
        set -e
        if [ -n "{{.CHART_NAME}}" ]; then
          CHARTS="{{.CHART_NAME}}"
        else
          CHARTS=$(find {{.CHARTS_DIR}} -mindepth 1 -maxdepth 1 -type d | xargs -I{} basename {} | sort)
        fi

        for chart in $CHARTS; do
          CHART_PATH="{{.CHARTS_DIR}}/$chart"
          [ ! -d "$CHART_PATH" ] && echo "  $CHART_PATH not found, skipping" && continue
          [ ! -f "$CHART_PATH/Chart.yaml" ] && echo "  No Chart.yaml in $CHART_PATH, skipping" && continue

          VALUES_ARGS=""
          for f in \
            "$CHART_PATH/values.yaml" \
            "$CHART_PATH/defaults/values.yaml" \
            "${ENV:+$CHART_PATH/{{.ENV}}/values.yaml}" \
          ; do
            [ -n "$f" ] && [ -f "$f" ] && VALUES_ARGS="$VALUES_ARGS -f $f"
          done

          helm lint $CHART_PATH $VALUES_ARGS

          if [ "{{.MODE}}" = "template" ]; then
            OUTPUT_PATH="{{.OUTPUT_DIR}}/{{.ENV}}/$chart"
            mkdir -p "$OUTPUT_PATH"
            helm template $chart $CHART_PATH $VALUES_ARGS --output-dir "$OUTPUT_PATH"
          fi
        done

  clean:
    desc: Clean the .argo output directory
    vars:
      ENV: '{{.ENV | default ""}}'
    cmds:
      - |
        if [ -n "{{.ENV}}" ]; then
          rm -rf {{.OUTPUT_DIR}}/{{.ENV}}
          mkdir -p {{.OUTPUT_DIR}}/{{.ENV}}
        else
          rm -rf {{.OUTPUT_DIR}}
          mkdir -p {{.OUTPUT_DIR}}
        fi

  list:
    desc: List all charts under deploy/charts
    cmds:
      - |
        echo "Charts under {{.CHARTS_DIR}}/:"
        find {{.CHARTS_DIR}} -mindepth 1 -maxdepth 1 -type d | xargs -I{} basename {} | sort | sed 's/^/  - /'
```

### Kubescape configuration

- **Framework** (`KUBESCAPE_FRAMEWORK`): `nsa` is the sensible default; `mitre` is heavier; `allcontrols` is exhaustive and noisy.
- **Threshold** (`KUBESCAPE_FAIL_THRESHOLD`): `high` fails on high+critical only. `medium` is stricter; `critical` is too lenient.
- **Exceptions** (`.kubescape/exceptions.json`): every entry must include a `reason` field — exceptions without rationale rot.

`.kubescape/exceptions.json` structure:

```json
[
  {
    "name": "allow-host-network-cni",
    "policyType": "postureException",
    "actions": ["alertOnly"],
    "resources": {
      "designatorType": "Attributes",
      "attributes": {
        "kind": "DaemonSet",
        "name": "my-cni-plugin",
        "namespace": "kube-system"
      }
    },
    "posturePolicies": [
      {
        "controlName": "Allow hostNetwork",
        "controlID": "C-0041"
      }
    ],
    "reason": "CNI plugin requires hostNetwork to manage node network interfaces directly."
  }
]
```

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
