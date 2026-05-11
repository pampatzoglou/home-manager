# Skaffold — Kubernetes services repo

See the shared `skaffold` skill for base setup (canonical `skaffold.yaml`, kind cluster lifecycle via devbox scripts, image naming, and common usage). This file covers chart-specific configuration for the services repo layout.

## Values ordering must match task template

The `valuesFiles` list must use the same precedence order as `task template ENV=dev`:

```yaml
valuesFiles:
  - deploy/charts/my-service/values.yaml
  - deploy/charts/my-service/defaults/values.yaml
  - deploy/charts/my-service/dev/values.yaml
```

If `task template ENV=dev` works but `skaffold dev` doesn't, the discrepancy is almost always a values file ordering or missing file issue. Use `skaffold render | less` to inspect what skaffold actually produces.

## dev/values.yaml overrides for kind

```yaml
image:
  repository: my-service    # bare local name, matches the skaffold artifact name
  pullPolicy: IfNotPresent  # use what's sideloaded — don't pull from registry
imagePullSecrets: []        # disable registry pull secrets set in defaults/values.yaml
```

## Third-axis overlay profiles (optional)

For charts with a third-axis overlay (chain, region, tenant — see `conventions.md`), add a Skaffold profile that appends the overlay values file:

```yaml
profiles:
  - name: <overlay-value>
    patches:
      - op: add
        path: /manifests/helm/releases/0/valuesFiles/-
        value: deploy/charts/my-service/dev/<overlay-value>.yaml
```

Activate with `skaffold dev -p <overlay-value>`. Profiles are local dev variations only — never use them to target real clusters.
