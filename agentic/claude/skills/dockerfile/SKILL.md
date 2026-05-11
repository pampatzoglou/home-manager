---
name: dockerfile
description: Generate a 3-stage Dockerfile (base → develop → production) and a matching .dockerignore. Base installs OS deps, develop adds code for docker-compose/skaffold inner loop, production uses distroless/slim with explicit non-root user, --chown on all COPYs, and declared VOLUME entries. All stages are architecture-agnostic.
user-invocable: true
---

# Generate Dockerfile

Generate a 3-stage Dockerfile and matching `.dockerignore` by analyzing the project's language, framework, dependencies, and entry point.

## The 3-stage model

```
base ──► develop ──► production
         (also used    (distroless/slim,
         by docker-     explicit app user,
         compose &      --chown on all COPYs,
         skaffold)      VOLUME for writable paths)
```

| Stage | Purpose | Who uses it |
|---|---|---|
| `base` | OS packages, CA certs — no application code, no user | shared foundation for develop and production |
| `develop` | Full dev environment: all deps (including dev), source code, build output, hot-reload CMD | docker-compose, skaffold local dev |
| `production` | Slim/distroless + explicit non-root user + artifacts with `--chown` + VOLUME declarations | CI image push, cluster deployments |

## Non-negotiable rules

1. **Verify before adding.** Read the actual source files and manifests before writing any instruction. Never assume a package is needed. Ask if uncertain.
2. **Architecture-agnostic always.** Use multi-arch official images. Never hardcode `amd64`, `arm64`, or `x86_64`. Detect arch dynamically for any binary download.
3. **No HEALTHCHECK.** Health endpoints are application-specific and cannot be verified from analysis. Users add their own.
4. **Explicit non-root user in production.** Always create an `app` user in the production stage. Use `--chown=app:app` on every `COPY`. Switch with `USER app` before `CMD`.
5. **Explicit COPY everywhere.** Never `COPY . .` in any stage — copy only what each stage needs.
6. **Pin base image versions.** Never `:latest`. Derive the version from project files.
7. **Declare writable paths.** Any directory the app writes to at runtime (`/tmp`, `/var/cache`, etc.) must be declared with `VOLUME`.

---

## Step 0: check for existing files

Before generating, check if `Dockerfile` and `.dockerignore` already exist and read them. If they exist, audit against this skill's patterns and improve rather than overwrite.

---

## Step 1: analyse the project

Read thoroughly before writing a single line. Shallow analysis produces broken Dockerfiles.

### 1.1 Language and runtime version

Find the language from source file extensions and dependency manifests (`go.mod`, `package.json`, `requirements.txt`/`pyproject.toml`, `Cargo.toml`, `Gemfile`, etc.). Extract the required runtime version from:
- Version files (`.nvmrc`, `.python-version`, `.tool-versions`)
- Manifest engine constraints (`engines.node` in `package.json`, `python_requires` in `pyproject.toml`)
- CI configuration
- `devbox.json` packages

If no version is found, look up the current LTS/stable.

### 1.2 Application type

Trace the entry point and its imports to determine what the app does:
- **HTTP service** — look for port binding, route registration, server start
- **Worker / consumer** — look for queue consumers, scheduled tasks
- **CLI tool** — look for argument parsing, `os.Args`, `click`, `cobra`, etc.
- **Static site** — look for build output config, no server code

Application type determines the develop CMD, the production entry point, and whether EXPOSE is appropriate.

### 1.3 Build requirements

- Does the app need a compile/transpile step? (Go → binary, TS → JS, Rust → binary)
- What is the build command? (verify in the manifest or Taskfile)
- What is the output? (binary path, `dist/` dir, `.next/`, etc.)

### 1.4 System dependencies

Search the codebase for calls to external binaries (`exec`, `subprocess`, `os.system`, `Command`, etc.). Every binary the app calls at runtime must be present in the production image. When in doubt, ask.

### 1.5 Environment variables

Search for env var reads (`os.Getenv`, `process.env`, `os.environ`, `std::env::var`). Check `.env.example` or `.env.sample` for documented variables. Distinguish required (no default, app fails) from optional (has fallback).

