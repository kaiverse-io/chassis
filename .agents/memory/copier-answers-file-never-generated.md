---
name: copier-answers-file-never-generated
description: chassis never actually wrote .copier-answers.yml to stamped projects, so copier update has never worked for any project stamped from chassis
metadata:
  type: project
---

`copier.yml` sets `_answers_file: .copier-answers.yml`, which only tells copier what to *name*
the answers file if it renders one — it does not make copier write one. Copier only generates the
answers file if the template itself contains a file literally named
`{{ _copier_conf.answers_file }}.jinja` with the content `{{ _copier_answers|to_nice_yaml }}`.
`template/` never had that file, so every project ever stamped from chassis (including aither) has
no `.copier-answers.yml` — `copier update` fails immediately with `TypeError: Template not found`.

**Why:** found while trying to run `copier update` on aither to pull a devcontainer fix — it
errored outright. Confirmed by stamping a fresh throwaway project from chassis's current HEAD and
finding no `.copier-answers.yml` in the output, then checking `template/` for the special
answers-file template and finding it absent. This is a copier idiom, not something obvious from
`copier.yml` alone — see [[devcontainer-docker-outside-of-docker-moby]] for the specific fix that prompted this
discovery.

**How to apply:** fixed by adding `template/{{ _copier_conf.answers_file }}.jinja` (single line:
`{{ _copier_answers|to_nice_yaml }}`) — the standard copier pattern. `just accept` now asserts
`.copier-answers.yml` exists post-stamp so this can't silently regress. Also found while verifying
this: `just accept`'s `copier copy .` (no `--vcs-ref`) silently pins to the latest git *tag* on a
local-path source, not the current commit — it now passes `--vcs-ref=HEAD` explicitly, otherwise
uncommitted/untagged work on main is never actually exercised by the acceptance test.

Projects already stamped before this fix (aither) still have no answers file retroactively — there
is no way to generate one after the fact except reconstructing it by hand (figuring out the
original `_commit` from timestamps, and the original answers from the project's current files).
