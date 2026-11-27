#!/usr/bin/env bash
# The friction log (chassis#22) only works if every piece names the same file: the stamp ships the
# seed, AGENTS.md tells agents to append to it, MEMORY.md indexes it, and /dev-coach reads it.
# Also checks the CODEOWNERS split: skills are reviewed, memory (written to routinely) is not.
set -euo pipefail
tmpdir="$1"
log=".agents/memory/papercuts.md"
test -f "$tmpdir/$log" || { echo "FAIL: stamp has no $log seed"; exit 1; }
grep -q 'papercuts.md' "$tmpdir/.agents/memory/MEMORY.md" || { echo "FAIL: MEMORY.md does not index papercuts.md"; exit 1; }
grep -q "$log" "$tmpdir/AGENTS.md" || { echo "FAIL: AGENTS.md does not tell agents to write to $log"; exit 1; }
grep -q "$log" "$tmpdir/.agents/skills/dev-coach/SKILL.md" || { echo "FAIL: dev-coach does not read $log"; exit 1; }
grep -q 'public' "$tmpdir/$log" || { echo "FAIL: the seed does not say the log is public"; exit 1; }
owners="$tmpdir/CODEOWNERS"
grep -qE '^\.agents/skills/[[:space:]]+@' "$owners" || { echo "FAIL: CODEOWNERS does not list .agents/skills/"; exit 1; }
grep -qE '^\.agents/(memory/)?[[:space:]]+@' "$owners" && { echo "FAIL: CODEOWNERS makes all of .agents/ (or memory) need owner review"; exit 1; }
exit 0
