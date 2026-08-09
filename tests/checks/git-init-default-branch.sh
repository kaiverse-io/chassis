#!/usr/bin/env bash
# CI and CONTRIBUTING.md both assume `main`. `_tasks` used to run plain `git init`,
# which follows the *host's* init.defaultBranch — on any host where that isn't
# configured to `main`, CI silently never fires on a fresh stamp. Checked two ways:
# the actual branch a fresh stamp lands on, and that copier.yml forces it explicitly
# (so a host that already defaults to `main` can't mask the underlying config gap).
set -euo pipefail
tmpdir="$1"

branch=$(git -C "$tmpdir" branch --show-current 2>/dev/null || echo "")
[ "$branch" = "main" ] || {
  echo "FAIL: fresh stamp is on branch '$branch', not 'main' — CI (branches: [main]) would never fire"
  exit 1
}

grep -qE '^\s*-\s*git init\b.*(-b main|--initial-branch[= ]main)' copier.yml || {
  echo "FAIL: copier.yml's _tasks does not force the initial branch explicitly — relies on host git config"
  exit 1
}
