#!/usr/bin/env python3
"""Checks tool-call ordering in `claude -p --output-format stream-json` transcripts:
did graphify/ctx get consulted before the first raw grep/glob/find?

NOTE: the exact stream-json event shape should be spot-checked against one real
trial's output before trusting this — parsing here is defensive (skips anything it
doesn't recognize) rather than asserting a schema this script hasn't been run against
live. Treat a "pass rate" from this script as a starting signal, not a certified metric,
consistent with how evals/chassis/README.md already frames this eval.
"""
import json
import sys


def tool_uses(path):
    """Yield (tool_name, input_dict) for every tool_use block in a transcript, in order."""
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            message = event.get("message", event)
            content = message.get("content") if isinstance(message, dict) else None
            if not isinstance(content, list):
                continue
            for block in content:
                if isinstance(block, dict) and block.get("type") == "tool_use":
                    yield block.get("name", ""), block.get("input", {}) or {}


def used_cockpit_first(path):
    """True if a graphify/ctx signal appears before the first raw grep/glob/find call."""
    for name, inp in tool_uses(path):
        command = str(inp.get("command", ""))
        file_path = str(inp.get("file_path", "")) or str(inp.get("path", ""))

        is_cockpit = (
            "graph_report" in file_path.lower()
            or "graphify" in command.lower()
            or "ctx search" in command.lower()
        )
        is_raw_search = (
            name in ("Grep", "Glob")
            or (name == "Bash" and any(tool in command for tool in ("grep ", "find ")))
        )

        if is_cockpit:
            return True
        if is_raw_search:
            return False
    return False  # no search activity at all — doesn't count as a pass


def main(paths):
    if not paths:
        print("No transcripts to check.")
        return 1

    results = [(p, used_cockpit_first(p)) for p in paths]
    passed = sum(1 for _, ok in results if ok)
    total = len(results)

    for path, ok in results:
        print(f"{'PASS' if ok else 'FAIL'}: {path}")

    print(f"\n{passed}/{total} trials consulted graphify/ctx before raw-grepping ({100 * passed // total}%)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