### 1.6 Port

Search for port binding with concrete evidence. Only add `EXPOSE` if a port is found. Never guess.

### 1.7 Writable paths at runtime

Search for file writes, temp file creation, log file writes, and cache directories. Common patterns: `os.TempDir()`, `ioutil.TempFile`, `tempfile.mktemp`, `/tmp/`, `/var/cache/`, `/var/log/`. Every writable path that isn't a mounted volume in the container runtime must be declared with `VOLUME` in the Dockerfile.

### 1.8 Integration with skaffold / docker-compose

Check for `skaffold.yaml` and `docker-compose.yaml`. Note which build target they use (or should use) and what volumes they mount. The `develop` stage must match what these tools expect.

---

## Step 2: write the Dockerfile

### Stage 1 — `base`

```dockerfile
# syntax=docker/dockerfile:1
# ── base ──────────────────────────────────────────────────────────────────────
# Shared OS foundation: packages and CA certs. No application code, no app user.
FROM <language-image>:<version>-<variant> AS base

# Install only OS-level packages required at both dev and runtime.
# Clean cache in the same layer.
RUN <pkg-manager> install -y --no-install-recommends \
        <package-1> \
        <package-2> && \
    <clean-cache-command>

WORKDIR /app
```

**Base stage rules:**
- Multi-arch official images only (official images are multi-arch by default).
- Only packages needed by both develop and production. Dev-only tools go in develop; any production-only runtime library goes in production.
- Set `WORKDIR /app` here so it's inherited.
- Do **not** create the app user here — each downstream stage has different security requirements.

### Stage 2 — `develop`

```dockerfile
# ── develop ───────────────────────────────────────────────────────────────────
# Full development environment: all dependencies, source code, build output.
# Used by docker-compose (bind mount for hot reload) and skaffold (sideloaded to kind).
FROM base AS develop

# Install dev-time tools (hot reload daemon, test runner, debugger, compiler).
RUN <install-dev-tools>

# Copy dependency manifests first for layer caching.
COPY <manifest-files> ./

# Install all dependencies (including dev/test deps).
RUN <install-all-deps>

# Copy source code. Be explicit — never COPY . .
COPY <src-dir> ./
COPY <config-files-needed-at-dev-time> ./

# For compiled languages: build the binary here so production can COPY --from=develop.
RUN <build-command>    # e.g., go build -o /app/server .  |  cargo build --release

# Dev entry point: hot-reload or direct run.
# docker-compose overrides this with a volume mount; skaffold uses it directly.
CMD ["<dev-entry-point>"]    # e.g., air, nodemon, uvicorn --reload, go run .
```

**Develop stage rules:**
- Install dev tools that are NOT needed in production.
- Copy dependency manifests before source code to maximise layer caching.
- For compiled languages, perform the build here so production can simply `COPY --from=develop /app/binary`.
- The `CMD` is the dev entry point — docker-compose may override it; skaffold sideloads this image and expects it to start the service.

**docker-compose target:**
```yaml
services:
  app:
    build:
      context: .
      target: develop
    volumes:
      - .:/app               # mount source for hot reload
    ports:
      - "8080:8080"
```

**skaffold target:**
```yaml
build:
  artifacts:
    - image: my-service
      docker:
        dockerfile: Dockerfile
        target: develop
```

### Stage 3 — `production`

```dockerfile
# ── production ────────────────────────────────────────────────────────────────
# Minimal runtime: explicit non-root user, --chown on every COPY, declared VOLUMEs.
FROM <runtime-image>:<version> AS production

# Create a dedicated non-root user and group.
# Alpine syntax:
RUN addgroup -S app && adduser -S app -G app
# Debian/slim syntax (use one or the other, matching the base image):
# RUN groupadd --system app && useradd --system --gid app --no-create-home app

WORKDIR /app

# Copy artifacts from the develop stage with explicit ownership.
# --chown ensures files are owned by app:app from the moment they enter the layer,
# not by root with a later USER switch — this is the minimal-attack-surface pattern.
#
# For compiled languages (single binary):
COPY --from=develop --chown=app:app /app/<binary> /app/<binary>
#
# For interpreted languages (copy selectively — never the full develop stage):
# COPY --from=develop --chown=app:app /app/<prod-deps-dir> /app/<prod-deps-dir>
# COPY --from=develop --chown=app:app /app/<src-dir> /app/<src-dir>

# Declare every directory the application writes to at runtime.
# In Kubernetes with readOnlyRootFilesystem: true, mount these as emptyDir volumes.
VOLUME ["/tmp"]
# Add others as needed: VOLUME ["/var/cache/app", "/var/log/app"]

USER app

EXPOSE <port>      # only if verified in Step 1.6

CMD ["<executable>", "<arg>"]    # exec form always — never shell form in production
```

