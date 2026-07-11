# chassis — task runner
# https://just.systems

default:
    @just --list

# ── Acceptance test ──────────────────────────────────────────────────────────

# Stamp a throwaway project and verify just ci is green (the chassis acceptance test)
# --trust: copier 9.x refuses to run copier.yml's _tasks (git init/uv sync/pre-commit
# install) without it. Safe here — this is our own template, not a third-party one.
# --vcs-ref=HEAD: without it, copier silently pins to the latest git *tag* on a local
# path source, not the current commit — so uncommitted or untagged work on main would
# never actually be exercised by this test. Found while verifying this recipe's own
# .copier-answers.yml guardrail below: it kept failing against stale tagged content.
accept:
    #!/usr/bin/env bash
    set -euo pipefail
    tmpdir=$(mktemp -d)
    echo "Stamping test project at $tmpdir …"
    copier copy . "$tmpdir" --vcs-ref=HEAD --defaults --trust \
        --data "project_name=TestProject" \
        --data "python_package_name=test_project" \
        --data "description=Chassis acceptance test" \
        --data "author_name=Test" \
        --data "author_email=test@example.com" \
        --data "github_owner=km2411" \
        --data "license=Proprietary" \
        --overwrite --quiet
    test -f "$tmpdir/.copier-answers.yml" || {
        echo "FAIL: .copier-answers.yml was not generated — copier update would be broken for every stamped project"
        exit 1
    }
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
    import pathlib, re, sys
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

    print("Chassis lint: checking AGENTS.md cockpit section matches template/AGENTS.md.jinja …")

    def extract(path):
        text = pathlib.Path(path).read_text()
        m = re.search(
            r"<!-- cockpit-section:start.*?-->\n(.*)<!-- cockpit-section:end -->",
            text,
            re.DOTALL,
        )
        if not m:
            return None
        return m.group(1)

    own = extract("AGENTS.md")
    template = extract("template/AGENTS.md.jinja")
    if own is None or template is None:
        print(
            "AGENTS.md and template/AGENTS.md.jinja must both have a "
            "<!-- cockpit-section:start/end --> block.",
            file=sys.stderr,
        )
        sys.exit(1)
    if own != template:
        print(
            "AGENTS.md's cockpit section has drifted from template/AGENTS.md.jinja's — "
            "these are meant to be identical (see AGENTS.md 'Hard rules'). Update whichever "
            "one is stale so both match, then rerun.",
            file=sys.stderr,
        )
        sys.exit(1)
    print("Cockpit sections match.")

# ── Helpers ──────────────────────────────────────────────────────────────────

# Install copier and dev tools
sync:
    pip install copier --quiet
