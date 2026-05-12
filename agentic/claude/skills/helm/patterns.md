# Helm — Patterns & Requirements

Recurring template patterns and operational requirements for Helm charts. Companion to `SKILL.md` (foundations). For Kubernetes resource-level standards see the `kubernetes` skill's `resource-standards.md`.

---

## Image construction

The image reference must support three cases: tag only, digest only, and tag+digest. The tag+digest form (`repo:tag@sha256:...`) gives you human-readable tags in `kubectl get pods` while guaranteeing immutability via the digest.

### Values shape

```yaml
image:
  repository: ""
  tag: ""                # e.g., "v1.4.2" or commit SHA
  digest: ""             # e.g., "sha256:abc123..." — takes precedence when set
  pullPolicy: IfNotPresent
```

### Helper

Add an image helper to `_helpers.tpl`:

```gotmpl
{{- define "my-chart.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- if .Values.image.digest -}}
  {{- printf "%s:%s@%s" .Values.image.repository $tag .Values.image.digest -}}
{{- else -}}
  {{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end -}}
{{- end -}}
```

### Usage in templates

```gotmpl
image: {{ include "my-chart.image" . }}
imagePullPolicy: {{ .Values.image.pullPolicy }}
```

Rendered output examples:
- Tag only: `ghcr.io/example/myapp:v1.4.2`
- Tag + digest: `ghcr.io/example/myapp:v1.4.2@sha256:abc123...`
- Digest only (tag empty): `ghcr.io/example/myapp:1.0.0@sha256:abc123...` (falls back to `appVersion`)

---

## ExternalSecret toggle pattern

Every credential block in `values.yaml` includes an `externalSecret` sub-key. When disabled, the chart renders a placeholder Secret for local development. When enabled, the template references a pre-existing Secret (managed by `external-secrets`, Vault, or secret replication).

### Values shape

```yaml
database:
  host: ""
  port: "5432"
  database: ""
  user: "postgres"
  password: "localdev"
  externalSecret:
    enable: false
    name: ""
    userKey: username
    passwordKey: password
```

### secrets.yaml — conditional chart-internal Secret

```gotmpl
{{- if not .Values.database.externalSecret.enable }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "my-chart.fullname" . }}-db
  labels:
    {{- include "my-chart.labels" . | nindent 4 }}
type: Opaque
stringData:
  user: {{ .Values.database.user | quote }}
  password: {{ .Values.database.password | quote }}
{{- end }}
```

### Deployment — secretKeyRef switching

```gotmpl
- name: DB_USER
  valueFrom:
    secretKeyRef:
      {{- if .Values.database.externalSecret.enable }}
      name: {{ .Values.database.externalSecret.name }}
      key: {{ .Values.database.externalSecret.userKey }}
      {{- else }}
      name: {{ include "my-chart.fullname" . }}-db
      key: user
      {{- end }}
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      {{- if .Values.database.externalSecret.enable }}
      name: {{ .Values.database.externalSecret.name }}
      key: {{ .Values.database.externalSecret.passwordKey }}
      {{- else }}
      name: {{ include "my-chart.fullname" . }}-db
      key: password
      {{- end }}
```

Both branches use `secretKeyRef` — the only difference is where `name` and `key` come from. When external, both are user-configurable via values. When chart-internal, the name is derived from `fullname` and the keys are fixed.

### Multi-secret naming convention

When a chart has multiple credential blocks (database, kafka, node RPC, etc.), each produces one Secret and one set of env vars. The naming convention:

| Values block | Secret suffix | Env var prefix |
|---|---|---|
| `database` | `{{ fullname }}-db` | `DB_*` or `POSTGRES_*` |
| `kafka` | `{{ fullname }}-kafka` | `KAFKA_*` |
| `node` | `{{ fullname }}-node` | `NODE_*` |
| `auth` | `{{ fullname }}-auth` | `AUTH_*` or service-specific |

The Secret suffix should match (or abbreviate) the values block name. Keep this mapping consistent across charts so ops can predict the Secret name from the values file.

### Secret replication via extraObjects

When a Secret exists in another namespace, use the mittwald replicator annotation injected through `extraObjects` in the env overlay:

```yaml
# dev/eth.yaml
extraObjects:
  - apiVersion: v1
    kind: Secret
    metadata:
      name: my-kafka-credentials
      annotations:
        replicator.v1.mittwald.de/replicate-from: kafka/my-kafka-credentials
    type: Opaque
```

### ExternalSecret creation via extraObjects

When the chart's env overlay needs to provision an `ExternalSecret` resource (e.g., pulling from AWS Secrets Manager), inject it through `extraObjects`:

```yaml
# dev/eth.yaml
extraObjects:
  - apiVersion: external-secrets.io/v1
    kind: ExternalSecret
    metadata:
      name: my-credentials
    spec:
      refreshInterval: 10m
      secretStoreRef:
        kind: ClusterSecretStore
        name: aws-secrets-manager
      target:
        name: my-credentials
        creationPolicy: Owner
        deletionPolicy: Retain
        template:
          type: Opaque
      data:
        - secretKey: url
          remoteRef:
            key: /foo/bar
            property: url
```

