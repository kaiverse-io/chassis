#!/usr/bin/env bash
# arch-review/SKILL.md contains {{ python_package_name }} but historically shipped
# without a .jinja suffix, so Copier copied it verbatim instead of rendering it.
# Canonical source is .agents/skills/ (the SKILL.md open standard) — .claude/skills
# is only ever a symlink into it (see preserve-symlinks-skills.sh), so checking the
# canonical path alone covers both.
set -euo pipefail
tmpdir="$1"

skill_file="$tmpdir/.agents/skills/arch-review/SKILL.md"
test -f "$skill_file" || {
  echo "FAIL: no arch-review SKILL.md at $skill_file in stamped output"
  exit 1
}

if grep -q '{{' "$skill_file"; then
  echo "FAIL: $skill_file ships unrendered Jinja syntax — it needs a .jinja suffix in template/"
  exit 1
fi
