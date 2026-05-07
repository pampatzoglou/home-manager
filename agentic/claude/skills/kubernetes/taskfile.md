# Taskfile (services repo)

This file documents the canonical `Taskfile.yaml` used by services repos for linting, templating, and auditing Helm charts. Read this when:

- The user is creating a new services repo and needs a starting Taskfile
- The user is modifying or debugging an existing Taskfile
- Claude needs to invoke `task template` / `task lint` / `task audit` and wants to know what files actually get loaded

## What it does

The Taskfile wraps `helm template`, `helm lint`, and `kubescape scan` for every chart under `deploy/charts/`. It handles values-file precedence and writes rendered output to `.argo/` for ArgoCD to consume.

## Core variables (KEY=VALUE form)

go-task uses `KEY=VALUE` arguments. Order doesn't matter; omit any variable to skip its layer.

| Variable | Effect |
|---|---|
| `ENV=dev` / `ENV=prod` | Adds `<chart>/<env>/values.yaml` to the helm command. Without it, only `values.yaml` + `defaults/values.yaml` are loaded. |
| `CHART_NAME=foo` | Process only `deploy/charts/foo`, not all charts. |

Examples:

```bash
task template                                       # all charts, no env
task template ENV=dev                               # all charts, dev values
task template ENV=prod CHART_NAME=my-service        # one chart, prod values
task lint ENV=dev                                   # lint without rendering or auditing
task audit ENV=dev                                  # render + kubescape scan on .argo/
task clean                                          # wipe .argo/
```

## Chart discovery

Charts are discovered by globbing `deploy/charts/*` directly — any directory there with a `Chart.yaml` is a chart. **The Taskfile does not depend on `.github/workflows/services.yaml` or any other CI config.** This is a deliberate decoupling; CI may discover charts independently from a workflow file, but the Taskfile is self-sufficient.

If a directory under `deploy/charts/` lacks a `Chart.yaml`, the task warns and skips it.

## Values file precedence

For each chart, the task assembles `-f` flags in this exact order (later overrides earlier):

1. `<chart>/values.yaml` — always, if present
2. `<chart>/defaults/values.yaml` — always, if present
3. `<chart>/<ENV>/values.yaml` — only if `ENV` is set and the file exists

Files that don't exist are skipped silently — there's no error for a missing env directory on a chart that doesn't differentiate by env.

## Tasks

### `task template`
Renders all charts (or `CHART_NAME=foo`) into `.argo/<chart>/` for the given `ENV`. Runs `task clean` first so the output dir is fresh. Lints each chart as a side effect — lint failures warn but don't abort, so all charts are processed before exiting.

### `task lint`
Runs `helm lint` on every chart with the same values-file ordering as template, but doesn't render or write to `.argo/`. Useful as a fast pre-commit check or in CI when you only need to validate chart syntax.

### `task audit`
**Depends on `task template`** — re-uses the rendered output in `.argo/` instead of duplicating the render logic. After templating, runs `kubescape scan` on the rendered tree and exits non-zero if findings exceed the configured severity (see `kubescape` section below). This is the task Claude runs at the end of any chart-modifying work — see SKILL.md "End-of-task audit" for how findings should be handled.

### `task clean`
Removes `.argo/` and recreates it empty. Called automatically by `template` and `audit`; explicit invocation is for resetting state when something's wedged.

## Canonical Taskfile.yaml

This is the version Claude should produce when scaffolding a new services repo.

