---
kind: adr
status: accepted
owner: platform
last_reviewed: 2026-07-08
---

# ADR-002 — Standardize an "AI-usage cockpit" bucket-C tool set across every stamped project

- **Status:** Accepted (2026-07-08)
- **Deciders:** founder

> **AMENDED 2026-07-13:** `lean-ctx` removed from the cockpit entirely. Twice caused
> machine-wide lockouts of native `Bash`/`Read`/`Grep`/`Glob` tools across every devcontainer
> on the host — it writes a hard `permissions.deny` into the shared, bind-mounted
> `~/.claude/settings.json` (one project's rebuild or even an ordinary session start could
> silently block every other stamped project's live session), via undocumented default
> behavior in an unpinned upstream dependency. The other bucket-C tools (codeburn, abtop,
> AI Engineer Coach, graphify, ctx) are unaffected and remain in place. The general rule this
> generalizes to — no silent rewriters in the agent's read path — is
> [ADR-004](adr-004-no-silent-rewriters.md); the mount-level root cause is
> [ADR-003](adr-003-settings-json-isolation.md).

> For the plain-language version of this decision — what each tool does, how the loop works,
> why it's language-agnostic, and how to extend it — see
> [docs/explanation/ai-usage-cockpit.md](../../explanation/ai-usage-cockpit.md). This ADR is the
> terse decision record; that doc is the standalone one.

## Context

Working with coding agents (Claude Code or otherwise) generates real signal about where the
agent wastes tokens, repeats corrections, or gets lost — but only if something captures it.
Before this ADR, that signal was scattered and mostly implicit: `codeburn`/`abtop`/AI Engineer
Coach existed (v0.3.0) but only as isolated bucket-C installs, and `/dev-coach` only read
memory files and `git log` — a narrow proxy that misses anything the agent didn't choose to
write down.

Three more tools close real gaps in that signal, and were validated by hand (installed, run,
inspected) in a live devcontainer before being templated here — not templated on the strength of
a README alone:

- **graphify** — turns a codebase into a queryable knowledge graph (`graph.json`), so an agent
  spends fewer tokens re-discovering structure it should be able to look up.
- **ctx** — indexes full local session transcripts (not just what got written to memory) so
  `/dev-coach` can search for repeated corrections directly, instead of relying on memory files
  a past session may not have written.
- **lean-ctx** — a context-compression MCP layer with its own receipts (`lean-ctx gain`,
  `lean-ctx heatmap`) showing which files get re-read at full size repeatedly — a second,
  independent signal for the same underlying gap (missing memory / missing skill).

Two installation lessons came out of the validation pass, both encoded in `post-create.sh`
comments so they don't get re-discovered the hard way on the next chassis edit:

1. `ctx` has no prebuilt GitHub Release asset and needs Rust 1.81+ (Debian's `apt` rustc is
   1.63) to build from source — its own installer script (fetches a prebuilt binary directly)
   is simpler and lighter than bootstrapping a Rust toolchain for one CLI.
2. `lean-ctx`'s source build (edition 2024, full feature set: embeddings, gateway/team/cloud
   server, ONNX runtime, tree-sitter for 27 languages) OOM'd an 8GB devcontainer via its LTO
   release profile. Its npm-packaged prebuilt binary (`lean-ctx-bin`) avoids the build entirely.

## Decision

Add `graphify`, `ctx`, and `lean-ctx` to the chassis's bucket-C cockpit in
`.devcontainer/post-create.sh`, installed the same way every other bucket-C tool is: idempotent
(`command -v` guarded), non-blocking (`|| echo "[warn] ... install manually"`), no project-language
coupling. Generalize `/dev-coach` (steps 2a/3a) to use `ctx search` and `lean-ctx gain`/`heatmap`
as additional, optional signal sources alongside memory files and `git log` — neither is required;
both sharpen the same detection the skill already does.

This is deliberately a **Plane-1 (dev-process) decision, not a Plane-2 (product) one** — it
governs how agents build whatever is stamped from this chassis, not how any stamped project's
own shipped product evaluates itself. A project that also needs product-quality evals wires
those through its own `evals/` slot (bucket D), independently of this cockpit.

## Consequences

**Good:** every future project stamped from chassis gets the full cockpit and the sharpened
`/dev-coach` loop from commit 1, with no per-project setup. The install lessons above are now
load-bearing comments, not tribal knowledge re-derived per project.

**Bad:** six bucket-C tools now run in every `post-create.sh`, adding real wall-clock time to
`just accept` (the thin-chassis acceptance test) — worth watching if that budget starts to matter
more than the coverage. `lean-ctx` in particular auto-writes a block into the *global*
`~/.claude/CLAUDE.md` and wires MCP config for other tools on the machine (VS Code, GitHub
Copilot, Amazon Q) during `lean-ctx onboard` — machine-wide, not project-scoped; documented here
so it's a known tradeoff rather than a surprise.

**Follow-up:** none of these six tools are required for `just ci` to pass — bucket C stays
strictly on-demand/non-blocking by definition.