**Production user patterns by base image:**

| Base image | Create user | COPY ownership |
|---|---|---|
| Alpine | `RUN addgroup -S app && adduser -S app -G app` | `--chown=app:app` |
| Debian slim | `RUN groupadd --system app && useradd --system --gid app --no-create-home app` | `--chown=app:app` |
| Distroless (preferred) | No `RUN` possible — use built-in `nonroot` user (uid 65532) | `--chown=65532:65532` or `--chown=nonroot:nonroot` |

For distroless images, if a named `app` user is strictly required, create it in a helper stage:
```dockerfile
FROM alpine:3.21 AS user-setup
RUN addgroup -S app && adduser -S app -G app

FROM gcr.io/distroless/static-debian12 AS production
COPY --from=user-setup /etc/passwd /etc/group /etc/
COPY --from=develop --chown=65534:65534 /app/binary /app/binary
USER app
```

**Production image selection:**

| Language | Preferred | Fallback |
|---|---|---|
| Go (static binary) | `gcr.io/distroless/static-debian12:nonroot` | `alpine:3.21` |
| Go (with cgo) | `gcr.io/distroless/base-debian12:nonroot` | `debian:12-slim` |
| Python | `gcr.io/distroless/python3-debian12:nonroot` | `python:3.x-slim` |
| Node.js | `gcr.io/distroless/nodejs22-debian12:nonroot` | `node:22-alpine` |
| Java | `gcr.io/distroless/java21-debian12:nonroot` | `eclipse-temurin:21-jre-alpine` |
| Rust (static) | `gcr.io/distroless/static-debian12:nonroot` | `alpine:3.21` |
| Generic binary | `gcr.io/distroless/base-debian12:nonroot` | `debian:12-slim` |

Use distroless unless the app requires a shell, a package manager, or system tools at runtime.

**Architecture-agnostic binary downloads** (when a binary must be fetched from a URL):
```dockerfile
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    curl -fsSL "https://example.com/releases/tool-linux-${ARCH}.tar.gz" | tar -xz -C /usr/local/bin
```

Never hardcode `amd64`, `x86_64`, or `arm64` in a URL or path.

---

## Step 3: write the .dockerignore

The `.dockerignore` applies to the entire build context. Since stages use explicit `COPY` commands (never `COPY . .`), the `.dockerignore` serves two purposes:
1. **Speed** — exclude large generated directories that slow context transfer.
2. **Security** — prevent secrets from entering the context even accidentally.

```dockerignore
# Version control
.git
.gitignore

# IDE and editor state
.vscode
.idea
*.swp
*.swo
.DS_Store

# Environment files — never let these into the build context
.env
.env.*
*.env
.envrc
!.env.example
!.env.sample

# Generated build artifacts (the Dockerfile rebuilds these)
# Go
bin/
# Node
node_modules/
dist/
.next/
out/
# Python
__pycache__/
*.pyc
*.pyo
.venv/
venv/
dist/
*.egg-info/
# Rust
target/
# Java
target/
*.jar
*.war
build/

# Local dev tooling (not needed inside the image)
devbox.json
devbox.lock
.devbox/
Taskfile.yaml
Taskfile.yml
skaffold.yaml
docker-compose*.yaml
.github/

# Test output and coverage
coverage/
*.coverprofile
htmlcov/
.pytest_cache/
.nyc_output/

# Docs
docs/
*.md
!README.md
```

