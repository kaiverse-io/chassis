# chassis

> A [Copier](https://copier.readthedocs.io/) template that stamps new projects with AI-native
> guardrails, a working devcontainer, and an AI-usage cockpit — from commit 1, not bolted on
> after the fact.

Coding agents are fast enough that "we'll add guardrails later" stops being true — by the time
you notice you need import boundaries, a coverage floor, or secret scanning, an agent has
already committed a few hundred lines without them. Chassis is a compounding answer: stamp a
project once and every guardrail is already there; improve the chassis and `copier update`
flows the improvement into every stamped project as a real diff, with conflicts surfaced
instead of silently lost. See [the design doc](docs/explanation/design.md) for the full
reasoning.

## What you get

Every tool is wired in from the first commit. What varies is *how strict it is* — the A/B/C/D
bucket model:

| Bucket | Behavior | What's in it |
|---|---|---|
| **A — Guardrails** | Blocks the commit or CI run. For things where "wrong" is always wrong. | `AGENTS.md`, ruff+mypy, import-linter boundary slot, opengrep self-weakening + prompts-as-code rules, gitleaks, conventional commits, CODEOWNERS, Diátaxis docs, `prompts/` convention, a 4-layer devcontainer |
| **B — Ratcheting** | Present from day one; the threshold only ever increases. | Coverage floor (start at 0%, raise as you write tests), complexity ceiling |
| **C — On-demand** | Installed automatically, never blocks anything — run it when it's useful. | The [AI-usage cockpit](docs/explanation/ai-usage-cockpit.md): `codeburn`, `abtop`, AI Engineer Coach, `graphify`, `ctx` |
| **D — Wired-but-waiting** | The slot exists in CI/config from day one but is a deliberate no-op until its input exists. | `evals/` (eval gate), ADLC agent-change gate, arch-drift slot |

The cockpit is the piece worth calling out: five tools that turn "working with a coding agent"
into something with a feedback loop. `ctx` indexes full session history so corrections don't
have to be repeated; `codeburn`/`abtop` surface cost and context usage; `graphify` turns the
codebase into a queryable graph; and `/dev-coach` periodically turns that signal into concrete
additions to the project's own `AGENTS.md` — asked-for, never silent.

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

## Working on chassis itself

Chassis has its own standalone devcontainer — `git clone` this repo alone and "Reopen in
Container." Its `post-create.sh`, Claude Code settings/hooks, and `dev-coach` skill are
**symlinks** into `template/`, so chassis dogfoods the identical cockpit it ships with zero
drift possible. `just ci` lints the chassis itself; `just accept` stamps a throwaway project
and verifies its `just ci` is green — if that ever takes more than ~2 minutes, the chassis has
gotten too heavy. Full reasoning in `AGENTS.md`.

## Versioning

SemVer tags + `CHANGELOG.md`. `copier update` in a stamped project pulls improvements.
See [docs/how-to/release-a-chassis-version.md](docs/how-to/release-a-chassis-version.md).

## Docs

- [Design](docs/explanation/design.md) — the problem, the two-plane model, the A/B/C/D
  buckets, the ten capability layers, and the thin-chassis discipline. Start here for
  "why does this piece exist."
- [AI-usage cockpit](docs/explanation/ai-usage-cockpit.md) — what the five bucket-C tools do,
  how they close the loop back into `AGENTS.md`, and how to add a sixth.
- [Devcontainer persistence](docs/explanation/devcontainer-persistence.md) — what survives a
  rebuild vs. what doesn't, and why.
- [ADR log](docs/decisions/adrs/) — MADR decision records.

## Status

Solo-maintained, actively used to build real projects, evolving in the open (see `CHANGELOG.md`).
Not yet 1.0 — expect the bucket contents to keep growing as gaps get found by actually using it.
