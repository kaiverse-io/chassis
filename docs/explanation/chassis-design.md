---
kind: explanation
status: active
last_reviewed: 2026-06-29
---

# Why a Copier chassis?

The chassis is the Plane-1 answer to a specific problem: solo, agent-driven development needs
guardrails enforced **from commit 1**, not bolted on later. And those guardrails need to reach
every future project without manual effort.

## The A/B/C/D bucket model

Every tool is wired in from day one. What varies is *how it behaves*:

- **A (Blocking):** fails the commit or CI run. Used for things where "wrong" is always wrong —
  secret leaks, import boundary violations, self-weakening patterns.
- **B (Ratcheting):** present from day one, threshold only ever increases. Coverage floor is the
  canonical example: start at 0%, raise as you write tests, never lower.
- **C (On-demand):** installed, never blocks. Run when useful. AI cost metrics (codeburn) live here.
- **D (Wired-but-waiting):** the job/slot exists in CI and config from day one, but it's a no-op
  until its input exists. The eval gate needs a model call (P1); the arch-drift gate needs an
  architecture model. The slot means the gate is trivially activatable — no retrofit.

## Why Copier over GitHub template repos

GitHub template repos are one-time copies — stamped projects never receive improvements.
Copier's `copier update` propagates base improvements into stamped projects (conflicts surfaced,
not silently lost). The chassis is a compounding asset: improvements flow downstream for free.

## Self-dogfooding

The chassis must pass its own gates (`just ci`). Its acceptance test is `just accept`:
stamp a throwaway project → `just ci` green. A chassis that doesn't pass its own rules is
unusable as a base.

## The thin-chassis discipline

Resist feature creep. The chassis should be the minimum that makes every project *start right*,
not a superset that makes new projects *start slow*. The acceptance test is the forcing function:
if `just accept` takes > 2 minutes, the chassis is too heavy.
