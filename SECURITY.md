# Security Policy

## Supported versions

chassis is a Copier template consumed by tag. Only the **latest released tag** is supported —
fixes ship forward as a new tag, and consumers pick them up with `copier update`. There are no
backported patch branches for older `0.x` tags.

## Reporting a vulnerability

Please report suspected vulnerabilities **privately**, not in a public issue or pull request.

- Preferred: open a [GitHub private security advisory](https://github.com/kaiverse-io/chassis/security/advisories/new)
  ("Report a vulnerability").
- Alternatively, email the maintainer at the address on the git commit history.

Include enough to reproduce: the chassis version/tag, what a stamped project ends up doing, and
the impact. We'll acknowledge receipt, work with you on a fix and a coordinated disclosure, and
credit you unless you'd rather stay anonymous.

## Scope

chassis provisions a devcontainer and installs a toolchain that runs unattended in a contributor's
container, so the security-relevant surface is mostly *what the template causes to run and what it
lets an agent do*:

- **The devcontainer toolchain** (`template/.devcontainer/post-create.sh`) — third-party tools
  installed on setup. These are version-pinned deliberately; an unpinned or unverified install
  landing here is in scope.
- **Agent guardrails and permissions** — the `permissions.allow` set, the pre-commit and CI
  gates, and the settings-isolation mount ([ADR-003](docs/decisions/adrs/adr-003-settings-json-isolation.md)).
  A way for a stamped project's container to reach the host or a sibling project's config is in
  scope.
- **The read-path rule** ([ADR-004](docs/decisions/adrs/adr-004-no-silent-rewriters.md)) — a
  cockpit tool that silently transforms what the agent perceives is treated as a defect, not a
  feature.

A vulnerability in an upstream tool the template installs should be reported to that tool's own
project; tell us too if the chassis default (pin, install method, or permission grant) makes the
exposure worse than it would be otherwise.
