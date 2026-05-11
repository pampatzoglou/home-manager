---
name: helm
description: Helm chart authoring — chart anatomy, values file layering (values.yaml → defaults/ → env/ → overlay), _helpers.tpl, template patterns (conditionals, extraObjects, secrets as file mounts), and local validation.
user-invocable: true
---

# Helm

Helm packages Kubernetes workloads as charts. This skill covers authoring charts and working with values files correctly. For what must be *in* the Kubernetes resources (security context, probes, resource limits), see the `kubernetes` skill's resource standards.

## Do you need a new chart?

Before scaffolding:
- If a similar chart exists, **extend it with a values overlay** — don't fork.
- A one-off Job or debug pod doesn't need a chart — a plain manifest is fine.
- A new chart is justified when the workload has >3 resources, needs per-environment values, or will be reused across teams.

When Helm is the wrong tool entirely:

| Situation | Use instead |
|---|---|
| Simple static manifests, single environment | Raw YAML or Kustomize |
| Platform-level resources managed by operators | Operator CRs directly (CNPG, Strimzi, etc.) |
| Heavy chart logic with many conditionals | Reconsider the design — charts should configure, not program |
| Library chart with no templates | A shared `_helpers.tpl` snippet included via chart dependency |

## Chart layout

```
my-chart/
├── Chart.yaml
├── values.yaml              # scaffold defaults + commented placeholders for every knob
├── values.schema.json       # recommended — catches values typos and wrong types at lint time
├── defaults/
│   └── values.yaml          # DRY layer — true for every cluster deployment
├── dev/
│   └── values.yaml          # dev-specific deltas only
├── prod/
│   └── values.yaml          # prod-specific deltas only
├── templates/
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── serviceaccount.yaml
│   ├── pdb.yaml
│   ├── networkpolicy.yaml
│   └── NOTES.txt
└── README.md
```

## Values file layering

Precedence — later overrides earlier:

```
values.yaml → defaults/values.yaml → <env>/values.yaml → <env>/<overlay>.yaml
```

| Layer | Purpose |
|---|---|
| `values.yaml` | Helm scaffold defaults + commented-out example shapes for every feature section |
| `defaults/values.yaml` | DRY layer: anything true for every cluster deployment — pull secrets, security context overrides, common labels, monitoring opt-ins |
| `<env>/values.yaml` | Environment-specific deltas only: replica counts, hostnames, resource sizes, ExternalSecret names |
| `<env>/<overlay>.yaml` | Optional third-axis overlay (region, tenant, chain variant) |

**Mental test before adding a value:** true in two or more environments? → `defaults/`. Environment-specific? → `<env>/values.yaml`. Copy-pasting the same value into both dev and prod is a signal to promote it to `defaults/`.

## Chart.yaml

```yaml
apiVersion: v2
name: my-chart
description: One-line description of what this deploys.
type: application
version: 0.1.0          # bump on every change — ArgoCD uses this for change detection
appVersion: "1.4.2"     # tracks the upstream image version
kubeVersion: ">=1.28.0"
maintainers:
  - name: team-name
dependencies:
  - name: common          # optional — shared helpers chart
    version: "2.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: common.enabled
```

Bump `version` on every change, even non-breaking ones. Both ArgoCD and Helm use it to detect that something changed.

**Chart dependencies** (`dependencies:` in `Chart.yaml`) pull in sub-charts at `helm dependency update` time, stored in `charts/`. Use them for:
- Shared `_helpers.tpl` logic packaged as a library chart (`type: library`)
- Bundling a sidecar chart (e.g., an exporter) that ships with every deployment of this workload

Commit the `charts/` directory or add `charts/*.tgz` to `.gitignore` and run `helm dependency update` in CI. Do **not** use chart dependencies as a replacement for ArgoCD `ApplicationSet` — each independently deployed component gets its own chart.

## values.yaml style

Every knob has a default and an inline comment:

```yaml
# Replicas. Set >= 2 for HA — PDB and anti-affinity activate at >= 2.
replicaCount: 1

image:
  repository: ghcr.io/example/myapp
  tag: "1.4.2"           # pin to tag or digest; never 'latest'
  pullPolicy: IfNotPresent

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: "1"
    memory: 512Mi

nodeSelector: {}
tolerations: []

# Feature sections are off by default:
ingress:
  enabled: false
  className: nginx
  hosts: []
```

Group related knobs (`image.*`, `service.*`, `ingress.*`). Use `enabled: false` at the top of feature sections and guard the whole resource with `{{- if .Values.ingress.enabled }}`.

New template features get commented-out example shapes in `values.yaml` so it doubles as documentation of every knob the chart exposes:

```yaml
# prometheusRules:
#   enabled: true
#   rules:
#     - alert: HighErrorRate
#       expr: rate(http_errors_total[5m]) > 0.05
#       for: 10m
```

## values.schema.json

