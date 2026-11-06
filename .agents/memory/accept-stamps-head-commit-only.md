---
name: accept-stamps-head-commit-only
description: `just accept` stamps the committed HEAD (--vcs-ref=HEAD), so uncommitted template edits are silently not tested; and import-linter >= 2.16 rejects an empty contract slot
metadata:
  type: project
---

`just accept` runs `copier copy . --vcs-ref=HEAD`: it stamps the **last commit**, not the
working tree. Template edits that are not committed yet are not exercised at all — the run
looks green against old content. Commit (on a branch) before running `accept`; amend as you
iterate.

Separately, import-linter 2.16 started exiting 1 on a config with no contracts ("No contracts
found in the configuration"). The template ships `.importlinter` with the contract slot empty,
so every fresh stamp's `just ci` went red with no change in chassis. Fixed 2026-11-06 by having
`ci-lint` run `lint-imports` only once a `[importlinter:contract:…]` section exists;
`tests/checks/import-linter-empty-slot.sh` guards both halves. Watch for this class of break: a
dev dependency's minor release changing what an *empty* config means.
