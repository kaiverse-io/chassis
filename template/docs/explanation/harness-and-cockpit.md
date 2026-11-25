---
kind: explanation
status: active
owner: founder
last_reviewed: 2026-11-25
---

# Harness configuration and the AI-usage cockpit

The detail behind the short section in `AGENTS.md`. It describes tools that mostly exist only
inside the devcontainer, so it lives here and is read when needed, instead of being loaded into
every session.

## Harness-specific configuration

This project's safety/quality floor comes from two different places: universally, in
CI and git (Guardrails, Ratchet — run regardless of which harness or human wrote the
commit), and per-harness, via that harness's own config — which requires a human to
explicitly trust this project on their machine before it does anything at all:

- **Claude Code**: `.claude/settings.json` (`permissions.allow`/`deny`) — active once
  you accept the workspace-trust dialog.
- **Codex CLI**: `.codex/config.toml` (`approval_policy`, `sandbox_mode`) and
  `.codex/rules/default.rules` (denies `git commit --no-verify` /
  `git push --no-verify`, best-effort — see that file's own comment for the exact
  matching limitation) — active only once you mark this project trusted in Codex;
  Codex skips `.codex/` entirely for untrusted projects.
- **goose**: no project-level config file exists for goose at all (confirmed against
  block/goose's own docs). `GOOSE_MODE=smart_approve` is instead set for every
  process in this devcontainer via `.devcontainer/devcontainer.json`'s
  `containerEnv` — a coarser, session-wide posture, not a per-command allow/deny
  list. A `goose` run anywhere outside this devcontainer does not inherit it.

None of the three is a substitute for the others, and none is a substitute for CI.
Stamping a config file is necessary, never sufficient. See
[chassis's docs/explanation/design.md](https://github.com/kaiverse-io/chassis/blob/main/docs/explanation/design.md#harness-neutrality-whats-guaranteed-vs-whats-harness-specific)
for the full reasoning.

## AI-usage cockpit & coaching

- `just metrics` (codeburn — cost/burn by project, model, task; one-shot rate) and
  `just monitor` (abtop — live context %, tokens, rate limits) are installed by
  `.devcontainer/post-create.sh`. Both read local session data; no OTEL required.
- **AI Engineer Coach** (VS Code dashboard, [microsoft/ai-engineering-coach](https://github.com/microsoft/ai-engineering-coach))
  is **opt-in** (`install_ai_coach`, default off). When enabled, `.devcontainer/post-create.sh`
  builds it from source (pinned to a commit) — 45 anti-pattern rules, practice scores, skill
  mining; open via Cmd/Ctrl+Shift+P → "AI Engineer Coach: Open Dashboard". Off by default
  because it builds upstream source unattended and its **Claude Code session-log support is
  unconfirmed** (the project documents GitHub Copilot harnesses) — if you enable it, verify
  what it actually surfaces for this project.
- **graphify** (`/graphify`, [Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify))
  — turns the repo into a queryable knowledge graph (`graphify-out/graph.json`/`GRAPH_REPORT.md`),
  installed via `uv tool install graphifyy` by `.devcontainer/post-create.sh`. Check
  `graphify-out/GRAPH_REPORT.md`'s God Nodes/communities before exploring unfamiliar code —
  fewer tokens spent re-discovering structure the graph already answers.
- **ctx** ([ctxrs/ctx](https://github.com/ctxrs/ctx)) — indexes full local session transcripts
  (not just memory files) for `ctx search "…"`, so `/dev-coach` can find corrections the agent
  actually got, not just what a past session chose to write down. Installed by
  `.devcontainer/post-create.sh` via its own installer (prebuilt binary, no Rust toolchain).
- OTEL telemetry is on and exports to console locally (`.claude/settings.json`) — the
  spine for a future OTLP collector + team dashboard (bucket D, activates at users > 1).
- `/dev-coach` — anti-pattern detection + AGENTS.md auditor, specifically for Claude Code
  session/memory data (complements AI Engineer Coach, doesn't replace it). Also draws on `ctx`
  (full-transcript correction search) when present. Run
  periodically to close the loop between "the user corrected something" and "the rule is durable
  in AGENTS.md." See `.agents/skills/dev-coach/SKILL.md`.
- This cockpit is a chassis-level standard, not project-specific — every project stamped from
  this chassis gets it via `post-create.sh`. See
  [chassis's docs/explanation/ai-usage-cockpit.md](https://github.com/kaiverse-io/chassis/blob/main/docs/explanation/ai-usage-cockpit.md)
  for the full writeup and [ADR-002](https://github.com/kaiverse-io/chassis/blob/main/docs/decisions/adrs/adr-002-ai-usage-cockpit.md).
