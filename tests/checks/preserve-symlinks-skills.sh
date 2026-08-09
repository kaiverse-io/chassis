#!/usr/bin/env bash
# Copier dereferences symlinks by default (_preserve_symlinks: false), so
# template/.claude/skills -> ../.agents/skills was landing as a duplicated real
# directory in every stamp, not a symlink — "one canonical copy, thin adapters"
# wasn't actually true.
set -euo pipefail
tmpdir="$1"

path="$tmpdir/.claude/skills"
test -e "$path" || {
  echo "FAIL: $path does not exist in stamped output"
  exit 1
}

[ -L "$path" ] || {
  echo "FAIL: $path is a real directory, not a symlink — _preserve_symlinks isn't working"
  exit 1
}
