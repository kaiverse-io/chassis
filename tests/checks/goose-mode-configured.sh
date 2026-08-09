#!/usr/bin/env bash
# goose has no project-level permission config file at all (confirmed against
# block/goose's own docs) — GOOSE_MODE via devcontainer.json's containerEnv is the
# only lever chassis can pin. Must land specifically in containerEnv, not remoteEnv:
# remoteEnv is scoped to VS-Code-Server's own sub-processes and may not reach a
# `goose` a developer launches by hand in a plain terminal — so this check anchors
# on the containerEnv block specifically, not just "GOOSE_MODE appears somewhere".
set -euo pipefail
tmpdir="$1"

devcontainer="$tmpdir/.devcontainer/devcontainer.json"
test -f "$devcontainer" || {
  echo "FAIL: no .devcontainer/devcontainer.json in stamped output"
  exit 1
}

block=$(awk '/"containerEnv": {/,/^  },?$/' "$devcontainer")
echo "$block" | grep -qE '"GOOSE_MODE": "smart_approve"' || {
  echo "FAIL: devcontainer.json's containerEnv does not pin GOOSE_MODE=smart_approve"
  exit 1
}
