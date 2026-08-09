#!/usr/bin/env bash
# uv and just used to install via an unpinned `curl .../install.sh | sh` — no version
# pin, no checksum — unlike gitleaks/opengrep/codeburn/abtop (version-pinned) and ctx
# (pinned + SHA256SUMS verified) in the same file. Chassis's own root CI explicitly
# avoids this exact pattern for `just`, with a comment explaining why.
set -euo pipefail
tmpdir="$1"

post_create="$tmpdir/.devcontainer/post-create.sh"
test -f "$post_create" || {
  echo "FAIL: no .devcontainer/post-create.sh in stamped output"
  exit 1
}

for tool in uv just; do
  # Grab the install block for this tool and confirm it's pinned to a version
  # (not `install.sh` piped straight to a shell) and checksum-verified.
  block=$(awk "/Installing $tool /,/^fi\$/" "$post_create")

  if echo "$block" | grep -qE '\| *sh\b|\| *bash\b'; then
    echo "$block" | grep -qE '_VERSION=' || {
      echo "FAIL: $tool install is still piped to a shell with no version pin"
      exit 1
    }
    echo "$block" | grep -qiE 'sha256|checksum' || {
      echo "FAIL: $tool install is pinned but has no checksum verification"
      exit 1
    }
  fi
done
