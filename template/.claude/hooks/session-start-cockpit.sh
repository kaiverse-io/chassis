#!/usr/bin/env bash
# SessionStart hook — refreshes the AI-usage cockpit and tells the agent what is available.
# Whatever this script prints to stdout is added directly to the agent's context at
# session start (before the first prompt) — see chassis's docs/explanation/
# ai-usage-cockpit.md and design.md ("Coaching" / "Context Engineering" layers).
#
# Everything printed is true on the machine it runs on: a tool is mentioned only if it is
# installed, and the graphify report only if it exists. Outside the devcontainer most of
# these tools are absent, and a line about a missing file would be an instruction to read
# something that is not there.
#
# Best-effort only: SessionStart hooks cannot block the session, so every step here
# is guarded to fail silently rather than surface a startup error for a bucket-C
# (on-demand, never-blocking) tool that may not even be installed in this project.
set -uo pipefail

# Resolve paths from the project root, whatever directory the harness starts the hook in.
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || true; fi

report="graphify-out/GRAPH_REPORT.md"
refreshed=0
if command -v graphify >/dev/null 2>&1; then
  graphify update . >/dev/null 2>&1 && refreshed=1
fi

have_ctx=0
if command -v ctx >/dev/null 2>&1; then
  have_ctx=1
  ctx setup >/dev/null 2>&1 || true
fi

lines=""
if [ -f "$report" ]; then
  if [ "$refreshed" = 1 ]; then
    lines+="- graphify: $report was just refreshed — check its God Nodes /
  communities before exploring unfamiliar code, instead of re-grepping from scratch.
"
  else
    lines+="- graphify: $report exists but was not refreshed this session, so it may be
  stale — treat its God Nodes / communities as a starting point, not as current fact.
"
  fi
fi
# shellcheck disable=SC2016  # the backticks are literal text for the agent
if [ "$have_ctx" = 1 ]; then
  lines+='- ctx: run `ctx search "<topic>"` before starting non-trivial work — it searches full
  past session transcripts, not just memory files, for prior decisions or corrections.
'
fi
if [ -f .agents/skills/dev-coach/SKILL.md ]; then
  lines+='- /dev-coach: run periodically, or right after a corrected mistake, to turn friction
  into a durable AGENTS.md rule instead of relearning it next session.
'
fi

if [ -n "$lines" ]; then
  printf 'AI-usage cockpit for this project (detail in\ndocs/explanation/harness-and-cockpit.md):\n%s' "$lines"
fi

exit 0
