---
kind: adr
status: accepted
owner: founder
last_reviewed: 2026-08-09
---

# ADR-006 — Governance adapters for Codex CLI and goose

- **Status:** Accepted (2026-08-09)
- **Deciders:** founder

## Context

Governance's only live mechanism was `.claude/settings.json` — Claude Code specific. A sibling
project, agnova, switches between three interchangeable agent adapters on the same repo —
`claude-agent-acp`, `goose`, and `codex-acp` — so a Claude-only Governance layer left two-thirds
of chassis's real usage with no enforcement at all, only `AGENTS.md`'s prose (which those two
harnesses do read natively, per the open standard, but obeying it is up to them).

## Decision drivers

- agnova switches harnesses per agent, on the same repo — not per project, not at stamp time.
- Each harness's own config mechanism is a fixed fact, not a chassis design choice — the design
  has to fit what Codex CLI and goose actually support, not what would be convenient.
- "Thin by discipline": any addition still has to fit `just accept`'s ~2-minute forcing
  function and add no new runtime cost when a harness isn't in use.

## Considered options

1. **A Copier question selecting which harness(es) to provision.** *Rejected* — wrong shape for
   a repo where the harness changes per-agent, not per-project; would force a `copier update` +
   re-answer just to switch which ACP adapter points at an unchanged repo.
2. **Wait for a common cross-harness permission standard.** *Rejected* — none exists today
   (verified directly against each harness's own docs); waiting leaves the gap open indefinitely
   for no benefit.
3. **Stamp a best-effort adapter per harness unconditionally, each honestly scoped to what that
   harness actually supports.** *Chosen.*

## Decision

Ship three per-harness Governance adapters, all unconditional (no Copier question — see drivers
above), each honestly documented for exactly what it does and doesn't guarantee:

- **Claude Code** — `.claude/settings.json` `permissions.allow`/`deny` (unchanged from earlier;
  see the "Harness neutrality" section of `docs/explanation/design.md`).
- **Codex CLI** — `.codex/config.toml` (`approval_policy = "untrusted"`,
  `sandbox_mode = "workspace-write"`) and `.codex/rules/default.rules` (`prefix_rule` denials for
  `git commit --no-verify` / `git push --no-verify`). Codex supports a real project-level config
  that applies automatically — but only once a human has manually marked the project trusted on
  their own machine ("if you mark a project as untrusted, Codex skips project-scoped `.codex/`
  layers" — Codex's own docs); a repo can never pre-trust itself. The rules mechanism is a strict
  positional-prefix match, not a substring-anywhere glob like Claude Code's
  `Bash(*--no-verify*)` — documented directly in the rules file's own comment, not glossed over.
- **goose** — `GOOSE_MODE=smart_approve` via `devcontainer.json`'s `containerEnv`. goose has **no
  project-level permission config file at all** (confirmed against block/goose's own docs —
  `config.yaml`/`permission.yaml` are user-global only). `containerEnv`, not `remoteEnv`, because
  `remoteEnv` is scoped to VS Code Server's own sub-processes and may not reach a `goose` a
  developer launches by hand in a plain terminal; `containerEnv` reaches every process in the
  container. This is a session-wide posture (`auto`/`approve`/`chat`/`smart_approve`), not a
  per-command allow/deny list — goose has no equivalent to `permissions.allow`'s `Bash(pattern)`
  rules, and the docs say so plainly rather than implying parity with Claude Code's adapter.

None of the three is a substitute for CI. Guardrails/Ratchet remain the only unconditional
floor — see `docs/explanation/design.md`'s "Harness neutrality" section, which this ADR is
linked from.

## Consequences

**Good:** a project stamped from chassis now has a real, if imperfect, Governance posture no
matter which of the three harnesses agnova (or any other multi-harness setup) points at it, with
zero stamp-time decision required and zero runtime cost for a harness that's never installed.

**Bad / risks:** the three adapters are not equivalent in strength — Claude Code's and Codex's
require manual per-machine trust before they do anything; goose's is coarser than either. A
future contributor could mistake "an adapter exists" for "the guarantee is uniform" if they
don't read each one's own caveat. Mitigated by stating the caveats directly in
`AGENTS.md`'s "Harness-specific configuration" section, in `docs/explanation/design.md`, and in
each config file's own comments — not just in this ADR, which fewer people will read day to day.
