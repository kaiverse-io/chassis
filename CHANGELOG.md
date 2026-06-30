# Changelog

All notable changes to the chassis are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [SemVer](https://semver.org/).

---

## [0.2.0] — 2026-06-30

### Added

- `.devcontainer/` template (4-layer model): pinned Python image, pinned features
  (no `lts`), post-create installs uv+just+pre-commit+gitleaks+opengrep, VS Code
  extensions/settings, cache volumes (uv-cache, precommit-cache, optional pnpm-cache),
  host-state mounts (`~/.claude` writable; `~/.gitconfig`, `~/.ssh` read-only).
- Closed the bucket-D gap ADR-016 promised but the v0.1.0 release didn't scaffold:
  - `evals/` — eval harness slot (golden/ + README explaining P1 activation).
  - `prompts/` — versioned prompt artifacts convention (12-factor-agents F2).
  - `.opengrep/rules/prompts-as-code.yaml` — no-inline-prompt-literals rule.
  - `.github/workflows/adlc-gate.yaml` — ADLC agent-change gate, path-filtered,
    documented no-op until `evals/golden/` has fixtures.

### Changed

- Skills canonical location: `.claude/skills/` → `.agents/skills/` (SKILL.md open
  standard is vendor-agnostic; `.claude/skills` now symlinks to `.agents/skills`).
- `tool.uv.dev-dependencies` → `[dependency-groups]` (uv deprecation).
- `pre-commit install` copier task is now non-fatal if pre-commit isn't on PATH.
- `opengrep` pre-commit hook now skips gracefully (instead of failing) when
  opengrep isn't installed outside the devcontainer.

### Fixed

- Added `tests/test_smoke.py.jinja` — a fresh stamp had 0 collected tests, which
  made `pytest` exit 5 and fail `just ci` on an otherwise-valid empty project.

---

## [0.1.0] — 2026-06-29

### Added

- Initial chassis: Copier template with A/B/C/D bucket structure (ADR-015).
- Bucket A guardrails: AGENTS.md (AAIF open standard), ruff+mypy, import-linter slot,
  opengrep self-weakening rules, gitleaks, conventional commits, CODEOWNERS, Diátaxis docs,
  pre-commit pipeline, CI calling `just ci-*`.
- Bucket B ratcheting: coverage floor (`fail_under = 0`, ratchet up as coverage grows).
- Bucket C on-demand: codeburn stub in justfile.
- Bucket D wired-but-waiting: eval gate, ADLC, arch-drift slots (documented in AGENTS.md).
- Acceptance test: `just accept` stamps a throwaway project and verifies `just ci` is green.
- Devcontainer standardisation: committed layers, mounted host-state, cache volumes.
