#!/usr/bin/env bash
# ub-mode (ADR-008) ships adapted, not verbatim: the upstream "push to the main line" rule
# contradicts AGENTS.md, and its quality tools must come from pinned commits, never a
# floating clone. Assert both, plus that the justfile's {% raw %} block rendered cleanly.
set -euo pipefail
tmpdir="$1"

skill="$tmpdir/.agents/skills/ub-mode/SKILL.md"
test -f "$skill" || { echo "FAIL: no ub-mode SKILL.md at $skill"; exit 1; }
grep -q '^name: ub-mode$' "$skill" || { echo "FAIL: ub-mode SKILL.md has no 'name: ub-mode' frontmatter"; exit 1; }
# Only the rules count — the Adaptations table at the end quotes the removed rule on purpose.
if sed '/^## Adaptations/,$d' "$skill" | grep -qi 'push to the main line'; then
  echo "FAIL: ub-mode still tells agents to push to the main line"
  exit 1
fi
grep -q 'Copyright (c) 2026 Robert C. Martin' "$skill" || { echo "FAIL: ub-mode is missing upstream's MIT notice"; exit 1; }
test -f "$tmpdir/.claude/skills/ub-mode/SKILL.md" || { echo "FAIL: ub-mode not reachable via .claude/skills"; exit 1; }

justfile="$tmpdir/justfile"
for recipe in ub-tools crap dry mutate; do
  grep -qE "^$recipe( |:)" "$justfile" || { echo "FAIL: justfile has no '$recipe' recipe"; exit 1; }
done
for pin in crapper_commit dryer_commit mutator_commit; do
  grep -qE "^$pin := \"[0-9a-f]{40}\"$" "$justfile" || { echo "FAIL: $pin is not pinned to a full commit SHA"; exit 1; }
done
if grep -qE '\{%|%\}' "$justfile"; then
  echo "FAIL: justfile ships unrendered Jinja block tags"
  exit 1
fi
