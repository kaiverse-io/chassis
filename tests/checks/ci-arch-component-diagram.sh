#!/usr/bin/env bash
# ADR-009: `just ci-arch` must fail when a top-level component has a section but no box in
# ARCHITECTURE.md's Component Diagram, and pass once it is drawn. Runs on a copy so the
# stamped project the other checks see is left untouched.
set -euo pipefail
tmpdir="$1"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp -a "$tmpdir/." "$work/"
cd "$work"

pkg=$(sed -n 's/^python_package_name: //p' .copier-answers.yml)
test -n "$pkg" || { echo "FAIL: no python_package_name in .copier-answers.yml"; exit 1; }
grep -q '^## Component Diagram' ARCHITECTURE.md || { echo "FAIL: stamped ARCHITECTURE.md has no Component Diagram section"; exit 1; }

touch "src/$pkg/billing_core.py"
printf '\n## billing_core\n\nPurpose: test fixture.\n' >> ARCHITECTURE.md

if just ci-arch >/dev/null 2>err.txt; then
  echo "FAIL: ci-arch passed although billing_core has no box in the Component Diagram"
  exit 1
fi
grep -q 'Component Diagram has no box for: billing_core' err.txt || {
  echo "FAIL: ci-arch failed for the wrong reason:"; cat err.txt; exit 1;
}

python3 - <<'PY'
import re, pathlib
p = pathlib.Path("ARCHITECTURE.md")
s = p.read_text()
s = re.sub(r"(## Component Diagram.*?```\n)", r"\1┌──────────────┐\n│ billing_core │\n└──────────────┘\n", s, count=1, flags=re.DOTALL)
p.write_text(s)
PY

just ci-arch >/dev/null 2>err.txt || {
  echo "FAIL: ci-arch still fails after billing_core was drawn:"; cat err.txt; exit 1;
}
