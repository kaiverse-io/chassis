#!/usr/bin/env bash
# ub-mode (ADR-008) is opt-in: include_ub_mode defaults to false, so the default stamp must
# carry none of it (chassis#10: "Do not make /ub-mode part of every stamp"). With
# include_ub_mode=true it ships adapted, not verbatim — the upstream "push to the main line"
# rule contradicts AGENTS.md — and its tools come from pinned commits. That case needs its own
# stamp, made here from the chassis checkout this check runs in.
set -euo pipefail
tmpdir="$1"

# ── Default stamp: absent ────────────────────────────────────────────────────
test -e "$tmpdir/.agents/skills/ub-mode" && { echo "FAIL: ub-mode skill in the default stamp — include_ub_mode should default to false"; exit 1; }
grep -qE '^(ub-tools|crap|dry|mutate)( |:)' "$tmpdir/justfile" && { echo "FAIL: ub-mode recipes in the default stamp's justfile"; exit 1; }
grep -q 'ub-tools' "$tmpdir/.gitignore" && { echo "FAIL: ub-mode gitignore lines in the default stamp"; exit 1; }
grep -qE '\{%|%\}' "$tmpdir/justfile" "$tmpdir/.gitignore" && { echo "FAIL: unrendered Jinja block tags in the default stamp"; exit 1; }

# ── include_ub_mode=true: present and adapted ────────────────────────────────
on=$(mktemp -d)
trap 'rm -rf "$on"' EXIT
copier copy . "$on" --vcs-ref=HEAD --defaults --trust \
  --data "project_name=UbProject" --data "python_package_name=ub_project" \
  --data "description=ub-mode opt-in check" --data "author_name=Test" \
  --data "author_email=test@example.com" --data "github_owner=kaiverse-io" \
  --data "license=Proprietary" --data "include_ub_mode=true" \
  --overwrite --quiet >/dev/null 2>&1 || { echo "FAIL: stamping with include_ub_mode=true failed"; exit 1; }

skill="$on/.agents/skills/ub-mode/SKILL.md"
test -f "$skill" || { echo "FAIL: include_ub_mode=true did not stamp $skill"; exit 1; }
grep -q '^name: ub-mode$' "$skill" || { echo "FAIL: ub-mode SKILL.md has no 'name: ub-mode' frontmatter"; exit 1; }
# Only the rules count — the Adaptations table at the end quotes the removed rule on purpose.
if sed '/^## Adaptations/,$d' "$skill" | grep -qi 'push to the main line'; then
  echo "FAIL: ub-mode still tells agents to push to the main line"; exit 1
fi
grep -q 'Copyright (c) 2026 Robert C. Martin' "$skill" || { echo "FAIL: ub-mode is missing upstream's MIT notice"; exit 1; }
test -f "$on/.claude/skills/ub-mode/SKILL.md" || { echo "FAIL: ub-mode not reachable via .claude/skills"; exit 1; }

for recipe in ub-tools crap dry mutate; do
  grep -qE "^$recipe( |:)" "$on/justfile" || { echo "FAIL: justfile has no '$recipe' recipe"; exit 1; }
done
for pin in crapper_commit dryer_commit mutator_commit; do
  grep -qE "^$pin := \"[0-9a-f]{40}\"$" "$on/justfile" || { echo "FAIL: $pin is not pinned to a full commit SHA"; exit 1; }
done
grep -q '^\.cache/ub-tools/$' "$on/.gitignore" || { echo "FAIL: include_ub_mode=true did not git-ignore .cache/ub-tools/"; exit 1; }
grep -qE '\{%|%\}' "$on/justfile" "$on/.gitignore" && { echo "FAIL: unrendered Jinja block tags with include_ub_mode=true"; exit 1; }
(cd "$on" && just --list >/dev/null) || { echo "FAIL: include_ub_mode=true justfile does not parse"; exit 1; }
exit 0
