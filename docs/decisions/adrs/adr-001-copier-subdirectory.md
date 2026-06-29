---
kind: adr
status: accepted
owner: platform
last_reviewed: 2026-06-29
---

# ADR-001 — Use `_subdirectory: template` to separate chassis meta from template content

- **Status:** Accepted (2026-06-29)
- **Deciders:** founder

## Context

A Copier template repo needs to contain both: (a) the template content that gets stamped into
projects, and (b) the chassis's own meta files (README, AGENTS.md, CHANGELOG, justfile, docs).
Without separation, meta files would be stamped into every new project.

## Decision

Use Copier's `_subdirectory: template` setting. All template content lives in `template/`;
the chassis's own meta files live at the root. `copier copy` only processes `template/`.

## Consequences

**Good:** clean separation; chassis docs don't pollute stamped projects; the chassis can
dogfood its own AGENTS.md without it being a template.

**Bad:** contributors must remember that template changes go in `template/`, not root.
