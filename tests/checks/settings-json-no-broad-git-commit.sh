#!/usr/bin/env bash
# `Bash(git commit *)` in permissions.allow prefix-matches `git commit --no-verify`,
# auto-approving the #1 Forbidden Pattern in AGENTS.md without a prompt. Claude Code
# evaluates deny before allow regardless of specificity (confirmed against its own
# docs), so the fix is an explicit deny for --no-verify — it wins over the broad
# commit allow without disrupting normal commits.
set -euo pipefail
tmpdir="$1"

settings="$tmpdir/.claude/settings.json"
test -f "$settings" || {
  echo "FAIL: no .claude/settings.json in stamped output"
  exit 1
}

python3 - "$settings" <<'PY'
import json, sys

path = sys.argv[1]
data = json.load(open(path))
perms = data.get("permissions", {})
allow = perms.get("allow", [])
deny = perms.get("deny", [])

has_no_verify_deny = any("no-verify" in d for d in deny)
if not has_no_verify_deny:
    print("FAIL: no permissions.deny entry blocks --no-verify")
    sys.exit(1)

# settings.json.jinja is excluded from the agent-no-skip-verify opengrep rule (its own
# deny entry necessarily contains the string it blocks) — assert directly that nothing
# in allow re-introduces a real bypass, since opengrep can no longer watch this file.
bad_allow = [a for a in allow if "no-verify" in a]
if bad_allow:
    print(f"FAIL: permissions.allow contains a --no-verify entry: {bad_allow}")
    sys.exit(1)
PY
