#!/usr/bin/env python3
"""Cap claude/CLAUDE.md, the user-scope file every session loads, by length.

code.claude.com/docs/en/memory: "target under 200 lines per CLAUDE.md
file. Longer files consume more context and reduce adherence."

claude/CLAUDE.md deploys to ~/.claude/CLAUDE.md, which loads into every
session on this machine. It was 2.7 KB on 2026-08-28, 56890ad trimmed it
to 13.9 KB on 2026-09-08, and it passed 16 KB the next day. By 2026-09-23
it was 666 lines, because /learn routed every environment learning there
at full length, evidence included. No per-edit review notices that kind of
growth, so this check fails the commit that crosses the line instead.

THE TWO FIXES THAT DO NOT WORK, and why the message below rules them out.
The same docs page says rules without `paths:` "are loaded
unconditionally", and that splitting into @imports "doesn't reduce
context, since imported files load at launch". Either would silence this
check without thinning anything. What does reduce what loads: moving
evidence to docs/evidence/user-claude-md.md, moving file-triggered
guidance to a `paths:`-scoped rule, moving task guidance to a skill, or
deleting.

MAX_LINES lives here and nowhere else. Prose elsewhere says "the cap"
without the number, so the two cannot drift apart.

Usage: lint-claude-md.py [path]
The optional path lints another file, which is how the failing arm is
proved against a scratch copy without touching the real one.

Exits 0 under the cap, 1 over it -- and 1, rather than a silent 0, if the
file is missing, since a check that measured nothing must not pass.
Output: one line per failure: <path>:<rule>: <message>
"""
from __future__ import annotations

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT = REPO_ROOT / "claude" / "CLAUDE.md"

MAX_LINES = 200

WHERE_TO = (
    "Make room rather than raising the cap: move evidence (how it was "
    "measured, what was believed before, issue numbers) to "
    "docs/evidence/user-claude-md.md under the same heading; move guidance "
    "a file type triggers to a paths:-scoped rule in claude/rules/; move "
    "guidance for one task to a skill; or delete. An @import or an "
    "unscoped rule still loads at launch, so neither helps."
)


def main(argv: list[str]) -> int:
    path = Path(argv[1]) if len(argv) > 1 else DEFAULT
    shown = path.as_posix() if len(argv) > 1 else "claude/CLAUDE.md"

    if not path.is_file():
        hint = (
            " REPO_ROOT is derived from this script's own location, so the usual "
            "cause is lint-claude-md.py having moved without its .parent count "
            "following."
            if len(argv) <= 1
            else ""
        )
        print(f"{shown}:missing-file: nothing to measure at {path}.{hint}")
        return 1

    # splitlines() counts a final line with no newline, which wc -l does not.
    lines = len(path.read_text(encoding="utf-8").splitlines())
    if lines > MAX_LINES:
        print(f"{shown}:too-long: {lines} lines, over the cap of {MAX_LINES}. {WHERE_TO}")
        return 1

    print(f"ok: {shown} is {lines} lines, cap {MAX_LINES}.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
