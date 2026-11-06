---
kind: adr
status: accepted
owner: founder
last_reviewed: 2026-11-06
---

# ADR-010 — The agent's check is the CI check, and a missing check fails

- **Status:** Accepted (2026-11-06)
- **Deciders:** founder

## Context

chassis#10 (and #8) set the bar: the template makes the agent's check identical to CI's, and a
check that is missing or inert fails. A review of a fresh v0.14.0 stamp found the opposite in
several places:

- pre-commit ran ruff 0.6.9 from a mirror repo while CI ran the uv-locked ruff, and ran mypy
  non-strict with `--ignore-missing-imports` while CI ran strict `mypy src/` — a commit could
  pass the hook and fail CI;
- shellcheck ran only as a hook, so CI, and any session without hooks installed, never ran it;
- `ci-docs` was an `echo` — a CI step that checked nothing — while every stamped `AGENTS.md`
  carried a broken relative link (to a chassis-only doc, with a stale anchor);
- nothing stopped the workflow from running fewer steps than `just ci`, nothing protected the
  gate files, and nothing bounded file size;
- the stamped CI installed `just` by piping an unpinned install script to bash, which chassis's
  own CI already refuses.

## Decision

- pre-commit's ruff, ruff-format and mypy hooks call the project's own `uv run` tools; the
  import-linter hook and `ci-lint` share one recipe (`_lint-imports`). shellcheck runs in
  `ci-lint` at the same pinned version the hook used (`uvx --from shellcheck-py==0.10.0.1`).
- `ci-docs` runs [lychee](https://github.com/lycheeverse/lychee) `--offline` — the standard
  Markdown link checker, local files only so it cannot flake on the network — pinned in CI and
  `post-create.sh`. The broken `AGENTS.md` link now points at chassis's own document.
- `_ci-gate-integrity` fails when `.github/workflows/ci.yaml`'s `just` steps differ from `ci`'s
  dependency list. `_ci-file-size` fails on a hand-written `src/` or `tests/` Python file over
  `max_file_lines` (500). Both run inside `ci-lint`.
- CODEOWNERS covers the gate files: `justfile`, workflows, pre-commit, opengrep, import-linter,
  `pyproject.toml`, and the harness settings.
- `just verify` is stamped as `verify: ci` — what an agent runs before calling a task done; a
  project extends it with its own end-to-end checks. AGENTS.md says to run `just ci` after each
  logical change and `just verify` before declaring done.
- The stamped CI installs `just` from a pinned release asset.

**Not done here, on purpose:** hadolint and osv-scanner still run only as hooks (moving them
needs pinned binaries in CI and post-create, and osv's results change with each new advisory —
a separate decision). The eval slot stays wired-but-waiting: with no model call in a fresh
project, a sample eval would be a check that tests nothing, which is what this ADR removes.

## Consequences

**Good:** what passes locally passes in CI, and the reverse; a step dropped from the workflow,
a giant file, or a broken doc link fails the build.

**Bad:** `just ci` now needs lychee locally (installed by `post-create.sh`; a session outside the
devcontainer must install it). Existing projects pick all of this up on `copier update` and may
find broken links or files over 500 lines on their first run.
