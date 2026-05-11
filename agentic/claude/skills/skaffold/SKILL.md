---
name: skaffold
description: Skaffold + kind for local development inner loop. Image sideloading to kind without a registry, canonical skaffold.yaml, devbox cluster scripts, and when skaffold is and isn't the right tool.
user-invocable: true
requires: [devbox, helm]
---

# Skaffold (local dev with kind)

## Load first

Before starting, load these skills:

- `devbox` — tool pinning, `.envrc`, cluster lifecycle scripts (`cluster:up`, `cluster:reset`)
- `helm` — chart structure and values layering that `valuesFiles` must match exactly

Skaffold provides the inner dev loop: edit → rebuild → kind picks up the new image → pod rolls. It targets a local `kind` cluster only. All other environments go through ArgoCD off committed manifests.

## Mental model

```
developer machine
├── kind cluster   (local k8s, managed via devbox scripts)
└── docker daemon  (shared with kind for image sideloading)
```

Loop:
1. Build image locally with docker
2. **Sideload** into kind (`kind load docker-image`) — no registry push, no round-trip
3. Render Helm chart with dev values
4. Apply rendered manifests to kind cluster
5. Watch source for changes → repeat

## Prerequisites

Add to `devbox.json`:

```json
{
  "packages": ["skaffold@2.16", "kind@0.27", "helm@3.16", "kubectl@1.33"],
  "shell": {
    "scripts": {
      "cluster:up":    "kind create cluster --name dev --config kind.yaml",
      "cluster:down":  "kind delete cluster --name dev",
      "cluster:reset": "devbox run cluster:down && devbox run cluster:up"
    }
  }
}
```

Each developer runs `devbox run cluster:up` once. The cluster persists between sessions until explicitly deleted.

See the `devbox` skill for `.envrc` setup and general devbox usage.

## Canonical skaffold.yaml

```yaml
apiVersion: skaffold/v4beta11
kind: Config
metadata:
  name: my-service

build:
  local:
    push: false           # sideload to kind, never push to a registry
    useBuildkit: true
  artifacts:
    - image: my-service   # bare local name — no registry prefix needed for kind
      context: .
      docker:
        dockerfile: Dockerfile
      sync:
        manual: []        # add infer patterns here for hot-reload without full rebuild

manifests:
  helm:
    releases:
      - name: my-service
        chartPath: deploy/charts/my-service
        valuesFiles:
          - deploy/charts/my-service/values.yaml
          - deploy/charts/my-service/defaults/values.yaml
          - deploy/charts/my-service/dev/values.yaml
        setValueTemplates:
          image.repository: '{{.IMAGE_REPO_my_service}}'
          image.tag: '{{.IMAGE_TAG_my_service}}'

deploy:
  kubeContext: kind-dev   # fail fast if pointed at the wrong cluster
```

## Image naming for kind

Use a bare local name (`my-service`, no registry prefix). In `dev/values.yaml`, override image settings so kind serves the sideloaded image:

```yaml
image:
  repository: my-service    # matches the artifact image name above
  pullPolicy: IfNotPresent  # use what's sideloaded — don't pull
imagePullSecrets: []        # disable registry pull secrets from defaults/
```

## Common usage

```bash
skaffold dev      # build + deploy + watch + tail logs (primary inner loop)
skaffold run      # one-shot build + deploy without watching
skaffold render   # render manifests skaffold would apply, without applying
skaffold delete   # tear down what skaffold deployed
```

## Behavior notes

- **Values ordering must match `task template`** — if `task template ENV=dev` works but `skaffold dev` doesn't, check that `valuesFiles` are in the same order with the same files.
- **Sideloading takes a few seconds per rebuild.** Use multi-stage Dockerfiles and `sync.infer` for source-only changes that don't need a full rebuild.
- **Skaffold doesn't know about ArgoCD.** Resources placed in the kind cluster are unrelated to what ArgoCD reconciles — keep the kind cluster in separate namespaces.
- **Profiles are for local dev variations** (overlay selection, debug builds), not for targeting different clusters.

## When skaffold isn't the right tool

| Goal | Use instead |
|---|---|
| Render manifests for a PR check | `task template ENV=<env>` |
| Test against the real dev/staging cluster | Push branch, let ArgoCD sync |
| Run unit or integration tests | `task test` via language test runner |
| Deploy to any cluster ArgoCD manages | Commit + ArgoCD sync |

## Companion skills — offer after completing

When skaffold setup is done, check the repo and offer whichever of these are missing or incomplete:

| Skill | Offer when |
|-------|-----------|
| `helm` | No Helm chart exists alongside the skaffold config |
| `devbox` | No `devbox.json` in the repo root |
| `document` | No `docs/ARCHITECTURE.md` or README doesn't describe the local dev loop |

Ask as a single grouped question — not mid-task, not separately for each.
