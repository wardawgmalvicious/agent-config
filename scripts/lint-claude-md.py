#!/usr/bin/env python3
"""Cap both CLAUDE.md files, the two that load at startup, by length.

code.claude.com/docs/en/memory: "target under 200 lines per CLAUDE.md
file. Longer files consume more context and reduce adherence."

- claude/CLAUDE.md deploys to ~/.claude/CLAUDE.md, which loads into every
  session on this machine. It was 2.7 KB on 2026-08-28, 56890ad trimmed it
  to 13.9 KB on 2026-09-08, and it passed 16 KB the next day. By 2026-09-23
  it was 666 lines, because /learn routed every environment learning there
  at full length, evidence included.
- Root CLAUDE.md is project scope and never deployed, but loads into every
  session in this repo, and again after /compact. It grew from 8.3 KB on
  2026-08-28 to 1,215 lines by 2026-09-23, over 104 commits.

No per-edit review notices that kind of growth, so this check fails the
commit that crosses the line instead.

THE TWO FIXES THAT DO NOT WORK, and why the message below rules them out.
The same docs page says rules without `paths:` "are loaded
unconditionally", and that splitting into @imports "doesn't reduce
context, since imported files load at launch". Either would silence this
check without thinning anything. What does reduce what loads: moving
evidence to the file's ledger, moving file-triggered guidance to a
`paths:`-scoped rule, moving task guidance to a skill, or deleting. Each
file's message names its own ledger and rules directory, in TARGETS.

MAX_LINES lives here and nowhere else. Prose elsewhere says "the cap"
without the number, so the two cannot drift apart.

Usage: lint-claude-md.py [path]
With no argument, both files are checked. A path lints one other file,
which is how a failing arm is proved against a scratch copy without
touching the real one. A file whose parent directory is named `claude`
gets claude/CLAUDE.md's message and any other gets root's, so a scratch
copy proves the user-scope arm from inside a directory named claude/.

Exits 0 when every file is under the cap, 1 when any is over it -- and 1,
rather than a silent 0, if a file is missing, since a check that measured
nothing must not pass.
Output: one line per failure: <path>:<rule>: <message>
"""
from __future__ import annotations

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

MAX_LINES = 200

# name: (path as shown, file, its evidence ledger, its rules directory)
TARGETS = {
    "user": ("claude/CLAUDE.md", REPO_ROOT / "claude" / "CLAUDE.md",
             "docs/evidence/user-claude-md.md", "claude/rules/"),
    "root": ("CLAUDE.md", REPO_ROOT / "CLAUDE.md",
             "docs/evidence/root-claude-md.md", ".claude/rules/"),
}

WHERE_TO = (
    "Make room rather than raising the cap: move evidence (how it was "
    "measured, what was believed before, issue numbers) to {ledger} under "
    "the same heading; move guidance a file type triggers to a paths:-scoped "
    "rule in {rules}; move guidance for one task to a skill; or delete. An "
    "@import or an unscoped rule still loads at launch, so neither helps."
)


def check(shown: str, path: Path, ledger: str, rules: str, is_default: bool) -> bool:
    if not path.is_file():
        hint = (
            " REPO_ROOT is derived from this script's own location, so the usual "
            "cause is lint-claude-md.py having moved without its .parent count "
            "following."
            if is_default
            else ""
        )
        print(f"{shown}:missing-file: nothing to measure at {path}.{hint}")
        return False

    # splitlines() counts a final line with no newline, which wc -l does not.
    lines = len(path.read_text(encoding="utf-8").splitlines())
    if lines > MAX_LINES:
        where_to = WHERE_TO.format(ledger=ledger, rules=rules)
        print(f"{shown}:too-long: {lines} lines, over the cap of {MAX_LINES}. {where_to}")
        return False

    print(f"ok: {shown} is {lines} lines, cap {MAX_LINES}.", file=sys.stderr)
    return True


def main(argv: list[str]) -> int:
    if len(argv) > 1:
        path = Path(argv[1])
        name = "user" if path.resolve().parent.name.lower() == "claude" else "root"
        _, _, ledger, rules = TARGETS[name]
        return 0 if check(path.as_posix(), path, ledger, rules, is_default=False) else 1

    passed = [check(*target, is_default=True) for target in TARGETS.values()]
    return 0 if all(passed) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
