# Helm chart Taskfile

Load this when the repo deploys Helm charts (a `deploy/charts/` directory exists). It extends the core conventions in `SKILL.md` with `template`, `lint`, and `audit` tasks following the `action:env` naming convention.

## Core variables

| Variable | Effect |
|---|---|
| `CHART_NAME=foo` | Process only `deploy/charts/foo`, not all charts. |

## Task naming

```bash
task template         # iterate all environments: dev → prod
task template:dev     # dev only
task template:prod    # prod only
task lint             # lint for all environments
task lint:dev         # dev only
task audit            # audit for all environments
task audit:dev        # dev only
```

## Output directories

Rendered output is split by environment to support committing both:

```
.argo/
├── dev/
│   └── <chart>/      # output of task template:dev
└── prod/
    └── <chart>/      # output of task template:prod
```

ArgoCD reads from these paths; committing the rendered output is intentional.

## Canonical Helm Taskfile.yaml

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

## Kubescape configuration

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
