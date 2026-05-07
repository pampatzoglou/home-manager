# Skaffold (services repo, local dev)

This file documents how `skaffold.yaml` is set up in services repos for local development against a `kind` cluster. Read this when:

- The user is creating a new services repo and needs a working `skaffold.yaml`
- The user is trying to get hot-reload / fast inner-loop on a service
- A `skaffold dev` invocation is failing or doing the wrong thing

## What it's for

Skaffold gives developers a tight inner loop: edit code → image rebuilds → kind picks up the new image → pod rolls. It's **only for local dev against `kind`**. It is not used for the dev cluster, testing, or prod — those go through ArgoCD off committed manifests.

## Mental model

The local dev workflow looks like:

```
developer machine
├── kind cluster (local k8s)
└── docker daemon (kind shares this for sideloading)
```

Skaffold:
1. Builds the image with the local docker daemon
2. **Sideloads** it into kind (`kind load docker-image …`) — no registry push
3. Renders the Helm chart with dev values
4. Applies the manifests to the kind cluster
5. Watches source files; on change, rebuilds and re-applies

No registry is involved in this loop. The `local.push: false` setting plus `loadImages: true` (or kind's built-in mechanism) makes this work.

## Canonical skaffold.yaml

```yaml
apiVersion: skaffold/v4beta11
kind: Config
metadata:
  name: my-service

build:
  local:
    push: false              # don't push — we sideload to kind
    useBuildkit: true
  artifacts:
    - image: my-service       # local image name; no registry prefix needed for kind
      context: .
      docker:
        dockerfile: Dockerfile
      sync:
        # Optional: sync specific files into the running container without rebuild.
        # Match the language's hot-reload-capable directories.
        # infer: ["**/*.{go,ts,py,rs}"]
        manual: []

manifests:
  helm:
    releases:
      - name: my-service
        chartPath: deploy/charts/my-service
        # Skaffold layers values files in order — same precedence as task template.
        valuesFiles:
          - deploy/charts/my-service/values.yaml
          - deploy/charts/my-service/defaults/values.yaml
          - deploy/charts/my-service/dev/values.yaml
        # setValueTemplates lets skaffold inject the freshly-built image tag.
        setValueTemplates:
          image.repository: '{{.IMAGE_REPO_my_service}}'
          image.tag: '{{.IMAGE_TAG_my_service}}'

deploy:
  kubeContext: kind-dev       # require the kind context — fail fast if pointed elsewhere

# Profiles below are optional — only include them if the chart uses a third-axis overlay
# (per-region, per-tenant, etc., as described in taskfile.md "Optional extensions").
# Each profile patches in an additional values file matching the overlay value.
#
# profiles:
#   - name: <overlay-value>
#     patches:
#       - op: add
#         path: /manifests/helm/releases/0/valuesFiles/-
#         value: deploy/charts/my-service/dev/<overlay-value>.yaml
```

## Required prerequisites on the developer machine

The skaffold flow assumes:

- `kind` is installed and a cluster named `dev` exists (`kind create cluster --name dev`)
- `kubectl` is configured with the `kind-dev` context
- `docker` daemon is running and accessible
- Pinned versions of `skaffold`, `helm`, `kind`, `kubectl` come from devbox — see `devbox.md`

If the user runs `skaffold dev` and gets "context not found" or wrong-context errors, that's the first thing to check.

## Image naming

Use a bare local name (`my-service`, no registry). The chart's `dev/values.yaml` should have `image.repository: my-service` and `imagePullPolicy: IfNotPresent` so kind serves the sideloaded image.

If `defaults/values.yaml` sets `imagePullSecrets` for the real registry, override that in `dev/values.yaml`:
```yaml
imagePullSecrets: []
image:
  repository: my-service     # local-only name
  tag: latest
  pullPolicy: IfNotPresent
```

## Common usage

```bash
# One-shot: build + deploy + tail logs
skaffold dev

# Build + deploy without watching (good for CI or scripts)
skaffold run

# Just render the manifests skaffold would apply, without applying
skaffold render

# Tear it all down
skaffold delete

# With an overlay profile (only if the chart has overlay variants)
skaffold dev -p <overlay-value>
```

## Behavior notes and gotchas

- **Skaffold's helm renderer is independent of `task template`.** Both wrap helm, but they're separate code paths. If `task template ENV=dev` works and `skaffold dev` doesn't, the discrepancy is usually a values file ordering issue or a `setValueTemplates` mismatch. Check the rendered output: `skaffold render | less`.
- **Sideloading takes a few seconds per rebuild.** If hot-reload feels slow, check the image size — multi-stage builds with a slim runtime stage matter more here than in CI. Also consider `sync.manual` for source-only changes that don't need a rebuild.
- **Skaffold doesn't know about ArgoCD.** Anything `skaffold dev` puts in the cluster will be torn down by ArgoCD if the same namespace is being reconciled — keep the local kind cluster separate from anything ArgoCD watches.
- **Profiles are not environments.** Skaffold profiles are for variations of local dev (overlay variant selection, debug builds, etc.). Don't use a profile to "deploy to prod" — that path goes through git + ArgoCD.

## When skaffold isn't the right tool

If the user wants to:
- **Render manifests for a PR check** → use `task template`
- **Test against the real dev cluster** → push a branch and let ArgoCD sync it, or use `kubectl apply -f .argo/<chart>/` against the dev cluster directly with appropriate caution
- **Run unit tests** → that's the language's test runner via `task test` or `make test`, not skaffold

Skaffold's job ends at the kind cluster boundary.
