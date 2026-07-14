---
kind: adr
status: accepted
owner: platform
last_reviewed: 2026-07-13
---

# ADR-003 — Isolate the agent's user-level `settings.json` per project

- **Status:** Accepted
- **Deciders:** founder
- **Date:** 2026-07-13

> **AMENDED 2026-07-14 (v0.8.1):** the shadow file is now **generated as `{}` and gitignored**,
> not committed. It doubles as the live user-level `settings.json` the container writes to
> (model, effort, onboarding flags), so committing it churned the tree every session and risked
> pinning one developer's prefs onto everyone — the same config-template-vs-live-config split the
> repo already makes for `.env` (ignored) vs `.env.example` (committed). `devcontainer.json`'s
> `initializeCommand` creates it host-side before the mount resolves, so the bind source is
> always a real file. The isolation mechanism (the more-specific mount) is unchanged.

## Context

The chassis devcontainer bind-mounts the host's `~/.claude` directory into every container
(`devcontainer.json` `mounts`), so agent config, credentials, skills, and session history are
visible inside the container. That mount is genuinely shared: every devcontainer built from this
template, plus the host's own Claude Code, read and write the *same* `~/.claude` tree.

For most of that tree this is fine or desired — `~/.claude/projects/<slug>` is already
partitioned per project by Claude Code itself, and `~/.claude/skills` is *meant* to be shared so
tools register their skills once and have them everywhere.

`~/.claude/settings.json` is the exception: it is a *single, non-partitioned* file holding
permissions, hooks, and other behavior-affecting config. Because it is shared and mutable, any
container-side write to it — a permissions change, a hook registration, or an install script's
undocumented default — reconfigures **every** sibling container's live session and the host's
own Claude Code, in one write, with no isolation and no warning at the point of failure. This is
the root cause a real incident exposed (a bucket-C tool wrote a machine-wide `permissions.deny`;
see [ADR-002](adr-002-ai-usage-cockpit.md)'s amendment and [ADR-004](adr-004-no-silent-rewriters.md)).
The problem is structural — *shared mutable agent config* — not specific to any one tool.

## Decision drivers

- A per-project, unattended template must not let one container's tooling silently alter another
  project's or the host's agent behavior.
- The fix must not regress the parts of the `~/.claude` mount that are correctly shared
  (skills, credentials, per-project session history).
- Isolation should be structural (guaranteed by the mount topology), not a matter of policy or
  agent discipline.

## Considered options

1. **Drop the `~/.claude` mount entirely.** *Rejected* — loses shared skills, credentials, and
   session-history durability that the mount exists to provide.
2. **Ask tools not to write `settings.json` / audit them.** *Rejected* — relies on every current
   and future tool behaving, and on catching undocumented defaults by hand. Not structural.
3. **Shadow just `~/.claude/settings.json` with a second, more specific mount.** *Chosen.*

## Decision

Add a second bind mount, more specific than the `~/.claude` mount, at exactly
`~/.claude/settings.json`, sourced from a file inside the project's own `.devcontainer/`
(`.devcontainer/claude-user-settings.json` — generated as `{}` by `devcontainer.json`'s
`initializeCommand` and gitignored; see the amendment above). Docker resolves overlapping
mounts by specificity, so this shadows the parent mount for that one path only.
Every other path under `~/.claude` (skills, credentials, `projects/<slug>`) still falls through
to the real shared host directory, unchanged.

Each project gets its own independent, git-visible `settings.json` for its container; nothing
written there is reachable from the host or any other project's container, by construction.
Project-scoped Claude Code settings that genuinely need to travel with the repo (e.g. OTEL
config) belong in the project-scoped `.claude/settings.json` that Claude Code already layers on
top of the user-scoped one — that path was never part of the problem. Full mechanism in
[docs/explanation/devcontainer-persistence.md](../../explanation/devcontainer-persistence.md).

## Consequences

**Good:** a container-side write to `settings.json` can no longer reach any other project or the
host — the blast radius is one container. The shared parts of `~/.claude` keep working exactly as
before. Isolation is enforced by the mount topology, not by trusting tools.

**Bad / risks:** because the file is generated and gitignored, a settings change a developer
genuinely wants shared across their own projects now has to be made in each project (or in the
host `~/.claude` before the shadow mount is added) — a deliberate trade of convenience for
isolation. The `initializeCommand` assumes a POSIX-ish host shell (fine on macOS/Linux and
WSL2, chassis's actual targets); a native-Windows host without one would need the file created
another way.
