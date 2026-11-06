---
kind: adr
status: accepted
owner: founder
last_reviewed: 2026-11-06
---

# ADR-009 — A required Component Diagram, with views named after C4 and arc42

- **Status:** Accepted (2026-11-06)
- **Deciders:** founder

## Context

`template/ARCHITECTURE.md.jinja` offered one diagram slot — the System Overview, a runtime
data-flow picture — plus an optional per-component diagram "if its internal flow isn't obvious".
`just ci-arch` checked that every top-level component had a `##` section and nothing else.

In practice stamped projects end up with exactly one diagram. A stamped project with thirteen
components had a System Overview and no other diagram at all: nothing showed which component
depends on which, so a reader could not see the structure without reading every import, and an
architectural change (a new dependency direction) left no visible trace in the doc.

The industry already names these views. The [C4 model](https://c4model.com/) defines Context,
Container, Component and Code levels and is explicitly notation-independent.
[arc42](https://arc42.org/overview) separates the Building Block View (static structure) from
the Runtime View (behaviour) and the Deployment View.

## Decision drivers

- Don't invent a taxonomy where C4 and arc42 already provide one.
- Keep the existing plain-text, same-PR diagram rule: no render step, no Mermaid.
- A gate must be mechanical; judgement stays in `/arch-review`.
- Thin: no new document, no new tool dependency.

## Considered options

1. **Adopt Structurizr DSL / PlantUML C4 diagrams-as-code.** Rejected for the template: adds a
   renderer and a second source of truth, contrary to the "redraw in the same PR" rule. C4
   being notation-independent means plain text loses nothing essential.
2. **Generate the dependency diagram from imports (pydeps, grimp).** Rejected as the diagram
   itself — a generated graph shows every edge, not the ones that matter, and nobody reviews it.
   Kept as the *check*: `/arch-review` derives the real edges with grimp (already installed
   via import-linter) and compares them with what is drawn.
3. **A hand-drawn Component Diagram section, required by `ci-arch`, views mapped to C4/arc42.**
   *Chosen.*

## Decision

- `ARCHITECTURE.md` gains `## Component Diagram`: one box per top-level component, an arrow
  wherever one imports another (C4 Component level, arc42 §5 level 1). It should agree with
  `.importlinter`.
- The header maps each section to its C4 level and arc42 view, and states the C4 diagram rules
  that apply to plain text: a title, one notation, labels on any non-obvious arrow.
- System Overview stays the runtime view (C4 Context + Container, arc42 §3/§6); a deployment
  boundary goes in it when it matters, rather than a separate section.
- `just ci-arch` additionally fails when the Component Diagram section is missing or a
  top-level component is not named inside its fenced block. It does not parse arrows.
- `/arch-review` compares drawn arrows with grimp's real import edges, both directions, and
  flags non-obvious components with no internal diagram.

## Consequences

**Good:** every stamped project shows its static structure, and a component cannot be added
without being drawn. The vocabulary is one a new contributor may already know.

**Bad:** existing projects fail `just ci-arch` after `copier update` until they add the
section — a one-time edit, called out in the release notes. Arrow accuracy is still only as
good as the last `/arch-review` run.
