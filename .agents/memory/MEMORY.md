# Memory index

<!-- One line per memory file:  - [Title](slug.md) — one-line hook -->
<!-- See AGENTS.md "Agent-memory convention". Commit this dir to persist memory across rebuilds. -->
- [Devcontainer cache permissions](devcontainer-cache-permissions.md) — fresh builds get root-owned ~/.cache/{uv,pre-commit}, breaking uv/copier/pre-commit; `sudo chown -R vscode:vscode ~/.cache` fixes it
- [docker-outside-of-docker moby network](devcontainer-docker-outside-of-docker-moby.md) — feature build fails "exit code 100" behind docker.com-only networks; `"moby": false` fixes it
