#!/usr/bin/env bash
# enable_release_automation defaults to false (copier.yml) — a stamp with no answer
# for it must not carry the release-please workflow/config/manifest at all. The
# "true" case is checked separately, inline in justfile's accept recipe, via a
# second stamp with --data enable_release_automation=true (this default $tmpdir
# never sets it).
set -euo pipefail
tmpdir="$1"

for path in \
  ".github/workflows/release-please.yaml" \
  "release-please-config.json" \
  ".release-please-manifest.json"; do
  test -e "$tmpdir/$path" && {
    echo "FAIL: $path exists in the default stamp — enable_release_automation should default to false"
    exit 1
  }
done
exit 0
