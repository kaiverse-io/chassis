#!/usr/bin/env bash
# pyproject.toml declares a license in metadata (Apache-2.0 by default); a project
# with license metadata and no LICENSE file is effectively unlicensed.
set -euo pipefail
tmpdir="$1"

test -f "$tmpdir/LICENSE" || {
  echo "FAIL: no LICENSE file stamped — pyproject.toml declares one in metadata with no text behind it"
  exit 1
}
