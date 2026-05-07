# Authoring Helm Charts

This file covers writing new charts and editing existing ones. For what should be *in* the resources, see `resource-standards.md`. For team-specific layout (`defaults/dev/prod`), see `team-conventions.md`.

## Decision: do you actually need a new chart?

Most of the time, the answer is no. Before scaffolding:

- If a similar chart already exists in the repo, **add a values file or extend it** — don't fork.
- If the workload is a one-off (a debug pod, a Job), a plain manifest in the right place is fine; don't wrap it in a chart for the sake of it.
- A new chart is justified when: the workload has a non-trivial template surface (>3 resources), needs per-environment values, or will be reused across teams.

## Chart layout

Standard structure:

```
my-chart/
├── Chart.yaml
├── values.yaml                # documented defaults, user-facing knobs
├── values.schema.json         # optional but recommended — catches typos in values
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

If the team uses a per-environment layout (`defaults/values.yaml`, `dev/values.yaml`, etc.), match it — see `team-conventions.md`.

## `Chart.yaml`

```yaml
apiVersion: v2
name: my-chart
description: One-line description of what this deploys.
type: application
version: 0.1.0          # chart version — bump on every change
appVersion: "1.4.2"     # app version — bump when the upstream image changes
kubeVersion: ">=1.28.0"
maintainers:
  - name: team-name
```

Bump `version` on every change, even non-breaking ones. ArgoCD and Helm both use it for change detection.

## `values.yaml` style

Two principles: every knob has a default, and every knob is documented in-line.

```yaml
# Number of replicas. Set replicaCount >= 2 for HA; PDB and anti-affinity activate at >= 2.
replicaCount: 1

image:
  repository: ghcr.io/example/myapp
  # Pin to a specific tag or digest. Avoid 'latest'.
  tag: "1.4.2"
  pullPolicy: IfNotPresent

# Resource requests/limits. See resource-standards.md for guidance on memory limit == request.
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: "1"
    memory: 512Mi

# Optional: explicit nodeSelector / tolerations. Leave empty unless the cluster requires them.
nodeSelector: {}
tolerations: []
```

Group related knobs (`image.*`, `service.*`, `ingress.*`, `persistence.*`). Don't flatten into top-level keys — it makes overrides messy.

For values that are off by default but enable a whole feature, use a single `enabled` flag at the top of the section:

```yaml
ingress:
  enabled: false
  className: nginx
  hosts: []
```

Then in templates: `{{- if .Values.ingress.enabled }}` … `{{- end }}`.

## `_helpers.tpl`

The generated `helm create` boilerplate is fine as a starting point. Keep it minimal:

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

Selector labels are a *subset* of full labels and **must not include version**. Selectors are immutable; if you bake the version in, you can't upgrade the chart.

## Templating patterns

**Conditional blocks:** prefer `{{- if .Values.x.enabled }}` at the top of a whole resource over scattering ifs inside it.

**Default values in templates:** `{{ .Values.x | default "fallback" }}` — but prefer setting defaults in `values.yaml` so they're visible to the user.

**Required values:** for things the user must set:
```gotmpl
{{ required "image.repository is required" .Values.image.repository }}
```

**Pass-through merges:** for things like resources, security context, or annotations that the user might want to fully override:
```gotmpl
resources:
  {{- toYaml .Values.resources | nindent 12 }}
```

**Don't `printf` YAML structure together** — it always blows up eventually. Use `toYaml` or write the structure directly.

### `extraObjects` — letting users append arbitrary manifests

Charts often need an escape hatch: a way for the user to add arbitrary Kubernetes resources (extra ConfigMaps, NetworkPolicies, ServiceMonitors, etc.) without forking the chart. The clean pattern is an `extraObjects` list in values, rendered through a helper that processes Helm templating in each entry:

In `_helpers.tpl`:
```gotmpl
{{- define "<chart>.render" -}}
  {{- if typeIs "string" .value -}}
    {{- tpl .value .context }}
  {{- else -}}
    {{- tpl (.value | toYaml) .context }}
  {{- end -}}
{{- end -}}
```

In a template file (e.g. `templates/extra.yaml`):
```gotmpl
{{- range .Values.extraObjects }}
---
{{ include "<chart>.render" (dict "value" . "context" $) }}
{{- end }}
```

Users then add objects in their values overlay:
```yaml
extraObjects:
  - apiVersion: monitoring.coreos.com/v1
    kind: ServiceMonitor
    metadata:
      name: {{ include "<chart>.fullname" . }}-extra
    spec:
      selector:
        matchLabels:
          {{ "{{" }} include "<chart>.selectorLabels" . {{ "}}" }}
