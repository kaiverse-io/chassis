#!/usr/bin/env bash
# Claude Code's auto-memory holds personal context. Linking it into the git-tracked
# .agents/memory/ would commit it, and publish it in a public project (chassis#20). The stamp
# must not create that link, and AGENTS.md must say .agents/memory/ is public.
set -euo pipefail
tmpdir="$1"
pc="$tmpdir/.devcontainer/post-create.sh"
test -f "$pc" || { echo "FAIL: stamp has no post-create.sh"; exit 1; }
if grep -nE '^[^#]*\bln\b[^#]*\.claude/projects|MEM_LINK' "$pc"; then
  echo "FAIL: post-create.sh links Claude's private auto-memory into the repo"; exit 1
fi
agents="$tmpdir/AGENTS.md"
grep -qiE 'memory[^.]*symlink|symlink[^.]*memory' "$agents" && { echo "FAIL: AGENTS.md still talks about a memory symlink"; exit 1; }
grep -q 'public' "$agents" || { echo "FAIL: AGENTS.md does not say .agents/memory/ is public"; exit 1; }
exit 0
