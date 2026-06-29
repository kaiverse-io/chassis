---
kind: agent-context
status: active
last_reviewed: 2026-06-29
---

# Chassis — Agent Context

> The Copier template that stamps all km2411 projects with AI-native guardrails from commit 1.
> This repo dogfoods the guide it enforces: it has its own ADRs, Diátaxis docs, and passes
> its own gates. CLAUDE.md is a symlink to this file.

## What this repo is

`km2411/chassis` is a [Copier](https://copier.readthedocs.io/) template. Running
`copier copy gh:km2411/chassis <dest>` stamps a new project with:

- Guardrails (A): AGENTS.md, ruff/mypy, import-linter boundary slot, opengrep self-weakening,
  gitleaks, conventional commits, CODEOWNERS, Diátaxis docs, pre-commit.
- Ratcheting gates (B): coverage floor (only-increase), complexity ceiling.
- On-demand tools (C): codeburn (AI cost metrics).
- Wired-but-waiting slots (D): eval gate, ADLC agent-change gate, arch-drift.

## Structure

```
copier.yml             — Copier config: variables, tasks, subdirectory pointer
template/              — Everything stamped into new projects (Jinja2 templates)
  AGENTS.md.jinja      — Canonical AI context for the stamped project
  pyproject.toml.jinja — uv + ruff + mypy + pytest + import-linter
  justfile.jinja        — The one runner (just ci, just fmt, just sync …)
  .pre-commit-config.yaml.jinja
  .importlinter.jinja  — Boundary contract slot (project fills)
  .opengrep/rules/     — self-weakening rules (generic, shipped by default)
  .github/workflows/   — CI calling just ci-*
  .claude/             — Claude Code settings + example skill
  src/ tests/ docs/    — Project skeleton
docs/                  — Chassis's own Diátaxis docs
```

## Hard rules (for working in this repo)

- **Generic only** — no project-specific rule ever ships in the chassis (except self-weakening,
  which is generic to any agent-built repo).
- **Self-dogfooding** — the chassis must pass its own gates (`just ci`).
- **Thin** — resist the urge to add features; validate via stamping, not by growing the template.
- **Contribution rule:** generic improvement → bump chassis version; project-specific rule →
  goes in the project's own slots, never upstreamed here.

## How to work here

```bash
uv sync          # install copier + dev tools
just accept      # acceptance test: stamp a throwaway project → just ci green
just ci          # lint/test the chassis itself
```

## Agent-memory convention

After significant multi-step work, save learnings to `~/.claude/projects/chassis/memory/`.

## Forbidden patterns

- `git commit --no-verify`
- Bare `# noqa` or `# type: ignore`
- Hardcoded secrets
- Adding project-specific rules to the chassis template
