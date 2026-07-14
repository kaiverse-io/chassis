---
kind: adr
status: accepted
owner: platform
last_reviewed: 2026-07-13
---

# ADR-004 — No silent rewriters in the agent's read path

- **Status:** Accepted
- **Deciders:** founder
- **Date:** 2026-07-13

## Context

A class of tool markets itself to coding-agent users as a "token optimizer": it installs a hook
(or a wire proxy) that intercepts the output of the commands an agent runs and compresses or
rewrites that output before the agent sees it, advertising 60–90% token reduction. The chassis
has now encountered this class twice — `lean-ctx`, which we shipped and then removed
([ADR-002](adr-002-ai-usage-cockpit.md) amendment), and `rtk`, which was briefly proposed as
`lean-ctx`'s replacement. This ADR generalizes both into one standing rule for the cockpit and
records the evidence, so the decision doesn't get re-litigated tool-by-tool.

### A taxonomy for tools that sit near the agent

Classify any candidate cockpit tool by **where it sits in the agent's observation/action path**:

1. **Observers** — read session logs or repo state after the fact (`codeburn`, `abtop`,
   AI Engineer Coach, `ccusage`). Never in the loop.
2. **Advisors** — on-demand, agent-invoked, output is *additive* context; native tools untouched
   (`graphify` queries, `ctx search`, skills, memory). Their failure mode is staleness or
   non-use, not deception.
3. **Gates** — deterministically block an action and **fail loudly**, surfacing the reason to the
   agent and the transcript (pre-commit, CI, the coverage ratchet, a PreToolUse deny). A block
   you can see is a block you can argue with.
4. **Interceptors** — sit inside the read/action path and silently transform what the agent
   perceives. This is the token-optimizer class.

The first three are admissible in the cockpit (bucket C, with version pinning). This ADR is about
the fourth.

### The three meters, and the one that matters

A token optimizer has three meters that rarely agree — the *vendor claim* ("60–90%"), the
*product's own dashboard* ("saved 1,243 tokens on that command"), and the *provider bill*. An
independent, pre-registered benchmark on a real agentic SDLC workload (Entelligentsia/`tokbench`)
measured the third against a no-middleware baseline and found billed **input** tokens *rose*:
`rtk` **+27%**, `lean-ctx` **+38–59%**, `headroom` **+43%**; `lean-ctx`'s own dashboard reported
"0 tokens saved · 0.0%" while the bill went up, and its maintainer conceded the dashboard
"overstated the net effect." An independent replay of `headroom` similarly found ~2.8% of real
session spend saved against a 60–95% claim. None of these three meters captures the meter chassis
actually cares about: **tokens per successfully completed task, including the recovery loops a
corrupted observation causes.** Per-command reduction is a Goodhart metric; tokens-per-solve is
the honest one.

## Decision drivers

- The chassis is an *unattended template* that stamps defaults into strangers' containers and
  runs in increasingly autonomous contexts — precisely where an unsupervised interceptor's
  failures stop being caught by a human reading the output.
- The failure mode of an interceptor is invisible by construction: the tool that corrupts an
  observation also filters the diagnostics the agent would use to notice.
- Substrate risk (rogue config writes) is containable; epistemic risk (a lie in the read path) is
  not — see below.

## Considered options

1. **`rtk`** (`rtk-ai/rtk`, Apache-2.0; ~29k★ at the article's April 2026 test date, ~70k★ by
   July 2026) — a PreToolUse hook that rewrites Bash commands through `rtk` and regex-filters the
   output. *Rejected* — see the evidence below.
2. **`lean-ctx`** (`yvgude/lean-ctx`, Apache-2.0) — shell hooks + PreToolUse rewrites + an
   optional wire proxy. *Rejected*; already removed in v0.7.8/0.7.9. See below.
3. **Adopt nothing; lean on the native baseline.** *Chosen for the template.* Claude Code and the
   Anthropic platform already provide the observer, advisor, and gate layers with loud-failure
   semantics — prompt caching (which third-party rewriting of already-sent turns *invalidates*),
   microcompact and `/compact`, subagents for context isolation, progressive disclosure of
   skills/rules, MCP tool-search deferral, `/context`–`/usage` visibility, and PreToolUse hooks
   as sanctioned loud gates. The only capability with *no* native equivalent is silent mid-flight
   transformation — exactly the rejected class.
4. **Per-project, opt-in, allowlisted interceptor.** *Permitted for an individual project, never
   as a template default* — see "Consequences."

## Decision

**No tool that silently transforms what the agent perceives on the hot path (an interceptor) ships
as a chassis cockpit default — categorically, regardless of the token savings it claims or its
current bug count.** Token frugality is pursued on the demand side instead (reduce the *need* to
read: `graphify` for structure, `ctx` for recall, memory/skills so lessons aren't re-derived,
`/dev-coach` to turn repeat-reads into durable rules) and via the native baseline above.

The litmus test for any future candidate: *does it silently transform what the agent perceives on
the hot path?* If yes, it's out.

### Evidence

**The rtk-test adversarial suite** (`TheDecipherist/rtk-test`; 60+ scenarios across 11
categories, 16 comparative tests; `rtk` v0.37.1 and `lean-ctx` v3.2.5, Linux, April 2026) scored
`rtk` **0 of 16** critical scenarios safe and `lean-ctx` **9 of 16**. Four `rtk` failures replaced
correct output with *incorrect* output rather than merely truncating:

- `rtk ls` hid the bare `.env` filename specifically — the exact state in which an agent
  "creates" a missing `.env` and overwrites live credentials.
- `rtk git status` rewrote `HEAD detached at <sha>` to `HEAD (no branch)` — every
  `actions/checkout`, submodule update, and tag checkout is detached HEAD; commits made under
  the misread dangle and are eventually GC'd while status reports clean.
- `rtk log` recognized only ERROR/WARN/INFO/DEBUG and silently dropped `[CRITICAL]`/`FATAL`/
  `ALERT` — Python stdlib's own highest severity.
- `rtk pip list` reported exactly 2 packages regardless of the real count, with no truncation
  indicator — breaking dependency and CVE checks outright.

(The suite's plain-English write-up was later removed from that repo; the harness and its
findings docs remain, and are the citation.)

**Upstream fixed all four**, verified against `rtk` source at HEAD (v0.43.0): a CHANGELOG entry
"filters: address adversarial test-suite findings on aggressive filtering" (commit `62fc0e0`);
`extract_detached_head()` now preserves the warning, `log_cmd.rs` buckets
CRITICAL/FATAL/ALERT/EMERGENCY, `pip_cmd.rs` gained a `never_worse(&raw, &filtered)` guard, and
the `.env` filter is gone from `ls.rs`. **The fixes do not change the decision.** The four bugs
shipped silently to a five-figure user base for months and were found only by adversarial
testing; patching four instances does not remove the category property that made them invisible.

**The category property, demonstrated twice by lean-ctx itself.** `lean-ctx` was removed from the
chassis (v0.7.8/0.7.9) for writing an undocumented machine-wide `permissions.deny` for
`Bash`/`Read`/`Grep`/`Glob` into the shared `~/.claude/settings.json` — a removal that *predates
and is independent of* the rtk-test article. The project then responded to rtk-test admirably,
fixing every fidelity finding within days (v3.3.0–v3.3.9), adding adversarial tests to CI, and
publishing a safety-tier table. And yet, three months later (v3.9.7/v3.9.8, July 2026), it made
a "Replace mode" that again writes `permissions.deny: [Read, Grep, Glob, Bash]` into
`~/.claude/settings.json` the *automatic default* for Claude Code — undocumented in its README —
which broke Claude Code plugins within a day (`lean-ctx` issue #799, filed 2026-07-13; the fix
removes only `Bash`, leaving `Read`/`Grep`/`Glob` denied by design). A responsive, well-run
project reproduced the exact class of incident that got it removed. That is the point: the risk is
structural to sitting in the read/action path, not a function of any one maintainer's diligence.

**Why isolation doesn't help.** Devcontainers and the per-project `settings.json` carve-out
([ADR-003](adr-003-settings-json-isolation.md)) contain *substrate* risk — a rogue config write
can't escape one container. No isolation boundary contains *epistemic* risk: a filter running
inside a pristine container still lies to the agent inside that container. A sandbox constrains
what a tool can *touch*, not what it can make the agent *believe*.

## Consequences

**Good:** the cockpit stays trustworthy by construction — every tool in it is an observer, an
advisor, or a loud gate, none of which can silently corrupt the agent's view of the world. The
token-frugality goal is met on the demand side and by native platform features, which the
independent benchmarks above suggest is where the real savings are anyway.

**Bad / risks:** chassis forgoes the *advertised* upside of output compression on genuinely
verbose, low-stakes commands (large `aws`/`docker`/`kubectl`/registry output), where an
interceptor's risk is lowest. A specific project that wants this may adopt an interceptor
**personally and project-scoped**, allowlisted to verbose read-only cloud output and never to
`git status`/`git diff`/logs/`ls`/`pip` — the rtk-test author's own recommended mitigation is
exactly such a disable-list. That is a per-project choice, never a template default. (Note also
the security face of this class: any tool that sits on `ANTHROPIC_BASE_URL` inherits proxy-grade
risk — e.g. the CORS key-exposure advisory GHSA-8hmm-4crw-vm2c in `claude-code-router`.)

### Revisit criteria

This is a category decision, not a permanent blacklist of two named tools. A rejected interceptor
becomes reconsiderable for the template only when **all** of the following hold, established by
evaluation rather than by re-argument:

1. **Mechanism audit** — installing it (and running it once) writes nothing undocumented to
   `~/.claude/settings.json`, shell RCs, or MCP config, and makes no undisclosed egress.
2. **Fidelity audit** — an *independent* re-run of the rtk-test scenarios against the *current*
   version shows zero lossy-silent failures on decision-critical facts (`.env` presence, detached
   HEAD, CRITICAL log lines, dependency lists, diff content, exit codes).
3. **Outcome economics** — a paired, tool-on/tool-off A/B on a fixed task suite shows
   **tokens-per-solve reduced** (95% CI excluding zero) with pass@1 non-inferior (≥ −2pp) and no
   increase in recovery-loop tax on an adversarial-aligned stratum.
4. **Track record** — six months without an undocumented config-write incident.

The path back in is the evaluation harness, not the argument.