```yaml
version: "3"

vars:
  CHARTS_DIR: deploy/charts
  OUTPUT_DIR: .argo
  KUBESCAPE_FRAMEWORK: nsa            # or 'mitre', 'allcontrols' — pick what the team has agreed on
  KUBESCAPE_FAIL_THRESHOLD: high      # severity at which audit exits non-zero

tasks:
  template:
    desc: Lint and template all Helm charts in deploy/charts
    vars:
      ENV: '{{.ENV | default ""}}'
      CHART_NAME: '{{.CHART_NAME | default ""}}'
    cmds:
      - task: clean
      - task: process-charts
        vars:
          ENV: "{{.ENV}}"
          CHART_NAME: "{{.CHART_NAME}}"
          MODE: template

  lint:
    desc: Lint all Helm charts in deploy/charts (no rendering)
    vars:
      ENV: '{{.ENV | default ""}}'
      CHART_NAME: '{{.CHART_NAME | default ""}}'
    cmds:
      - task: process-charts
        vars:
          ENV: "{{.ENV}}"
          CHART_NAME: "{{.CHART_NAME}}"
          MODE: lint

  audit:
    desc: Render charts and run kubescape against the output
    deps: [template]
    vars:
      ENV: '{{.ENV | default ""}}'
      CHART_NAME: '{{.CHART_NAME | default ""}}'
    cmds:
      - |
        set -e
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🛡️  Auditing rendered output: {{.OUTPUT_DIR}}/"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        kubescape scan framework {{.KUBESCAPE_FRAMEWORK}} \
          {{.OUTPUT_DIR}} \
          --severity-threshold {{.KUBESCAPE_FAIL_THRESHOLD}} \
          $([ -f .kubescape/exceptions.json ] && echo "--exceptions .kubescape/exceptions.json")

  process-charts:
    internal: true
    vars:
      ENV: '{{.ENV | default ""}}'
      CHART_NAME: '{{.CHART_NAME | default ""}}'
      MODE: '{{.MODE | default "template"}}'
    cmds:
      - |
        set -e

        # Discover charts: either the one named via CHART_NAME, or every dir under CHARTS_DIR
        if [ -n "{{.CHART_NAME}}" ]; then
          CHARTS="{{.CHART_NAME}}"
        else
          CHARTS=$(find {{.CHARTS_DIR}} -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
        fi

        for chart in $CHARTS; do
          CHART_PATH="{{.CHARTS_DIR}}/$chart"

          if [ ! -d "$CHART_PATH" ]; then
            echo "⚠️  Chart directory $CHART_PATH does not exist, skipping..."
            continue
          fi
          if [ ! -f "$CHART_PATH/Chart.yaml" ]; then
            echo "⚠️  Chart.yaml not found in $CHART_PATH, skipping..."
            continue
          fi

          echo ""
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "📊 Processing: $chart"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

          # Build values args in precedence order
          VALUES_ARGS=""
          for f in \
            "$CHART_PATH/values.yaml" \
            "$CHART_PATH/defaults/values.yaml" \
            "${ENV:+$CHART_PATH/{{.ENV}}/values.yaml}" \
          ; do
            [ -n "$f" ] && [ -f "$f" ] && VALUES_ARGS="$VALUES_ARGS -f $f" && echo "  📄 Using: ${f#$CHART_PATH/}"
          done

          echo ""
          echo "🔍 Linting..."
          if helm lint $CHART_PATH $VALUES_ARGS; then
            echo "  ✅ Lint passed"
          else
            echo "  ⚠️  Lint failed (continuing)"
          fi

          if [ "{{.MODE}}" = "template" ]; then
            OUTPUT_PATH="{{.OUTPUT_DIR}}/$chart"
            mkdir -p "$OUTPUT_PATH"
            echo ""
            echo "📦 Templating..."
            if helm template $chart $CHART_PATH $VALUES_ARGS --output-dir "$OUTPUT_PATH"; then
              echo "  ✅ Output: $OUTPUT_PATH"
            else
              echo "  ❌ Template failed"
              exit 1
            fi
          fi
        done

  clean:
    desc: Clean the .argo output directory
    cmds:
      - rm -rf {{.OUTPUT_DIR}}
      - mkdir -p {{.OUTPUT_DIR}}

  list:
    desc: List all charts under deploy/charts
    cmds:
      - |
        echo "Charts under {{.CHARTS_DIR}}/:"
        find {{.CHARTS_DIR}} -mindepth 1 -maxdepth 1 -type d -printf '  - %f\n' | sort
```

