---
name: kubernetes
description: Use this skill whenever a task involves Kubernetes manifests, Helm charts, or GitOps with ArgoCD. Triggers include authoring or editing Helm charts (Chart.yaml, values.yaml, templates/*.yaml), reviewing or fixing Kubernetes YAML (Deployment, StatefulSet, Service, Ingress, CRDs), debugging failing pods, PVCs, or ArgoCD application sync, and writing operator-managed resources (CNPG, Kafka/Redpanda, ClickHouse). Also use this for any request mentioning "k8s", "kubectl", "helm template", "sync wave", "PDB", "HPA", "NetworkPolicy", or "argocd" — even when the user does not explicitly say "Kubernetes".
---

# Kubernetes

This skill helps with three related modes of Kubernetes work: authoring resources, reviewing them, and troubleshooting them. Most requests fit one of these — pick the right reference file and follow it.

## Routing

Identify which mode the task fits, then load the relevant reference. More than one may apply.

| Mode | Signals | Read |
|---|---|---|
| Authoring | "create a chart", "add a values file", new manifests, scaffolding a component | `references/authoring-helm-charts.md` + `references/resource-standards.md` |
| Reviewing | "review this YAML", "is this safe", "audit", PR-style feedback | `references/reviewing-manifests.md` (which points back into resource-standards) |
| Troubleshooting | "pod is CrashLooping", "sync is failing", "PVC stuck pending", "DNS not resolving" | `references/troubleshooting.md` |
| Operator resources | CNPG, Kafka, Redpanda, ClickHouse, Strimzi CRDs | `references/resource-standards.md` (operators section) |
| Services-repo tooling | Taskfile, skaffold, devbox, GitHub Actions for a services repo | `references/taskfile.md`, `references/skaffold.md`, `references/devbox.md`, `references/github-actions.md` (read only those that match the task) |

If the user's repo follows the conventions described in `references/conventions.md`, also read that file. The team uses two layouts: a **platform repo** where top-level folders are namespaces (e.g., `cert-manager/`, `monitoring/datadog/`), and a **services repo** with a `deploy/charts/` + `deploy/argo/` structure. Tells for either: a `defaults/values.yaml` next to `dev/`/`prod/` dirs inside a chart, ArgoCD `Application`/`ApplicationSet` files with `argocd.argoproj.io/sync-wave` annotations, references to `linstor-csi-lvm`, or a `Taskfile.yaml` with `template`/`lint` tasks. For services repos there are also four supporting tooling files described in their own references: `taskfile.md`, `skaffold.md`, `devbox.md`, `github-actions.md` — read these when the user is setting up or modifying that tooling.

## Top-level principles (apply to all modes)

These are non-negotiable for any K8s resource Claude produces or approves. The reference files expand on them.

1. **GitOps, not kubectl apply.** Changes go through git and are reconciled by ArgoCD (or Flux). Never instruct the user to `kubectl apply` to a managed cluster as the primary workflow — only as a last-resort debugging step on dev.
2. **No production secrets in git.** Use `external-secrets` / SealedSecrets / Vault. If a chart needs a credential, reference an `ExternalSecret` or a pre-existing `Secret`, never an inline literal.
3. **Every workload has resource requests and limits.** No exceptions for "it's just a small thing" — unbounded pods are how clusters die.
4. **Every workload runs as non-root with a dropped capability set**, unless the workload demonstrably cannot. The defaults in `resource-standards.md` are the floor.
5. **Every workload has liveness and readiness probes** (or a documented reason not to — e.g., one-shot Jobs).
6. **Pin image tags to a digest or specific version.** Never `:latest` in committed manifests.
7. **Multi-replica workloads need a PodDisruptionBudget and anti-affinity.** A 3-replica Deployment with no PDB is a 1-replica Deployment during node drain.

## How to work

### When authoring
- Before writing templates, check whether the team conventions apply (see routing above). If they do, match the existing `defaults/values.yaml` + `{env}/values.yaml` layout exactly — don't invent a new structure.
- Render the chart locally before declaring it done: `helm template <release> <chart-path> --values ... --include-crds`. If the user has a `Taskfile.yaml` (e.g. `task template ENV=dev`), prefer that.
- Put user-facing knobs in `values.yaml` with sensible defaults; put template logic in `_helpers.tpl`.
- **End every chart-modifying task with an audit.** Run `task audit ENV=<env>` (or the equivalent `kubescape scan` against the rendered output) and process the findings before declaring the task done. See "End-of-task audit" below.

### When reviewing
- Walk the checklist in `references/reviewing-manifests.md`. Be specific in feedback — "missing resource limits on the `app` container" beats "consider resource limits".
- Distinguish blockers (security, data loss, unbounded resources) from suggestions (label hygiene, naming). Lead with blockers.

### When troubleshooting
- Ask for the actual error first: `kubectl describe`, pod events, ArgoCD sync status. Don't guess from symptoms alone if the data is one command away.
- The decision trees in `references/troubleshooting.md` are organized by symptom (Pending pod, ImagePullBackOff, sync failure, etc.). Jump to the matching one.

## End-of-task audit

Any task that creates or modifies a chart or manifest ends with `task audit ENV=<env>` (which renders to `.argo/` and runs `kubescape scan`). Don't claim a task is done until the audit has been run and findings have been addressed.

How to handle findings:

1. **Fix obvious ones inline.** Missing `securityContext`, missing resource limits, default service account when the workload doesn't need API access, root user — these are mechanical fixes that don't need user input. Apply them.
2. **Ask about ambiguous ones.** If a control flags something that might be intentional — a privileged init container, `hostNetwork` because the workload is a CNI plugin, a wide capability set because it's a debug tool — surface it to the user with the finding's rationale and ask whether to fix or to add an exception. Don't silently add the exception or silently strip the privilege.
3. **Propose exceptions for genuine false positives.** When the user confirms a finding is intentional, propose an entry in `.kubescape/exceptions.json` with a `reason` field that explains *why* (not just "approved"). Exceptions without rationale are how that file rots.
4. **Re-run audit after fixes.** Apply changes, re-run `task audit ENV=<env>`, and report the diff: what was flagged, what was fixed, what was excepted, what remains.

If a repo doesn't have `task audit` configured (no `Taskfile.yaml` or no kubescape in devbox), the equivalent is rendering with `helm template` to a temp dir and running `kubescape scan framework nsa <dir>` directly. The shape of the audit step is the same.

When audit isn't applicable (read-only review tasks, troubleshooting tasks that don't modify manifests, conversational explanations), skip it — it's a closing step for changes, not a checkpoint for every reply.

## What NOT to do

- Do not write a `Deployment` and `Service` from scratch when the user is clearly working in a Helm chart — extend the chart instead.
- Do not invent sync wave numbers if the user has conventions; the wave assignments in `conventions.md` are deliberate.
- Do not suggest `hostNetwork: true`, `privileged: true`, or `runAsUser: 0` to "make it work". These are escape hatches with real consequences; if a workload needs them, say so explicitly and explain why.
- Do not produce YAML with placeholders like `<your-image-here>` and stop there. Either ask for the missing value or use a clearly-marked default and flag it.
