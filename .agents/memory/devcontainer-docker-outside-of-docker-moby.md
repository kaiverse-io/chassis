---
name: devcontainer-docker-outside-of-docker-moby
description: docker-outside-of-docker feature build fails with bare "exit code 100" behind networks that only allowlist docker.com, not packages.microsoft.com
metadata:
  type: project
---

`ghcr.io/devcontainers/features/docker-outside-of-docker:1` defaults to `"moby": true`, which
installs `moby-cli`/`moby-buildx` from `packages.microsoft.com`. On a build sandbox behind a
corporate VPN/proxy that only allowlists `docker.com` domains (a common shape on Mac setups),
that apt install fails during `devcontainer-features-install.sh` with a bare
`exit code: 100` — apt's generic failure code. BuildKit hides the real `curl`/`apt-get` error
line unless you rebuild with `--progress=plain` or open Docker Desktop's "View build details"
link, so the log alone looks unfixable.

**Why:** confirmed by reading `install.sh` from `devcontainers/features` directly — `moby: true`
imports Microsoft's apt repo (`packages.microsoft.com`); `moby: false` imports Docker's official
repo (`download.docker.com`, package `docker-ce-cli`) instead. Bookworm/other codenames are
supported either way per `DOCKER_MOBY_ARCHIVE_VERSION_CODENAMES` — this isn't the classic
distro-compatibility failure mode ([devcontainers/features#742](https://github.com/devcontainers/features/issues/742)),
it's specifically which vendor's repo the sandbox can reach. Found debugging aither's devcontainer
build, which hit this exact failure with the base image `mcr.microsoft.com/devcontainers/python:1-3.12-bookworm`.

**How to apply:** chassis's documented opt-in recipe in
`template/.devcontainer/devcontainer.json.jinja` now defaults the snippet to
`{ "moby": false }`. If a project's build still fails with `exit code: 100` on this feature after
that, the network is blocking `download.docker.com` too — get the real error via
`--progress=plain` rather than guessing further. See [[devcontainer-cache-permissions]] for the
sibling opt-in-feature gotcha (socket permissions) this recipe already accounts for.
