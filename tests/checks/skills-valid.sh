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

# ── Fixtures: each broken skill must fail for the stated reason; valid variants must pass ───
fixture() { # <skill SKILL.md content, printf format> -> fresh copy of the skills in $bad
  rm -rf "${bad:?}"/* "${bad:?}"/.[!.]* 2>/dev/null || true
  cp "$tmpdir/justfile" "$bad/justfile"
  mkdir -p "$bad/.agents"
  cp -rL "$tmpdir/.agents/skills" "$bad/.agents/skills"
  # shellcheck disable=SC2059
  printf -- "$1" > "$bad/.agents/skills/example/SKILL.md"
}
expect_fail() { # <label> <expected message fragment> <printf content>
  fixture "$3"
  out=$(cd "$bad" && just _ci-skills 2>&1) && { echo "FAIL: just _ci-skills accepted a skill with $1"; exit 1; }
  grep -qF -- "$2" <<<"$out" || { echo "FAIL: '$1' failed for the wrong reason (wanted '$2')"; echo "$out"; exit 1; }
}
expect_pass() { # <label> <printf content>
  fixture "$2"
  out=$(cd "$bad" && just _ci-skills 2>&1) || { echo "FAIL: just _ci-skills rejected valid frontmatter: $1"; echo "$out"; exit 1; }
  # The same block must also be valid for a real YAML parser, with string name and description.
  python3 - "$bad/.agents/skills/example/SKILL.md" <<'PY' || { echo "FAIL: fixture '$1' is not valid for PyYAML, so the test itself is wrong"; exit 1; }
import sys, yaml
text = open(sys.argv[1]).read()
d = yaml.safe_load(text.split("\n---\n", 1)[0][4:])
assert isinstance(d["name"], str) and isinstance(d["description"], str), d
PY
}
hdr='---\nname: example\n'
expect_fail "no frontmatter" "no frontmatter block" '# Example\n'
expect_fail "an unquoted ': ' in the description" "quote it" "${hdr}description: Use when: the user asks\n---\n\nbody\n"
python3 -c 'import yaml; yaml.safe_load("description: Use when: the user asks")' 2>/dev/null \
  && { echo "FAIL: fixture assumption wrong, PyYAML accepts an unquoted ': '"; exit 1; }
expect_fail "a reserved leading character" "quote it" "${hdr}description: \`foo\`\n---\n\nbody\n"
expect_fail "a boolean description" "bool, null or number" "${hdr}description: true\n---\n\nbody\n"
expect_fail "a null description" "bool, null or number" "${hdr}description: ~\n---\n\nbody\n"
expect_fail "a list description" "quote it" "${hdr}description: [a, b]\n---\n\nbody\n"
expect_fail "a name that is not the folder name" "must equal the folder name" '---\nname: other\ndescription: ok\n---\n\nbody\n'
expect_fail "a missing description" "no usable 'description'" "${hdr}---\n\nbody\n"
expect_fail "a tab-indented line" "tab" "${hdr}description: ok\n\tfoo: bar\n---\n\nbody\n"
expect_fail "an over-long description" "limit 1024" "${hdr}description: $(printf 'x%.0s' $(seq 1 1025))\n---\n\nbody\n"
expect_fail "a 501-line body" "limit 500" "${hdr}description: ok\n---\n$(awk 'BEGIN{for(i=0;i<501;i++)printf "line\\n"}')\n"
fixture "${hdr}description: ok\n---\n\nbody\n"; echo '{}' > "$bad/.agents/skills/example/.mcp.json"
out=$(cd "$bad" && just _ci-skills 2>&1) && { echo "FAIL: accepted a skill with its own .mcp.json"; exit 1; }
grep -qF 'must not carry its own .mcp.json' <<<"$out" || { echo "FAIL: .mcp.json failed for the wrong reason"; echo "$out"; exit 1; }
fixture "${hdr}description: ok\n---\n\nbody\n"; mkdir "$bad/.agents/skills/empty"
out=$(cd "$bad" && just _ci-skills 2>&1) && { echo "FAIL: accepted a skill folder with no SKILL.md"; exit 1; }
grep -qF 'no SKILL.md' <<<"$out" || { echo "FAIL: empty folder failed for the wrong reason"; echo "$out"; exit 1; }
fixture "${hdr}description: ok\n---\n\nbody\n"; ln -s /nonexistent-skill-target "$bad/.agents/skills/ghost"
out=$(cd "$bad" && just _ci-skills 2>&1) && { echo "FAIL: accepted a dangling skill symlink"; exit 1; }
grep -qF 'dangling symlink' <<<"$out" || { echo "FAIL: dangling symlink failed for the wrong reason"; echo "$out"; exit 1; }

expect_pass "quoted value with a trailing comment" "${hdr}description: \"ok\" # note\n---\n\nbody\n"
expect_pass "plain name with a trailing comment" '---\nname: example  # the folder\ndescription: ok\n---\n\nbody\n'
expect_pass "comment line inside the frontmatter" "${hdr}# a note\ndescription: ok\n---\n\nbody\n"
expect_pass "single-quoted value" "${hdr}description: 'it''s ok: really'\n---\n\nbody\n"
expect_pass "folded block" "${hdr}description: >\n  first line\n  second line\n---\n\nbody\n"
exit 0
