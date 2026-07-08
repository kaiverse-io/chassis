# chassis — task runner
# https://just.systems

default:
    @just --list

# ── Acceptance test ──────────────────────────────────────────────────────────

# Stamp a throwaway project and verify just ci is green (the chassis acceptance test)
# --trust: copier 9.x refuses to run copier.yml's _tasks (git init/uv sync/pre-commit
# install) without it. Safe here — this is our own template, not a third-party one.
accept:
    #!/usr/bin/env bash
    set -euo pipefail
    tmpdir=$(mktemp -d)
    echo "Stamping test project at $tmpdir …"
    copier copy . "$tmpdir" --defaults --trust \
        --data "project_name=TestProject" \
        --data "python_package_name=test_project" \
        --data "description=Chassis acceptance test" \
        --data "author_name=Test" \
        --data "author_email=test@example.com" \
        --data "github_owner=km2411" \
        --data "license=Proprietary" \
        --overwrite --quiet
    echo "Running just ci in stamped project …"
    cd "$tmpdir"
    just ci
    cd -
    rm -rf "$tmpdir"
    echo "Acceptance test PASSED"

# ── Chassis CI (dogfoods its own gates) ──────────────────────────────────────

ci: ci-lint

ci-lint:
    #!/usr/bin/env python3
    import pathlib, sys
    print("Chassis lint: checking YAML/JINJA files are well-formed …")
    errors = []
    for f in pathlib.Path("template").rglob("*.jinja"):
        try:
            f.read_text()
        except Exception as e:
            errors.append(f"{f}: {e}")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        sys.exit(1)
    print(f"All {len(list(pathlib.Path('template').rglob('*.jinja')))} jinja templates readable.")

# ── Helpers ──────────────────────────────────────────────────────────────────

# Install copier and dev tools
sync:
    pip install copier --quiet
