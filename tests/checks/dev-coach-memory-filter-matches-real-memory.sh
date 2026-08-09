#!/usr/bin/env bash
# dev-coach's step 2 filters memory files by `metadata.type: feedback`, but chassis's
# own real memory files all use `type: project` — running dev-coach against chassis's
# own dogfooded memory matches zero files. Checks chassis's own repo (the real,
# accumulated memory), not a freshly-stamped tmpdir's near-empty seed — $1 is ignored
# on purpose; ground truth lives at chassis root.
set -euo pipefail

skill=".agents/skills/dev-coach/SKILL.md"
memory_dir=".agents/memory"

test -f "$skill" || {
  echo "FAIL: $skill not found"
  exit 1
}

real_types=$(grep -rhoE '^\s*type:\s*\w+' "$memory_dir"/*.md 2>/dev/null \
  | awk '{print $2}' | sort -u)

filtered_type=$(grep -oE 'metadata\.type:\s*\w+' "$skill" | awk -F': *' '{print $2}' | head -1 || true)

if [ -n "$filtered_type" ]; then
  echo "$real_types" | grep -qx "$filtered_type" || {
    echo "FAIL: dev-coach filters on metadata.type: $filtered_type, but real memory files use: $(echo "$real_types" | tr '\n' ' ')"
    exit 1
  }
fi
