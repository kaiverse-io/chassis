# chassis

> Copier template — AI-native project base for km2411 projects.

Stamps every new project with guardrails, conventional tooling, and the Plane-1 agent framework
from commit 1. See [AGENTS.md](AGENTS.md) for the agent context.

## Stamp a new project

```bash
copier copy gh:km2411/chassis path/to/new-project
```

## Update a stamped project

```bash
cd path/to/stamped-project
copier update
```

## Acceptance test

```bash
just accept    # stamp a throwaway project → just ci green
```

## What gets stamped

| Bucket | Contents |
|---|---|
| **A — Guardrails** | AGENTS.md, `.agents/skills/`, devcontainer (4-layer), ruff+mypy, import-linter slot, opengrep self-weakening + prompts-as-code, gitleaks, conventional commits, CODEOWNERS, Diátaxis docs, `prompts/` convention |
| **B — Ratcheting** | Coverage floor, complexity ceiling |
| **C — On-demand** | codeburn AI metrics |
| **D — Wired-waiting** | `evals/` (eval gate, activates P1), `.github/workflows/adlc-gate.yaml` (no-op until `evals/golden/` has fixtures), arch-drift slot |

## Versioning

SemVer tags + CHANGELOG.md. `copier update` in a stamped project pulls improvements.
