---
kind: explanation
status: active
last_reviewed: 2026-07-12
---

# Devcontainer persistence: what survives a rebuild, and what doesn't

Every devcontainer eventually gets rebuilt — a base image updates, a `Dockerfile` change needs
picking up, or something just gets into a bad state and a clean rebuild is the fastest fix. This
explains exactly what data lives where in this chassis's devcontainer setup, so "did I just lose
that?" has a definite answer instead of a guess.

## The three storage mechanisms, and their guarantees

A devcontainer's *own* filesystem (the writable layer on top of its image) is always thrown away
on rebuild — that's the point of a rebuild. Anything you want to survive has to live somewhere
else. This template uses three different somewhere-elses, each with a different guarantee:

| Mechanism | Survives rebuild? | Survives a different host? | Used for |
|---|---|---|---|
| **Git-tracked files** | Always | Always (it's in the repo) | `.agents/memory/`, source, docs — anything that should be portable to a fresh clone |
| **Docker named volume** | Only if the volume itself isn't recreated | No — tied to this Docker daemon, and lives on its VM disk, not the host disk | `uv-cache`, `precommit-cache`, any project-specific data store (e.g. Postgres) |
| **Host bind mount** | Only if the host path is itself durable | No — by definition, it's this host's path | `~/.claude` (the whole tree, including `/projects`), `~/.gitconfig`, `~/.ssh`, `~/.config/gh` — real host state you want visible inside the container; `~/.aws` is the same mechanism, added per-project when needed |

The bind mount's "only if" is the one that bites people. `devcontainer.json`'s `mounts` array
binds `${localEnv:HOME}/.claude` from whatever machine is running the devcontainer. On a laptop
running Docker Desktop, that's a real, durable path — the bind mount works perfectly and always
has. On a remote or cloud-hosted devcontainer runner, `${localEnv:HOME}` may point at something
ephemeral that doesn't survive a rebuild of the *runner* itself, not just the container — and
there's no way to tell which situation you're in just by looking at `devcontainer.json`.

## Why `settings.json` is carved out of the shared `~/.claude` mount (added 2026-07-13)

The host bind mount above is genuinely shared: every devcontainer built from this template, plus
the host's own Claude Code, all read and write the *same* `~/.claude` directory. For most of that
directory this is fine or actively desired — `~/.claude/projects/<slug>` is already partitioned
per project by Claude Code itself, and `~/.claude/skills` is meant to be shared (that's how
`graphify`/`ctx` register their skills once and have them available everywhere).

`~/.claude/settings.json` is the one path in that tree that is a *single, non-partitioned* file
holding permissions, hooks, and other behavior-affecting config — and it is genuinely dangerous to
share. A container-side tool that writes to it (see [ADR-002](../decisions/adrs/adr-002-ai-usage-cockpit.md)'s
lean-ctx amendment: a real bug, not hypothetical) silently reconfigures or hard-blocks every
sibling container's live session *and* the host's own Claude Code, in one write, with no warning
at the point of failure.

The fix does not touch the shared `~/.claude` mount itself — it adds a **second, more specific
mount** on top of it, at exactly `~/.claude/settings.json`, sourced from a file inside the
project's own repo (`.devcontainer/claude-user-settings.json`, committed, starts as `{}`). Docker
resolves overlapping mounts by specificity, so this shadows the parent mount for that one path
only; every other path under `~/.claude` (skills, credentials, `projects/`) still falls through to
the real shared host directory exactly as before, with no durability change. Each project gets its
own independent, git-visible settings.json for its container; nothing written there is reachable
from the host or from any other project's container, by construction — not by policy or agent
discipline. Project-specific Claude Code settings that genuinely need to travel with the repo
(e.g. the OTEL config mentioned in [ai-usage-cockpit.md](ai-usage-cockpit.md)) belong in the
*project-scoped* `.claude/settings.json` (committed, stamped by this template), which Claude Code
already layers on top of the user-scoped one — that path was never part of the problem.

## Why agent memory is git-tracked, not just bind-mounted

`.agents/memory/` (a coding agent's durable, cross-session notes) started as something the
`~/.claude` bind mount alone was supposed to handle. That's exactly the fragile case above: fine
on a local devcontainer, silently lost on a rebuild elsewhere. The fix was to make the *canonical*
copy git-tracked (`.agents/memory/` in the repo itself — portable to a fresh clone, immune to any
devcontainer or host question entirely) and have `post-create.sh` recreate a symlink at the
conventional path (`~/.claude/projects/<project-slug>/memory`) on every build. The lesson
generalizes: **if data needs to survive independent of the devcontainer's host, put it in git.**
That's not always possible (session transcripts aren't meant to be committed), which is why the
other two mechanisms exist.

## Why session transcripts do NOT get their own named volume (reverted 2026-07-12)

Claude Code session transcripts (`~/.claude/projects/<slug>/*.jsonl`) can't go in git — they're
local working data, not source. An earlier version of this template nested a Docker **named
volume** at the specific path `~/.claude/projects`, inside the existing `~/.claude` bind mount,
reasoning that the bind mount alone isn't durable on a remote/cloud devcontainer runner where
`${localEnv:HOME}` may not resolve to a real host path:

```yaml
volumes:
  - claude-projects:/home/vscode/.claude/projects   # REVERTED — do not reintroduce
```

That reasoning was correct for the remote/cloud case, but wrong for the common case this
template actually targets: a laptop running Docker Desktop. There, the named volume lives on
the *Docker Desktop VM's own virtual disk*, not the host machine's disk — it is not, in fact,
more durable than the host bind mount it was meant to protect. Worse, it's **less** durable in a
specific, easy-to-hit way: Docker recreates a named volume's underlying storage whenever the
compose project identity changes (e.g. certain `devcontainer.json` features/config changes
trigger a rebuild that Docker treats as a new volume), and a fresh volume starts **empty** —
Docker doesn't merge old and new, it just replaces what's visible at that path. This happened for
real on a project built from this template: a routine devcontainer rebuild silently orphaned
every prior Claude Code session with no host-side trace, because the "durable" volume had
quietly been recreated.

The fix: drop the nested volume entirely. `~/.claude/projects` now falls through to the plain
`~/.claude` host bind mount, same as everything else under `~/.claude` (credentials, settings,
skills). On a local Docker Desktop devcontainer — the case this template is built for — that
bind mount is a real, durable host path and always has been; removing the "safety net" volume
removes the actual failure mode. The remote/cloud durability gap the original volume was trying
to close is real, but nothing in this template currently runs on a remote/cloud devcontainer, and
a volume that actively makes the common case worse is the wrong way to hedge against a case that
doesn't apply yet. Revisit if and when a project on this template actually needs to run on a
remote/cloud runner — see the git history of this file and `.devcontainer/docker-compose.yml`
around 2026-07-12 for the exact mechanism, should that day come.

## What this means for tools that keep their own state

Two of the AI-usage cockpit tools ([docs/explanation/ai-usage-cockpit.md](ai-usage-cockpit.md))
keep meaningful local state that isn't covered by any of the above yet: `ctx`'s session-history
index (`~/.ctx`) and `lean-ctx`'s cache/stats (`~/.local/share/lean-ctx`). Neither has a volume
in this template today — they're rebuilt from scratch (`ctx setup` / `lean-ctx onboard` re-run by
`post-create.sh`) every time. `ctx` re-indexes existing session transcripts on `ctx setup`, so it
self-heals as long as the transcripts themselves survived (see above); `lean-ctx`'s compression
stats and learned patterns do not currently survive a rebuild. Nesting a named volume at either
tool's data path would "fix" that the same way `claude-projects` once did — meaning it would
carry the identical durability trap on a local Docker Desktop devcontainer. Don't, unless it's
paired with the bind-mount-first reasoning above and a real remote/cloud target.
