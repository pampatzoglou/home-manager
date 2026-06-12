---
name: docker-compose
description: Author docker-compose.yaml for the local development inner loop, built to mirror how the workload runs in Kubernetes. Use when adding or editing a compose file, setting up local dev for a service, or running docker compose up. Every service gets named volumes (like PVCs/emptyDir), file-based secrets mounted at /run/secrets/<name> via the *_FILE / FILE__ env convention (identical to mounted k8s Secrets so app code is unchanged dev↔prod), and a securityContext-equivalent hardening block (read_only, tmpfs, cap_drop, no-new-privileges, non-root user). Triggers on docker-compose, compose.yaml, docker compose, "local dev environment", "run it locally".
user-invocable: true
requires: [dockerfile]
---

# docker-compose for local dev (Kubernetes-parity)

Generate a `docker-compose.yaml` for the local inner loop that behaves like the in-cluster deployment, so "works on my machine" means "works in the cluster." The bridge is built from three things every service must have: **file-based secrets at the k8s paths**, **named volumes**, and a **security block that maps to a pod `securityContext`**.

## Why parity matters

The app should read secrets, write state, and run under the same constraints locally as in production. If a secret is an env var locally but a mounted file in k8s, the app needs two code paths. Make local match prod instead.

| Local dev (compose) | Kubernetes equivalent | Why it must match |
|---|---|---|
| `secrets:` `file:` + per-service `target: /run/secrets/x` | mounted `Secret` / ExternalSecret volume | identical in-container path → no code change |
| `*_FILE` / `FILE__` env pointing at `/run/secrets/x` | same `*_FILE` env in the chart | app reads the secret the same way both places |
| named volume / bind mount | PVC (or `hostPath`) | persistent state survives restarts |
| `tmpfs:` | `emptyDir` (memory) | writable scratch when the rootfs is read-only |
| `read_only: true` | `readOnlyRootFilesystem: true` | immutable rootfs catches accidental writes early |
| `cap_drop: [ALL]` + minimal `cap_add` | `capabilities: { drop: [ALL], add: [...] }` | least privilege, same set |
| `security_opt: [no-new-privileges:true]` | `allowPrivilegeEscalation: false` | no privilege escalation |
| `user: "65532:65532"` | `runAsUser` / `runAsGroup` (+ `runAsNonRoot`) | same non-root UID — sourced from the Dockerfile's `USER` |
| `security_opt: [seccomp:...]` | `seccompProfile.type: RuntimeDefault` | same syscall filter |
| `healthcheck:` | readiness / liveness probe | same definition of "ready" |
| `networks:` (frontend/backend) | NetworkPolicy / namespace boundaries | segment traffic the same way |
| `expose:` vs `ports:` | ClusterIP vs NodePort / Ingress | only publish what truly needs the host |

Keep the secret paths and the capability set **the same** as the `kubernetes`/`helm` skills' `resource-standards.md` — that consistency is the whole point. The UID has a single source of truth: the Dockerfile (see below).

## Secrets — always from files, never inline

Define secrets once at the top level from files, then mount each into the services that need it at the **same path the chart uses** (`/run/secrets/<name>`). Never put a secret in `environment:` as a literal.

```yaml
secrets:
  db_password:
    file: ./secrets/db_password        # gitignored; one secret per file, no trailing newline
  api_token:
    file: ./secrets/api_token
```

Per service, mount it and point the app at the file with the `*_FILE` convention (most images support either `FOO_FILE=/run/secrets/foo` or the linuxserver `FILE__FOO=...` form):

```yaml
    environment:
      - DATABASE_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - source: db_password
        target: /run/secrets/db_password
```

**Where the files come from.** `./secrets/` is gitignored and populated locally — ideally from the **same Vault paths the cluster reads via ExternalSecret** (see the `helm` skill's credential blocks and the `devbox` skill's Vault init). A small task can materialise them so dev and prod resolve identical keys:

```sh
# task secrets:files — write Vault values to the files compose mounts
mkdir -p secrets && chmod 700 secrets
vault kv get -field=password secret/myapp/dev > secrets/db_password
vault kv get -field=token    secret/myapp/dev > secrets/api_token
chmod 600 secrets/*
```

`.gitignore`:

```gitignore
# Local dev secret material — never commit
secrets/
```

## Volumes — every service that has state gets one

- **Named volumes** for persistent state (`name:/path`) — the PVC equivalent.
- **Read-only bind mounts** for config you edit in the repo (`./config/app:/etc/app:ro`) — the ConfigMap equivalent; `:ro` mirrors a read-only mount.
- **`tmpfs`** for writable scratch when `read_only: true` is set — the `emptyDir` equivalent. These writable paths are the **same ones the Dockerfile declares as `VOLUME`** (the single source of truth) and the chart mounts as `emptyDir` — keep all three in sync. List every path the app writes at runtime (`/tmp`, `/run`, framework caches).

```yaml
volumes:
  app_data:                 # plain named volume — portable across machines
  db_data:
# Bind a host directory only when the data lives outside the project
# (the local stand-in for a hostPath PV — avoid in shareable composes):
#  media:
#    driver: local
#    driver_opts: { type: none, o: bind, device: /srv/media }
```

