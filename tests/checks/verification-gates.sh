#!/usr/bin/env bash
# chassis#10 / #8: the agent's check is the CI check, and a missing check fails. Proves, on a
# copy of the stamp: `just verify` exists and runs `ci`; the workflow-vs-`ci` integrity gate
# catches a dropped step; the file-size gate catches a giant file; pre-commit uses the
# project's own uv-locked tools; and CI installs `just` from a pinned release.
set -euo pipefail
tmpdir="$1"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp -a "$tmpdir/." "$work/"
cd "$work"

just --show verify | grep -qE '^verify: ci$' || { echo "FAIL: no 'verify: ci' recipe"; exit 1; }

just _ci-gate-integrity >/dev/null 2>&1 || { echo "FAIL: gate-integrity fails on a fresh stamp"; exit 1; }
cp .github/workflows/ci.yaml ci.yaml.orig
python3 - <<'PY'
import pathlib, re
p = pathlib.Path(".github/workflows/ci.yaml")
p.write_text(re.sub(r"\n\s*- name: Docs\n\s*run: just ci-docs\n", "\n", p.read_text()))
PY
if just _ci-gate-integrity >/dev/null 2>&1; then
  echo "FAIL: gate-integrity passed with ci-docs dropped from the workflow"; exit 1
fi
mv ci.yaml.orig .github/workflows/ci.yaml

pkg=$(sed -n 's/^python_package_name: //p' .copier-answers.yml)
just _ci-file-size >/dev/null 2>&1 || { echo "FAIL: file-size gate fails on a fresh stamp"; exit 1; }
python3 -c "print('\n'.join('x = 0' for _ in range(501)))" > "src/$pkg/giant.py"
if just _ci-file-size >/dev/null 2>&1; then
  echo "FAIL: file-size gate passed a 501-line file"; exit 1
fi

if grep -qE 'repo: https://github.com/(astral-sh/ruff-pre-commit|pre-commit/mirrors-mypy|shellcheck-py/shellcheck-py)' .pre-commit-config.yaml; then
  echo "FAIL: pre-commit still uses mirror repos with their own tool versions"; exit 1
fi
grep -q 'entry: uv run mypy src/' .pre-commit-config.yaml || { echo "FAIL: mypy hook does not run the project's mypy"; exit 1; }

if grep -rq 'just.systems/install.sh' .github/workflows/; then
  echo "FAIL: CI installs just from the unpinned install script"; exit 1
fi
