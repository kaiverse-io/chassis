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

A commit to `main` is **not** a release. Copier resolves a git-based template source to the
**latest semver tag**, not the branch HEAD — a change that isn't tagged is invisible to everyone
running `copier copy`/`copier update`, with no error. If a change should reach stamped projects,
it needs a tag.

Checklist:

1. Make the change in `template/` (or chassis's own tooling).
2. `just ci` — chassis's guardrails must pass.
3. `just accept` — the end-to-end stamp-and-verify.
4. Add a `CHANGELOG.md` entry under a new version heading (`## [x.y.z] — YYYY-MM-DD`),
   [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) style. Move `[Unreleased]` items down.
5. Commit and push `main`.
6. **Tag it and push the tag** — the step that actually ships the release:
   ```bash
   git tag -a vX.Y.Z -m "short summary"
   git push origin main
   git push origin vX.Y.Z
   ```
7. Verify the tag is what resolves, especially after a tagging mistake:
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

SemVer, pre-1.0 (`0.x.y`) while the template is still finding its shape. Treat a minor bump
(`0.x`) as a notable addition or a change in stamped output (new copier variable, new default);
reserve patch bumps (`0.x.y`) for pure bugfixes with no new template content.

If you're unsure whether something needs a tag, ask: "would a project running `copier update`
today actually pick this up?" If not without a new tag, it needs one before the change is shipped.

## Reporting security issues

See [`SECURITY.md`](SECURITY.md). Don't open a public issue for a vulnerability.
