---
kind: adr
status: accepted
owner: founder
last_reviewed: 2026-08-09
---

# ADR-007 — Automated releases via release-please

- **Status:** Accepted (2026-08-09)
- **Deciders:** founder

## Context

PR #3 (ADR-006's harness-neutral Governance adapters, plus the earlier determinism fixes) merged
to `main` with no tag following it. Chassis's only release process was a manual checklist in
`CONTRIBUTING.md`: hand-edit `CHANGELOG.md`, `git tag -a`, push the tag. Copier resolves a
git-based template source to the latest semver tag, not branch HEAD — a merged, untagged change
is invisible to every `copier copy`/`copier update`, silently, with no error. The manual step is
also the one most likely to be forgotten, since nothing enforces it the way `just ci`/`just
accept` enforce everything else.

## Decision drivers

- Chassis already enforces Conventional Commits (`AGENTS.md` Hard Rules) and already keeps
  `CHANGELOG.md` in Keep a Changelog format — both prerequisites a release tool can build on
  rather than impose.
- "Significant decisions get reviewed" is chassis's own standing norm (ADRs, PR review); a release
  mechanism that tags and publishes with no human checkpoint would be out of step with that.
- Chassis's own root and the stamped `template/` are different consumers with different needs:
  chassis always wants versioned releases of itself; a stamped project might not want any (an
  internal app, or one with its own release process already).

## Considered options

1. **semantic-release.** *Rejected* — Node/npm-based plugin chain to install and pin; default mode
   tags and publishes immediately on merge to `main` with no staging PR, a weaker review gate than
   the alternative below. Better fit for projects publishing an npm package than for chassis, which
   isn't one.
2. **release-drafter.** *Rejected* — only auto-drafts release notes; a human still has to manually
   compute the version and click "Publish" to actually cut a tag. Doesn't answer "make it
   automatic," only "make the notes easier to write."
3. **Homegrown workflow + a pinned `git-cliff` binary**, following chassis's own preference for
   pinned release assets over external tooling (ADR-004). *Rejected, for now* — closest to
   chassis's existing dependency posture, but it means chassis owns the version-bump/tag/changelog
   -promotion logic itself: real code, with its own edge cases (semver computation, changelog
   parsing), directly trading dependency-surface for maintenance-surface. Revisit if
   release-please's opinions ever become a real constraint.
4. **release-please.** *Chosen.* Parses Conventional Commits since the last release, keeps a
   standing `chore(main): release X.Y.Z` PR up to date with the computed bump and generated
   changelog, and only tags + publishes a GitHub Release when *that* PR is merged — a human
   checkpoint on every release, consistent with driver 2, while removing the manual tagging toil
   that driver 1 exists to prevent recurring.

## Decision

Two integration points, deliberately different defaults:

- **Chassis's own root** (`.github/workflows/release-please.yml`,
  `release-please-config.json`, `.release-please-manifest.json`) — unconditional.
  `release-type: "simple"` (chassis has no root `pyproject.toml` to bump; only `CHANGELOG.md` +
  the tag + the GitHub Release are managed). Manifest seeded at the real current tag, `0.12.0`, so
  release-please computes forward from reality instead of restarting at `0.0.0`. The GitHub Action
  is pinned to a commit SHA with a `# vX` comment, matching `.github/workflows/ci.yml`'s own
  convention — Renovate (`pinDigests: true`) keeps it current the same way it already does for
  `actions/checkout` and `astral-sh/setup-uv`.
- **`template/`** — gated behind a new opt-in Copier question, `enable_release_automation`
  (default `false`), matching the unanimous precedent of every other behavior-changing toggle in
  `copier.yml` (`include_ts`, `install_ai_coach`, `enable_docker_outside_of_docker` are all
  opt-in). This is a different shape of decision than ADR-006's Codex/goose adapters, which are
  inert static config until that harness happens to be installed — a release-please workflow
  actively opens PRs and rewrites files in the stamped repo the moment it's present, whether or
  not the project owner wants automated version bumps at all. When enabled, `release-type:
  "python"` bumps `pyproject.toml`'s PEP 621 `[project] version` field directly (confirmed by
  reading release-please's own `PyProjectToml` updater and `python.ts` strategy source: it targets
  `parsed.project.version` when present, `createIfMissing: false`, and gracefully skips the
  setup.py/setup.cfg files a stamped project never has). The Action reference stays an unpinned
  floating tag (`@v5`), matching `ci.yaml.jinja`/`adlc-gate.yaml.jinja`'s own convention — stamped
  projects get no Renovate config from chassis today, so a hand-pinned SHA there would never
  update and would be strictly worse than a tag a human can audit by eye.

The three new template files (`release-please.yaml`, `release-please-config.json`,
`.release-please-manifest.json`) use Copier's documented conditional-filename idiom —
`{% if enable_release_automation %}name{% endif %}.jinja`, with the `.jinja` suffix kept outside
the condition — rather than a templated `_exclude` entry. This is the first file of this shape in
chassis; every other optional feature (`install_ai_coach`, `enable_docker_outside_of_docker`) is
an inline `{% if %}` block inside an always-present shared file, because a GitHub Actions workflow
can't be "partially" rendered the way a shell script block can.

## Consequences

**Good:** chassis itself gets a real, enforced release process instead of a checklist step that's
easy to forget; a stamped project that opts in gets the same, adapted to bump its own
`pyproject.toml`; neither requires any new secret (the default `GITHUB_TOKEN` with
`contents`/`pull-requests`/`issues` write permissions is sufficient for same-repo tag + release
creation).

**Bad / risks:** one-time bootstrap wrinkle — release-please's first run generates its own
changelog entries from commit history since `v0.12.0`, which may not exactly match the
hand-written prose already sitting under `CHANGELOG.md`'s `[Unreleased]` heading; expect the first
release PR's diff to need a manual look, not just a rubber-stamp merge. Ongoing: a stamped project
that enables `enable_release_automation` is trusting release-please's Conventional-Commit parsing
to compute its version correctly — a mis-typed commit prefix (e.g. `feat:` for something that
should have been `fix:`) now directly produces a wrong version bump, where before it was just a
changelog miscategorization. Mitigated by the same PR-review checkpoint the whole design is built
around: the bump is visible in the release PR's diff before anything is tagged.
