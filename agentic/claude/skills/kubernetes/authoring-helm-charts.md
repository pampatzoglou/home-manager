# Authoring Helm Charts — Kubernetes specifics

See the shared `helm` skill for chart anatomy, values file layering, `_helpers.tpl` patterns, template techniques (`extraObjects`, secrets as file mounts), and local validation. This file covers the Kubernetes-specific requirements that every chart must satisfy on top of those foundations.

## Resource standards in every workload

Every container in every chart must satisfy `resource-standards.md`:

- **Security context** at both pod and container level: `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`, `readOnlyRootFilesystem: true` (with `emptyDir` mounts as needed)
- **Resources**: explicit `requests` and `limits` on all containers including init containers and sidecars
- **Probes**: `readinessProbe` and `livenessProbe` on all long-running containers; `startupProbe` for slow starters
- **HA**: `PodDisruptionBudget` and `topologySpreadConstraints` when `replicaCount >= 2`

See `resource-standards.md` for the exact YAML patterns and guidance.

## ExternalSecret wiring

Use the `externalSecret.enable` toggle pattern from the `helm` skill with `external-secrets` as the cluster-side provider. In env overlays:

```yaml
# dev/values.yaml or prod/values.yaml
config:
  database:
    externalSecret:
      enable: true
      name: my-service-db-credentials    # name of the ExternalSecret resource
```

The chart-internal placeholder Secret (rendered when `enable: false`) is for `task template` and `skaffold dev` only — it is never deployed to a real cluster.

## Reloader annotation

Add to every Deployment or StatefulSet that mounts Secrets or ConfigMaps so that rotation and config changes trigger a rolling restart automatically:

```yaml
metadata:
  annotations:
    reloader.stakater.com/auto: "true"
```

## Prefer task template over raw helm

Always use `task template ENV=dev` (or `task template ENV=prod`) rather than raw `helm template` when validating locally — it uses the exact same values-file precedence as CI and ArgoCD, eliminating "works locally, breaks in CI" surprises.

## Kubernetes completion checklist

In addition to the `helm` skill's completion checklist, verify:

- [ ] Every container has `securityContext` at both pod and container level (see `resource-standards.md`)
- [ ] Every container has explicit `resources.requests` and `resources.limits`
- [ ] Every long-running container has `readinessProbe` and `livenessProbe`
- [ ] `replicaCount >= 2` → PDB exists and topology spread is configured
- [ ] No literal credentials anywhere — ExternalSecret references only in env overlays
- [ ] `reloader.stakater.com/auto: "true"` on workloads that mount Secrets or ConfigMaps
- [ ] Image tag pinned (no `:latest`)
- [ ] `automountServiceAccountToken: false` unless the workload calls the API server