---

## extraObjects — arbitrary manifest escape hatch

In `_helpers.tpl` (the `render` helper):
```gotmpl
{{- define "my-chart.render" -}}
  {{- if typeIs "string" .value -}}
    {{- tpl .value .context }}
  {{- else -}}
    {{- tpl (.value | toYaml) .context }}
  {{- end -}}
{{- end -}}
```

In `templates/extra-manifests.yaml`:
```gotmpl
{{- range .Values.extraObjects }}
---
{{ include "my-chart.render" (dict "value" . "context" $) }}
{{- end }}
```

The `tpl` call allows users to embed Helm expressions (e.g., `{{ include "my-chart.fullname" . }}`) inside their extra objects. Common uses: ExternalSecrets, replicated Secrets, VaultDynamicSecrets, NetworkPolicies, any resource the base chart doesn't template.

---

## Config checksum annotation

Force a rolling restart when chart-internal secrets change by adding a checksum annotation to the pod template:

```gotmpl
spec:
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/secrets.yaml") . | sha256sum }}
```

This complements the reloader annotation:
- **Checksum** — triggers restart when the chart's own `secrets.yaml` output changes (values change between deploys)
- **Reloader** (`reloader.stakater.com/auto: "true"`) — triggers restart when an external Secret or ConfigMap is updated in-place (credential rotation, ExternalSecret refresh)

Use both. Checksum goes in the template; reloader goes in `defaults/values.yaml` via `podAnnotations`.

---

## Downward API metadata injection

Standard env var block for every container. Provides runtime context for logging, metrics labels, and resource-aware tuning:

```gotmpl
- name: NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: POD_IP
  valueFrom:
    fieldRef:
      fieldPath: status.podIP
- name: HOST_IP
  valueFrom:
    fieldRef:
      fieldPath: status.hostIP
- name: NODE_NAME
  valueFrom:
    fieldRef:
      fieldPath: spec.nodeName
- name: CPU_REQUEST
  valueFrom:
    resourceFieldRef:
      divisor: 1m
      resource: requests.cpu
- name: CPU_LIMIT
  valueFrom:
    resourceFieldRef:
      divisor: 1m
      resource: limits.cpu
- name: MEM_REQUEST
  valueFrom:
    resourceFieldRef:
      divisor: 1Mi
      resource: requests.memory
- name: MEM_LIMIT
  valueFrom:
    resourceFieldRef:
      divisor: 1Mi
      resource: limits.memory
```

Include this block in every Deployment, CronJob, and Job template. The resource fields let applications self-tune (thread pools, buffer sizes, GC settings) based on their actual allocation.

---

## Environment variable ordering

Maintain a consistent ordering in the `env:` block across all templates:

1. **Downward API** — NAMESPACE, POD_NAME, POD_IP, HOST_IP, NODE_NAME, CPU/MEM request/limit
2. **Plain config values** — non-secret configuration set via `value:` (chain ID, batch sizes, topic names, feature flags)
3. **Secret references** — credentials via `secretKeyRef`, grouped by resource block (all DB_* together, all KAFKA_* together)

This ordering makes templates scannable — metadata at the top, config in the middle, secrets at the bottom.

---

## Scheduling fields

Every Deployment, StatefulSet, and CronJob template must include all five scheduling fields. Use `{{- with }}` + `toYaml` for list/map types and `{{- if }}` for scalars:

```gotmpl
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.topologySpreadConstraints }}
      topologySpreadConstraints:
        {{- tpl (toYaml .) $ | nindent 8 }}
      {{- end }}
      {{- if .Values.priorityClassName }}
      priorityClassName: {{ .Values.priorityClassName | quote }}
      {{- end }}
```

`topologySpreadConstraints` uses `tpl` so label selectors can reference chart helpers (e.g., `{{ include "my-chart.selectorLabels" . }}`). The other fields use plain `toYaml`.

All five fields must have corresponding empty defaults in `values.yaml`:

```yaml
nodeSelector: {}
affinity: {}
tolerations: []
topologySpreadConstraints: []
priorityClassName: ""
```

---

## Volumes and volumeMounts pass-through

Volumes and volumeMounts are defined in values and passed through with `toYaml`. The `defaults/values.yaml` layer typically adds the `/tmp` emptyDir; env overlays can add more:

```gotmpl
          {{- with .Values.volumeMounts }}
          volumeMounts:
            {{- toYaml . | nindent 12 }}
          {{- end }}
      # ... (at pod spec level)
      {{- with .Values.volumes }}
      volumes:
        {{- toYaml . | nindent 8 }}
      {{- end }}
```

The base `values.yaml` defines empty lists; `defaults/values.yaml` provides the operational baseline:

