---
kind: adr
status: accepted
owner: founder
last_reviewed: 2026-11-07
---

# ADR-012 — Vendor cloudflare/security-audit-skill, opt-in and verbatim

- **Status:** Accepted (2026-11-07)
- **Deciders:** founder

## Context

[cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) (MIT) is
the skill that seeded Cloudflare's vulnerability-discovery harness. Its premise: a coding agent
asked to find security bugs will report some, real or not. So it runs a six-phase audit —
reconnaissance into a deterministic coverage ledger, coverage-led hunting by isolated agents, a
fresh verifier that tries to disprove every candidate, schema-validated `findings.json`,
independent record verification, and reporting — and later runs read earlier ledgers to target
what was skipped. Target code runs only inside an OS-enforced sandbox; reports go outside the
repository by default.

It is generic (any stamped repository has a security surface), defensive, and on-demand. It is
also large (20 files, ~5,300 lines including Node validators and their tests) and a full audit
fans out many agents. chassis#10 lists "an AI-reviewer product" under *not chassis*; this is
not a review bot wired into CI, but a skill a person invokes, which is the line that row draws.

## Decision drivers

- Generic, defensive, invoked by a person — not a gate, not a CI reviewer.
- Thin and pinned (ADR-004): no unattended fetch of "latest".
- Cost: a full audit is many agent invocations; it must not load into every project unasked.
- Don't reinvent: take upstream's methodology and validators as they are.

## Considered options

1. **Install with the Skills CLI (`npx skills add …`) at stamp time.** Rejected: an unpinned
   network fetch during `copier copy`, and a moving target.
2. **Vendor an adapted copy, like ub-mode (ADR-008).** Rejected: nothing in it conflicts with
   `AGENTS.md` — it never commits or pushes, writes reports outside the repo, and refuses to run
   target code without a sandbox — so adapting would only make re-vendoring harder.
3. **Vendor verbatim at a pinned commit, behind an opt-in Copier question.** *Chosen.*

## Decision

- `include_security_audit` (default `false`) stamps the skill at
  `.agents/skills/security-audit/` (reachable via `.claude/skills/`), copied verbatim from
  upstream commit `c1c8a8c`, with upstream's `LICENSE` and an `UPSTREAM.md` recording the
  repository, path, commit and a sha256 manifest of every file.
- `tests/checks/security-audit-skill.sh` asserts the default stamp has none of it, and that
  an opted-in stamp matches the manifest exactly — a local edit or a partial re-vendor fails.
- Re-vendoring is a manual, reviewed change: copy upstream's `skills/security-audit/`,
  regenerate the manifest, update the commit. No Renovate rule: upstream has no releases.

## Consequences

**Good:** a project gets a disprove-before-report security audit with one Copier answer, and
the copy it gets is provably upstream's.

**Bad:** an opted-in project carries ~300 KB of skill files and uses Node to run the
validators (always present in the devcontainer). Upstream fixes arrive only when chassis
re-vendors.
