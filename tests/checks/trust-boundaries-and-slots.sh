#!/usr/bin/env bash
# chassis#10 / #9: one-way-door commands are denied in every harness config chassis stamps;
# MCP servers come from one reviewed file; the slots #10 lists exist; and AGENTS.md — loaded
# by every session — cannot silently grow past its size limit.
set -euo pipefail
tmpdir="$1"

python3 - "$tmpdir/.claude/settings.json" <<'PY'
import json, sys
deny = json.load(open(sys.argv[1]))["permissions"]["deny"]
need = ["Bash(git push --force*)", "Bash(git push -f*)", "Bash(git reset --hard*)", "Bash(git clean -f*)"]
missing = [d for d in need if d not in deny]
if missing:
    print(f"FAIL: .claude/settings.json does not deny {missing}"); sys.exit(1)
PY
rules="$tmpdir/.codex/rules/default.rules"
for cmd in '"push", "--force"' '"push", "-f"' '"reset", "--hard"' '"clean", "-f"'; do
  grep -q "pattern = \[\"git\", $cmd\]" "$rules" || { echo "FAIL: Codex rules do not forbid git $cmd"; exit 1; }
done

python3 -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if d.get('mcpServers')=={} else 1)" "$tmpdir/.mcp.json" \
  || { echo "FAIL: .mcp.json missing, invalid, or not empty by default"; exit 1; }
grep -q '^\.mcp\.json ' "$tmpdir/CODEOWNERS" || { echo "FAIL: .mcp.json is not under CODEOWNERS"; exit 1; }

for slot in docs/feature-map.md tests/boundary/README.md docs/how-to/review-agent-changes.md; do
  test -f "$tmpdir/$slot" || { echo "FAIL: slot $slot missing"; exit 1; }
done

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp -a "$tmpdir/." "$work/"
cd "$work"
just _ci-agents-size >/dev/null 2>&1 || { echo "FAIL: AGENTS.md size gate fails on a fresh stamp"; exit 1; }
python3 -c "print('\n'.join('filler' for _ in range(200)))" >> AGENTS.md
if just _ci-agents-size >/dev/null 2>&1; then
  echo "FAIL: AGENTS.md size gate passed a 350-line AGENTS.md"; exit 1
fi