**Keep the file lean.** Only exclude things that exist in directories being COPY-ed or that are large enough to matter for context transfer time. Don't exclude directories the Dockerfile never copies — that's redundant noise.

---

## Step 4: build, run, validate

### 4.1 Build both targets

```bash
# Develop target
docker build --target develop -t my-service:develop .

# Production target (no --target needed — last stage is the default)
docker build -t my-service:latest .
```

### 4.2 Verify production image

```bash
docker run --rm my-service:latest                          # CLI tools / one-shot
docker run -d --name test my-service:latest && sleep 5    # services
docker inspect --format='{{.State.Status}}' test
docker inspect --format='{{.State.ExitCode}}' test
docker logs test 2>&1
```

**Expected by application type:**
- Services: container still running after 5 seconds
- CLI tools / one-shot: exited with code 0

### 4.3 Verify develop image

```bash
# Confirm the image starts correctly with a bind-mounted source
docker run --rm -v $(pwd):/app my-service:develop
```

### 4.4 Lint (if hadolint is available)

```bash
hadolint Dockerfile
```

Evaluate each finding — some may be intentional. Fix or note the reason before declaring done.

### 4.5 Security scan (if trivy is available)

```bash
trivy image --severity HIGH,CRITICAL my-service:latest
```

HIGH/CRITICAL findings in the base image → consider a different image variant. Findings in application dependencies → note for the user but don't block (dependency updates are outside Dockerfile scope).

### 4.6 Iterate

Maximum 5 iterations before stopping to report state to the user.

| Symptom | Likely cause |
|---|---|
| Missing file in production | `COPY --from=develop` path wrong, or artifact wasn't built |
| Permission denied | File is owned by root; `--chown=app:app` was missing or path mismatch |
| Binary not found at runtime | System dep present in `base`/`develop` but missing in production image |
| Hot reload not working | Bind-mount path doesn't match `WORKDIR` |
| Architecture error | Hardcoded arch in a download URL or binary path |
| `/tmp` not writable | `VOLUME ["/tmp"]` missing; in k8s, add `emptyDir` mount |

### 4.7 Cleanup

Always clean up after validation, whether successful or not:

```bash
docker stop test 2>/dev/null || true
docker rm test 2>/dev/null || true
docker rmi my-service:develop my-service:latest 2>/dev/null || true
```

Only present the Dockerfile to the user after all validation steps pass and cleanup is complete.

---

## Step 5: present and document

### For new Dockerfiles

Present both files to the user:

1. **Dockerfile** — with comments explaining each stage and any non-obvious decision
2. **.dockerignore** — with section headers

Then provide:
- Brief explanation of design choices (base image selection, why distroless vs slim, how writable paths were identified)
- Build commands for both targets
- docker-compose snippet with `target: develop` and volume mount
- skaffold snippet with `target: develop` (if `skaffold.yaml` is present or expected)
- How to use in CI: `docker build -t <name>:<tag> .` (production by default)
- Required environment variables or build args, with defaults and setup instructions

### For improved Dockerfiles

Present the improved files with a summary:

1. **Dockerfile** — improved version
2. **Changes made** — brief list of what changed and why:
   - Security fixes (e.g., "Added `--chown=app:app` to all COPYs — files were owned by root")
   - Pattern fixes (e.g., "Moved user creation to production stage — develop doesn't need it")
   - Missing declarations (e.g., "Added `VOLUME [\"/tmp\"]` — app writes temp files at startup")
3. **Preserved** — intentional customizations that were kept
4. **.dockerignore** — improved version if changes were needed

---

## Example workflows

### New Dockerfile (no existing file)

1. **Check**: "No existing Dockerfile found. Will generate a new 3-stage one."
2. **Explore**: "Finding dependency manifest... found `go.mod`. Reading it for the Go version and module path."
3. **Identify**: "Go 1.23 project. Entry point is `cmd/server/main.go`. Binds to `$PORT` (default 8080). Writes temp files under `/tmp`."
4. **Build requirements**: "No external system deps called at runtime. Single static binary output to `./server`."
5. **Stage design**: "Base: `golang:1.23-alpine`. Develop: full Go toolchain + `air` for hot reload, builds binary. Production: `gcr.io/distroless/static-debian12:nonroot` with `--chown=65532:65532` and `VOLUME [\"/tmp\"]`."
6. **Generate**: "Writing Dockerfile and .dockerignore."
7. **Build & test**: "Building develop target... building production target... running production container... verifying it stays up..."
8. **Iterate** (if needed): "Container exited — logs show `/tmp` not writable. Adding `VOLUME [\"/tmp\"]` and retrying."
9. **Cleanup & present**: "Validation passed. Cleanup done. Here are the files."

