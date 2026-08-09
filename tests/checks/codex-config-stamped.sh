#!/usr/bin/env bash
# Codex is one of the two other harnesses agnova switches between interchangeably
# (goose is the other — see goose-mode-configured.sh). Governance's live enforcement
# was Claude-Code-only until these files existed (design.md's "Harness neutrality").
set -euo pipefail
tmpdir="$1"

config="$tmpdir/.codex/config.toml"
test -f "$config" || {
  echo "FAIL: no .codex/config.toml in stamped output"
  exit 1
}

grep -qE '^approval_policy = "untrusted"$' "$config" || {
  echo "FAIL: .codex/config.toml does not pin approval_policy = \"untrusted\""
  exit 1
}

grep -qE '^sandbox_mode = "workspace-write"$' "$config" || {
  echo "FAIL: .codex/config.toml does not pin sandbox_mode = \"workspace-write\""
  exit 1
}

rules="$tmpdir/.codex/rules/default.rules"
test -f "$rules" || {
  echo "FAIL: no .codex/rules/default.rules in stamped output"
  exit 1
}

for verb in commit push; do
  grep -qE "pattern = \[\"git\", \"$verb\", \"--no-verify\"\]" "$rules" || {
    echo "FAIL: default.rules has no prefix_rule for git $verb --no-verify"
    exit 1
  }
done

# opengrep can no longer watch this file (it's excluded from agent-no-skip-verify,
# since the rule that blocks --no-verify necessarily contains the string) — assert
# directly that both patterns are actually paired with decision = "forbidden", not
# silently weakened to "allow" or "prompt".
forbidden_count=$(grep -c 'decision = "forbidden"' "$rules")
[ "$forbidden_count" -ge 2 ] || {
  echo "FAIL: default.rules has fewer than 2 decision = \"forbidden\" rules (found $forbidden_count)"
  exit 1
}
