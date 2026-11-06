#!/usr/bin/env bash
# import-linter >= 2.16 exits 1 when .importlinter defines no contracts, which turned every
# fresh stamp's `just ci` red. The template now runs lint-imports only once a contract exists.
# Prove both halves: the empty slot passes, and a real contract is still enforced (a broken
# one must fail) — the guard must not become a way to skip the gate.
set -euo pipefail
tmpdir="$1"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp -a "$tmpdir/." "$work/"
cd "$work"

line=$(grep -m1 "importlinter:contract:' .importlinter" justfile | sed 's/^[[:space:]]*@//')
test -n "$line" || { echo "FAIL: ci-lint has no guarded lint-imports line"; exit 1; }

bash -c "$line" >/dev/null 2>&1 || { echo "FAIL: empty .importlinter slot fails ci-lint's import check"; exit 1; }

pkg=$(sed -n 's/^python_package_name: //p' .copier-answers.yml)
mkdir -p "src/$pkg/core" "src/$pkg/web"
touch "src/$pkg/core/__init__.py" "src/$pkg/web/__init__.py"
echo "import $pkg.web" > "src/$pkg/core/uses_web.py"
cat >> .importlinter <<CONTRACT

[importlinter:contract:core-independent-of-web]
name = core must not import web
type = forbidden
source_modules =
    $pkg.core
forbidden_modules =
    $pkg.web
CONTRACT

if bash -c "$line" >/dev/null 2>&1; then
  echo "FAIL: a violated import contract passed — lint-imports did not run"
  exit 1
fi