```yaml
# values.yaml
volumes: []
volumeMounts: []

# defaults/values.yaml
volumes:
  - emptyDir: {}
    name: tmp
volumeMounts:
  - name: tmp
    mountPath: /tmp
```

---

## Deployment strategy

### RollingUpdate (default — stateless HTTP services)

```yaml
strategy:
  rollingUpdate:
    maxSurge: 25%
    maxUnavailable: 25%
  type: RollingUpdate
```

Use for stateless workloads where multiple versions can coexist during deploy.

### Recreate (single-writer consumers)

```yaml
strategy:
  type: Recreate
```

Use when the workload cannot run two instances simultaneously — Kafka consumers with a single partition assignment, workers with exclusive locks, or processes that hold file locks. All old pods are terminated before new ones start.

Values shape (optional — only expose if the chart supports both):

```yaml
strategy:
  type: RollingUpdate
# strategy:
#   type: Recreate
```

---

## Liveness probe patterns

### HTTP services

Use named ports (`http`, `metrics`) in all `httpGet` probes. For standard values and anti-patterns (liveness ≠ readiness thresholds, slow-start `startupProbe`, TCP vs HTTP) see `kubernetes/resource-standards.md` — the canonical defaults apply here too.

### Non-HTTP workers (heartbeat file)

For background consumers, producers, and other non-HTTP workloads that have no endpoint to probe. The application writes a Unix timestamp to a heartbeat file periodically; the probe checks staleness:

```gotmpl
livenessProbe:
  exec:
    command:
      - /bin/sh
      - -c
      - test $(( $(date +%s) - $(cat /tmp/heartbeat) )) -lt {{ .Values.livenessProbe.maxAgeSeconds }}
  initialDelaySeconds: {{ .Values.livenessProbe.delays.initialDelaySeconds }}
  periodSeconds: {{ .Values.livenessProbe.delays.periodSeconds }}
  timeoutSeconds: {{ .Values.livenessProbe.delays.timeoutSeconds }}
  failureThreshold: {{ .Values.livenessProbe.delays.failureThreshold }}
```

Values shape:
```yaml
livenessProbe:
  maxAgeSeconds: 300
  delays:
    initialDelaySeconds: 10
    periodSeconds: 15
    timeoutSeconds: 10
    failureThreshold: 3
```

The heartbeat file (`/tmp/heartbeat`) requires a writable `/tmp` — pair with an `emptyDir` volume (see defaults layer).

---

## Defaults layer — operational baseline

`defaults/values.yaml` contains everything true for every cluster deployment. This is the canonical shape:

```yaml
imagePullSecrets:
  - name: registry-credentials

image:
  tag: ""    # set by CI — commit SHA or release tag
  digest: ""

podAnnotations:
  reloader.stakater.com/auto: "true"

podLabels:
  function: app
  env: dev
  region: ""
  provider: ""
  owner: ""

podSecurityContext:
  fsGroup: 2000
  runAsNonRoot: true
  seccompProfile:
    type: RuntimeDefault

securityContext:
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  runAsNonRoot: true
  runAsUser: 1000
```
---

## Deployment template skeleton

The canonical Deployment template wiring everything together. Adapt for your workload — this is the reference structure, not a copy-paste target:

```gotmpl
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-chart.fullname" . }}
  labels:
    {{- include "my-chart.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "my-chart.selectorLabels" . | nindent 6 }}
  {{- with .Values.strategy }}
  strategy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/secrets.yaml") . | sha256sum }}
        {{- with .Values.podAnnotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      labels:
        {{- include "my-chart.labels" . | nindent 8 }}
        {{- with .Values.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "my-chart.serviceAccountName" . }}
      {{- with .Values.podSecurityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .Chart.Name }}
          image: {{ include "my-chart.image" . }}
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          command: [...]
          {{- with .Values.securityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          env:
            # 1. Downward API metadata
            - name: NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            # ... (full downward API block — see section above)

            # 2. Plain config values
            - name: ENV
              value: {{ .Values.config.env | quote }}

            # 3. Secret references (grouped by resource block)
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  {{- if .Values.database.externalSecret.enable }}
                  name: {{ .Values.database.externalSecret.name }}
                  key: {{ .Values.database.externalSecret.userKey }}
                  {{- else }}
                  name: {{ include "my-chart.fullname" . }}-db
                  key: user
                  {{- end }}
          {{- with .Values.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          # Probes — HTTP depending on workload type
          livenessProbe:
            httpGet:
              path: /health
              port: http
          readinessProbe:
            httpGet:
              path: /ready
              port: http
          {{- with .Values.volumeMounts }}
          volumeMounts:
            {{- toYaml . | nindent 12 }}
          {{- end }}
      {{- with .Values.volumes }}
      volumes:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.topologySpreadConstraints }}
      topologySpreadConstraints:
        {{- tpl (toYaml .) $ | nindent 8 }}
      {{- end }}
      {{- if .Values.priorityClassName }}
      priorityClassName: {{ .Values.priorityClassName | quote }}
      {{- end }}
```