### Improving existing Dockerfile

1. **Check**: "Found existing Dockerfile. Reading it..."
2. **Analyse project**: Same exploration as above to understand what the Dockerfile should do.
3. **Evaluate**: "Checking against skill patterns..."
   - "❌ Two stages (builder + runtime) — missing `develop` stage for docker-compose/skaffold"
   - "❌ `COPY . .` in builder — should be explicit"
   - "❌ Files copied without `--chown` — owned by root in production"
   - "❌ No `VOLUME` — app writes to `/tmp` at startup"
   - "✅ Non-root USER directive already present"
   - "✅ Pinned image tags"
4. **Preserve**: "Keeping the custom CA cert installation in base — it's intentional."
5. **Improve**: "Adding develop stage, replacing `COPY . .`, adding `--chown`, adding `VOLUME`."
6. **Build & test**: "Building both targets... running production container... checking logs..."
7. **Iterate** (if needed): "Production container exits — `--chown` uid doesn't match USER. Fixing and retrying."
8. **Cleanup & present**: "Validation passed. Here are the improvements."

---

## Success criteria

### Dockerfile checklist

- [ ] Builds successfully — both `--target develop` and default (production)
- [ ] Three named stages: `base`, `develop`, `production`
- [ ] All base images use pinned version tags (no `:latest`)
- [ ] No hardcoded `amd64`/`arm64`/`x86_64` anywhere
- [ ] No `COPY . .` in any stage — all COPYs are explicit
- [ ] Dependency manifests copied before source code in `develop` (layer caching)
- [ ] Production stage creates an explicit `app` user and group
- [ ] Every `COPY` in the production stage uses `--chown=app:app` (or `--chown=65532:65532` for distroless)
- [ ] `USER app` appears before `CMD` in production
- [ ] All writable runtime paths declared with `VOLUME`
- [ ] Production uses distroless (or slim with documented justification)
- [ ] CMD in exec form (`["executable", "arg"]`) — never shell form in production
- [ ] No HEALTHCHECK
- [ ] EXPOSE only if a port was verified in analysis
- [ ] No debugging tools in production image

### .dockerignore checklist

- [ ] Excludes `.env` and all secret file patterns
- [ ] Excludes large generated directories (`node_modules`, `target/`, `dist/`, etc.)
- [ ] Excludes local dev tooling (`devbox.json`, `Taskfile.yaml`, `skaffold.yaml`, `docker-compose*.yaml`)
- [ ] Does not exclude directories the Dockerfile never copies
- [ ] Under 40 lines

### Validation checklist

- [ ] Production image builds without errors
- [ ] Production container starts and stays up (services) or exits 0 (one-shot)
- [ ] Develop image builds without errors
- [ ] Develop container starts with bind-mounted source
- [ ] Logs show no errors indicating application or permission failure
- [ ] `hadolint` passes (if installed)
- [ ] `trivy` shows no critical base image vulnerabilities (if installed)
- [ ] Test containers and images cleaned up

**Do not present the Dockerfile to the user until all validation checks pass.**

## Companion skills — offer after completing

Once the Dockerfile and `.dockerignore` are done, check the repo and offer whichever of these are missing or incomplete:

| Skill | Offer when |
|-------|-----------|
| `skaffold` | No `skaffold.yaml` — the develop stage exists specifically for skaffold/docker-compose local loops |
| `devbox` | No `devbox.json` in the repo root |
| `taskfile` | No `Taskfile.yaml` / `Taskfile.yml` in the repo root |
| `document` | No `docs/ARCHITECTURE.md`, or existing README doesn't describe the container stages |

Ask as a single grouped question — not mid-task, not separately for each.
