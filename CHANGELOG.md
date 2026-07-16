# Changelog

All notable changes to the chassis are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [SemVer](https://semver.org/).

Rationale for a decision lives in its [ADR](docs/decisions/adrs/); this file records *what*
changed, tersely. Anything longer is in git history or an ADR.

---

## [0.8.6] — 2026-07-16

### Fixed

- v0.8.5's own-root workspace mount never worked: it used
  `..:/workspaces/${localWorkspaceFolderBasename}:cached` in
  `template/.devcontainer/docker-compose.yml.jinja`, but that variable is substituted only in
  `devcontainer.json` — Docker Compose resolves `${...}` from its environment, where it's unset,
  so the workspace silently mounted at bare `/workspaces` while VS Code opened
  `/workspaces/<name>`, failing every stamped project's container open with "workspace doesn't
  exist". Both the compose mount and `devcontainer.json.jinja`'s `workspaceFolder` are now a
  hardcoded literal (`/workspaces/{{ python_package_name }}`), matching how chassis's own
  devcontainer always did it.

## [0.8.5] — 2026-07-15

### Fixed

- `template/.devcontainer/docker-compose.yml.jinja` mounted a shared `../..:/workspaces:cached`
  parent folder, meaning every stamped project's container could see and reach whatever other
  projects happened to be cloned alongside it — the same class of cross-project leak
  [ADR-003](docs/decisions/adrs/adr-003-settings-json-isolation.md) fixes for `settings.json`.
  Stamped projects now mount only their own root
  (`..:/workspaces/${localWorkspaceFolderBasename}:cached`), matching chassis's own devcontainer
  and `devcontainer.json.jinja`'s existing `workspaceFolder`.

## [0.8.4] — 2026-07-15

### Fixed

- `template/.gitignore.jinja` was missing the `.devcontainer/devcontainer-lock.json` rule that
  chassis's own root `.gitignore` has had all along — every stamped project was one `git add -A`
  away from committing a devcontainer-CLI-generated snapshot that goes stale the moment
  `devcontainer.json`'s features change. Found by inspection, not by a failure; verified against
  a fresh stamp.

## [0.8.3] — 2026-07-15

### Added

- A **Principles** section at the top of `docs/explanation/design.md`: ten tenets (determinism
  wraps non-determinism, observe/advise/gate-never-intercept, two planes, own-your-prompts/
  context-window, curated-vs-exhaustive memory, canonical-copy-thin-adapters, compounding not
  one-time, thin by discipline, generic only) stated once with a link to where each is earned,
  instead of only being derivable by reading the full doc plus ADR-004.

## [0.8.2] — 2026-07-15

### Fixed

- CI's `gates` job piped `just.systems/install.sh` through bash and hit a transient 403 on a
  real release run (the v0.8.0 tag build failed while the same commit's `main` build passed
  seconds earlier). `just` is now installed from a pinned GitHub release binary with retries.
- GitHub Actions in `.github/workflows/ci.yml` are now pinned to a commit SHA (with a `# vX`
  comment), not a mutable tag — [OpenSSF Scorecard](https://scorecard.dev/)'s
  Pinned-Dependencies convention.

### Added

- [Renovate](https://github.com/apps/renovate) config (`renovate.json`, free for public repos):
  auto-pins/updates GitHub Action digests, and a custom regex manager keeps every shell-variable
  version pin (gitleaks/codeburn/abtop/graphify/ctx/just) current via a
  `# renovate: datasource=... depName=...` marker comment above each. Documented in
  `CONTRIBUTING.md` "Keeping pinned versions current".

## [0.8.1] — 2026-07-14

### Fixed

- The shadow `settings.json` ([ADR-003](docs/decisions/adrs/adr-003-settings-json-isolation.md))
  is now **generated as `{}` by `devcontainer.json`'s `initializeCommand` and gitignored**,
  instead of committed. It doubles as the live user-level settings Claude Code writes into (model,
  effort, onboarding flags), so tracking it churned the working tree every session and risked
  committing one developer's prefs for everyone — now the same `.env` / `.env.example` split the
  repo already uses. `initializeCommand` creates it host-side before the mount resolves, so the
  bind source is always a real file (also fixing the latent "Docker makes a directory" case on a
  fresh clone).

### Changed

- Pruned a stale agent-memory entry (a copier-answers bug now fixed and guarded by `just accept`)
  and scrubbed consuming-project names from the remaining entries.

## [0.8.0] — 2026-07-14

Open-source readiness: docs describe the current design only, installs are pinned, and the
standing rule against read-path interceptors is now a decision record.

### Added

- [ADR-003](docs/decisions/adrs/adr-003-settings-json-isolation.md) (per-project `settings.json`
  isolation) and [ADR-004](docs/decisions/adrs/adr-004-no-silent-rewriters.md) (no silent
  rewriters in the agent's read path) — promote two decisions from changelog prose to records.
- `install_ai_coach` copier variable (default `false`): the AI Engineer Coach build is now
  opt-in (and pinned to a commit when enabled), so its `git clone` + `npm ci` of upstream source
  no longer runs by default.
- OSS scaffolding: `LICENSE` (Apache-2.0), root `.github/workflows/ci.yml` (`just ci` +
  `just accept` + a real devcontainer image build), `CONTRIBUTING.md`, `SECURITY.md`.

### Changed

- Docs describe the current design only (history moved to git/CHANGELOG/ADRs). Merged
  `chassis-design.md` + `two-plane-model.md` + `layered-model.md` into
  `docs/explanation/design.md`; absorbed `docs/how-to/release-a-chassis-version.md` into
  `CONTRIBUTING.md`; the cockpit is five tools.
- Pinned cockpit install versions (codeburn, abtop, graphify, ctx) — no unattended "latest" in
  other people's containers; `ctx` now installs from a versioned release asset with checksum
  verification instead of a piped install script.
- Scrubbed consuming-project references so the repo names no downstream project.

## [0.7.9] — 2026-07-13

### Fixed

- Removed `lean-ctx` from the cockpit entirely — it sits between the agent and its context by
  design; the category rule is [ADR-004](docs/decisions/adrs/adr-004-no-silent-rewriters.md).
- Carved `~/.claude/settings.json` out of the shared `~/.claude` bind mount so no container-side
  write reaches sibling projects or the host — [ADR-003](docs/decisions/adrs/adr-003-settings-json-isolation.md).

## [0.7.8] — 2026-07-12

### Fixed

- `lean-ctx onboard` wrote an undocumented machine-wide `permissions.deny` for
  Bash/Read/Grep/Glob into the shared `~/.claude/settings.json`; switched to `setup` + `init`
  (a mitigation, superseded by full removal in 0.7.9).

## [0.7.7] — 2026-07-12

### Fixed

- Removed a dangling reference to a chassis-only doc from `docker-compose.yml.jinja` — it never
  stamps into downstream projects.

## [0.7.6] — 2026-07-12

### Fixed

- Dropped the `claude-projects` named volume: on Docker Desktop it lived on the VM disk and was
  recreated empty on compose-identity changes, silently orphaning session history. Sessions now
  fall through to the `~/.claude` bind mount.

## [0.7.5] — 2026-07-11

### Fixed

- Yarn `NO_PUBKEY` build failure traced to the base image's pre-installed Yarn apt source (not
  the node feature); fixed by removing that source in the project Dockerfile. Verified with a
  real `@devcontainers/cli build`, which `just accept` never invokes.

## [0.7.4] — 2026-07-11

### Fixed

- `installYarnUsingApt: false` to route around the broken `dl.yarnpkg.com` key on fresh builds
  enabling docker-outside-of-docker (superseded by 0.7.5 — the real cause was the base image).

## [0.7.3] — 2026-07-11

### Fixed

- `copier update` never worked: `template/` lacked a `{{ _copier_conf.answers_file }}.jinja`, so
  no stamped project got a `.copier-answers.yml`. `just accept` now asserts it exists and passes
  `--vcs-ref=HEAD`.
- `docker-outside-of-docker` recipe defaults to `"moby": false` (the `moby: true` default fails
  behind docker.com-only sandboxes).

## [0.7.2] — 2026-07-11

### Fixed

- Fresh named-volume mounts came up root-owned, breaking uv/pip/pre-commit; `post-create.sh` now
  chowns `~/.cache` (and the scoped `~/.claude/projects` mount) before install steps.
- Documented docker-outside-of-docker as opt-in, with the `chmod 666` socket fix it needs.

---

## [0.7.1] — 2026-07-08

### Fixed

- Node/npm installed unconditionally (the cockpit and Claude Code CLI need npm regardless of
  `include_ts`).
- The agent-memory symlink step degrades to a warning on a permission failure instead of aborting
  `post-create.sh`.

---

## [0.7.0] — 2026-07-08

### Added

- Chassis's own standalone devcontainer at the repo root — clone chassis alone and "Reopen in
  Container." Root `post-create.sh`, Claude settings/hooks, and the dev-coach skill are symlinks
  into `template/`; `devcontainer.json`/`docker-compose.yml` and `.agents/memory/` are
  deliberately independent.
- Cockpit section marked with `<!-- cockpit-section:start/end -->` in both `AGENTS.md` and
  `template/AGENTS.md.jinja`; `ci-lint` fails if they diverge.

---

## [0.6.3] — 2026-07-08

### Added

- `SessionStart` hook: refreshes graphify/ctx and injects a cockpit reminder into the agent's
  context at session start.

---

## [0.6.2] — 2026-07-08

### Added

- Explanation docs for the layered model and two-plane model (merged into `design.md` in 0.8.0).
- Brought `AGENTS.md.jinja`'s cockpit section to parity with the installed tools.

### Changed

- README rewritten to lead with the problem chassis solves and why each bucket exists.

---

## [0.6.1] — 2026-07-08

### Added

- `devcontainer-persistence.md`, `release-a-chassis-version.md` (tag, not commit, is the
  release), and assorted README/cockpit-doc notes.

---

## [0.6.0] — 2026-07-08

### Added

- `claude-projects` named volume for session-transcript durability (reverted in 0.7.6).

### Fixed

- `ci-lint` converted to a shebang recipe (the old `python3 -c` block never ran).
- `just accept` passes `--trust` (copier 9.x refuses `_tasks` without it).

### Note

- Copier resolves the latest semver tag, not branch HEAD — a chassis change needs a tag, not just
  a commit, to reach stamped projects.

---

## [0.5.0] — 2026-07-08

### Added

- `graphify`, `ctx`, and `lean-ctx` added to the bucket-C cockpit (lean-ctx later removed in
  0.7.9; see [ADR-002](docs/decisions/adrs/adr-002-ai-usage-cockpit.md)).
- `/dev-coach` gained optional ctx/lean-ctx signal steps.

---

## [0.4.0] — 2026-06-30

### Added

- Agent-memory durability: `.agents/memory/` is git-tracked and symlinked to
  `~/.claude/projects/<slug>/memory` on every build, so memory survives rebuilds and travels to a
  fresh clone.

---

## [0.3.0] — 2026-06-30

### Added

- OTEL console exporters in `.claude/settings.json`.
- `codeburn` and `abtop` auto-installed (local-first cost/context cockpit; `just metrics` /
  `just monitor`).
- AI Engineer Coach built from source (Claude Code session-log support unconfirmed; made opt-in
  in 0.8.0).
- `dev-coach` skill — anti-pattern detection + AGENTS.md auditor.

---

## [0.2.0] — 2026-06-30

### Added

- `.devcontainer/` template (4-layer model) and the bucket-D slots (`evals/`, `prompts/`,
  prompts-as-code opengrep rule, ADLC gate).

### Changed

- Skills canonical location moved to `.agents/skills/` (`.claude/skills` symlinks to it).
- uv `dev-dependencies` → `[dependency-groups]`; pre-commit/opengrep hooks degrade gracefully
  when the tool isn't on PATH.

### Fixed

- Added a smoke test so a fresh stamp collects at least one test (empty pytest exited 5).

---

## [0.1.0] — 2026-06-29

### Added

- Initial chassis: Copier template with the A/B/C/D bucket structure — bucket-A guardrails,
  bucket-B coverage ratchet, bucket-C codeburn stub, bucket-D wired-but-waiting slots, the
  devcontainer, and the `just accept` acceptance test.
