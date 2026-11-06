---
kind: adr
status: accepted
owner: founder
last_reviewed: 2026-11-06
---

# ADR-011 — Deny one-way doors, reviewed MCP config, bounded AGENTS.md, and #10's slots

- **Status:** Accepted (2026-11-06)
- **Deciders:** founder

## Context

chassis#10 sorts practices into "template", "slot only" and "not chassis", and #9 asks for
deny defaults and a review pattern. On a fresh stamp: the only denied command was
`--no-verify`, so force-push, `reset --hard` and `clean -f` ran unprompted under a permissive
mode; there was no reviewed place for MCP servers; `AGENTS.md` — loaded by every session — had
no size bound (150 lines and growing); and the feature-map, boundary-test and review-pattern
slots did not exist.

## Decision

- **One-way doors denied** in both harness configs chassis stamps: `.claude/settings.json`
  denies `git push --force*` / `-f*` (either position), `git reset --hard*`, `git clean -f*`;
  `.codex/rules/default.rules` forbids the same prefixes (with Codex's documented
  prefix-match limitation). A project's own data-loss commands (dropping a migration, deleting
  a bucket) are its to add.
- **`.mcp.json`** is stamped with no servers, under CODEOWNERS: the one reviewed place an MCP
  server is added.
- **`AGENTS.md` size gate** (`_ci-agents-size`, 200 lines, in `ci-lint`): it is an index into
  `docs/`, not the docs. `AGENTS.md` joins CODEOWNERS.
- **Slots** (#10's "slot only" column): `docs/feature-map.md` (heading + one example row),
  `tests/boundary/` (README; empty, so pytest collects nothing until filled),
  `docs/how-to/review-agent-changes.md` (fresh-context review, one-way doors, regenerate over
  patch — #9's review pattern and disposable-code note, in one place).

Not taken: `git commit *` stays pre-allowed with `--no-verify` denied — the existing, tested
choice (`settings-json-no-broad-git-commit.sh`); flipping it is a separate decision. No harness
sandbox settings: they differ per harness and per version, and a wrong one fails open.

## Consequences

**Good:** an irreversible git operation needs a human in every stamped harness; MCP access
and the steering file change only with review; #10's slots exist to be filled.

**Bad:** a project that legitimately force-pushes (a release branch rewrite) does it by hand.
Existing projects whose `AGENTS.md` is over 200 lines fail `ci-lint` after `copier update`
until they move detail into `docs/`.