Key points:
- `replicas` guarded by `autoscaling.enabled` — when HPA is active, it controls replica count
- Config checksum annotation **before** `podAnnotations` merge so user annotations can override
- Labels include both chart labels and user `podLabels`
- Env vars follow the ordering convention: downward API → config → secrets
- Image uses the `my-chart.image` helper for tag+digest support

---

## Service template

```gotmpl
apiVersion: v1
kind: Service
metadata:
  name: {{ include "my-chart.fullname" . }}
  labels:
    {{- include "my-chart.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "my-chart.selectorLabels" . | nindent 4 }}
```

Values shape:
```yaml
service:
  type: ClusterIP
  port: 8080
```

Use named ports (`http`, `metrics`, `grpc`) — they're referenced by probes, ServiceMonitors, and HTTPRoutes. Only create a Service for workloads that receive traffic (HTTP APIs, gRPC services). Background consumers/producers don't need one.

---

## Multi-deployment charts

When a single chart deploys multiple components (frontend + backend + worker, or per-tenant deployments), organize templates by component and use annotations to distinguish them.

### When to use multi-deployment vs separate charts

| Pattern | Use when |
|---------|----------|
| **Multi-deployment single chart** | Components share lifecycle, values, and version. Deploy/rollback as one unit. Examples: frontend + backend + worker in a monorepo. |
| **Separate charts** | Components have independent lifecycles, separate teams, or different release cadences. Compose via ArgoCD ApplicationSet. |

### Folder structure

```
my-chart/
├── templates/
│   ├── _helpers.tpl
│   ├── frontend/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── hpa.yaml
│   │   └── httproute.yaml
│   ├── backend/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── hpa.yaml
│   │   └── httproute.yaml
│   ├── worker/
│   │   └── deployment.yaml
│   ├── shared/
│   │   ├── secrets.yaml
│   │   ├── serviceaccount.yaml
│   │   └── pdb.yaml
│   └── NOTES.txt
```

Group by component when each has multiple resources. Use `shared/` for resources used by all components (ServiceAccount, shared Secrets, NetworkPolicy).

### Component-scoped helpers

Extend `_helpers.tpl` with component-aware helpers:

```gotmpl
{{- define "my-chart.componentName" -}}
{{- $component := .component -}}
{{- if $component -}}
{{- printf "%s-%s" (include "my-chart.fullname" .root) $component | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- include "my-chart.fullname" .root -}}
{{- end -}}
{{- end -}}

{{- define "my-chart.componentLabels" -}}
{{ include "my-chart.labels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{- define "my-chart.componentSelectorLabels" -}}
{{ include "my-chart.selectorLabels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}
```

Usage in templates:

```gotmpl
# frontend/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-chart.componentName" (dict "root" . "component" "frontend") }}
  labels:
    {{- include "my-chart.componentLabels" (dict "root" . "component" "frontend") | nindent 4 }}
    {{- with .Values.frontend.podLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  selector:
    matchLabels:
      {{- include "my-chart.componentSelectorLabels" (dict "root" . "component" "frontend") | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "my-chart.componentLabels" (dict "root" . "component" "frontend") | nindent 8 }}
        {{- with .Values.frontend.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      annotations:
        {{- with .Values.frontend.podAnnotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
```

### Component label conventions

Standard labels for multi-component charts:

```yaml
labels:
  role: web | worker | cron | infra | data
  component-type: frontend | backend | api | consumer | producer | sidecar
  tier: presentation | application | data | cache
```

These labels help with:
- Filtering in dashboards and log aggregation (`kubectl get pods -l role=web`)
- Network policy rules (`role: web` can receive ingress, `role: worker` cannot)
- Cost allocation and chargeback
- Automated security scanning (different rules for `tier: presentation` vs `tier: data`)
- Label selectors in monitoring, backup policies, and other controllers

Place them in both `metadata.labels` (Deployment level) and `spec.template.metadata.labels` (Pod level) so they're available for selection at both the workload and pod level.

### Values structure for multiple components

```yaml
# Global settings shared by all components
image:
  repository: ghcr.io/example/myapp
  pullPolicy: IfNotPresent

imagePullSecrets:
  - name: registry-credentials

# Component-specific overrides
frontend:
  enabled: true
  replicaCount: 2
  image:
    tag: "v1.4.2"
  service:
    type: ClusterIP
    port: 3000
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
  podLabels:
    role: web
    component-type: frontend
    tier: presentation

backend:
  enabled: true
  replicaCount: 3
  image:
    tag: "v1.4.2"
  service:
    type: ClusterIP
    port: 8080
  resources:
    requests:
      cpu: 200m
      memory: 256Mi
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 20
  podLabels:
    role: web
    component-type: backend
    tier: application

worker:
  enabled: true
  replicaCount: 5
  image:
    tag: "v1.4.2"
  service:
    enabled: false  # workers don't serve traffic
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
  podLabels:
    role: worker
    component-type: consumer
    tier: application

# Shared configuration
database:
  host: postgres.default.svc.cluster.local
  port: "5432"
  externalSecret:
    enable: true
    name: my-app-db-credentials
```

