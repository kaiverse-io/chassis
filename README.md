# chassis

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Copier](https://img.shields.io/badge/copier-9.x-blue.svg)](https://copier.readthedocs.io/)
[![Release](https://img.shields.io/github/v/release/kaiverse-io/chassis?display_name=tag)](https://github.com/kaiverse-io/chassis/releases)
[![CI](https://github.com/kaiverse-io/chassis/actions/workflows/ci.yml/badge.svg)](https://github.com/kaiverse-io/chassis/actions/workflows/ci.yml)

**A [Copier](https://copier.readthedocs.io/) template that stamps AI-native Python projects with guardrails from commit 1** — not bolted on after an agent has already shipped a few hundred unguarded lines.

Stamp once; every gate is already there. Improve the chassis; `copier update` flows the change into every stamped project as a real diff. Full reasoning: [design doc](docs/explanation/design.md).

## Quick start

Requires Copier (`pip install copier` or `uvx copier`) and Docker for the devcontainer.

```bash
copier copy gh:kaiverse-io/chassis path/to/new-project --trust
```

`--trust` is required by Copier 9.x for this template's `_tasks` (`git init`, `uv sync`, `pre-commit install`). Only pass it for templates you actually trust.

Default license answer: **Apache-2.0** (MIT and Proprietary remain available).

Open the result in a devcontainer and you have a linted, tested, guardrailed project before writing a line of your own code.

```bash
cd path/to/stamped-project
copier update --trust    # pulls the latest *tag*, not main HEAD
```

## What you get

| Bucket | Behavior | Contents |
|---|---|---|
| **A — Guardrails** | Blocks commit / CI when wrong is always wrong | `AGENTS.md`, ruff + mypy, import-linter slot, opengrep self-weakening + prompts-as-code, gitleaks, conventional commits, CODEOWNERS, Diátaxis docs, `prompts/` convention, `ARCHITECTURE.md` coverage (`just ci-arch`), 4-layer devcontainer |
| **B — Ratcheting** | Present from day one; thresholds only rise | Coverage floor (`coverage_fail_under`, default `0`), complexity ceiling |
| **C — On-demand** | Installed, never blocking | [AI-usage cockpit](docs/explanation/ai-usage-cockpit.md): `codeburn`, `abtop`, AI Engineer Coach, `graphify`, `ctx`; `/arch-review` skill |
| **D — Wired-but-waiting** | Slot exists; no-op until input exists | `evals/` gate, ADLC agent-change gate |

The cockpit closes the loop: session history (`ctx`), cost/context (`codeburn` / `abtop`), codebase graph (`graphify`), and `/dev-coach` turning signal into durable `AGENTS.md` rules — asked-for, never silent.

## Working on chassis itself

Chassis has a standalone devcontainer — clone this repo alone and reopen in container. `post-create.sh`, Claude Code settings/hooks, and `dev-coach` are **symlinks into `template/`**, so chassis dogfoods the identical cockpit it ships. `just ci` lints the chassis; `just accept` stamps a throwaway project and requires its `just ci` green (~2 minutes ceiling — if slower, the chassis is too heavy).

## Versioning

SemVer tags + [`CHANGELOG.md`](CHANGELOG.md). Consumers resolve the **latest tag**, not `main`. Release process: [CONTRIBUTING.md](CONTRIBUTING.md#releasing-a-version).

## Documentation

- [Design](docs/explanation/design.md) — principles, two-plane model, A/B/C/D buckets, thin-chassis discipline
- [AI-usage cockpit](docs/explanation/ai-usage-cockpit.md)
- [Devcontainer persistence](docs/explanation/devcontainer-persistence.md)
- [ADR log](docs/decisions/adrs/)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Security reports: [SECURITY.md](SECURITY.md).

## License

[Apache License 2.0](LICENSE)

Solo-maintained, used on real projects, evolving in the open. Pre-1.0 — bucket contents will keep growing as gaps show up in practice.
