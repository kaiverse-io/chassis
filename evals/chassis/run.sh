#!/usr/bin/env bash
# Drives the graphify/ctx-before-raw-grep eval N times against a disposable clone of
# chassis's own repo, and reports a pass rate. Never wired into just ci/accept — costs
# real API calls, takes minutes, and the outcome is a model's choice, not a code fact.
set -euo pipefail

N="${1:-5}"
repo_root=$(git rev-parse --show-toplevel)
eval_dir="$repo_root/evals/chassis"
prompt=$(cat "$eval_dir/graphify-before-grep.prompt.md")

results_dir=$(mktemp -d)
echo "Running $N trial(s), results in $results_dir …"

for i in $(seq 1 "$N"); do
  scratch=$(mktemp -d)
  git clone --quiet "$repo_root" "$scratch"
  if command -v graphify >/dev/null 2>&1; then
    (cd "$scratch" && graphify update . >/dev/null 2>&1 || true)
  fi
  (
    cd "$scratch"
    # stream-json, not json: we need the individual tool-call events to check
    # ordering, not just the final result.
    claude -p "$prompt" --output-format stream-json --verbose \
      > "$results_dir/trial-$i.jsonl" 2>"$results_dir/trial-$i.stderr" || true
  )
  rm -rf "$scratch"
done

python3 "$eval_dir/check_transcript.py" "$results_dir"/trial-*.jsonl
