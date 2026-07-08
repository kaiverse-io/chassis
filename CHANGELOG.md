# Changelog

All notable changes to the chassis are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [SemVer](https://semver.org/).

---

## [0.7.1] — 2026-07-08

### Fixed

Both found from an actual rebuild attempt of chassis's own new standalone devcontainer (v0.7.0):

- **Node.js/npm was never installed** unless `include_ts: true` — `ghcr.io/devcontainers/features/node:1`
  was gated behind the TypeScript module toggle in `devcontainer.json.jinja`, but the AI-usage
  cockpit (`codeburn`, `lean-ctx`) and the Claude Code CLI itself are all installed via `npm` in
  `post-create.sh` regardless of the project's own language. Every plain-Python project stamped
  from chassis (`include_ts: false`, the default) has been hitting `npm: command not found` on
  those installs. Now unconditional, in both the template and chassis's own root
  `devcontainer.json`.
- **A permission failure on the agent-memory symlink step took down the entire
  `post-create.sh`** — the `mkdir` there had no fallback, and with `set -euo pipefail`, its
  failure aborted the whole script, meaning `uv sync`/`pre-commit install` never ran either. Hit
  for real: a restrictive/UID-mismatched `~/.claude` bind mount on a fresh standalone chassis
  devcontainer. Now wrapped in a subshell that degrades to a warning instead — proven by
  reproducing the exact failure and confirming the rest of the script now runs regardless.

---

## [0.7.0] — 2026-07-08

### Added

- Chassis now has its **own standalone devcontainer** at the repo root — `git clone` chassis
  alone, no sibling project needed, "Reopen in Container" just works. Previously chassis could
  only be developed by piggybacking inside another project's devcontainer that happened to mount
  it as a sibling folder.
- `.devcontainer/post-create.sh`, `.claude/settings.json`, `.claude/hooks/session-start-cockpit.sh`,
  and `.agents/skills/dev-coach/SKILL.md` at the repo root are **symlinks** into `template/` —
  the literal same file a stamped project gets, not a hand-maintained copy. A bugfix to any of
  these fixes chassis's own devcontainer and every future stamped project at once.
- `.devcontainer/devcontainer.json`/`docker-compose.yml` are deliberately independent, not
  symlinked or generated from the template: they mount just chassis's own root
  (`..:/workspaces/chassis`), not the template's sibling-project convention
  (`../..:/workspaces`, which assumes a shared parent folder with other projects — appropriate
  for a stamped project developed alongside chassis, wrong for a standalone chassis clone which
  has no sibling to see and shouldn't be exposed to whatever else happens to live nearby).
- `AGENTS.md`'s cockpit/token-frugality section is now a proven, checked invariant, not just a
  hand-copied one-time bootstrap: both `AGENTS.md` and `template/AGENTS.md.jinja` mark the shared
  span with `<!-- cockpit-section:start/end -->`, and `ci-lint` fails if they diverge. This
  exists because the drift already happened for real once this session — `AGENTS.md.jinja` sat
  three tools behind for most of it before anyone noticed.
- `.agents/memory/MEMORY.md` seed at the repo root — chassis's own real, accumulated memory,
  independent of the template's seed by design (meant to diverge immediately, like any stamped
  project's does).

---

## [0.6.3] — 2026-07-08

### Added

- `SessionStart` hook (`.claude/hooks/session-start-cockpit.sh`): refreshes `graphify`'s graph
  and `ctx`'s session index at the start of every session, and injects a short reminder of the
  cockpit's existence directly into the agent's context (confirmed: `SessionStart` stdout is
  added to context automatically, before the first prompt, and cannot block the session — so
  this is genuinely free of downside, only upside). This is the mechanism that makes the cockpit
  a first-class, hardcoded default rather than "documented, easily forgotten" — which is
  precisely what happened earlier in the same session that produced this fix: `graphify` sat
  installed and unused for the entire session until asked about directly.

---

## [0.6.2] — 2026-07-08

### Added

- `docs/explanation/layered-model.md` — ten capability layers grouped into Foundation
  (Substrate, Governance, Guardrails, Prompts, Ratchet), Cockpit (Memory, Context Engineering,
  Tools/Skills, Coaching), and Readiness, with a Mermaid diagram. Names and grounds distinctions
  that were previously implicit across several docs: Memory (curated, deliberate) vs. Context
  Engineering (automatic, exhaustive) vs. Governance (constrains agent *actions*) vs. Guardrails
  (constrains *code* quality) vs. determinism (the unifying purpose of the whole Foundation
  group — wrapping non-deterministic agent output in checks that don't care who wrote it).
  Maps onto 12-factor-agents: only F2 (Own your Prompts) and F3 (Own your Context Window) are
  chassis's job, because they're the only two factors describing *any* agent's behavior rather
  than a specific shipped product's architecture.
- `docs/explanation/two-plane-model.md` — the Plane-1 (how the software gets built, chassis's
  entire job) / Plane-2 (what the shipped product does, deliberately not chassis's job)
  distinction, previously only implicit across several docs, now explained on its own with a
  concrete example.
- `AGENTS.md.jinja`: brought the stamped project's cockpit section to parity with the actual six
  tools (was only listing three), and added a **Token frugality — tool preference** section —
  vendor-agnostic (conditional on whatever MCP tools are actually listed in a given agent's
  session, not Claude-specific), covering the `ctx_*` tool-preference table, read modes, and
  edit-failure handling.

### Changed

- README rewritten for a reader with zero prior context: leads with the problem chassis solves
  (guardrails from commit 1, compounding via `copier update` instead of a one-time template
  copy), explains *why* each A/B/C/D bucket exists rather than just listing contents, highlights
  the AI-usage cockpit specifically, adds a directory sketch of what a stamped project looks
  like, and a Quick Start with prerequisites. Previously assumed the reader already knew what
  chassis was for.

---

## [0.6.1] — 2026-07-08

### Added

- `docs/explanation/devcontainer-persistence.md` — the full persistence model (git-tracked
  files, Docker named volumes, host bind mounts), what survives a rebuild and what doesn't, and
  the migration gotcha when nesting a new volume inside an existing bind mount (as `v0.6.0`'s
  `claude-projects` volume does).
- `docs/how-to/release-a-chassis-version.md` — copier resolves the latest git tag, not branch
  HEAD, so a commit alone never reaches consumers. This is the release checklist that makes
  that fact actionable instead of a war story.
- `ai-usage-cockpit.md`: documented that `lean-ctx`'s MCP tools need a session restart to
  appear after `lean-ctx onboard` — registering an MCP server mid-session doesn't inject its
  tools into an already-running conversation.
- README: docs index section, `--trust` noted on `copier update` (not just `copy`).

---

## [0.6.0] — 2026-07-08

### Added

- `claude-projects` named Docker volume in `docker-compose.yml.jinja`, nested inside the
  devcontainer.json `~/.claude` bind mount at `.claude/projects`. That bind mount only persists
  when `${localEnv:HOME}` is itself a durable host path (true on local devcontainers, not
  guaranteed on remote/cloud ones) — the nested volume guarantees Claude Code session
  transcripts survive a rebuild either way.

### Fixed

- `ci-lint`'s justfile recipe had a bad indentation-sensitive `python3 -c` block since the
  initial commit (`56cbad2`) — `just` was silently never able to run it. Converted to a shebang
  recipe, matching the pattern `accept` already used correctly.
- `just accept` never actually completed: copier 9.x refuses templates with `_tasks` (`git
  init`/`uv sync`/`pre-commit install`) without `--trust`. Added it to `accept` and to the
  README's stamp instructions.

### Note

**Copier resolves the latest semver tag by default, not branch HEAD**, for a git-based template
source — confirmed by testing (a canary commit on `main` was invisible to `copier copy`/`update`
until a new tag was cut). This means every chassis change that should actually reach stamped
projects needs a version tag, not just a commit to `main` — the fixes above sat unreachable on
`main` between `v0.5.0` and this tag despite being pushed.

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
