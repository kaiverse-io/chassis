# Memory index

<!-- One line per memory file:  - [Title](slug.md) — one-line hook -->
<!-- See AGENTS.md "Agent-memory convention". Commit this dir to persist memory across rebuilds. -->
- [Devcontainer cache permissions](devcontainer-cache-permissions.md) — fresh builds get root-owned ~/.cache/{uv,pre-commit}, breaking uv/copier/pre-commit; `sudo chown -R vscode:vscode ~/.cache` fixes it
- [docker-outside-of-docker moby network](devcontainer-docker-outside-of-docker-moby.md) — feature build fails "exit code 100" behind docker.com-only networks; `"moby": false` fixes it
- [Devcontainer yarn apt key drift](devcontainer-yarn-apt-key-drift.md) — dl.yarnpkg.com repo's signature no longer matches Yarn's published keyring; breaks fresh builds enabling docker-outside-of-docker after node; `installYarnUsingApt: false` fixes it
- [Devcontainer sibling workspace mount](devcontainer-sibling-workspace-mount.md) — template used to mount a shared `../..:/workspaces` parent, exposing sibling projects; fixed 2026-07-15 to mount only the project's own root
