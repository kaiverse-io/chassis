---
name: devcontainer-cache-permissions
description: Fresh chassis devcontainer builds get root-owned ~/.cache dirs, breaking uv/copier/pre-commit for the vscode user
metadata:
  type: project
---

On a fresh build of chassis's standalone devcontainer, `/home/vscode/.cache/uv` and
`/home/vscode/.cache/pre-commit` come up owned by `root:root`, not `vscode`. `uv tool install`,
`pip install --user`, `copier` (via its own cache dir), and the `pre-commit` git hook all fail
with `PermissionError` until this is fixed.

**Why:** `.devcontainer/docker-compose.yml` declares `uv-cache` and `precommit-cache` as named
Docker volumes mounted at those exact paths. Docker initializes a new named volume's mount point
as `root:root` before the container's entrypoint/user takes over, and nothing in
`.devcontainer/post-create.sh` (or `template/.devcontainer/post-create.sh`, the same symlinked
file) chowns them afterward. `postCreateCommand` runs as `remoteUser: vscode`, so it can't fix its
own mount ownership without `sudo`.

**How to apply:** Fixed at the source in `template/.devcontainer/post-create.sh` (2026-07-11) —
it now chowns `~/.cache` (fully, since it's container-local, not a host bind mount) and
`~/.claude/projects` (scoped, since the parent `~/.claude` *is* a host bind mount and shouldn't
be recursively chowned) right after `set -euo pipefail`, before any install step touches them.
Verified via `just ci` + `just accept`. This fixes chassis's own devcontainer (symlinked) and
every *future* `copier copy`. Already-stamped projects (e.g. aither, stamped before this fix) got
a static copy at stamp time, not a symlink — their `.devcontainer/post-create.sh` needs the same
patch applied manually, or a `copier update`, or just run
`sudo chown -R vscode:vscode ~/.cache ~/.claude/projects` once by hand in the stuck container.
