# chassis

> A [Copier](https://copier.readthedocs.io/) template that stamps new projects with AI-native
> guardrails, a working devcontainer, and an AI-usage cockpit — from commit 1, not bolted on
> after the fact.

## The problem this solves

Coding agents are fast enough now that "we'll add guardrails later" stops being true — by the
time you notice you need import boundaries, a coverage floor, or secret scanning, an agent has
already committed a few hundred lines without them. And if you're solo or a small team building
several projects this way, you end up re-solving the same setup problem every time: which lint
config, which pre-commit hooks, which devcontainer quirks you already debugged last project and
forgot you'd debugged.

Chassis is a **compounding answer** to that: stamp a project once, and every guardrail — plus
every fix discovered while dogfooding chassis on real projects — is already there. Improve the
chassis, run `copier update` in an existing project, and the improvement flows downstream. GitHub
"template repositories" can't do this — they're a one-time copy; `copier update` is a real diff
against what changed upstream, with conflicts surfaced instead of silently lost. See
[Why a Copier chassis?](docs/explanation/chassis-design.md) for the full reasoning.

## What you get, and why each piece exists

Every tool is wired in from the first commit. What varies is *how strict it is* — the A/B/C/D
bucket model:

| Bucket | Behavior | What's in it |
|---|---|---|
| **A — Guardrails** | Blocks the commit or CI run. For things where "wrong" is always wrong. | `AGENTS.md`, ruff+mypy, import-linter boundary slot, opengrep self-weakening + prompts-as-code rules, gitleaks, conventional commits, CODEOWNERS, Diátaxis docs, `prompts/` convention, a 4-layer devcontainer |
| **B — Ratcheting** | Present from day one; the threshold only ever increases, never decreases. | Coverage floor (start at 0%, raise as you write tests), complexity ceiling |
| **C — On-demand** | Installed automatically, never blocks anything — run it when it's useful. | The [AI-usage cockpit](docs/explanation/ai-usage-cockpit.md): `codeburn`, `abtop`, AI Engineer Coach, `graphify`, `ctx`, `lean-ctx` |
| **D — Wired-but-waiting** | The slot exists in CI/config from day one but is a deliberate no-op until its input exists — trivially activatable later, no retrofit. | `evals/` (eval gate, activates once you have real eval fixtures), ADLC agent-change gate, arch-drift slot |

The forcing function for all of this staying disciplined: `just accept` stamps a throwaway
project and checks its `just ci` passes, end to end. If that ever takes more than ~2 minutes,
the chassis has gotten too heavy — see [the thin-chassis discipline](docs/explanation/chassis-design.md#the-thin-chassis-discipline).

That bucket table answers *how strict* each piece is. A second, orthogonal question — *what's it
for* — is answered by [the layered model](docs/explanation/layered-model.md): ten capability
layers grouped into Foundation (Substrate, Governance, Guardrails, Prompts, Ratchet), Cockpit
(Memory, Context Engineering, Tools/Skills, Coaching), and Readiness — two of which map directly
onto [12-factor-agents](https://github.com/humanlayer/12-factor-agents) (F2 Own your Prompts,
F3 Own your Context Window), the only two factors that describe *any* agent's behavior rather
than a specific shipped product's architecture. Which factors chassis deliberately doesn't
touch, and why, is [the two-plane model](docs/explanation/two-plane-model.md).

## The AI-usage cockpit

The one piece worth calling out specifically: six tools, installed automatically, that turn
"working with a coding agent" into something with an actual feedback loop instead of every
session starting from a blank slate. `ctx` indexes full session history so corrections don't
have to be repeated; `lean-ctx` compresses what the agent reads; `codeburn`/`abtop` surface
cost and context usage; `graphify` turns the codebase into a queryable graph; and `/dev-coach`
(a Claude Code skill) periodically turns all of that signal into concrete additions to the
project's own `AGENTS.md` — asked-for, never silent. Full writeup:
[docs/explanation/ai-usage-cockpit.md](docs/explanation/ai-usage-cockpit.md).

## Quick start

Requires [Copier](https://copier.readthedocs.io/) (`pip install copier` or `uvx copier`) and,
for the devcontainer, Docker.

```bash
copier copy gh:km2411/chassis path/to/new-project --trust
```

`--trust` is required by copier 9.x to run this template's `_tasks` (`git init`, `uv sync`,
`pre-commit install`). Only pass `--trust` for templates you actually trust — this one included.
Open the result in a devcontainer (VS Code will offer to) and you have a working, linted,
tested, guardrailed project before writing a line of your own code.

## Update a stamped project

```bash
cd path/to/stamped-project
copier update --trust
```

Note: `copier update`/`copier copy` resolve the **latest git tag**, not `main`'s HEAD — a commit
that isn't tagged yet won't show up. See
[docs/how-to/release-a-chassis-version.md](docs/how-to/release-a-chassis-version.md) if you're
the one shipping the chassis change, not just consuming it.

## What's inside a stamped project

```
AGENTS.md              — canonical agent context (CLAUDE.md symlinks to it)
.agents/skills/        — reusable agent skills (dev-coach ships by default)
.agents/memory/        — git-tracked agent memory (survives devcontainer rebuilds)
.devcontainer/         — 4-layer model: pinned image, installed toolchain, cache volumes, host-state mounts
.opengrep/rules/       — self-weakening + prompts-as-code rules, generic by default
.github/workflows/     — CI calling `just ci-*`
prompts/               — versioned prompt artifacts (never inline)
evals/                 — eval harness slot (wired-but-waiting)
docs/                  — Diátaxis skeleton (tutorials / how-to / reference / explanation)
justfile               — the one runner: just ci, just fmt, just sync, …
```

## Acceptance test

```bash
just accept    # stamp a throwaway project → just ci green
```

## Self-dogfooding

Chassis enforces its own rules on itself — `just ci` here must pass the same way it does in any
stamped project. A chassis that can't pass its own gates isn't credible as a base for anyone
else's.

## Versioning

SemVer tags + `CHANGELOG.md`. `copier update` in a stamped project pulls improvements.
See [docs/how-to/release-a-chassis-version.md](docs/how-to/release-a-chassis-version.md).

## Docs

- [The layered model](docs/explanation/layered-model.md) — the ten capability layers, mapped
  to 12-factor-agents, with a diagram. Start here for "why does this piece exist."
- [The two-plane model](docs/explanation/two-plane-model.md) — why chassis (Plane 1: how the
  software gets built) is deliberately silent about your product's own architecture (Plane 2:
  what it does once it's built).
- [AI-usage cockpit](docs/explanation/ai-usage-cockpit.md) — what the six bucket-C tools do, how
  they close the loop back into `AGENTS.md`, and how to add a seventh.
- [Devcontainer persistence](docs/explanation/devcontainer-persistence.md) — what survives a
  rebuild (git, named volumes) vs. what doesn't (the container's own filesystem), and the
  migration gotcha when adding a new volume over existing bind-mounted data.
- [Why a Copier chassis?](docs/explanation/chassis-design.md) — the A/B/C/D bucket model and the
  thin-chassis discipline, in full.
- [How to release a chassis version](docs/how-to/release-a-chassis-version.md) — the tag is the
  release, not the commit.
- [ADR log](docs/decisions/adrs/) — MADR decision records.

## Status

Solo-maintained, actively used to build real projects, evolving in the open (see `CHANGELOG.md`
for what's landed recently). Not yet 1.0 — expect the bucket contents to keep growing as gaps
get found by actually using it.
