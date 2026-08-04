---
kind: agent-context
status: active
last_reviewed: 2026-07-08
---

# Chassis — Agent Context

> The Copier template that stamps new projects with AI-native guardrails from commit 1.
> This repo dogfoods the guide it enforces: it has its own ADRs, Diátaxis docs, and passes
> its own gates — including its own copy of the AI-usage cockpit below. CLAUDE.md is a symlink
> to this file.

## What this repo is

`kaiverse-io/chassis` is a [Copier](https://copier.readthedocs.io/) template. Running
`copier copy gh:kaiverse-io/chassis <dest> --trust` stamps a new project with:

- Guardrails (A): AGENTS.md, ruff/mypy, import-linter boundary slot, opengrep self-weakening,
  gitleaks, conventional commits, CODEOWNERS, Diátaxis docs, pre-commit, `ARCHITECTURE.md`
  coverage gate (`just ci-arch`).
- Ratcheting gates (B): coverage floor (only-increase; stamped via Copier
  `coverage_fail_under` into both `fail_under` and `--cov-fail-under`; enforced by
  `just ci-test`). On `copier update`, projects must carry their current answer so a
  default of `0` cannot silently lower a raised floor. Complexity ceiling.
- On-demand tools (C): the AI-usage cockpit — codeburn, abtop, AI Engineer Coach, graphify,
  ctx; the `/arch-review` skill (architecture-doc accuracy).
- Wired-but-waiting slots (D): eval gate, ADLC agent-change gate.

See [docs/explanation/design.md](docs/explanation/design.md) for the full breakdown of *why*
each piece exists — the two-plane model, the buckets, the ten capability layers, and the
harness-plane rules for what may sit between an agent and its context.

## Structure

```
copier.yml             — Copier config: variables, tasks, subdirectory pointer
template/              — Everything stamped into new projects (Jinja2 templates)
  AGENTS.md.jinja      — Canonical AI context for the stamped project
  pyproject.toml.jinja — uv + ruff + mypy + pytest + import-linter
  justfile.jinja        — The one runner (just ci, just fmt, just sync …)
  .pre-commit-config.yaml.jinja
  .importlinter.jinja  — Boundary contract slot (project fills)
  .opengrep/rules/     — self-weakening rules (generic, shipped by default)
  .github/workflows/   — CI calling just ci-*
  .claude/, .agents/   — Claude Code settings/hooks, skills, memory seed
  src/ tests/ docs/    — Project skeleton
docs/                  — Chassis's own Diátaxis docs
.devcontainer/         — Chassis's OWN standalone dev environment (not stamped — see below)
.agents/, .claude/     — Chassis's own cockpit, mostly symlinked into template/ (see below)
```

## Chassis's own devcontainer is deliberately not a stamped copy

`.devcontainer/`, `.claude/settings.json`, `.claude/hooks/`, and
`.agents/skills/dev-coach/SKILL.md` at this repo's root exist so chassis can be cloned and
developed **standalone** — `git clone` this repo alone, no sibling project required, no
piggybacking inside something else's devcontainer (which is how chassis was actually developed
before these files existed).

Everything with zero project-specific content is a **symlink** straight into `template/` — not a
copy kept in sync by hand, the literal same file:

- `.devcontainer/post-create.sh` → `template/.devcontainer/post-create.sh`
- `.claude/settings.json` → `template/.claude/settings.json.jinja`
- `.claude/hooks/session-start-cockpit.sh` → `template/.claude/hooks/session-start-cockpit.sh`
- `.agents/skills/dev-coach/SKILL.md` → `template/.agents/skills/dev-coach/SKILL.md`

A bugfix to any of these fixes chassis's own devcontainer and every future stamped project
simultaneously — there is no second copy to remember.

**`.devcontainer/devcontainer.json` and `docker-compose.yml` are deliberately *not* symlinked or
generated from the template** — they're the concrete instantiation, not a `.jinja` file needing
Copier's rendering step (`project_name`, `include_ts`, …). Both chassis's own files and the
template now mount only their own project root, at a hardcoded literal path
(`..:/workspaces/<project>:cached` — `${localWorkspaceFolderBasename}` cannot be used there:
it's substituted only in devcontainer.json, and Docker Compose resolves it as an unset env var,
i.e. empty) — never a shared parent folder — so a
stamped project's container can't reach a sibling project's files, the same isolation concern
[ADR-003](docs/decisions/adrs/adr-003-settings-json-isolation.md) fixes for `settings.json`. The
template mounted a shared `/workspaces` parent (`../..:/workspaces:cached`) prior to 2026-07-15;
that convention assumed a multi-project sibling folder and was dropped once it was flagged as the
same class of cross-project leak.

**`.agents/memory/MEMORY.md` is independent, not a symlink** — it holds chassis's own real,
accumulated memory over time, the same way any stamped project's memory diverges immediately
from the empty seed it started from.

## Hard rules (for working in this repo)

- **Generic only** — no project-specific rule ever ships in the chassis (except self-weakening,
  which is generic to any agent-built repo).
- **Self-dogfooding** — the chassis must pass its own gates (`just ci`), including keeping this
  file's cockpit section in sync with `template/AGENTS.md.jinja`'s (checked by `just ci`, not
  just promised — see the `ci-lint` recipe).
- **Thin** — resist the urge to add features; validate via stamping, not by growing the template.
- **No consuming-project references, anywhere in this repo** — chassis is independent, meant to
  be cloned and used on its own. If a doc or config file here needs a specific downstream
  project's name to make sense, that content belongs in the consuming project, not here.
- **Contribution rule:** generic improvement → bump chassis version; project-specific rule →
  goes in the project's own slots, never upstreamed here.

## How to work here

```bash
uv sync          # install copier + dev tools
just accept      # acceptance test: stamp a throwaway project → just ci green
just ci          # lint/test the chassis itself, including the cockpit-section sync check
```

## Agent-memory convention

After a significant multi-step task, save reusable learnings to `.agents/memory/` (git-tracked —
survives devcontainer rebuilds and is portable to a fresh clone, same convention every stamped
project gets). One file per insight; `MEMORY.md` index (one line per entry).

<!-- cockpit-section:start (kept in sync with template/AGENTS.md.jinja — see justfile ci-lint) -->
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

<!-- cockpit-section:end -->

## Forbidden patterns

- `git commit --no-verify`
- Bare `# noqa` or `# type: ignore`
- Hardcoded secrets
- Adding project-specific rules to the chassis template
- Referencing a specific consuming project (e.g. by name) anywhere in this repo
- `Co-authored-by` / `Co-Authored-By` trailers in commits — commits belong solely
  to the GitHub credential owner that pushes
