#!/usr/bin/env bash
# agent-no-bare-noqa and no-inline-prompt-literals used to be WARNING while both
# opengrep runners filter --severity ERROR, so they never fired. Proves the promoted
# rules actually catch violations, using a throwaway fixture built in mktemp -d —
# never commit a violating fixture, or chassis's own ci-secrets/opengrep self-trips.
set -euo pipefail
tmpdir="$1"

command -v opengrep >/dev/null 2>&1 || {
  echo "SKIP: opengrep not installed — cannot verify rule enforcement"
  exit 0
}

rules_dir="$tmpdir/.opengrep/rules"
test -d "$rules_dir" || {
  echo "FAIL: no .opengrep/rules/ in stamped output"
  exit 1
}

fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT

cat > "$fixture/bad_noqa.py" <<'PY'
import os  # noqa
PY

python3 - "$fixture/bad_prompt.py" <<'PY'
import sys
long_body = "x" * 220
content = 'prompt = """' + long_body + '"""\n'
open(sys.argv[1], "w").write(content)
PY

findings=$(opengrep scan --config "$rules_dir" "$fixture" --severity ERROR --json 2>/dev/null \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len(d.get("results", [])))' \
  || echo 0)

[ "$findings" -ge 2 ] || {
  echo "FAIL: promoted rules found $findings ERROR findings against a 2-violation fixture (expected >= 2) — still not enforced"
  exit 1
}
