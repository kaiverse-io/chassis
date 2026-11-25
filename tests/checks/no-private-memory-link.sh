#!/usr/bin/env bash
# Claude Code's auto-memory holds personal context. Linking it into the git-tracked
# .agents/memory/ would commit it, and publish it in a public project (chassis#20). The stamp
# must not create that link, and AGENTS.md must say .agents/memory/ is public.
set -euo pipefail
tmpdir="$1"
pc="$tmpdir/.devcontainer/post-create.sh"
test -f "$pc" || { echo "FAIL: stamp has no post-create.sh"; exit 1; }
if grep -nE '^[^#]*\bln\b[^#]*\.claude/projects' "$pc"; then
  echo "FAIL: post-create.sh links Claude's private auto-memory into the repo"; exit 1
fi
agents="$tmpdir/AGENTS.md"
grep -qiE 'memory[^.]*symlink|symlink[^.]*memory' "$agents" && { echo "FAIL: AGENTS.md still talks about a memory symlink"; exit 1; }
grep -q 'public' "$agents" || { echo "FAIL: AGENTS.md does not say .agents/memory/ is public"; exit 1; }

# A project stamped before this change still has the link; post-create must remove it (the
# symlink only), or every new auto-memory note keeps landing in git.
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
proj="$work/proj"; home="$work/home"
mkdir -p "$proj/.agents/memory" "$home"
echo keep > "$proj/.agents/memory/note.md"
link="$home/.claude/projects/${proj//\//-}/memory"
mkdir -p "$(dirname "$link")"; ln -s "$proj/.agents/memory" "$link"
sed -n '/^# legacy-memory-link:start$/,/^# legacy-memory-link:end$/p' "$pc" > "$work/block.sh"
test -s "$work/block.sh" || { echo "FAIL: post-create.sh has no legacy-memory-link block"; exit 1; }
(cd "$proj" && HOME="$home" bash "$work/block.sh") >/dev/null
test -L "$link" && { echo "FAIL: legacy memory symlink was not removed"; exit 1; }
test -f "$proj/.agents/memory/note.md" || { echo "FAIL: cleanup deleted the memory directory behind the link"; exit 1; }
# A link that points somewhere else is not ours to remove.
other="$work/other"; mkdir -p "$other"; ln -s "$other" "$link"
(cd "$proj" && HOME="$home" bash "$work/block.sh") >/dev/null
test -L "$link" || { echo "FAIL: removed a memory link that does not point at .agents/memory"; exit 1; }
exit 0
