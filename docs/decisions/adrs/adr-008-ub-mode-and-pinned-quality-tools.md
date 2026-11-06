---
kind: adr
status: accepted
owner: founder
last_reviewed: 2026-11-06
---

# ADR-008 — Ship ub-mode as an opt-in skill, with its quality tools pinned behind `just`

- **Status:** Accepted (2026-11-06); amended 2026-11-06 — opt-in via `include_ub_mode`, default off (see Amendment)
- **Deciders:** founder

## Context

[unclebob/ub-mode](https://github.com/unclebob/ub-mode) (MIT) is a short agent skill for
writing and changing code — TDD, root-cause fixes, boundary and type discipline, idempotent
operations, small commits — paired with three deterministic gates:
[crapper](https://github.com/unclebob/crapper) (CRAP score per function),
[dryer](https://github.com/unclebob/dryer) (structural duplication) and
[mutator](https://github.com/unclebob/mutator) (mutation testing). All three support Python.

Stamped projects had complexity limits in prose and a coverage ratchet, but nothing that
combined the two (a complex function that is also untested) and nothing that measured whether
the tests would catch a change at all. Prose-only rules decay; numbers a tool computes do not.

Taken verbatim, the skill conflicts with chassis in places: it ends by pushing to the main line
(`AGENTS.md` forbids committing to `main` without CI green), its worktree cleanup deletes
without asking, two rules pull against each other (smallest edit vs. unconditional redesign),
and one rule ("Attack the Premise") does not map to an action an agent can take. The tools are
installed ad hoc — cloned anywhere, each building its own `.venv` on first run, mutator assuming
crapper sits in `../crapper` — and none publishes a release.

## Decision drivers

- Enforcement over documentation — prefer a number a tool computes to a rule an agent recalls.
- Pinned installs only: a template runs unattended in strangers' containers (ADR-004).
- Thin: no new blocking gate until the existing code base can pass it.
- Opt-in: a coding-discipline skill must not load on every task.

## Considered options

1. **Point stamped projects at upstream, unmodified.** Rejected: ships the push-to-`main` rule
   and the unattended deletion into every project.
2. **Prose rules only, plus ruff's complexity rules (C901, PLR0913).** Rejected: complexity
   without coverage misses the risky case CRAP is built to find, and says nothing about test
   strength.
3. **Vendor an adapted copy of the skill; run the tools through pinned `just` recipes.**
   *Chosen.* Keeps upstream's substance and attribution, removes the conflicts, and gives the
   tools one reproducible install path.

## Decision

- `template/.agents/skills/ub-mode/SKILL.md`: upstream's text with the adaptations tabled at the
  end of that file, upstream's MIT notice included. `AGENTS.md` wins any conflict.
- `template/justfile.jinja` gains `just crap`, `just dry`, `just mutate <path>` and `just
  ub-tools`. Each tool is fetched into `.cache/ub-tools/<name>` at a pinned commit; the layout
  satisfies mutator's `../crapper` lookup. Thresholds match the skill: CRAP 10, duplication 0.8.
- Bucket C (on-demand). None of the three is part of `just ci`. Mutation testing is slow enough
  that it runs per file, by choice.
- The commit pins are bumped by hand, like `AEC_COMMIT`: upstream has no releases for Renovate
  to track, so moving a pin means reading what changed first.
- Outputs (`.cache/ub-tools/`, `.metrics/`, `target/coverage/`) are git-ignored.

## Consequences

**Good:** stamped projects get a complexity × coverage signal and a test-strength signal with
one command each, from a pinned, reviewable source.

**Bad:** first run needs network access to github.com and builds three virtualenvs. crapper
installs `coverage`/`pytest` into the project interpreter when they are missing (they are not,
in a stamped project). Upstream is new; pins will need deliberate attention.

**Follow-up:** once a stamped project passes `just crap` cleanly, promote CRAP < 10 to a
blocking ratchet in `just ci`, the same way the coverage floor works — a separate decision,
not taken here.

## Amendment (2026-11-06): opt-in at stamp time

v0.14.0 stamped the skill and the four recipes into every project. That contradicts
chassis#10's mutation-testing row ("Optional, off by default … Do not make `/ub-mode` part of
every stamp"), which records a 2026-10-31 spike at 52% of mutants killed on one file and calls
the full ritual heavy. The skill, the `ub-tools`/`crap`/`dry`/`mutate` recipes and their
`.gitignore` lines are now behind the Copier question `include_ub_mode` (default `false`), the
same shape as `install_ai_coach`. A project stamped at v0.14.0 keeps what it has until its next
`copier update`, which removes them unless it answers `include_ub_mode=true`.

