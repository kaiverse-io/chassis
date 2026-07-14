---
kind: explanation
status: active
last_reviewed: 2026-07-13
---

# The AI-usage cockpit: a repeatable practice for working with coding agents

This explains the *practice*, not just the install list. If you only want the install list,
see `.devcontainer/post-create.sh` and [ADR-002](../decisions/adrs/adr-002-ai-usage-cockpit.md).

## The problem this solves

Working with a coding agent (Claude Code or otherwise) generates real signal — where it wastes
tokens, where it repeats a mistake, where you correct it twice for the same thing — but only if
something captures that signal and only if something turns it into a durable change. Without
both halves, every project relearns the same lessons from a blank slate, and every session
starts over with no memory of what already went wrong.

This practice is two things working together: **five small tools that capture signal**, and
**one skill (`/dev-coach`) that turns signal into a durable change** (an addition to the
project's own `AGENTS.md`, asked-for and confirmed, never silent).

It is not tied to any one project, to Python, or to Claude Code specifically (though the
loop-closing skill happens to be Claude-Code-native today — see "Language and tool agnosticism"
below). It lives in this chassis so any project stamped from it gets the practice for free,
from commit 1.

## The five tools, and what each one actually contributes

| Tool | Captures | Role |
|---|---|---|
| **codeburn** | Cost/burn, one-shot rate, by project/model/task | Feeds `/dev-coach`'s step 1 |
| **abtop** | Live context %, tokens, rate limits | Real-time only; nothing to close a loop on |
| **AI Engineer Coach** | 45 anti-pattern rules, practice scores (VS Code dashboard) | Parallel, broader view — complements `/dev-coach`, doesn't replace it |
| **graphify** | A queryable knowledge graph of the codebase | Comprehension accelerant — fewer tokens spent re-discovering structure |
| **ctx** | Full local session transcripts, indexed and searchable | Feeds `/dev-coach`'s step 2a — finds corrections the agent got that never made it into a memory file |

Only two of the five feed the loop directly (`ctx` and `codeburn`). The others are legitimate
on their own: `abtop` is just a live dashboard, `graphify` just makes the agent faster at
understanding code, `AI Engineer Coach` is a second, independent lens. None of them are
required for any other tool to work — that's deliberate (see "Quality controls").

Every tool in the cockpit is a **passive observer or an on-demand advisor**: it reads local
session data or answers when asked, and nothing sits between the agent and its context
rewriting what the agent sees. That's a hard boundary, not a coincidence — see
[ADR-004](../decisions/adrs/adr-004-no-silent-rewriters.md) for why silent rewriters
(token-optimizer proxies and output filters) are categorically excluded from this cockpit,
and [the design doc](design.md) for the taxonomy behind that line.

One cost note: `abtop`'s optional session summaries shell out to `claude --print`, which makes
its own API call — the only cockpit feature that spends tokens rather than merely observing
them. Everything else reads local files only.

`ctx`'s session-history index does not currently survive a devcontainer rebuild — see
[docs/explanation/devcontainer-persistence.md](devcontainer-persistence.md) for why, and what
fixing it would look like. It self-heals: `ctx setup` re-indexes existing transcripts on every
build.

## The loop, concretely

1. You work with an agent. It makes a mistake, or you correct it, or it re-reads the same file
   five times across a week of sessions.
2. `ctx` captures that regardless of whether anyone thought to write it down, because it
   indexes the actual transcript.
3. Periodically (or right after a frustrating session), you run `/dev-coach`. It pulls
   `codeburn`'s cost signal, searches `ctx` for correction-shaped phrases, cross-references
   what's already covered by existing rules, and proposes a specific addition to `AGENTS.md` —
   then asks before writing it.
4. The fix is now durable. The next session — yours or anyone else's — starts with the lesson
   already learned, instead of relearning it from a blank slate.

This is the **dev-process loop** (how agents build whatever you're stamping from this chassis).
It is a different loop from **product evals** (`evals/`, bucket D) — that one scores what a
*shipped product's own agents* produce for end users, once there's live traffic to score. Don't
conflate the two: this cockpit is about you and the agent working together, not about whatever
the two of you eventually ship.

## Language and tool agnosticism

Every tool in this cockpit is a devcontainer-level install (`npm`, `uv`, a project's own
installer) — none of them care what language the *stamped project* is written in. A Go project,
a Rust project, a pure-frontend project stamped from this chassis gets the exact same cockpit a
Python project does, because the cockpit operates one layer below the project's own language:
it watches the *agent*, not the *codebase*.

The one caveat: `/dev-coach` as written today is Claude-Code-native (it reads Claude Code's own
memory-file convention and hooks). The signal sources (`ctx`, `codeburn`) are themselves
multi-agent (`ctx` explicitly supports 30+ coding agents). Porting the loop-closing half to a
different harness means rewriting `/dev-coach` against that harness's own
memory/instruction-file convention — the signal-capture half needs no changes.

## Quality controls

- **Every install is idempotent and non-blocking.** Each tool is guarded by `command -v <tool>
  || install`, and every install failure degrades to a `[warn]` message, never a failed
  `post-create.sh` run. None of these tools can break `just ci` — they're additive by
  construction, not gates.
- **Every install is version-pinned.** A template that runs unattended in other people's
  containers doesn't get to install "latest" — see the pinned versions in `post-create.sh`.
- **`/dev-coach` never edits silently.** It reports what it found and the evidence (a transcript
  hit, a memory file that was never promoted), proposes exact text, and waits for confirmation
  before writing anything.
- **Every signal source is optional.** `/dev-coach` runs its full loop with only memory
  files and `git log` if `ctx` isn't present — step 2a sharpens the signal, it doesn't gate it.

## Extending this cockpit

Before adding a tool, classify it: **observer** (reads session data after the fact), **advisor**
(answers when the agent asks), **gate** (blocks loudly and deterministically), or
**interceptor** (silently transforms what the agent sees in flight). The first three are
admissible here; interceptors never are, no matter the token savings claimed —
[ADR-004](../decisions/adrs/adr-004-no-silent-rewriters.md) has the full argument and the
evidence.

The install pattern is the reusable part — apply it to add another tool:

```bash
if ! command -v <tool> >/dev/null 2>&1; then
  echo "→ Installing <tool> …"
  <simplest official install command, PINNED to a version — prefer a versioned GitHub
   Release binary or a pinned npm/uv install over piping an install script through sh,
   and prefer either over building from source>
    || echo "[warn] <tool> install failed — install manually: <command>"
fi
```

Two install-method lessons worth checking before adding a Rust-based tool specifically: confirm
it ships a prebuilt binary (via its own installer, `cargo-binstall`, or an npm-packaged wrapper)
before reaching for `cargo build --release` — a full-featured Rust project's release profile
(LTO, `codegen-units=1`) can need far more RAM than a typical devcontainer has, and a modern
crate may need a newer `rustc` than Debian's `apt` package provides.

If the new tool produces a signal worth closing the loop on (corrections, rework, repeat-reads),
add a step to `/dev-coach` describing how to query it — following the shape of step 2a — so
the loop-closing half stays a single skill instead of one script per tool.
