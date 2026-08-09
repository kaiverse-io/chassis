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
        --data "github_owner=kaiverse-io" \
        --data "license=Proprietary" \
        --overwrite --quiet
    test -f "$tmpdir/.copier-answers.yml" || {
        echo "FAIL: .copier-answers.yml was not generated — copier update would be broken for every stamped project"
        exit 1
    }
    echo "Running tests/checks/ against the stamped project …"
    failed=()
    for check in tests/checks/*.sh; do
        if ! bash "$check" "$tmpdir"; then
            failed+=("$check")
        fi
    done
    if [ "${#failed[@]}" -gt 0 ]; then
        echo "FAILED CHECKS (${#failed[@]}):"
        printf '  - %s\n' "${failed[@]}"
        exit 1
    fi
    echo "All tests/checks/ passed."
    # Default coverage floor must stamp as 0 in BOTH enforcement sites (keep in sync).
    grep -q -- '--cov-fail-under=0' "$tmpdir/pyproject.toml" || {
        echo "FAIL: default stamp missing --cov-fail-under=0 in pytest addopts"
        exit 1
    }
    grep -qE '^fail_under = 0$' "$tmpdir/pyproject.toml" || {
        echo "FAIL: default stamp missing fail_under = 0 in [tool.coverage.report]"
        exit 1
    }
    grep -q 'coverage_fail_under: 0' "$tmpdir/.copier-answers.yml" || {
        echo "FAIL: .copier-answers.yml missing coverage_fail_under: 0"
        exit 1
    }
    # Parameterization: a non-default floor must render into both sites (no full ci —
    # a high floor would fail the smoke test; we only check the stamp).
    tmpdir_floor=$(mktemp -d)
    copier copy . "$tmpdir_floor" --vcs-ref=HEAD --defaults --trust \
        --data "project_name=FloorProject" \
        --data "python_package_name=floor_project" \
        --data "description=Coverage floor stamp check" \
        --data "author_name=Test" \
        --data "author_email=test@example.com" \
        --data "github_owner=kaiverse-io" \
        --data "license=Proprietary" \
        --data "coverage_fail_under=42" \
        --overwrite --quiet
    grep -q -- '--cov-fail-under=42' "$tmpdir_floor/pyproject.toml" || {
        echo "FAIL: coverage_fail_under=42 did not render into --cov-fail-under"
        exit 1
    }
    grep -qE '^fail_under = 42$' "$tmpdir_floor/pyproject.toml" || {
        echo "FAIL: coverage_fail_under=42 did not render into fail_under"
        exit 1
    }
    rm -rf "$tmpdir_floor"
    echo "Running just ci in stamped project …"
    cd "$tmpdir"
    just ci
    cd -
    rm -rf "$tmpdir"
    echo "Acceptance test PASSED"

# ── Chassis CI (dogfoods its own gates) ──────────────────────────────────────

ci: ci-lint ci-secrets

ci-secrets:
    gitleaks detect --source . --verbose
    opengrep scan --config template/.opengrep/rules/ . --error --severity ERROR

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

# ── Evals (chassis testing itself — bucket C, not a gate) ────────────────────

# Does an agent actually consult graphify/ctx before raw-grepping? Costs real API
# calls; never part of `ci`/`accept`. See evals/chassis/README.md.
eval-cockpit-usage n="5":
    bash evals/chassis/run.sh {{n}}

# ── Helpers ──────────────────────────────────────────────────────────────────

# Install copier and dev tools
sync:
    pip install copier --quiet
