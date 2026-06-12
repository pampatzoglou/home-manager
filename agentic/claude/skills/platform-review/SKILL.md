---
name: platform-review
description: Entry point for reviewing an IaC/platform change. Use when reviewing a branch, PR, or diff that touches infrastructure-as-code or the delivery platform (Terraform, Helm, Kubernetes, ArgoCD/GitOps, GitHub Actions, Dockerfiles, devbox/Taskfile, Nix). This skill does not carry its own review rules — it detects which stacks the change touches and dispatches to the matching skills (helm, kubernetes, argo-applicationset, terraform, taskfile, devbox, skaffold, dockerfile, github-actions, document), plus the built-in /code-review and /security-review. Each invoked skill owns its criteria; this one owns routing, the cross-stack seams between them, and the consolidated report.
user-invocable: true
---

# Platform Review — Entry Point

A dispatcher, not a checklist. When asked to review an infrastructure/platform change, this skill figures out *which* skills are relevant and runs them, then checks the seams they each can't see and consolidates the findings. **It deliberately holds no review criteria of its own** — that lives in the individual skills, so there's nothing here to drift or conflict with them.

## Procedure

### 1. Delegate the generic layer
- Run the built-in **`/code-review`** — diff-level correctness, reuse/simplification, efficiency.
- Run the built-in **`/security-review`** — security on the pending changes.

### 2. Dispatch to the matching stack skills
Detect what the change touches and invoke each matching skill. Apply that skill's own checklist as the authoritative criteria — do not re-derive its rules here.

| Detected in the change | Invoke skill |
|---|---|
| Terraform / HCL (`*.tf`, `*.tfvars`) | `terraform` |
| Helm charts (`Chart.yaml`, `values.yaml`, `templates/`) | `helm` (it loads `postgres.md` / `kafka.md` as needed) |
| Kubernetes manifests / rendered workloads | `kubernetes` |
| ArgoCD ApplicationSets (`deploy/argo/`) | `argo-applicationset` |
| Local dev loop (`skaffold.yaml`) | `skaffold` |
| GitHub Actions (`.github/workflows/`) | `github-actions` |
| Dockerfiles (`Dockerfile`, `.dockerignore`) | `dockerfile` |
| Tooling (`devbox.json`, `Taskfile.yaml`) | `devbox`, `taskfile` |
| Nix expressions / home-manager (`*.nix`, `flake.nix`) | _(use CLAUDE.md Nix guidance)_ |
| Docs affected (README, `docs/`, chart/module READMEs) | `document` |

Invoke only the skills whose surface the diff actually changes. If none match (e.g. pure application code), the built-ins from step 1 are the whole review.

### 3. Check the cross-stack seams
The only criteria this skill owns — bugs that live *between* skills, so no single one catches them:
- [ ] Values-layering order is identical across `taskfile` (`_template`), `argo-applicationset`, and `skaffold`: `values.yaml → defaults/ → <env>/ → <variant>`
- [ ] Image tag/digest produced by CI matches what the chart and ApplicationSet consume — no drift, no `:latest`
- [ ] Non-root UID is consistent across the Dockerfile (`USER`, the source of truth), docker-compose (`user:`), and the pod `securityContext` (`runAsUser`/`runAsGroup`/`fsGroup`) — e.g. distroless `65532`
- [ ] Chart `name` matches its directory and the ApplicationSet's expectation
- [ ] CI delegates to Taskfile tasks (no inline helm/kubectl/terraform) so local and CI behave identically
- [ ] Read-only rootfs is consistent: every Dockerfile `VOLUME` has a writable mount in compose (tmpfs/volume) and the chart (`emptyDir`), and the rootfs is read-only in both (`read_only` / `readOnlyRootFilesystem: true`)
- [ ] Secrets flow through ExternalSecret/Vault, never inlined into a committed `values.yaml`, tfvars, or workflow

### 4. Consolidate and report
Merge every finding — from the built-ins, each invoked skill, and the seams above — into one report. Lead with **blockers** (security, data loss, unbounded resources, broken correctness, cluster-wide misconfig). For each finding: file and line, what's wrong and *why* it matters, a concrete fix. Tag each **must fix** / **should fix** / **consider**.

## After the review

If a review surfaces follow-on work, offer the matching skill:

| Skill | Offer when |
|---|---|
| `debugging` | A subtle bug surfaced whose root cause isn't obvious |
| `tidy` | Mechanical style drift found (indentation, quoting, trailing whitespace) |
| `prune` | Dead code, unused values/variables, or orphaned files found |
| `document` | Docs are missing or out of date and weren't already covered in step 2 |
