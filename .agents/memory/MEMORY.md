# Memory index

<!-- One line per memory file:  - [Title](slug.md) — one-line hook -->
<!-- See AGENTS.md "Agent-memory convention". Commit this dir to persist memory across rebuilds. -->
- [Devcontainer cache permissions](devcontainer-cache-permissions.md) — fresh builds get root-owned ~/.cache/{uv,pre-commit}, breaking uv/copier/pre-commit; `sudo chown -R vscode:vscode ~/.cache` fixes it
