# Changelog

All notable changes to the chassis are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [SemVer](https://semver.org/).

Rationale for a decision lives in its [ADR](docs/decisions/adrs/); this file records *what*
changed, tersely. Anything longer is in git history or an ADR.

---

## [Unreleased]

### Added

- `template/CLAUDE.md` (`@AGENTS.md` import) — Claude Code reads `CLAUDE.md`, not
  `AGENTS.md`; without this bridge, every stamped project's Forbidden Patterns and Hard
  Rules never reached a Claude Code session at all.
- `template/LICENSE.jinja` — no LICENSE file was ever stamped despite `pyproject.toml`
  declaring one in metadata.
- `tests/checks/` — a regression suite (one script per defect, taking a stamped tmpdir)
  that `just accept` now runs and reports in full, instead of aborting at the first
  failure.
- `_preserve_symlinks: true` in `copier.yml` — the one symlink in `template/`
  (`.claude/skills -> ../.agents/skills`) was being dereferenced into a duplicated real
  directory on every stamp and `copier update`, silently breaking the "one canonical
  copy, thin adapter" pattern it exists to demonstrate.
- `permissions.deny: ["Bash(*--no-verify*)"]` in `.claude/settings.json.jinja` —
  `Bash(git commit *)` was pre-approving `--no-verify`, the first Forbidden Pattern in
  AGENTS.md, without a prompt.
- `.github/workflows/release-please.yml` (chassis's own root, unconditional) — a merge
  to `main` was not itself a release (Copier resolves the latest tag, not HEAD), and the
  only path to a tag was a manual checklist step in `CONTRIBUTING.md`, easy to forget.
  release-please now stages a `chore(main): release X.Y.Z` PR from Conventional Commits;
  merging it cuts the tag + GitHub Release. See
  [ADR-007](docs/decisions/adrs/adr-007-automated-releases-via-release-please.md).
- `enable_release_automation` Copier question (default `false`) — the same release-please
  automation, opt-in for stamped projects, bumping `pyproject.toml`'s version instead of
  chassis's own package-less root.

### Fixed

- `agent-no-bare-noqa` and `no-inline-prompt-literals` opengrep rules promoted
  `WARNING` → `ERROR` — both runners filter `--severity ERROR`, so these never actually
  fired. `agent-no-lower-coverage-floor` stays `WARNING` deliberately (see its own
  comment) — promoting it would fail the default stamp's intentional `fail_under = 0`.
- `template/.agents/skills/arch-review/SKILL.md` renamed to `SKILL.md.jinja` — it
  contains `{{ python_package_name }}` but shipped unrendered to every stamped project.
- `_tasks`: `git init` → `git init -b main` — CI and CONTRIBUTING both assume `main`;
  on any host without `init.defaultBranch` set, a fresh stamp landed on `master` and CI
  silently never fired.
- `uv` and `just` installs in `post-create.sh` are now pinned to a specific release and
  SHA-256 verified, matching the standard `ctx` already held in the same file — both
  were previously an unpinned `curl | sh`/`curl | bash` against "latest."
- `dev-coach/SKILL.md` step 2 now reads `.agents/memory/` directly instead of filtering
  on `metadata.type: feedback` — chassis's own real memory files all use
  `type: project`, so the filter matched zero files even against chassis's own
  dogfooded memory.
- `AGENTS.md.jinja`'s "Agent-memory convention" pointed agents at
  `~/.claude/projects/<slug>/memory/`, which only exists because a `post-create.sh`
  symlink step recreates it (and degrades to a warning, not an abort, on failure) — now
  points at the canonical `.agents/memory/` directly.
- Dangling `ADR-016` citations in `dev-coach/SKILL.md` and
  `docs/decisions/adrs/adr-002-ai-usage-cockpit.md` — no such ADR exists.
- Stale `github_owner=km2411` in `justfile`'s `accept` recipe and `copier.yml`'s help
  text, and in `LICENSE`'s copyright line — the org renamed to `kaiverse-io`.

### Changed

- `enable_docker_outside_of_docker` now defaults to `false`. It was `true` while its
  own help text called it "opt-in," and grants the container read-write access to the
  host's docker socket (`post-create.sh` `chmod 666`'s it) — equivalent to root on the
  host. True opt-in also fits the template's own claim to support no-host-Docker
  remote/cloud devcontainers better than a default-on socket mount does.
- `include_ts`'s help text now describes what it actually does (gates a pre-commit
  cache volume and one VS Code extension) instead of implying a generated TypeScript
  scaffold that never existed.

## [0.11.0] — 2026-08-02

### Added

- Copier answer `coverage_fail_under` (int, default `0`, validated 0–100): stamps the
  bucket-B pytest-cov floor into **both** `[tool.coverage.report] fail_under` and pytest
  `--cov-fail-under` (kept identical on purpose). The cov target remains
  `python_package_name`. CI already enforces via `just ci-test` → `uv run pytest` — no
  workflow change. After stamp, raise the floor in-repo only; never lower it. On
  `copier update`, keep the answer at the project's current floor so a default `0`
  cannot silently rewrite a raised ratchet. See
  [ADR-005](docs/decisions/adrs/adr-005-coverage-fail-under-stamp.md).
- `just accept` now asserts the default stamp renders `0` in both sites and that a
  non-default `coverage_fail_under=42` stamp renders `42` in both (without running that
  project's tests, so a high floor doesn't false-fail the smoke suite).

## [0.10.0] — 2026-07-31

### Added

- Activated the former arch-drift bucket-D slot: every stamped project now gets a
  hand-maintained `ARCHITECTURE.md` (one `##` section per top-level `src/<package>/`
  component — purpose, dependencies, plain-ASCII diagram, no Mermaid) plus a mechanical
  coverage gate (`just ci-arch`, wired into `just ci` and the CI workflow) that blocks CI
  if a component has no matching section. Semantic accuracy (does the section still match
  the code) is a separate concern, covered by the new `/arch-review` skill
  (`.agents/skills/arch-review/SKILL.md`) — on-demand, not a hard gate, since drift
  detection needs a read of the actual code, not a regex match.
- `AGENTS.md` gained an "Architecture documentation" section instructing agents to add a
  component's `ARCHITECTURE.md` section in the same PR that adds the component.
- Reclassified in the bucket model: coverage moves from D (wired-but-waiting) to A
  (blocking); the accuracy-review skill lives in C (on-demand) alongside `/dev-coach`.

## [0.9.0] — 2026-07-31

### Added

- `enable_docker_outside_of_docker` copier variable (default `true`): the
  docker-outside-of-docker feature + host `docker.sock` mount is now included in every
  stamped project's `devcontainer.json` by default, instead of a comment-only recipe a
  project had to hand-copy in. Turn it off at stamp time for a no-host-Docker
  remote/cloud devcontainer. Chassis's own root `.devcontainer/devcontainer.json` mirrors
  the same default.

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
