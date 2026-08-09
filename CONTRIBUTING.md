# Contributing to chassis

Thanks for your interest. chassis is a [Copier](https://copier.readthedocs.io/) template that
stamps new projects with AI-native guardrails, a devcontainer, and an AI-usage cockpit. This
guide is for people changing **chassis itself** — not for working in a project stamped from it
(that project has its own `CONTRIBUTING.md`).

Read [`AGENTS.md`](AGENTS.md) first: it's the canonical context for this repo, including the hard
rules below in more detail, and [`docs/explanation/design.md`](docs/explanation/design.md) for
why the template is shaped the way it is.

## Ground rules

- **Generic only.** No project-specific rule ever ships in the chassis (the one exception is
  self-weakening detection, which is generic to any agent-built repo). If a change only makes
  sense for one downstream project, it belongs in that project's own slots, not here.
- **Thin.** Resist adding features. Validate the template by *stamping* it, not by growing it.
  If `just accept` starts taking more than ~2 minutes, the chassis is too heavy.
- **Self-dogfooding.** chassis must pass its own gates. `just ci` here runs the same discipline a
  stamped project gets, including the check that this repo's cockpit section stays in sync with
  `template/AGENTS.md.jinja`.
- **Decisions get recorded.** A non-trivial change to how the template behaves gets an
  [ADR](docs/decisions/adrs/) (MADR format — see `adr-000-madr-template.md`), not just a commit
  message.
- **No silent rewriters in the agent's read path.** Cockpit tools may observe, advise, or gate
  loudly — never silently transform what the agent perceives. See
  [ADR-004](docs/decisions/adrs/adr-004-no-silent-rewriters.md).
- **No consuming-project references.** Don't name a specific downstream project anywhere in this
  repo; chassis is meant to be cloned and used on its own.

Conventional commits are enforced (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`), and
`git commit --no-verify` is forbidden — fix the violation, don't skip the gate.

## Where changes go

- **Template content** (what gets stamped into projects) lives in `template/`. Its files are
  rendered by Copier; only files ending in `.jinja` are treated as templates (others are copied
  verbatim — e.g. `post-create.sh`, which is why it reads runtime config rather than Jinja).
- **Chassis's own meta** (this file, `README.md`, `AGENTS.md`, `CHANGELOG.md`, `justfile`,
  `docs/`) lives at the repo root, kept out of stamped projects by `copier.yml`'s
  `_subdirectory: template` (see [ADR-001](docs/decisions/adrs/adr-001-copier-subdirectory.md)).
- Some root files (`.devcontainer/post-create.sh`, `.claude/settings.json`, hooks, the dev-coach
  skill) are **symlinks** into `template/` so chassis dogfoods the exact file it ships — edit the
  target in `template/`, and both chassis and every future stamped project get the fix.

## Working locally

```bash
uv tool install copier   # or: pip install copier / uvx copier
just ci                  # lint the chassis + the cockpit-section sync check
just accept              # stamp a throwaway project and verify its own `just ci` is green
```

`just accept` is the real end-to-end check — it stamps from your *current* working tree (via
`copier copy . --vcs-ref=HEAD`) and runs the stamped project's gates. Both `just ci` and
`just accept` must be green before every commit.

## Releasing a version

A commit to `main` is **not** a release by itself. Copier resolves a git-based template source to
the **latest semver tag**, not the branch HEAD — a change that isn't tagged is invisible to
everyone running `copier copy`/`copier update`, with no error. Tagging is automated by
[release-please](https://github.com/googleapis/release-please-action)
(`.github/workflows/release-please.yml` — see
[ADR-007](docs/decisions/adrs/adr-007-automated-releases-via-release-please.md)), not manual:

1. Make the change in `template/` (or chassis's own tooling), using a
   [Conventional Commit](https://www.conventionalcommits.org/) prefix — the prefix is what decides
   the version bump (see "Versioning" below), not a judgment call at tag time anymore.
2. `just ci` — chassis's guardrails must pass.
3. `just accept` — the end-to-end stamp-and-verify.
4. Commit and push (or merge a PR) to `main`. Do **not** hand-edit `CHANGELOG.md` — release-please
   generates its entries from commit history.
5. release-please opens or updates a standing `chore(main): release X.Y.Z` PR, accumulating every
   commit since the last release. **Merging that PR is what actually ships the release** — it
   bumps `.release-please-manifest.json`, rewrites `CHANGELOG.md`, and pushes the `vX.Y.Z` tag +
   GitHub Release automatically. Nothing to run locally.
6. Verify the tag is what resolves, if you need to double check what a fresh `copier copy` sees:
   ```bash
   rm -rf ~/.cache/copier   # copier caches the resolved clone — clear it to force fresh resolution
   git describe --tags      # should print exactly vX.Y.Z with no -N-gHASH suffix when HEAD is the tag
   ```

## Keeping pinned versions current

Every third-party install in `template/.devcontainer/post-create.sh`, the GitHub Actions in
`.github/workflows/ci.yml`, and the `just` binary CI installs are version-pinned — a template
running unattended in strangers' containers doesn't install "latest" (ADR-004). Pinning without
an update process just becomes silent staleness, so [Renovate](https://github.com/apps/renovate)
(free for public repos) is configured in `renovate.json` to open a PR whenever any of these move:

- **GitHub Actions** are pinned to a commit SHA with a `# vX` comment
  ([OpenSSF Scorecard](https://scorecard.dev/)'s Pinned-Dependencies convention); Renovate keeps
  the SHA current via `pinDigests`.
- **Shell-variable pins** (`GITLEAKS_VERSION`, `CODEBURN_VERSION`, `ABTOP_VERSION`,
  `GRAPHIFY_VERSION`, `CTX_VERSION`, `JUST_VERSION`) are matched by a custom regex manager, keyed
  off the `# renovate: datasource=... depName=...` comment directly above each assignment — add
  that same comment above any new pinned variable and Renovate picks it up automatically.
- The **AI Engineer Coach commit pin** (`AEC_COMMIT`) is intentionally *not* Renovate-managed —
  it tracks upstream `main` with no releases, so bumping it is a deliberate, manual act (verify
  what changed before moving the pin), not something to rubber-stamp via an automated PR.

Every Renovate PR still has to pass `just ci` + `just accept` + the devcontainer build before
merge — pinning + automation doesn't mean unattended merges, it means the *proposal* to update
is automatic and the *validation* stays exactly as strict as a hand-authored change.

### Versioning

SemVer, pre-1.0 (`0.x.y`) while the template is still finding its shape. release-please computes
the bump directly from Conventional Commit prefixes since the last release, not from manual
judgment: `feat:` → minor, `fix:` → patch, a `!` after the type or a `BREAKING CHANGE:` footer →
major. Pick the prefix with that mapping in mind — it's no longer just changelog categorization,
it's the thing that decides the version number.

If you're unsure whether something needs a tag, ask: "would a project running `copier update`
today actually pick this up?" If not without a new tag, it needs one — which now just means
merging release-please's standing release PR.

## Reporting security issues

See [`SECURITY.md`](SECURITY.md). Don't open a public issue for a vulnerability.
