# Devbox — Kubernetes tooling

See the shared `devbox` skill for base setup (`.envrc` with `eval "$(devbox generate direnv --print-envrc)"`, `devbox.json` structure, pinning strategy, and CI integration). This file covers Kubernetes-specific packages and cluster lifecycle scripts.

## Packages to pin

```json
{
  "packages": [
    "go-task@3.40",
    "helm@3.16",
    "kubectl@1.33",
    "kind@0.27",
    "skaffold@2.16",
    "kubeconform@0.7",
    "kubescape@3",
    "yq-go@4.45",
    "jq@1.7"
  ]
}
```

Versions are illustrative — pick the latest stable at repo creation, then update deliberately via `devbox update`.

## Cluster lifecycle scripts

Add to `devbox.json` `shell.scripts`:

```json
"shell": {
  "init_hook": [
    "echo \"devbox ready — helm $(helm version --short 2>/dev/null), kubectl $(kubectl version --client --short 2>/dev/null | head -1)\""
  ],
  "scripts": {
    "cluster:up":    "kind create cluster --name dev --config kind.yaml",
    "cluster:down":  "kind delete cluster --name dev",
    "cluster:reset": "devbox run cluster:down && devbox run cluster:up"
  }
}
```

Usage:
```bash
devbox run cluster:up     # create the kind cluster (once per machine)
devbox run cluster:reset  # tear down and recreate
```
