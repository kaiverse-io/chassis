---
kind: how-to
status: active
last_reviewed: 2026-07-08
---

# How to release a chassis version

A commit to `main` is not a release. If you skip the tag, every project that runs `copier
update` — or anyone stamping a new project with `copier copy` — will not see your change, with
no error or warning that anything is wrong.

## Why the tag is mandatory, not just convention

Copier resolves a git-based template source (`gh:km2411/chassis` or a local path) to the
**latest semver tag** by default, not to the branch's HEAD commit. This was confirmed directly:
a commit pushed to `main` remained completely invisible to both `copier copy` and `copier
update` — for every project — until a new tag was cut, even though the commit was on `main` and
pushed. Passing `--vcs-ref HEAD` explicitly does pick up an untagged commit, but nothing in a
normal `copier update` workflow does that by default, and there's no warning that you're getting
stale content.

Practically: **if a change should reach stamped projects, it needs a tag.** A commit alone is not
enough, no matter how clearly it's described in the CHANGELOG.

## The release checklist

1. Make your change(s) to `template/` (or chassis's own tooling — `justfile`, docs, etc., which
   don't need a tag since they're not part of what gets stamped, but tagging everything together
   keeps history simple).
2. `just ci` — chassis's own guardrails must pass.
3. `just accept` — the real end-to-end check: stamps a throwaway project from your *current*
   working tree state and verifies its own `just ci` passes. Note: `just accept` calls `copier
   copy .` on the working directory, which (being a local path) does reflect uncommitted changes
   correctly for this specific check — the tag-resolution issue above only bites *other*
   consumers pointing at `gh:km2411/chassis`, not this local acceptance test.
4. Add a `CHANGELOG.md` entry under a new version heading (`## [x.y.z] — YYYY-MM-DD`), following
   [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) style — already the convention here.
5. Commit. Push `main`.
6. **Tag it and push the tag** — this is the step that actually makes the release real:
   ```bash
   git tag -a vX.Y.Z -m "short summary"
   git push origin main
   git push origin vX.Y.Z
   ```
7. Verify the tag is actually what gets resolved, especially after any tagging mistake:
   ```bash
   rm -rf ~/.cache/copier   # copier caches the resolved clone locally — clear it to force a fresh resolution
   git describe --tags      # should print exactly vX.Y.Z with no -N-gHASH suffix if HEAD == the new tag
   ```

## Versioning

SemVer, pre-1.0 (`0.x.y`) while the template is still finding its shape. Treat a `0.x` bump as
"notable addition" and reserve patch bumps (`0.x.y`) for pure bugfixes with no new template
content — same distinction used in `CHANGELOG.md` today.

## If you're not sure whether something needs a tag

Ask: "would a project running `copier update` today actually pick this up?" If the answer is
no without a new tag, it needs one before you consider the change shipped.
