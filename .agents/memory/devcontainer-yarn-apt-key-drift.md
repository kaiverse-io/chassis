---
name: devcontainer-yarn-apt-key-drift
description: mcr.microsoft.com/devcontainers/python base image bakes in a Yarn apt repo whose signature no longer matches Yarn's published keyring, breaking the first feature that runs apt-get update on a fresh build
metadata:
  type: project
---

**Corrected 2026-07-11** — an earlier version of this memory blamed `node:1`'s
`installYarnUsingApt` default. That was wrong: setting `installYarnUsingApt: false` on the
node feature does **not** fix this. Verified by actually reproducing the build (not just
reading logs) after applying that fix and watching it fail identically.

**Real root cause:** `mcr.microsoft.com/devcontainers/python:1-3.12-bookworm` (and presumably
sibling `devcontainers/*` base images) ships Node **and Yarn pre-installed at the image's own
build time**, completely independent of the devcontainer `node` feature — confirmed by running
`docker run --rm mcr.microsoft.com/devcontainers/python:1-3.12-bookworm sh -c 'dpkg -l | grep
yarn'` and finding `yarn 1.22.22-1` already present, with `/etc/apt/sources.list.d/yarn.list`
already in place pointing at `/usr/share/keyrings/yarn-archive-keyring.gpg`. That keyring's
subkeys expire 2026-01-23; Yarn rotated to a new signing key 2026-01-28 (confirmed via
`dl.yarnpkg.com/debian/pubkey.gpg`); the base image has not been republished since
**2025-07-10** (`docker inspect ... --format '{{.Created}}'`, confirmed still the current tag
via a forced `docker pull`) so it never picked up the new key. `dl.yarnpkg.com`'s repo is
signed with the new key now, so any fresh build's *first* `apt-get update` — from whichever
feature's install layer runs first, `node:1` not required to be involved at all — fails with
`NO_PUBKEY 62D54FD4003F6525`.

**Symptom:** in a real build log, this shows up as the base image's `FROM` layer directly
followed by whichever feature layer runs first (confirmed: `docker-outside-of-docker` ran as
literally the first feature layer, stage 4/6, before `node:1`'s own layer even started) hitting
`Err:5 https://dl.yarnpkg.com/debian stable InRelease ... NO_PUBKEY 62D54FD4003F6525` during
its own `apt-get update`. Docker layer caching hides this on an already-built container — an
old image built before the key rotation never re-touches the repo — so "but it works here" on
an existing container proves nothing about a fresh clone. Don't trust it without checking
`/var/log/apt/history.log` timestamps and `docker inspect --format '{{.Created}}'` on the base
image first.

**Fix:** a custom `.devcontainer/Dockerfile` that does `RUN rm -f
/etc/apt/sources.list.d/yarn.list` as its own layer, with `docker-compose.yml`'s `app` service
switched from `image:` to `build: { context: ., dockerfile: Dockerfile }`. This has to happen
in your *own* Dockerfile, not a feature option — devcontainer features are appended as RUN
layers on top of whatever your Dockerfile produces, so removing the broken source there
guarantees it's gone before any feature's `apt-get update` ever runs, regardless of feature
order. `template/.devcontainer/Dockerfile.jinja` + `docker-compose.yml.jinja` now do this;
verified by actually building both chassis's own devcontainer and a freshly copier-stamped test
project with the real `@devcontainers/cli build` (not just `just accept`'s stamp-and-lint —
that doesn't invoke Docker at all and would not have caught this).

**Why one downstream repo looked unaffected:** it already had this *exact* fix (a hand-written
`.devcontainer/Dockerfile` with the same `rm -f` line) from an earlier session, predating this
one — it wasn't cache luck, it was a real fix that had already landed there and nowhere else.
`installYarnUsingApt: false` is still set on `node:1` across these repos as harmless
defense-in-depth, but the Dockerfile fix is the one doing the actual work.

**How to apply:** if a chassis-stamped project's fresh devcontainer build fails with
`NO_PUBKEY 62D54FD4003F6525` on `dl.yarnpkg.com`, check for `.devcontainer/Dockerfile` with the
`rm -f /etc/apt/sources.list.d/yarn.list` line and `docker-compose.yml`'s `app` service using
`build:` not `image:`. If both are present and it still fails, this is a different problem —
don't assume it's a recurrence without checking the actual error first this time.
