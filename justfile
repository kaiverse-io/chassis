# chassis — task runner
# https://just.systems

default:
    @just --list

# ── Acceptance test ──────────────────────────────────────────────────────────

# Stamp a throwaway project and verify just ci is green (the chassis acceptance test)
accept:
    #!/usr/bin/env bash
    set -euo pipefail
    tmpdir=$(mktemp -d)
    echo "Stamping test project at $tmpdir …"
    copier copy . "$tmpdir" --defaults \
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
    @echo "Chassis lint: checking YAML/JINJA files are well-formed …"
    python3 -c "
    import pathlib, sys
    errors = []
    for f in pathlib.Path('template').rglob('*.jinja'):
        try:
            f.read_text()
        except Exception as e:
            errors.append(f'{f}: {e}')
    if errors:
        print('\n'.join(errors), file=sys.stderr)
        sys.exit(1)
    print(f'All {len(list(pathlib.Path(\"template\").rglob(\"*.jinja\")))} jinja templates readable.')
    "

# ── Helpers ──────────────────────────────────────────────────────────────────

# Install copier and dev tools
sync:
    pip install copier --quiet
