#!/usr/bin/env bash
# Every skill a stamp ships must be a valid SKILL.md for strict harnesses (chassis#20, #21):
# frontmatter with name (= folder) and description, parseable by a real YAML parser, a bounded
# body, and no .mcp.json inside a skill. `just _ci-skills` is the check every stamped project
# runs; this script proves it passes on both stamps and fails on each broken fixture, and that
# its hand-rolled parser agrees with PyYAML on every shipped skill.
set -euo pipefail
tmpdir="$1"

validate_with_pyyaml() { # <stamp dir>
  python3 - "$1" <<'PY'
import pathlib, sys, yaml
root = pathlib.Path(sys.argv[1]) / ".agents/skills"
for skill in sorted(p for p in root.iterdir() if p.is_dir()):
    text = (skill / "SKILL.md").read_text()
    assert text.startswith("---\n"), f"{skill.name}: no frontmatter"
    block = text.split("\n---\n", 1)[0][4:]
    data = yaml.safe_load(block)
    assert isinstance(data, dict), f"{skill.name}: frontmatter is not a mapping"
    assert data.get("name") == skill.name, f"{skill.name}: name {data.get('name')!r} != folder"
    desc = data.get("description")
    assert isinstance(desc, str) and desc.strip() and len(desc) <= 1024, f"{skill.name}: bad description"
PY
}

# ── Default stamp ────────────────────────────────────────────────────────────
(cd "$tmpdir" && just _ci-skills) || { echo "FAIL: just _ci-skills fails on the default stamp"; exit 1; }
validate_with_pyyaml "$tmpdir" || { echo "FAIL: a default-stamp skill is not valid YAML frontmatter"; exit 1; }

# ── Both opt-in skills on ────────────────────────────────────────────────────
on=$(mktemp -d)
bad=$(mktemp -d)
trap 'rm -rf "$on" "$bad"' EXIT
copier copy . "$on" --vcs-ref=HEAD --defaults --trust \
  --data "project_name=SkillsProject" --data "python_package_name=skills_project" \
  --data "description=skills frontmatter check" --data "author_name=Test" \
  --data "author_email=test@example.com" --data "github_owner=kaiverse-io" \
  --data "license=Proprietary" --data "include_ub_mode=true" --data "include_security_audit=true" \
  --overwrite --quiet >/dev/null 2>&1 || { echo "FAIL: stamping with both skills opted in failed"; exit 1; }
for s in arch-review dev-coach example ub-mode security-audit; do
  test -f "$on/.agents/skills/$s/SKILL.md" || { echo "FAIL: $s missing from the opted-in stamp"; exit 1; }
done
(cd "$on" && just _ci-skills) || { echo "FAIL: just _ci-skills fails with both skills opted in"; exit 1; }
validate_with_pyyaml "$on" || { echo "FAIL: an opted-in skill is not valid YAML frontmatter"; exit 1; }

# ── Broken fixtures must fail ────────────────────────────────────────────────
expect_fail() { # <label> <skill name> <mutation command run in the fixture>
  rm -rf "${bad:?}"/* "${bad:?}"/.[!.]* 2>/dev/null || true
  cp "$tmpdir/justfile" "$bad/justfile"
  mkdir -p "$bad/.agents"
  cp -rL "$tmpdir/.agents/skills" "$bad/.agents/skills"
  (cd "$bad" && eval "$3")
  if (cd "$bad" && just _ci-skills >/dev/null 2>&1); then
    echo "FAIL: just _ci-skills accepted a skill with $1"; exit 1
  fi
}
expect_fail "no frontmatter" example "printf '# Example\\n' > .agents/skills/example/SKILL.md"
expect_fail "an unquoted ': ' in the description" example "printf -- '---\nname: example\ndescription: Use when: the user asks\n---\n\nbody\n' > .agents/skills/example/SKILL.md"
python3 -c 'import yaml,sys; yaml.safe_load("description: Use when: the user asks")' 2>/dev/null \
  && { echo "FAIL: fixture assumption wrong, PyYAML accepts an unquoted ': '"; exit 1; }
expect_fail "a name that is not the folder name" example "printf -- '---\nname: other\ndescription: ok\n---\n\nbody\n' > .agents/skills/example/SKILL.md"
expect_fail "a missing description" example "printf -- '---\nname: example\n---\n\nbody\n' > .agents/skills/example/SKILL.md"
expect_fail "a 501-line body" example "{ printf -- '---\nname: example\ndescription: ok\n---\n'; awk 'BEGIN{for(i=0;i<501;i++)print 1}'; } > .agents/skills/example/SKILL.md"
expect_fail "its own .mcp.json" example "echo '{}' > .agents/skills/example/.mcp.json"
expect_fail "no SKILL.md" empty "mkdir .agents/skills/empty"
exit 0