### Component image helper

When components use different images or tags, extend the image helper:

```gotmpl
{{- define "my-chart.componentImage" -}}
{{- $component := .component -}}
{{- $componentConfig := index .root.Values $component -}}
{{- $globalImage := .root.Values.image -}}
{{- $repository := $componentConfig.image.repository | default $globalImage.repository -}}
{{- $tag := $componentConfig.image.tag | default $globalImage.tag | default .root.Chart.AppVersion -}}
{{- $digest := $componentConfig.image.digest | default $globalImage.digest -}}
{{- if $digest -}}
  {{- printf "%s:%s@%s" $repository $tag $digest -}}
{{- else -}}
  {{- printf "%s:%s" $repository $tag -}}
{{- end -}}
{{- end -}}
```

Usage:

```gotmpl
image: {{ include "my-chart.componentImage" (dict "root" . "component" "frontend") }}
```

### Disabling components

Guard each component's templates with an `enabled` flag:

```gotmpl
# frontend/deployment.yaml
{{- if .Values.frontend.enabled }}
apiVersion: apps/v1
kind: Deployment
...
{{- end }}
```

This allows per-environment component control:

```yaml
# dev/values.yaml
frontend:
  enabled: true
  replicaCount: 1

backend:
  enabled: true
  replicaCount: 1

worker:
  enabled: false  # disabled in dev
```

### Iteration pattern for homogeneous components

When deploying N identical components with different config (per-tenant, per-chain), use iteration instead of folders:

```gotmpl
# templates/tenant-deployments.yaml
{{- range $tenant, $config := .Values.tenants }}
{{- if $config.enabled }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-chart.fullname" $ }}-{{ $tenant }}
  labels:
    {{- include "my-chart.labels" $ | nindent 4 }}
    app.kubernetes.io/component: tenant
    tenant: {{ $tenant }}
    role: worker
    component-type: consumer
spec:
  replicas: {{ $config.replicaCount }}
  selector:
    matchLabels:
      {{- include "my-chart.selectorLabels" $ | nindent 6 }}
      tenant: {{ $tenant }}
  template:
    metadata:
      labels:
        {{- include "my-chart.labels" $ | nindent 8 }}
        tenant: {{ $tenant }}
        role: worker
        component-type: consumer
    spec:
      containers:
        - name: processor
          image: {{ include "my-chart.image" $ }}
          env:
            - name: TENANT_ID
              value: {{ $tenant | quote }}
            - name: TENANT_CONFIG
              value: {{ $config.endpoint | quote }}
          resources:
            {{- toYaml $config.resources | nindent 12 }}
{{- end }}
{{- end }}
```

Values:

```yaml
tenants:
  acme:
    enabled: true
    replicaCount: 2
    endpoint: "https://acme.example.com"
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
  globex:
    enabled: true
    replicaCount: 3
    endpoint: "https://globex.example.com"
    resources:
      requests:
        cpu: 200m
        memory: 256Mi
  initech:
    enabled: false  # disabled tenant
```

**Important:** Use `$` to reference the root context inside `range`. `.` inside the loop is the current iteration value.

### NOTES.txt for multi-component charts

Show status for each enabled component:

```gotmpl
{{- $fullName := include "my-chart.fullname" . -}}
Multi-component deployment: {{ $fullName }}

Enabled components:
{{- if .Values.frontend.enabled }}
- Frontend: {{ $fullName }}-frontend
  Port: {{ .Values.frontend.service.port }}
{{- end }}
{{- if .Values.backend.enabled }}
- Backend: {{ $fullName }}-backend
  Port: {{ .Values.backend.service.port }}
{{- end }}
{{- if .Values.worker.enabled }}
- Worker: {{ $fullName }}-worker (no service)
{{- end }}

Check status:
  kubectl get pods -l app.kubernetes.io/instance={{ .Release.Name }} -n {{ .Release.Namespace }}

View frontend logs:
  kubectl logs -l app.kubernetes.io/instance={{ .Release.Name }},app.kubernetes.io/component=frontend -n {{ .Release.Namespace }}
```

---

## Workload variants

### Deployment (default)

The standard workload type. Values include `replicaCount`, `service`, `ingress`/`httpRoute`, `autoscaling`, `pdb`, `metrics`. See the deployment template skeleton above.

### CronJob

For periodic batch workloads (reconcilers, cleanup jobs, reports). Different values shape — no `replicaCount`, `service`, `ingress`, `autoscaling`, `pdb`, or `metrics`:

```yaml
cron:
  schedule: "0 0,12 * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 2
  activeDeadlineSeconds: 1800
```

