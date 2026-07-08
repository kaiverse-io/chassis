---
kind: explanation
status: active
last_reviewed: 2026-07-08
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
| **Docker named volume** | Always | No — tied to this Docker daemon | `uv-cache`, `precommit-cache`, `claude-projects`, any project-specific data store (e.g. Postgres) |
| **Host bind mount** | Only if the host path is itself durable | No — by definition, it's this host's path | `~/.claude` (minus `/projects`), `~/.aws`, `~/.gitconfig`, `~/.ssh` — real host state you want visible inside the container |

The bind mount's "only if" is the one that bites people. `devcontainer.json`'s `mounts` array
binds `${localEnv:HOME}/.claude` from whatever machine is running the devcontainer. On a laptop
running Docker Desktop, that's a real, durable path — the bind mount works perfectly and always
has. On a remote or cloud-hosted devcontainer runner, `${localEnv:HOME}` may point at something
ephemeral that doesn't survive a rebuild of the *runner* itself, not just the container — and
there's no way to tell which situation you're in just by looking at `devcontainer.json`.

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

## Why session transcripts got their own named volume

Claude Code session transcripts (`~/.claude/projects/<slug>/*.jsonl`) can't go in git — they're
local working data, not source. They also can't rely on the bind mount alone, for the reason
above. The fix: nest a Docker **named volume** at the specific path `~/.claude/projects`, inside
the existing `~/.claude` bind mount.

```yaml
volumes:
  - claude-projects:/home/vscode/.claude/projects
```

Docker's mount layering rule is simple: the more specific (deeper) mount wins for its subtree.
So `~/.claude` still comes from the host bind mount for everything else (credentials, settings),
but `~/.claude/projects` specifically now comes from the `claude-projects` volume — durable
regardless of whether the outer bind mount's host path is itself durable.

### The migration gotcha this introduces

A named volume starts **empty**. If a project already had real session history sitting in the
bind-mounted host path before this volume was introduced, that history doesn't move itself —
Docker doesn't merge the two, the volume just becomes what's visible at that path going forward.
On the *first* rebuild after adding a volume like this, existing history at that path will appear
to vanish from the container's point of view (it's still on the host, just no longer reachable
from inside the container, since the volume now shadows that subtree).

If that matters to you, run this **on the host** (not inside the container) once, after the
first rebuild that creates the volume:

```bash
docker volume ls | grep claude-projects   # find the actual (project-prefixed) volume name
docker run --rm \
  -v "<host-path-to-old-.claude-projects-slug>":/from \
  -v <volume-name-from-above>:/to \
  alpine sh -c "cp -a /from/. /to/"
```

There's no way to automate this from `post-create.sh` — by the time it runs, the volume has
already replaced visibility into the old host path from inside the container. The copy has to
happen at the host level, once, before or right after the first rebuild.

## What this means for tools that keep their own state

Two of the AI-usage cockpit tools ([docs/explanation/ai-usage-cockpit.md](ai-usage-cockpit.md))
keep meaningful local state that isn't covered by any of the above yet: `ctx`'s session-history
index (`~/.ctx`) and `lean-ctx`'s cache/stats (`~/.local/share/lean-ctx`). Neither has a volume
in this template today — they're rebuilt from scratch (`ctx setup` / `lean-ctx onboard` re-run by
`post-create.sh`) every time. `ctx` re-indexes existing session transcripts on `ctx setup`, so it
self-heals as long as the transcripts themselves survived (see above); `lean-ctx`'s compression
stats and learned patterns do not currently survive a rebuild. Following the same pattern used
for `claude-projects` — a named volume nested at the tool's data path — would fix both, if that
history turns out to matter enough to want in future work.
