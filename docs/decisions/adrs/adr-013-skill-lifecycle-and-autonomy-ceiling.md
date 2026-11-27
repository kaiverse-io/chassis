---
kind: adr
status: proposed
owner: founder
last_reviewed: 2026-11-25
---

# ADR-013 — Skill lifecycle, and the autonomy ceiling on steering files

- **Status:** Proposed (2026-11-25)
- **Deciders:** founder

## Context

Chassis ships skills (`arch-review`, `dev-coach`, `ub-mode`, `security-audit`) and already has
the pieces of a loop around them without a stated shape: `dev-coach` reads sessions
(observe), the agent-memory convention (capture), `copier update` (spread), and the ADLC
agent-change gate (a fix gate, still a no-op). chassis#21 (hygiene gate) and #22 (friction log)
add more. Uber's write-up of running 5,000+ skills
(<https://www.uber.com/us/en/blog/optimizing-ubers-agent-skills/>, vendor-reported) frames the
whole as one loop: capture, run, observe, fix, prune, spread, and describes agents that file
their own bug reports.

The pull is toward a system that evolves its own skills. The risk is the one the repo already
defends against elsewhere: an agent that can edit the check can make any change pass it
(chassis#10, CODEOWNERS on the gates), and ADR-004 excludes anything that silently rewrites what
the agent reads. A skill is a steering file, so a curator that edits skills unreviewed is the
same hazard applied to the agent's own instructions.

[docs/explanation/skill-lifecycle-principles.md](../../explanation/skill-lifecycle-principles.md)
sets out the principles and their grounding; this ADR records the decisions that follow from
them.

## Decision drivers

- Adaptation is wanted, but only where it is safe.
- Enforcement over documentation: each rule maps to a check, or is labelled judgement.
- Evidence before change; deletion is a first-class outcome.
- General: no dependency on one harness or one language.

## Considered options

1. **Keep adding pieces ad hoc.** Rejected: the shape is implicit, and each piece re-argues
   who may change what.
2. **An autonomous curator that creates, edits and prunes skills, merging when evals pass.**
   Rejected: evals here are not yet a trustworthy sole judge (the eval slot is empty in the
   template), and "green CI" is exactly the signal an agent that edits its own steering can
   satisfy. Uber's own pipeline keeps an approval step.
3. **A loop where agents observe and propose and humans approve; principles fixed, practices
   adaptable.** *Chosen.*

## Decision

1. **Two layers.** *Principles* (the document above, and ADRs) change only by a human-written
   ADR. *Practices* (skills, rules, prompts, hooks, config) may be created, rewritten and
   retired through the loop.
2. **Autonomy ceiling.** Level 0 log friction or a run; 1 file an issue with evidence; 2 open a
   draft change to a steering file. Levels 3 (approve and merge a change to a steering file)
   and 4 (change a principle) are human only. Steering files: `AGENTS.md`, `.agents/skills/**`,
   `.claude/**`, `.codex/**`, prompts. Emergency exceptions to a rule are a human's, and are
   recorded.
3. **Precedence** when sources conflict: deterministic gate, then ADR or principle, then
   `AGENTS.md`, then skill, then memory or habit.
4. **Classify before writing.** Every new rule is nitya (always, so a gate where it can be
   mechanical), naimittika (names its trigger), kamya (opt-in, says what for) or nishiddha
   (enforced by a deny, not prose). A rule that fits none is a candidate no-op.
5. **Artifact states.** `proposed`, `probation`, `established`, `dormant`, `retired`, kept with
   `owner` and `last_reviewed` in the artifact's metadata. Retirement is the default for an
   artifact with no recorded use or no measured lift. "Dormant" may be concluded only when a run
   log exists that could have recorded use.
6. **Evidence.** A change to a steering file cites at least one claim from direct observation
   (a run, a failing then passing check) or inference from observed facts. Testimony and
   analogy are labelled (for example "vendor-reported") wherever repeated.
7. **Metrics observe and never aim.** Reports give the number and how it was measured, not a
   verdict.

## Consequences

**Good:** the loop has one stated shape; autonomy has a ceiling that does not depend on CI being
green; pruning is part of the design, so skills do not accumulate; every future piece (#21,
#22, a run log, ablation evals) slots into a stage rather than re-arguing authority.

**Bad:** human approval is a throughput limit on skill changes, accepted on purpose. The
Sanskrit grounding is an interpretive lens, which the principles document states and bounds; a
reader may disagree with a mapping without affecting the rules, which stand on their
engineering reasons. The `owner` / `last_reviewed` / state metadata is a new convention that
#21 must enforce, or it decays.

## Follow-ups

- #21: skill hygiene gate, extended with the upstream-provenance check (adapted skills carry
  their licence and an adaptations note) and the metadata fields.
- #22: friction log read by `dev-coach`.
- `.agents/` listed explicitly in CODEOWNERS, with a check in `tests/checks/`.
- Run-log spike: can a hook see skill invocations; if not, `dev-coach` scans transcripts.
- `dev-coach`: prune step (needs the run log) and the quality-rubric report.
- Ablation evals for one skill, as the first real use of the eval slot.
- Runtime plane: the same checks for agent homes scaffolded by a runtime built on a stamp, then a
  curator for them, once that runtime's message round trip is verified.