Template skeleton:
```gotmpl
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ include "my-chart.fullname" . }}
  labels:
    {{- include "my-chart.labels" . | nindent 4 }}
spec:
  schedule: {{ .Values.cron.schedule | quote }}
  concurrencyPolicy: {{ .Values.cron.concurrencyPolicy }}
  successfulJobsHistoryLimit: {{ .Values.cron.successfulJobsHistoryLimit }}
  failedJobsHistoryLimit: {{ .Values.cron.failedJobsHistoryLimit }}
  jobTemplate:
    spec:
      {{- if .Values.cron.activeDeadlineSeconds }}
      activeDeadlineSeconds: {{ .Values.cron.activeDeadlineSeconds }}
      {{- end }}
      backoffLimit: 1
      template:
        metadata:
          labels:
            {{- include "my-chart.labels" . | nindent 12 }}
            {{- with .Values.podLabels }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
          annotations:
            checksum/config: {{ include (print $.Template.BasePath "/secrets.yaml") . | sha256sum }}
            {{- with .Values.podAnnotations }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
        spec:
          restartPolicy: OnFailure
          {{- with .Values.imagePullSecrets }}
          imagePullSecrets:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          serviceAccountName: {{ include "my-chart.serviceAccountName" . }}
          {{- with .Values.podSecurityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          containers:
            - name: {{ .Chart.Name }}
              image: {{ include "my-chart.image" . }}
              imagePullPolicy: {{ .Values.image.pullPolicy }}
              command: [...]
              {{- with .Values.securityContext }}
              securityContext:
                {{- toYaml . | nindent 16 }}
              {{- end }}
              {{- with .Values.resources }}
              resources:
                {{- toYaml . | nindent 16 }}
              {{- end }}
              env:
                # ... downward API + config env vars + secretKeyRef blocks
              {{- with .Values.volumeMounts }}
              volumeMounts:
                {{- toYaml . | nindent 16 }}
              {{- end }}
          {{- with .Values.volumes }}
          volumes:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.nodeSelector }}
          nodeSelector:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.affinity }}
          affinity:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.tolerations }}
          tolerations:
            {{- toYaml . | nindent 12 }}
          {{- end }}
```

### Migration Job with Helm hooks

For database migrations that must run before the application starts. Uses Helm hook ordering:

```gotmpl
{{- if .Values.migrate.enabled }}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "my-chart.fullname" . }}-migrate
  annotations:
    "helm.sh/hook": post-install,pre-upgrade
    "helm.sh/hook-weight": "0"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  backoffLimit: {{ .Values.migrate.backoffLimit }}
  ttlSecondsAfterFinished: {{ .Values.migrate.ttlSecondsAfterFinished }}
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: migrate
          image: {{ include "my-chart.image" . }}
          command: [...]
          env:
            # credentials via secretKeyRef — same toggle pattern
```

When the migration needs admin credentials (separate from app credentials), create a hook-ordered admin Secret:

```gotmpl
{{- if and .Values.migrate.enabled (not .Values.database.admin.externalSecret.enable) }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "my-chart.fullname" . }}-db-admin
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "-10"
    "helm.sh/hook-delete-policy": before-hook-creation
type: Opaque
stringData:
  user: {{ .Values.database.admin.user | quote }}
  password: {{ .Values.database.admin.password | quote }}
{{- end }}
```

Hook weight `-10` ensures the admin Secret exists before the migrate Job (weight `0`) starts.

Values shape:
```yaml
migrate:
  enabled: false
# migrate:
#   enabled: true
#   backoffLimit: 1
#   ttlSecondsAfterFinished: 600
```

---

## Validation patterns for CRD templates

When a chart templates operator CRDs with user-provided lists (topics, users, ACLs), use `required` and `fail` to catch misconfigurations at render time:

### required — mandatory fields

```gotmpl
{{- $cluster := required "Values.clusterName is required" .Values.clusterName -}}

{{- range $t := .Values.topics.list }}
---
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: {{ required "topic.name is required" $t.name | quote }}
  labels:
    strimzi.io/cluster: {{ $cluster | quote }}
spec:
  partitions: {{ default 1 $t.partitions }}
  replicas: {{ default 3 $t.replicas }}
{{- end }}
```

### fail — conditional validation

```gotmpl
{{- range .authorization.acls }}
  {{- if and (ne .resource.type "cluster") (not (hasKey .resource "name")) }}
    {{- fail "acl.resource.name is required for non-cluster resource types" }}
  {{- end }}
{{- end }}
```

Use `required` for single mandatory fields. Use `fail` for cross-field validation where the condition is more complex than a nil check.

---

## Observability — monitoring templates

### PodMonitor

```gotmpl
{{- if and .Values.metrics.enabled .Values.metrics.podMonitor.enabled }}
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: {{ include "my-chart.fullname" . }}
  labels:
    {{- include "my-chart.labels" . | nindent 4 }}
    {{- with .Values.metrics.podMonitor.additionalLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  {{- with .Values.metrics.podMonitor.jobLabel }}
  jobLabel: {{ . }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "my-chart.selectorLabels" . | nindent 6 }}
  podMetricsEndpoints:
    - port: metrics
      interval: {{ .Values.metrics.podMonitor.interval }}
      {{- with .Values.metrics.podMonitor.scrapeTimeout }}
      scrapeTimeout: {{ . }}
      {{- end }}
      honorLabels: {{ .Values.metrics.podMonitor.honorLabels }}
{{- end }}
```