Add a JSON Schema file to catch typos and wrong value types at `helm lint` and `helm template` time — before manifests ever reach the cluster:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["image"],
  "properties": {
    "replicaCount": {
      "type": "integer",
      "minimum": 1
    },
    "image": {
      "type": "object",
      "required": ["repository", "tag"],
      "properties": {
        "repository": { "type": "string" },
        "tag":        { "type": "string" },
        "pullPolicy": {
          "type": "string",
          "enum": ["Always", "IfNotPresent", "Never"]
        }
      }
    },
    "resources": {
      "type": "object"
    }
  }
}
```

Schema at the top level of the chart (`my-chart/values.schema.json`). Helm validates values against it on every `helm lint`, `helm template`, and `helm install`. This catches `replicaCount: "two"` and missing required keys before they cause confusing runtime failures.

Add a schema entry for every key you care about. You don't need to be exhaustive — cover required keys and any key whose type is easy to get wrong.

## _helpers.tpl

```gotmpl
{{- define "my-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "my-chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "my-chart.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "my-chart.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "my-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "my-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "my-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

**Selector labels must not include version.** Selectors on Deployments and StatefulSets are immutable — baking the version in means you can't upgrade the chart without deleting and recreating the workload.

## Template patterns

**Conditional resource** — guard the whole resource, not lines inside it:
```gotmpl
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
...
{{- end }}
```

**Required values:**
```gotmpl
{{ required "image.repository is required" .Values.image.repository }}
```

**Pass-through structs** — use `toYaml` for blocks the user might fully override:
```gotmpl
resources:
  {{- toYaml .Values.resources | nindent 12 }}
```

Never `printf` YAML structure together — it always breaks eventually on edge cases.

**`extraObjects` — arbitrary manifest escape hatch:**

In `_helpers.tpl`:
```gotmpl
{{- define "my-chart.render" -}}
  {{- if typeIs "string" .value -}}
    {{- tpl .value .context }}
  {{- else -}}
    {{- tpl (.value | toYaml) .context }}
  {{- end -}}
{{- end -}}
```

In `templates/extra.yaml`:
```gotmpl
{{- range .Values.extraObjects }}
---
{{ include "my-chart.render" (dict "value" . "context" $) }}
{{- end }}
```

Add `extraObjects: []` in `values.yaml`. The `tpl` call lets users embed Helm expressions (e.g., `{{ include "my-chart.fullname" . }}`) inside their extra objects. Add to any chart reused across teams — it's the clean alternative to forking.

## Secrets: file mounts over env vars

File mounts are strongly preferred:
- Env vars leak into process listings, log lines, and crash dumps; file mounts don't.
- File mounts hot-reload with the `reloader` annotation; env vars require a pod restart.
- File-mounted secrets work cleanly with `external-secrets` rotating credentials in place.

Pattern in `defaults/values.yaml`:
```yaml
config:
  database:
    externalSecret:
      enable: false    # true in cluster envs where ExternalSecret is provisioned
      name: ""         # name of the ExternalSecret-managed Secret
```

In the Deployment template:
```yaml
volumes:
  - name: db-credentials
    secret:
      secretName: {{ if .Values.config.database.externalSecret.enable -}}
                    {{ .Values.config.database.externalSecret.name }}
                  {{- else -}}
                    {{ include "my-chart.fullname" . }}-db
                  {{- end }}
volumeMounts:
  - name: db-credentials
    mountPath: /etc/secrets/db
    readOnly: true
```

When `externalSecret.enable: false`, render a dev-only Secret from placeholder values:
```gotmpl
{{- if not .Values.config.database.externalSecret.enable }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "my-chart.fullname" . }}-db
type: Opaque
stringData:
  user: {{ .Values.config.database.user | default "dev" }}
  password: {{ .Values.config.database.password | default "dev-only-not-for-prod" }}
{{- end }}
```

This keeps prod off the chart-internal Secret path while letting `task template` and `skaffold dev` work locally without ExternalSecret infrastructure.

## Local validation

Prefer `task template:dev` when a Taskfile is present — it matches exactly what CI and ArgoCD use. Falling back to raw helm:

```bash
helm template my-release ./my-chart \
  --namespace my-namespace \
  --include-crds \
  -f values.yaml \
  -f defaults/values.yaml \
  -f dev/values.yaml
```

Stricter checks:
```bash
helm lint ./my-chart
helm template ... | kubeconform -strict -summary
```

Things to look for in rendered output:
- No `<no value>` strings
- Consistent indentation (no `nindent` off-by-one)
- `spec.selector.matchLabels` ⊂ `metadata.labels`
- CRDs render before the resources that depend on them

## Completion checklist

- [ ] Chart renders cleanly with `helm template` or `task template:dev`
- [ ] `Chart.yaml` version bumped
- [ ] Every knob in `values.yaml` has a default and inline comment
- [ ] Feature sections use `enabled: false` guard pattern
- [ ] `_helpers.tpl` defines name, fullname, labels, selectorLabels
- [ ] Selector labels don't include version
- [ ] Secrets use file mounts (env vars only with documented justification)
- [ ] `extraObjects: []` present for charts reused across teams
- [ ] `README.md` describes purpose, prerequisites, and a minimal values example

## Companion skills — offer after completing

When chart work is done, check the repo and offer whichever of these are missing or incomplete:

| Skill | Offer when |
|-------|-----------|
| `skaffold` | No `skaffold.yaml` and the project has a local dev use case |
| `devbox` | No `devbox.json` in the repo root |
| `document` | No `docs/ARCHITECTURE.md`, or chart `README.md` is missing or minimal |

Ask as a single grouped question — not mid-task, not separately for each.
