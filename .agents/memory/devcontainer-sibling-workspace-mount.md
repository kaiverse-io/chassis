---
name: devcontainer-sibling-workspace-mount
description: "Template's devcontainer.json/docker-compose.yml.jinja used to mount a shared ../..:/workspaces parent folder, exposing sibling projects; fixed to mount only the project's own root"
metadata: 
  node_type: memory
  type: project
  originSessionId: 1b352b4b-9c17-4000-98bd-f099e50b3517
---

Until 2026-07-15, `template/.devcontainer/docker-compose.yml.jinja` mounted a shared
`../..:/workspaces:cached` parent folder into every stamped project's container — any other
project cloned alongside it on the host was fully visible and reachable from inside the
container. This was distinct from chassis's own root `.devcontainer/`, which had always mounted
only its own repo root (`..:/workspaces/chassis:cached`) — a difference the repo's AGENTS.md used
to describe as a *permanent, intentional* divergence rather than drift.

**Fixed**: the user asked to close this gap. The template now mounts only the project's own root
too, at a hardcoded literal path: `..:/workspaces/{{ python_package_name }}:cached`, with
`devcontainer.json.jinja`'s `workspaceFolder` hardcoded to match. The first version of this fix
(v0.8.5) used `..:/workspaces/${localWorkspaceFolderBasename}:cached` instead — that was wrong:
`${localWorkspaceFolderBasename}` is substituted **only in devcontainer.json**; Docker Compose
resolves `${...}` from its own environment, where the variable is unset, so it silently became
`""`. The workspace mounted at bare `/workspaces` while VS Code opened `/workspaces/<name>`,
failing with "workspace doesn't exist" on every stamped project (hit 2026-07-15;
fixed in v0.8.6).

**Why**: the shared-parent mount was the same class of cross-project information leak that
[[devcontainer-settings-json-isolation]] (ADR-003) fixes for `~/.claude/settings.json` — a
container built for one project shouldn't be able to read another project's files just because
they happen to share a parent directory on the host.

**How to apply**: if AGENTS.md or design.md is ever regenerated/reviewed and still describes the
template's mount as a *shared sibling-parent* convention, that text is stale — both chassis's own
devcontainer and every stamped project now mount only their own root. Files touched: `AGENTS.md`
(root), `template/.devcontainer/docker-compose.yml.jinja`, `CHANGELOG.md` (added under
`[Unreleased]`, not yet tagged/released — see [[chassis-release-process]]).