### ServiceMonitor

```gotmpl
{{- if and .Values.metrics.enabled .Values.metrics.serviceMonitor.enabled }}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ include "my-chart.fullname" . }}
  labels:
    {{- include "my-chart.labels" . | nindent 4 }}
    {{- with .Values.metrics.serviceMonitor.additionalLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  selector:
    matchLabels:
      {{- include "my-chart.selectorLabels" . | nindent 6 }}
  endpoints:
    - port: metrics
      interval: {{ .Values.metrics.serviceMonitor.interval }}
      honorLabels: {{ .Values.metrics.serviceMonitor.honorLabels }}
      {{- with .Values.metrics.serviceMonitor.relabelings }}
      relabelings:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.metrics.serviceMonitor.metricRelabelings }}
      metricRelabelings:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end }}
```

### PrometheusRule

```gotmpl
{{- if and .Values.metrics.enabled .Values.metrics.prometheusRule.enabled }}
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: {{ include "my-chart.fullname" . }}
  labels:
    {{- include "my-chart.labels" . | nindent 4 }}
    {{- with .Values.metrics.prometheusRule.additionalLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  groups:
    - name: {{ include "my-chart.fullname" . }}
      rules:
        {{- toYaml .Values.metrics.prometheusRule.rules | nindent 8 }}
{{- end }}
```

### Values shape for all three

```yaml
metrics:
  enabled: false
  podMonitor:
    enabled: false
    interval: 30s
    scrapeTimeout: ""
    honorLabels: false
    jobLabel: ""
    additionalLabels: {}
  serviceMonitor:
    enabled: false
    interval: 30s
    honorLabels: false
    relabelings: []
    metricRelabelings: []
    additionalLabels: {}
  prometheusRule:
    enabled: false
    additionalLabels: {}
    rules: []
# metrics:
#   enabled: true
#   podMonitor:
#     enabled: true
#     interval: 30s
#     additionalLabels:
#       release: prometheus
#   prometheusRule:
#     enabled: true
#     additionalLabels:
#       release: prometheus
#     rules:
#       - alert: HighErrorRate
#         expr: rate(http_errors_total{job="my-chart"}[5m]) > 0.05
#         for: 10m
#         labels:
#           severity: warning
```

Use `podMonitor` for workloads without a Service (background consumers/producers). Use `serviceMonitor` for workloads with a Service (HTTP APIs). Both are behind `metrics.enabled` as a top-level gate.

---

## HPA template

```gotmpl
{{- if .Values.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "my-chart.fullname" . }}
  labels:
    {{- include "my-chart.labels" . | nindent 4 }}
    {{- with .Values.autoscaling.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with .Values.autoscaling.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "my-chart.fullname" . }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
    {{- if .Values.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if .Values.autoscaling.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetMemoryUtilizationPercentage }}
    {{- end }}
    {{- with .Values.autoscaling.metrics }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with .Values.autoscaling.behavior }}
  behavior:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
```

The template supports both shorthand (`targetCPUUtilizationPercentage`) and full custom `metrics` and `behavior` blocks. When both are present, they merge — the shorthand CPU/memory metrics come first, followed by any custom metrics.

---

## PDB template

```gotmpl
{{- if .Values.pdb.enabled }}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "my-chart.fullname" . }}
  labels:
    {{- include "my-chart.labels" . | nindent 4 }}
    {{- with .Values.pdb.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with .Values.pdb.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if .Values.pdb.maxUnavailable }}
  maxUnavailable: {{ .Values.pdb.maxUnavailable }}
  {{- else }}
  minAvailable: {{ .Values.pdb.minAvailable | default 1 }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "my-chart.selectorLabels" . | nindent 6 }}
{{- end }}
```

The PDB selector must use the same `selectorLabels` as the Deployment. Don't add extra labels (like `app.kubernetes.io/component`) to the PDB selector unless they're also set on the pod template — a mismatch means the PDB silently protects nothing.

---

## Gateway API — HTTPRoute

For clusters running a Gateway API implementation (Envoy Gateway, Istio, etc.). Alongside or instead of traditional Ingress:

```gotmpl
{{- range $name, $route := .Values.route }}
  {{- if $route.enabled }}
---
apiVersion: {{ $route.apiVersion | default "gateway.networking.k8s.io/v1" }}
kind: {{ $route.kind | default "HTTPRoute" }}
metadata:
  name: {{ include "my-chart.fullname" $ }}{{ if ne $name "main" }}-{{ $name }}{{ end }}
  labels:
    {{- include "my-chart.labels" $ | nindent 4 }}
  {{- with $route.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- with $route.parentRefs }}
  parentRefs:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $route.hostnames }}
  hostnames:
    {{- tpl (toYaml .) $ | nindent 4 }}
  {{- end }}
  rules:
    {{- range $rule := $route.rules }}
    - backendRefs:
        - group: ""
          kind: Service
          name: {{ $rule.backendRef.name | default (include "my-chart.fullname" $) }}
          port: {{ $rule.backendRef.port | default $.Values.service.port }}
          weight: 1
      {{- with $rule.matches }}
      matches:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $rule.filters }}
      filters:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    {{- end }}
{{- end }}
{{- end }}
```

Values shape:
```yaml
route:
  main:
    enabled: false
#   enabled: true
#   parentRefs:
#     - name: gateway
#       namespace: envoy-gateway-system
#   hostnames:
#     - "api.example.com"
#   rules:
#     - matches:
#         - path:
#             type: PathPrefix
#             value: /
```

The `range` over `$name, $route` supports multiple named routes per chart (e.g., `main`, `internal`, `admin`). The route named `main` omits the suffix from the resource name.

---

## Operational labels

Define organizational labels in `defaults/values.yaml` via `podLabels`. These are used for cost allocation, filtering in dashboards, and policy enforcement:

```yaml
podLabels:
  function: app          # app, worker, cron, infra
  env: dev               # dev, staging, prod
  region: ""             # cloud region or datacenter
  provider: ""           # cloud provider or hosting
  owner: ""              # team or individual
```

These are distinct from the Kubernetes recommended labels in `_helpers.tpl` (`app.kubernetes.io/*`), which identify the application. Operational labels identify the deployment context.

---

## ServiceAccount template

```gotmpl
{{- if .Values.serviceAccount.create -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "my-chart.serviceAccountName" . }}
  labels:
    {{- include "my-chart.labels" . | nindent 4 }}
  {{- with .Values.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
automountServiceAccountToken: {{ .Values.serviceAccount.automount }}
{{- end }}
```

---

## Patterns checklist

In addition to the foundations checklist in `SKILL.md`:

- [ ] Image helper supports tag, digest, and tag+digest (`repo:tag@sha256:...`)
- [ ] Every credential block has `externalSecret.enable` toggle with configurable `name` and key fields
- [ ] Chart-internal Secrets rendered only when `externalSecret.enable: false`
- [ ] `secretKeyRef` env vars switch between external and chart-internal name/key
- [ ] Secret suffixes match values block names (`-db`, `-kafka`, `-node`)
- [ ] Config checksum annotation on pod template
- [ ] Reloader annotation in `defaults/values.yaml` via `podAnnotations`
- [ ] Downward API metadata env vars present (NAMESPACE, POD_NAME, POD_IP, HOST_IP, NODE_NAME, CPU/MEM request/limit)
- [ ] Env var ordering: downward API → config values → secret references
- [ ] All five scheduling fields in every workload template (nodeSelector, affinity, tolerations, topologySpreadConstraints, priorityClassName)
- [ ] Volumes and volumeMounts pass-through with `toYaml`
- [ ] Deployment strategy appropriate for workload type (RollingUpdate vs Recreate)
- [ ] Liveness probe appropriate for workload type (HTTP or heartbeat file)
- [ ] `defaults/values.yaml` sets security context, pull secrets, reloader annotation, `/tmp` emptyDir
- [ ] PDB selector uses `selectorLabels` — matches Deployment selector exactly
- [ ] HPA wires both shorthand and custom `metrics`/`behavior`
- [ ] Monitoring templates (PodMonitor/ServiceMonitor/PrometheusRule) behind `metrics.enabled` gate
- [ ] Migration Jobs use correct hook weight ordering (Secret before Job)
- [ ] CRD templates use `required` and `fail` for input validation
- [ ] Service uses named ports (`http`, `metrics`, `grpc`)
- [ ] No duplicate template blocks (e.g., tolerations rendered twice)
- [ ] Image tag pinned (no `:latest` in committed manifests)
- [ ] No literal credentials in env overlays — ExternalSecret references only
- [ ] `automountServiceAccountToken: false` unless the workload calls the API server

**Multi-deployment charts:**

- [ ] Templates organized in component folders (`frontend/`, `backend/`, `worker/`, `shared/`)
- [ ] Component-scoped helpers defined: `componentName`, `componentLabels`, `componentSelectorLabels`
- [ ] `app.kubernetes.io/component` label present on all multi-component resources
- [ ] Component labels defined: `role`, `component-type`, `tier` (both Deployment and Pod level)
- [ ] Each component has `enabled: false` toggle for per-environment control
- [ ] Component values nested under component name (`.Values.frontend.*`, `.Values.backend.*`)
- [ ] `componentImage` helper supports per-component image/tag overrides with global fallback
- [ ] NOTES.txt shows status for each enabled component
- [ ] For iteration pattern: use `$` for root context inside `range` loops
- [ ] Component selectors include component identifier (label or tenant name) for proper isolation
