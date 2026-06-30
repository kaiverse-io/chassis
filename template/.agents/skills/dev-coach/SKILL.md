# Dev Coach

> The chassis's coaching loop (ADR-016): anti-pattern detection + an AGENTS.md/skills auditor
> that writes improvements back. Invoke with `/dev-coach`.
>
> **Related prior art:** [microsoft/ai-engineering-coach](https://github.com/microsoft/ai-engineering-coach)
> (3.1k★, MIT) does this more comprehensively (45 anti-pattern rules, practice scores, skill
> mining) as a VS Code dashboard extension — but it's Copilot-focused, doesn't confirm Claude
> Code session-log support, and ships no marketplace build (build-from-source only). This skill
> is the pragmatic now-version for Claude Code specifically: zero new infra, runs via tools
> Claude Code already has. Revisit adopting/integrating the Microsoft tool later (bucket C/D
> candidate) if it gains Claude Code harness support.

## What this skill does

Reviews recent agent-assisted work in this repo, finds recurring friction (corrections the user
had to repeat, rework, low one-shot rate), and proposes specific additions to `AGENTS.md` or new
skills — then asks before writing anything. It never edits silently.

## Steps

1. **Pull the cost/outcome signal.** If `codeburn` is installed, run it (or `codeburn --json` if
   a flag like that exists) to get one-shot rate, task-type breakdown, and rework signal for this
   project. If not installed, say so and skip — don't block on it.

2. **Scan recent memory for unreflected feedback.** Read every file under
   `~/.claude/projects/<project-slug>/memory/` with `metadata.type: feedback` (check
   `MEMORY.md` for the index — `<project-slug>` is the dashed form of the repo path, e.g.
   `-workspaces-example_project`). For each one, check whether its rule already appears in `AGENTS.md`
   (the "Hard rules", "Forbidden patterns", or "How to work here" sections). Flag any feedback
   memory that exists but was never promoted into AGENTS.md — that's a correction the user may
   have to repeat to a future session that doesn't load this specific memory file.

3. **Scan recent git history for rework signal.** `git log --oneline -30`. Look for patterns:
   consecutive commits touching the same file with messages like "fix", "typo", "revert", "oops" —
   this is a proxy for low one-shot rate when transcript data isn't available.

4. **Cross-reference against current guardrails.** For each anti-pattern found in steps 2–3,
   check whether an existing opengrep rule, import-linter contract, or AGENTS.md rule already
   covers it. Only propose *new* rules for gaps, not duplicates.

5. **Report, then ask.** Present a short list: what was found, the evidence (memory file name /
   commit hash), and the proposed AGENTS.md or skill addition as exact text. Ask the user to
   confirm before editing anything. If they confirm, write the change and tell them what changed.

## When to use

- Periodically (e.g. weekly, or after a noticeably frustrating session) to close the loop between
  "the user corrected something" and "the rule is now durable in AGENTS.md."
- Right after a session where the user repeated a correction they'd already given before — that's
  the strongest signal this skill exists to catch.

## When NOT to use

- Mid-task, as a distraction from the actual work.
- As a substitute for the real eval harness (`evals/`) — this is about dev-process friction, not
  product-quality scoring.
