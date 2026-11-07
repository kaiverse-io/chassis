#!/usr/bin/env bash
# cloudflare/security-audit-skill (ADR-012) is opt-in: include_security_audit defaults to false,
# so the default stamp carries none of it. With include_security_audit=true it ships verbatim at
# the pinned commit: every file must match the sha256 manifest in UPSTREAM.md, so a local edit
# (or a partial re-vendor) fails here instead of drifting silently.
set -euo pipefail
tmpdir="$1"

test -e "$tmpdir/.agents/skills/security-audit" && { echo "FAIL: security-audit skill in the default stamp — include_security_audit should default to false"; exit 1; }

on=$(mktemp -d)
trap 'rm -rf "$on"' EXIT
copier copy . "$on" --vcs-ref=HEAD --defaults --trust \
  --data "project_name=SecProject" --data "python_package_name=sec_project" \
  --data "description=security-audit opt-in check" --data "author_name=Test" \
  --data "author_email=test@example.com" --data "github_owner=kaiverse-io" \
  --data "license=Proprietary" --data "include_security_audit=true" \
  --overwrite --quiet >/dev/null 2>&1 || { echo "FAIL: stamping with include_security_audit=true failed"; exit 1; }

dir="$on/.agents/skills/security-audit"
test -f "$dir/SKILL.md" || { echo "FAIL: include_security_audit=true did not stamp $dir/SKILL.md"; exit 1; }
grep -q '^name: security-audit$' "$dir/SKILL.md" || { echo "FAIL: SKILL.md has no 'name: security-audit' frontmatter"; exit 1; }
grep -q 'Copyright (c) 2025-2026 Cloudflare, Inc.' "$dir/LICENSE" || { echo "FAIL: upstream MIT LICENSE missing"; exit 1; }
test -f "$on/.claude/skills/security-audit/SKILL.md" || { echo "FAIL: security-audit not reachable via .claude/skills"; exit 1; }

manifest=$(sed -n '/^## Manifest/,$p' "$dir/UPSTREAM.md" | grep -E '^[0-9a-f]{64}  ')
test -n "$manifest" || { echo "FAIL: UPSTREAM.md has no sha256 manifest"; exit 1; }
(cd "$dir" && echo "$manifest" | sha256sum --check --quiet) || { echo "FAIL: vendored security-audit files differ from UPSTREAM.md's manifest"; exit 1; }
listed=$(echo "$manifest" | awk '{print $2}' | sort)
present=$(cd "$dir" && ls | grep -v '^UPSTREAM.md$' | sort)
[ "$listed" = "$present" ] || { echo "FAIL: files in security-audit/ do not match the manifest list"; exit 1; }
exit 0