## kubescape configuration

`task audit` runs `kubescape scan framework <framework> .argo/` with a configurable severity threshold and an optional exceptions file:

- **Framework** (`KUBESCAPE_FRAMEWORK`): which control set to scan against. `nsa` is a sensible default for general workloads; `mitre` is heavier and security-focused; `allcontrols` is exhaustive and noisy. Pick one and stick with it across the team.
- **Severity threshold** (`KUBESCAPE_FAIL_THRESHOLD`): minimum severity that causes a non-zero exit. `high` fails on high+critical only; `medium` is stricter; `critical` is too lenient for most teams.
- **Exceptions** (`.kubescape/exceptions.json`): a JSON file listing controls or resources to skip with a `reason` per entry. See the kubescape docs for the exact schema. Only used if the file exists.

When Claude proposes adding an exception, the entry must include a `reason` field — exceptions without rationale are how this file becomes a graveyard.

## Behavior notes

- **`task template` with no `ENV`** loads only `values.yaml` + `defaults/values.yaml`. Useful as a quick smoke test that the chart renders without env-specific values; not a real deploy artifact.
- **`task template` always cleans `.argo/` first.** For incremental rendering, run `task lint`; the rendered-output workflow is intentionally all-or-nothing.
- **`task lint` continues past lint failures.** By design: it processes every chart so all errors surface at once.
- **`task template` exits non-zero on the first templating failure** so CI fails loudly.
- **`task audit` requires `kubescape` on PATH.** The team's `devbox.json` should pin it; see `devbox.md`.

## Optional extensions

When a repo legitimately needs more than the two-axis model (env + chart), extend the Taskfile rather than fighting it. Common cases:

### Adding a third-axis overlay

If charts in the repo deploy multiple variations within an environment (e.g., per-region, per-tenant, per-customer), add a third variable. The team picks the name that fits the domain — `REGION`, `TENANT`, etc. The pattern:

```yaml
# In task vars
REGION: '{{.REGION | default ""}}'

# In the values loop, append after the env file
"${REGION:+${ENV:+$CHART_PATH/{{.ENV}}/{{.REGION}}.yaml}}" \
```

The overlay file lives at `<chart>/<env>/<region>.yaml` and is appended after `<env>/values.yaml`. It only loads when both `ENV` and `REGION` are set and the file exists, so charts that don't use the overlay are unaffected.

If a chart in the repo uses this and most don't, that's fine — the per-chart files just don't exist for the others.

### Adding `--kube-version` / `--api-versions`

For matching cluster server-side schema (e.g., when CRDs vary by cluster version), thread these through as task vars and add to the `helm template` invocation. Useful when the team runs different Kubernetes versions in dev vs prod.

### Adding a `validate` task

For schema validation beyond what `helm lint` does, pipe `helm template` output through `kubeconform`:

```yaml
validate:
  desc: Validate rendered manifests against the K8s schema
  deps: [template]
  cmds:
    - kubeconform -strict -summary {{.OUTPUT_DIR}}
```

### Adding a `diff` gate

To enforce that rendered `.argo/` output is committed:

```yaml
diff:
  desc: Fail if .argo/ differs from the committed version
  deps: [template]
  cmds:
    - |
      if ! git diff --quiet {{.OUTPUT_DIR}}/; then
        echo "::error::Rendered output is out of date. Run 'task template ENV=<env>' and commit."
        git diff --stat {{.OUTPUT_DIR}}/
        exit 1
      fi
```

Useful as a PR check.

### What not to add

- **Don't add `CHART_NAME`-specific tasks** (`template-my-service:`). The `CHART_NAME=foo` variable already covers single-chart targeting and avoids per-chart maintenance.
- **Don't bake `kubectl apply` into a task.** Deployment is ArgoCD's job; the Taskfile's job ends at `.argo/`.
