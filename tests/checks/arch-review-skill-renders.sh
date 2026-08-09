#!/usr/bin/env bash
# arch-review/SKILL.md contains {{ python_package_name }} but historically shipped
# without a .jinja suffix, so Copier copied it verbatim instead of rendering it.
set -euo pipefail
tmpdir="$1"

skill_file=""
for candidate in \
  "$tmpdir/.agents/skills/arch-review/SKILL.md" \
  "$tmpdir/.claude/skills/arch-review/SKILL.md"
do
  [ -f "$candidate" ] && skill_file="$candidate" && break
done

[ -n "$skill_file" ] || {
  echo "FAIL: no arch-review SKILL.md found in stamped output at either canonical path"
  exit 1
}

if grep -q '{{' "$skill_file"; then
  echo "FAIL: $skill_file ships unrendered Jinja syntax — it needs a .jinja suffix in template/"
  exit 1
fi
