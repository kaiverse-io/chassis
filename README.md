# chassis

> Copier template — AI-native project base for km2411 projects.

Stamps every new project with guardrails, conventional tooling, and the Plane-1 agent framework
from commit 1. See [AGENTS.md](AGENTS.md) for the agent context.

## Stamp a new project

```bash
copier copy gh:km2411/chassis path/to/new-project --trust
```

`--trust` is required by copier 9.x to run this template's `_tasks` (`git init`, `uv sync`,
`pre-commit install`). Only pass `--trust` for templates you actually trust — this one included.

## Update a stamped project

```bash
cd path/to/stamped-project
copier update --trust
```

Note: `copier update`/`copier copy` resolve the **latest git tag**, not `main`'s HEAD — a commit
that isn't tagged yet won't show up. See
[docs/how-to/release-a-chassis-version.md](docs/how-to/release-a-chassis-version.md) if you're
the one shipping the chassis change, not just consuming it.

## Acceptance test

```bash
just accept    # stamp a throwaway project → just ci green
```

## What gets stamped

| Bucket | Contents |
|---|---|
| **A — Guardrails** | AGENTS.md, `.agents/skills/`, devcontainer (4-layer), ruff+mypy, import-linter slot, opengrep self-weakening + prompts-as-code, gitleaks, conventional commits, CODEOWNERS, Diátaxis docs, `prompts/` convention |
| **B — Ratcheting** | Coverage floor, complexity ceiling |
| **C — On-demand** | [AI-usage cockpit](docs/explanation/ai-usage-cockpit.md): codeburn, abtop, AI Engineer Coach, graphify, ctx, lean-ctx |
| **D — Wired-waiting** | `evals/` (eval gate, activates P1), `.github/workflows/adlc-gate.yaml` (no-op until `evals/golden/` has fixtures), arch-drift slot |

## Versioning

SemVer tags + CHANGELOG.md. `copier update` in a stamped project pulls improvements.
See [docs/how-to/release-a-chassis-version.md](docs/how-to/release-a-chassis-version.md).

## Docs

- [AI-usage cockpit](docs/explanation/ai-usage-cockpit.md) — what the six bucket-C tools do, how
  they close the loop back into `AGENTS.md`, and how to add a seventh.
- [Devcontainer persistence](docs/explanation/devcontainer-persistence.md) — what survives a
  rebuild (git, named volumes) vs. what doesn't (the container's own filesystem), and the
  migration gotcha when adding a new volume over existing bind-mounted data.
- [Why a Copier chassis?](docs/explanation/chassis-design.md) — the A/B/C/D bucket model and the
  thin-chassis discipline.
- [How to release a chassis version](docs/how-to/release-a-chassis-version.md) — the tag is the
  release, not the commit.
- [ADR log](docs/decisions/adrs/) — MADR decision records.