```

The `tpl` call is what makes this work — it lets users embed Helm templating (`{{ include … }}`, `{{ .Values.x }}`) inside their extra objects and have it resolved against the current chart context. Without `tpl`, extra objects are just static YAML.

When to add this: every chart that gets reused across teams or environments benefits from `extraObjects`. Don't pre-emptively add it to a one-off chart — but the moment a second team needs "almost this chart but with one extra resource", `extraObjects` is the answer instead of a fork.

### Externalized secrets (file mount preferred, env vars as fallback)

Secrets get into pods two ways: file mounts and env vars. **File mounts are strongly preferred** when the application supports reading them from a file:

- Env vars leak into process listings, log lines, and crash dumps; file mounts don't.
- File mounts hot-reload when paired with `reloader`; env vars require a pod restart.
- File-mounted secrets work cleanly with `external-secrets` rotating credentials in place.

The pattern: in `defaults/values.yaml`, expose a toggle for whether the secret is provided externally (via `ExternalSecret`) or generated by the chart itself for dev:

```yaml
# defaults/values.yaml
config:
  database:
    externalSecret:
      enable: false              # set true in env overlays where ExternalSecret is provisioned
      name: ""                   # name of the ExternalSecret-managed Secret to mount
```

In the template, prefer mounting the secret as a file. The application reads `/etc/secrets/db/{user,password}`:

```yaml
volumes:
  - name: db-credentials
    secret:
      secretName: {{ if .Values.config.database.externalSecret.enable -}}
                    {{ .Values.config.database.externalSecret.name }}
                  {{- else -}}
                    {{ include "<chart>.fullname" . }}-db
                  {{- end }}
volumeMounts:
  - name: db-credentials
    mountPath: /etc/secrets/db
    readOnly: true
```

Pair the workload with the `reloader` annotation so credential rotation triggers a rolling restart automatically:

```yaml
metadata:
  annotations:
    reloader.stakater.com/auto: "true"
```

**When the application can't read secrets from files**, fall back to env vars referencing the same toggle:

```yaml
env:
  - name: POSTGRES_USER
    valueFrom:
      secretKeyRef:
        {{- if .Values.config.database.externalSecret.enable }}
        name: {{ .Values.config.database.externalSecret.name }}
        key: {{ .Values.config.database.externalSecret.userKey }}
        {{- else }}
        name: {{ include "<chart>.fullname" . }}-db
        key: user
        {{- end }}
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        {{- if .Values.config.database.externalSecret.enable }}
        name: {{ .Values.config.database.externalSecret.name }}
        key: {{ .Values.config.database.externalSecret.passwordKey }}
        {{- else }}
        name: {{ include "<chart>.fullname" . }}-db
        key: password
        {{- end }}
```

If the application is one Claude controls (i.e., the team owns the source code), and it reads credentials only from env vars, **flag this in the chart review** — the application should be updated to support file-based credentials. It's a small change in the application code (read from `/etc/secrets/db/user` if the file exists, else fall back to the env var) that pays off in security and ops every time credentials rotate.

The chart-internal `<chart>-db` Secret (the `else` branch) is for dev convenience: a Secret rendered from `defaults/values.yaml` placeholder values, never used in prod. In env overlays where `externalSecret.enable: true`, the chart skips creating the internal Secret entirely:

```gotmpl
{{- if not .Values.config.database.externalSecret.enable }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "<chart>.fullname" . }}-db
type: Opaque
stringData:
  user: {{ .Values.config.database.user | default "dev" }}
  password: {{ .Values.config.database.password | default "dev-only-not-for-prod" }}
{{- end }}
```

This keeps prod off the chart-internal-Secret path entirely while still letting `task template` and `skaffold dev` work without an `ExternalSecret` infrastructure dependency.

## Testing locally before committing

Always render the chart at least once before committing.

```bash
helm template my-release ./my-chart \
  --namespace my-namespace \
  --include-crds \
  --values values.yaml \
  --values dev/values.yaml          # if using env overlays
```

If the team has a `Taskfile.yaml` with `template` task (`task template ENV=<env>`), use that — it'll match what the CI does.

Things to look for in the rendered output:
- All references resolve (no `<no value>` strings)
- Indentation is consistent (no `nindent` mistakes producing one-off keys)
- Selectors match labels — `spec.selector.matchLabels` ⊂ `metadata.labels`
- CRDs render before the resources that use them (sync wave or `helm.sh/hook` if needed)

For a stricter check, install `helm lint` and `kubeconform`:
```bash
helm lint ./my-chart
helm template ... | kubeconform -strict -summary
```

## Documentation: README and NOTES.txt

`README.md` for humans browsing the repo:
- One-paragraph description of what the chart deploys
- Prerequisites (operators, CRDs, secrets that must exist first)
- A minimal `values.yaml` example
- Table of the most-used values (not every value — link to `values.yaml` for the full list)

`templates/NOTES.txt` for users running `helm install`:
- How to verify the install worked
- How to access the service (port-forward command, ingress URL)
- A pointer to next steps if relevant

Keep NOTES.txt short — nobody reads a wall of text after a successful install.

## When you finish

Before declaring the chart done:

- [ ] Chart renders cleanly with `helm template`
- [ ] Every container has resources, securityContext, and probes
- [ ] If `replicaCount >= 2`: PDB exists, anti-affinity or topology spread is set
- [ ] No secrets in `values.yaml` — references to ExternalSecrets only
- [ ] Image tag is pinned (no `:latest`)
- [ ] `README.md` describes purpose and prerequisites
- [ ] If team conventions apply, the env overlay structure matches

Then run the team's templating recipe (or `helm template` manually) and skim the diff if updating an existing chart.
