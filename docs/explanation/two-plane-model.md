---
kind: explanation
status: active
last_reviewed: 2026-07-08
---

# The two-plane model

Every other doc in here — the [layered model](layered-model.md), the [bucket
model](chassis-design.md), the [AI-usage cockpit](ai-usage-cockpit.md) — assumes a distinction
that's never actually been spelled out on its own: **chassis and the thing you build with it are
two different planes, governed by two different sets of concerns.** This is that doc.

## The two planes

**Plane 1 — how the software gets built.** The dev process. The agent (human + AI, working
together) writing code, running tests, making commits. Chassis lives entirely here: guardrails,
the coaching loop, the devcontainer, the AI-usage cockpit. Its unit of concern is *this
session, this commit, this PR* — did the work go well, did a mistake get corrected once and
never repeated, is the codebase in a state the next session can pick up cleanly.

**Plane 2 — what the software does once it's built.** The shipped product. If what you're
building is itself an AI agent (chassis's primary use case, though not its only one), Plane 2 is
that agent's own runtime architecture: how it turns language into tool calls, how it manages its
own execution state, how it's triggered, how it talks to humans. Its unit of concern is
*production traffic* — did the agent do the right thing for a real user, is the loop between
"it made a mistake" and "it won't make that mistake again" closing for the *product*, not just
for the code that built it.

## Why the distinction is load-bearing, not academic

Two mistakes follow directly from collapsing this distinction, and both have concrete symptoms:

**Mistake 1: importing Plane-2 concerns into chassis.** 12-factor-agents ([the layered
model](layered-model.md) explains this in detail) is a Plane-2 framework — it's about how to
architect a *shipped* agent. Ten of its twelve factors don't belong in chassis at all, because
chassis doesn't know what you're shipping. If chassis tried to prescribe "how your agent should
manage execution state" (F5) or "how your agent should be triggered" (F11), it would be making
product decisions on your behalf. The two factors that *do* show up in chassis (F2 Own your
Prompts, F3 Own your Context Window) are the only two that are actually about Plane 1 as well —
they describe how *any* agent works, including the one currently building your software.

**Mistake 2: importing Plane-1 tooling into Plane-2's quality bar.** The AI-usage cockpit closes
a loop for the *dev process* — `/dev-coach` turns a repeated correction into a durable
`AGENTS.md` rule. That is not the same loop a shipped product needs. A shipped agent's quality
loop runs on production traces and eval scores (Braintrust-shaped: turn a bad production
response into a regression test), not on `git log` and session transcripts. Chassis's `evals/`
slot (bucket D, wired-but-waiting) exists specifically so that when you're ready to build Plane
2's quality loop, there's a slot already provisioned — but chassis doesn't populate it, because
it can't know your product's eval criteria in advance.

## A concrete example

Say you're using chassis to build a customer-support agent. Plane 1 is: you and Claude Code (or
whatever agent you're using) writing the support agent's code, in a devcontainer chassis
provisioned, with `ctx`/`lean-ctx` managing *your* context window while you work, and
`/dev-coach` making sure you don't keep re-explaining the same architectural constraint every
session. Plane 2 is: the support agent itself, once deployed, deciding how to route a ticket,
when to escalate to a human, how it manages the state of a multi-turn conversation with a real
customer. Those are different agents, different failure modes, different loops. Chassis only
ever touches the first one.

## Where this shows up elsewhere in the docs

- [The layered model](layered-model.md) draws this exact line at F2/F3 — the only two
  12-factor-agents factors that are genuinely Plane-1 concerns.
- [The AI-usage cockpit](ai-usage-cockpit.md) is explicit that `/dev-coach`'s loop is "about
  dev-process friction, not product-quality scoring."
- The `evals/` bucket-D slot is Plane 2's entry point into chassis — provisioned, not populated,
  precisely because chassis can't make Plane-2 decisions for you.
