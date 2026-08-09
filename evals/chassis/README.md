# evals/chassis/

> This is chassis testing **itself** — a different thing from `template/evals/`, which is the
> inert slot every *stamped project* gets for its own product evals. This one asks: does an
> agent working inside chassis's own repo actually use the cockpit chassis ships?

## Why this isn't a `tests/checks/*.sh` script

`tests/checks/` is deterministic: same input, same output, every time — a code fact, not a
model's choice. Whether an agent reaches for `graphify-out/GRAPH_REPORT.md` or `ctx search`
before raw-grepping is a **model's choice**, shaped but not guaranteed by the `SessionStart`
hook's reminder. This directory reports a pass rate over N trials, not a boolean, and is not
wired into `just ci` or `just accept` — an unaudited pass rate self-certifies nothing; read the
transcripts before trusting the number.

## What goes here

- `graphify-before-grep.prompt.md` — a scripted, code-exploration-shaped task chosen so an
  agent that's actually using the cockpit's reminder should reach for the graph or `ctx`
  before a raw search.
- `run.sh` — drives `claude -p "$(cat graphify-before-grep.prompt.md)" --output-format json`
  N times against a disposable scratch clone of chassis's own repo, capturing each transcript.
- `check_transcript.py` — deterministically checks each transcript's tool-call *ordering*: did
  a read of `graphify-out/GRAPH_REPORT.md` or a `ctx search` Bash call happen before the first
  raw `Grep`/`Glob`/`grep`/`find` call?

## Running it

```bash
just eval-cockpit-usage
```

Costs real API calls and takes longer than the ~2-minute `just accept` budget — that's exactly
why it's a separate recipe, never part of `gates` in CI.
