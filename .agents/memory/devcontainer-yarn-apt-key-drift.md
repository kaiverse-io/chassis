---
name: devcontainer-yarn-apt-key-drift
description: node feature's default apt-based Yarn install breaks fresh builds that also enable docker-outside-of-docker, because dl.yarnpkg.com's repo signature no longer matches Yarn's published keyring
metadata:
  type: project
---

`ghcr.io/devcontainers/features/node:1` defaults to `installYarnUsingApt: true`, which adds
the `dl.yarnpkg.com/debian` apt repo to install Yarn. That repo's signature no longer verifies
against any key in Yarn's currently published keyring — confirmed 2026-07-11 by fetching
`dl.yarnpkg.com/debian/pubkey.gpg` directly: it contains only a 2016 key and a brand new
`Yarn Packaging (2026)` key created 2026-01-28, and the specific key ID apt wants
(`62D54FD4003F6525`) is absent from the file entirely. Yarn deprecated this apt repo years ago
in favor of Corepack; it's effectively unmaintained.

**Symptom:** a fresh `docker compose build` of a project that enables an apt-based feature
*after* `node:1` (e.g. `docker-outside-of-docker`) fails with `NO_PUBKEY 62D54FD4003F6525`
during that later feature's own `apt-get update` — not node's own layer, which doesn't
hard-fail on the key issue. Docker layer caching hides this on an already-built container: an
old cached Yarn layer never re-touches the repo, so a project that's been incrementally rebuilt
over time can look fine while a genuinely fresh clone fails immediately. Don't trust "but it
works here" on this class of bug without checking `/var/log/apt/history.log` timestamps first.

**Why:** found debugging `aither`'s first-ever fresh build, which hit this immediately after
[[devcontainer-docker-outside-of-docker-moby]]'s moby fix was already applied — a second,
unrelated apt-repo problem in the same feature-ordering shape (node → docker-outside-of-docker).

**How to apply:** `template/.devcontainer/devcontainer.json.jinja`'s `node:1` feature now sets
`installYarnUsingApt: false` unconditionally — Corepack/npm installs Yarn fine without apt, and
no stamped project's `post-create.sh` ever shells out to the apt-installed `yarn` binary, so
there's no downside even for projects that never add `docker-outside-of-docker`. If a *different*
apt repo key error shows up later, it's a new issue — this fix only covers `dl.yarnpkg.com`.
