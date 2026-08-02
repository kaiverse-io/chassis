---
kind: adr
status: accepted
owner: platform
last_reviewed: 2026-08-02
---

# ADR-005 — Stamp the coverage floor via Copier (`coverage_fail_under`)

- **Status:** Accepted (2026-08-02)
- **Deciders:** founder

## Context

Chassis already wires pytest-cov into every stamp (`just ci-test` → CI) with a bucket-B
ratchet: `fail_under` in `[tool.coverage.report]` and a matching `--cov-fail-under` in
pytest `addopts`. Both started hardcoded at `0`. Mature projects raised the floor by hand
in `pyproject.toml`; that value was not recorded as a Copier answer, so `copier update`
had no structured way to re-render it, and the two enforcement sites could drift (one
project dropped `--cov-fail-under` from `addopts` and only kept `fail_under`).

The cov *target* is already per-package (`python_package_name`). What's missing is
parameterizing the *floor* at stamp time.

## Decision

1. Add Copier answer `coverage_fail_under` (`int`, default `0`, validated 0–100).
2. Render it into **both** sites in `template/pyproject.toml.jinja`:
   - `--cov-fail-under={{ coverage_fail_under }}`
   - `fail_under = {{ coverage_fail_under }}`
3. Keep CI unchanged: `just ci-test` → `uv run pytest` already fails when either site is
   violated; no workflow-level duplicate threshold.
4. Document that after stamp, projects raise the floor in-repo only — never lower it —
   and that `copier update` must carry the project's current answer so a default of `0`
   cannot silently rewrite a ratcheted floor.

## Consequences

**Good:** initial floor is a first-class stamp answer; both enforcement sites stay in
sync; `just accept` can assert parameterization; existing CI path needs no change.

**Bad / discipline:** updating an already-ratcheted project to a chassis version that
introduces this variable requires setting `coverage_fail_under` to the project's current
floor in `.copier-answers.yml` (or answering the prompt) — otherwise Copier will propose
writing `0` and surface a conflict. That conflict is intentional; silent downgrade is not.
