#!/usr/bin/env bash
# Claude Code reads CLAUDE.md, not AGENTS.md (confirmed against Claude Code's own docs).
# Without a bridge, every "Forbidden pattern" / "Hard rule" in AGENTS.md never reaches
# a Claude Code session in any stamped project.
set -euo pipefail
tmpdir="$1"

test -f "$tmpdir/CLAUDE.md" || {
  echo "FAIL: CLAUDE.md not stamped — Claude Code will never load AGENTS.md's rules"
  exit 1
}

grep -q '@AGENTS.md' "$tmpdir/CLAUDE.md" || {
  echo "FAIL: CLAUDE.md exists but does not import AGENTS.md via @AGENTS.md"
  exit 1
}