Prefer plain named volumes in a shareable compose; reserve host `bind` devices for machine-specific data (it's the `hostPath` of compose — not portable).

## Per-service hardening — the securityContext block

Apply this to every service by default; relax only with a comment explaining why (the NAS reference does exactly this — e.g. pihole omits `no-new-privileges` because `pihole-FTL` needs `setcap`).

```yaml
    read_only: true
    tmpfs:
      - /tmp
      - /run
    user: "65532:65532"               # the Dockerfile's USER — see "One UID" below
    cap_drop: [ALL]
    cap_add: []                       # add back only what's proven necessary
    security_opt:
      - no-new-privileges:true
```

### One UID, defined in the Dockerfile

The non-root UID is **declared once, in the Dockerfile's `USER`** (the `dockerfile` skill: a created `app` user, or distroless `nonroot` = `65532`). Everything else mirrors it — there is no second place to "decide" the UID:

```
Dockerfile  USER 65532
   ├── docker-compose   user: "65532:65532"
   └── Helm chart       runAsUser: 65532   runAsGroup: 65532   fsGroup: 65532
```

If they drift, the same image runs as different users in each environment and file ownership on the mounted volume breaks. When you change the Dockerfile user, update both the compose `user:` and the chart values in the same commit.

**Third-party images set their own UID** — you don't own their Dockerfile, so use the UID that image ships and document it: `postgres` runs as `999`, `mariadb` as a `mysql` user, linuxserver images take `PUID`/`PGID` (commonly `1000`) via env. Match *that* image's expectation, not your app's `65532`.

## Canonical example

One app (built from the `dockerfile` skill's `develop` target) plus its database — every pattern above in context:

```yaml
name: myapp

secrets:
  db_password:
    file: ./secrets/db_password

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true                    # no host egress — like a backend NetworkPolicy

volumes:
  db_data:

services:
  app:
    build:
      context: .
      target: develop                 # the dockerfile skill's hot-reload stage
    restart: unless-stopped
    read_only: true
    tmpfs: [/tmp, /run]
    user: "65532:65532"               # = Dockerfile USER = chart runAsUser
    cap_drop: [ALL]
    security_opt: [no-new-privileges:true]
    networks: [frontend, backend]
    depends_on:
      db:
        condition: service_healthy
    environment:
      - DATABASE_HOST=db
      - DATABASE_USER=myapp
      - DATABASE_PASSWORD_FILE=/run/secrets/db_password   # *_FILE, not a literal
    secrets:
      - source: db_password
        target: /run/secrets/db_password
    volumes:
      - .:/app                        # bind source for hot reload (dev-only)
    ports:
      - "8080:8080"                   # publish only the user-facing port
    healthcheck:
      test: ["CMD", "curl", "-fsS", "http://localhost:8080/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 20s

  db:
    image: postgres:17
    restart: unless-stopped
    read_only: true
    tmpfs: [/tmp, /run/postgresql]
    user: "999:999"                   # the postgres image's own UID, not ours
    cap_drop: [ALL]
    security_opt: [no-new-privileges:true]
    networks: [backend]              # never published to the host
    environment:
      - POSTGRES_USER=myapp
      - POSTGRES_DB=myapp
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - source: db_password
        target: /run/secrets/db_password
    volumes:
      - db_data:/var/lib/postgresql/data
    expose:
      - 5432                          # reachable on backend net only, not the host
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U myapp"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
```

## `expose` vs `ports`

- `expose:` — reachable by other services on the same network only (the ClusterIP default). Use for databases, internal APIs.
- `ports: ["host:container"]` — published to the host (NodePort/Ingress). Publish **only** what a human or external client actually hits. A database with `ports:` is a foot-gun.

## Validate

```bash
docker compose config                 # parse + interpolate; catches schema and ${VAR} errors
docker compose up -d
docker compose ps                     # confirm State=running / healthy
docker compose logs -f app
docker compose down                   # add -v to also drop named volumes
```

Wait for `healthy` before declaring success; a container can be `running` but not ready. Then confirm the secret landed: `docker compose exec app cat /run/secrets/db_password` should match Vault (don't paste the value into chat).

## When compose vs skaffold

| Use | When |
|---|---|
| `docker-compose` | Fast inner loop, no cluster needed; a couple of services + a DB; you want the lightest possible local run |
| `skaffold` (+ kind) | You need to exercise the actual Helm chart, k8s objects, probes, and ArgoCD-style rendering locally |

Both consume the `dockerfile` skill's `develop` stage, so the image is identical across them.

## Companion skills — offer after completing

| Skill | Offer when |
|---|---|
| `dockerfile` | No `Dockerfile`, or it lacks a `develop` stage for compose to build |
| `helm` | The service deploys to Kubernetes — port the volumes/secrets to chart values and ExternalSecret |
| `skaffold` | The team also needs a real-cluster local loop against the chart |
| `devbox` | Secret files should be populated from Vault on shell entry (`devbox` init) |

Ask as a single grouped question — not mid-task, not separately for each.
