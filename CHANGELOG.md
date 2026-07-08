# Changelog

All notable changes to the chassis are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [SemVer](https://semver.org/).

---

## [0.5.0] — 2026-07-08

### Added

- `graphify` (uv tool, knowledge-graph skill), `ctx` (cross-session agent-history search), and
  `lean-ctx` (context-compression MCP layer) added to the bucket-C AI-usage cockpit in
  `.devcontainer/post-create.sh`, alongside `codeburn`/`abtop`/AI Engineer Coach. See
  [ADR-002](docs/decisions/adrs/adr-002-ai-usage-cockpit.md) for why these three, the
  install-method lessons (no Rust toolchain needed for either Rust tool), and the tradeoffs
  (`lean-ctx onboard` touches machine-wide config, not just the project).
- `/dev-coach` steps 2a/3a: when `ctx`/`lean-ctx` are present, search full session transcripts
  for repeated corrections (`ctx search`) and check repeat-read hotspots (`lean-ctx
  gain`/`heatmap`) as additional signal beyond memory files and `git log`. Optional, not
  required — the skill degrades gracefully without them, same as it always has for `codeburn`.

### Note

All three installs are unattended and run on every devcontainer rebuild across every project
stamped from this chassis, same blast-radius profile as the v0.3.0 cockpit tools — user-
authorized explicitly given that (2026-07-08), after each tool was installed and inspected by
hand in a live devcontainer first (not templated from documentation alone).

---

## [0.4.0] — 2026-06-30

### Added

- **Agent-memory durability.** `.agents/memory/` is now a git-tracked location, and
  `.devcontainer/post-create.sh` recreates the conventional `~/.claude/projects/<slug>/memory`
  path as a symlink to it on every build (mirrors `.claude/skills → .agents/skills`). The
  `~/.claude` bind mount only persists on *local* devcontainers — on remote/cloud containers
  `.claude` is ephemeral, so agent memory was silently lost on rebuild. Committing
  `.agents/memory/` now makes memory durable across rebuilds and portable to a fresh clone.
  Seed `.agents/memory/MEMORY.md` ships so the dir exists in fresh stamps; AGENTS.md documents
  the convention.

---

## [0.3.0] — 2026-06-30

### Added

- OTEL console exporters (`OTEL_METRICS_EXPORTER`/`OTEL_LOGS_EXPORTER=console`) in
  `.claude/settings.json` — telemetry was enabled but had no exporter, so it was
  captured and silently dropped. Foundation for the future OTLP collector (bucket D).
- `codeburn` (npm) and `abtop` (curl installer) auto-installed by
  `.devcontainer/post-create.sh` — local-first AI-usage cockpit (cost/burn, one-shot
  rate, live context %), no OTEL required. `just metrics` / `just monitor` targets.
- [AI Engineer Coach](https://github.com/microsoft/ai-engineering-coach) (VS Code
  dashboard, 45 anti-pattern rules) built from source and auto-installed by
  `.devcontainer/post-create.sh`. Claude Code session-log support unconfirmed —
  documented as a caveat in AGENTS.md.
- `.agents/skills/dev-coach/SKILL.md` — anti-pattern detection + AGENTS.md auditor
  for Claude Code specifically (reads feedback-type memory files + git history,
  proposes AGENTS.md additions, asks before writing). Complements AI Engineer Coach.

### Note

The codeburn/abtop/AI-Engineer-Coach installs are unattended and run on every
devcontainer rebuild across every project stamped from this chassis — user-authorized
explicitly given that blast radius (2026-06-30).

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
