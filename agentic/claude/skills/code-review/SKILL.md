---
name: code-review
description: Perform thorough code reviews covering security, quality, performance, testing, and documentation. Includes Nix-specific checks.
user-invocable: true
---

# Code Review

## Load context first

Before starting the review, identify the tech stack and load the relevant skills:

| Stack present | Also load |
|---|---|
| Helm charts, Kubernetes manifests | `kubernetes` skill + `helm` skill |
| Terraform / HCL | `terraform` skill |
| GitHub Actions workflows | `github-actions` skill |
| Nix expressions / home-manager | _(use CLAUDE.md Nix guidance)_ |

When those skills are loaded, apply their checklists as additional review criteria — don't just use the generic checklist below.

## Review checklist

### Security
- [ ] No hardcoded credentials, API keys, or tokens
- [ ] Input validation at system boundaries (user input, external APIs)
- [ ] Proper error handling without information leakage in responses
- [ ] Dependencies vetted and pinned to specific versions
- [ ] Secrets managed via environment variables or secret managers

### Code quality
- [ ] Names are self-documenting (no need to read the body to understand the purpose)
- [ ] Functions do one thing; side effects are explicit
- [ ] No unnecessary duplication — shared logic extracted, not copy-pasted
- [ ] Error handling is explicit; no silent failures
- [ ] Consistent with project style guide and formatter settings

### Performance
- [ ] No obvious hot-path bottlenecks (tight loops doing unnecessary work)
- [ ] Resources cleaned up (connections, file handles, goroutines, locks)
- [ ] DB queries are indexed and avoid N+1 patterns
- [ ] Caching applied where reads dominate and staleness is acceptable

### Testing
- [ ] Critical paths have test coverage
- [ ] Tests are behaviour-focused, not implementation-focused
- [ ] Edge cases and error paths tested, not just happy path
- [ ] Integration tests for code that crosses system boundaries
- [ ] Tests are maintainable — no magic values, clear arrange/act/assert

### Documentation
- [ ] Complex *why* has a comment; obvious *what* does not
- [ ] Public APIs have a one-line summary
- [ ] Breaking changes noted; migration path described
- [ ] README updated if user-facing behaviour changed

### Nix-specific (when applicable)
- [ ] Pure functions preferred; impure use is justified
- [ ] Proper use of `lib` functions (avoid reimplementing what nixpkgs provides)
- [ ] Formatted with `nixpkgs-fmt` or `alejandra`
- [ ] Dependencies pinned via `flake.lock` or explicit hash
- [ ] Build reproducibility not broken (no `builtins.currentSystem` in derivations)

## How to give feedback

Lead with **blockers** (security issues, data loss, unbounded resources, broken correctness) before suggestions. For each finding:
- State the file and line
- Say what the problem is and *why* it matters
- Give a concrete fix or ask a clarifying question if intent is unclear

Distinguish: **must fix** (blocker) / **should fix** (quality / best practice) / **consider** (style, optional improvement).

## Companion skills — offer after completing

| Skill | Offer when |
|---|---|
| `debugging` | Review uncovered a subtle bug whose root cause isn't obvious |
| `tidy` | Mechanical style drift found (indentation, quoting, trailing whitespace) |
| `prune` | Dead code, unused variables, or orphaned files found |
| `document` | README or architecture docs are missing or out of date |
