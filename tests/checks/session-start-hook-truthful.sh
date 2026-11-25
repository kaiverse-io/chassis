#!/usr/bin/env bash
# The session-start hook's stdout goes straight into the agent's context as fact (chassis#20).
# It must mention a tool only when that tool is installed, and the graphify report only when it
# exists. Outside the devcontainer neither is usually true.
set -euo pipefail
tmpdir="$1"
hook="$tmpdir/.claude/hooks/session-start-cockpit.sh"
test -f "$hook" || { echo "FAIL: stamp has no session-start hook"; exit 1; }
bash_bin=$(command -v bash)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
none="$work/none"; mkdir -p "$none"            # a PATH with no tools at all
both="$work/both"; mkdir -p "$both"
printf '#!/bin/sh\nexit 0\n' > "$both/graphify"; cp "$both/graphify" "$both/ctx"
broken="$work/broken"; mkdir -p "$broken"
printf '#!/bin/sh\nexit 1\n' > "$broken/graphify"
chmod +x "$both"/* "$broken"/*

proj() { # <name> [report] [skill]  -> prints the project dir
  local d="$work/$1"; mkdir -p "$d"
  [ "${2:-}" = report ] && { mkdir -p "$d/graphify-out"; echo "# report" > "$d/graphify-out/GRAPH_REPORT.md"; }
  [ "${3:-}" = skill ] && { mkdir -p "$d/.agents/skills/dev-coach"; echo x > "$d/.agents/skills/dev-coach/SKILL.md"; }
  echo "$d"
}
run() { (cd "$1" && env -i HOME="$work" PATH="$2" "$bash_bin" "$hook"); }
must()    { grep -q -- "$2" <<<"$1" || { echo "FAIL: $3"; echo "--- output ---"; echo "$1"; exit 1; }; }
mustnot() { grep -q -- "$2" <<<"$1" && { echo "FAIL: $3"; echo "--- output ---"; echo "$1"; exit 1; }; return 0; }

# Nothing installed, no report: only the skill line may appear.
out=$(run "$(proj a no skill)" "$none")
mustnot "$out" 'GRAPH_REPORT' "mentions the graphify report with no graphify and no report"
mustnot "$out" 'ctx search' "mentions ctx with ctx not installed"
must "$out" '/dev-coach' "omits /dev-coach although the skill is present"

# Nothing installed and no skill: nothing to say.
out=$(run "$(proj b no no)" "$none")
test -z "$out" || { echo "FAIL: printed output with nothing to report"; echo "$out"; exit 1; }

# Both tools installed, report present: both lines, graphify refreshed.
out=$(run "$(proj c report skill)" "$both")
must "$out" 'was just refreshed' "does not say graphify refreshed when it did"
must "$out" 'ctx search' "omits ctx although it is installed"

# graphify installed but its refresh fails: must not claim it was refreshed.
out=$(run "$(proj d report skill)" "$broken")
mustnot "$out" 'just refreshed' "claims a refresh that failed"
must "$out" 'not refreshed' "does not say the report may be stale"

# A report exists but graphify is not installed: not refreshed.
out=$(run "$(proj e report skill)" "$none")
mustnot "$out" 'just refreshed' "claims a refresh with graphify not installed"
exit 0
