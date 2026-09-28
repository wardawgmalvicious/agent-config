#!/usr/bin/env python3
"""Cap every CLAUDE.md here by length, and fail one placed where it harms.

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

NESTED FILES have been allowed since 2026-09-27, when a ban on them became
this check. One loads on a session's own first Read beneath it, never at
launch, into a session already at work: it holds what a session must know
before working in that directory, under NESTED_MAX_LINES, and the
directory's README keeps the reasoning. It fails where it would do harm,
in NO_NESTED and in a skill's own directory. An AGENTS.md fails anywhere:
under the default settings a root CLAUDE.md keeps Claude from reading any
AGENTS.md in the repo, so here one could only be the parallel file for
another tool that root CLAUDE.md forbids. Both names match without case,
as Windows paths do. The files come from git, tracked or untracked but
never ignored, which keeps the worktrees under .claude/worktrees/ out.

MAX_LINES and NESTED_MAX_LINES live here and nowhere else. Prose elsewhere
says "the cap" without the number, so the two cannot drift apart.

Usage: lint-claude-md.py [path]
With no argument, every file is checked. A path lints one other file
against MAX_LINES, which is how a failing arm is proved against a scratch
copy without touching the real one. A file whose parent directory is named
`claude` gets claude/CLAUDE.md's message and any other gets root's, so a
scratch copy proves the user-scope arm from inside a directory named
claude/. The nested arms are proved in a scratch clone instead, since a
copy of this script there takes the clone as REPO_ROOT.

Exits 0 when every file passes, 1 when any fails -- and 1, rather than a
silent 0, if a file is missing or git cannot list the tree, since a check
that measured nothing must not pass.
Output: one line per failure: <path>:<rule>: <message>
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

MAX_LINES = 200
NESTED_MAX_LINES = 60

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

INSTRUCTION_NAMES = {"claude.md", "agents.md"}

# Where a nested CLAUDE.md does harm: a lowercased path prefix, and why.
# claude/CLAUDE.md is the payload, one of the TARGETS, so never checked here.
NO_NESTED = {
    ".claude/": (
        "Claude Code reads .claude/ as config: .claude/CLAUDE.md loads at "
        "launch beside root, and every .md under .claude/rules/ is a rule"
    ),
    "claude/": (
        "claude/ copies to ~/.claude/, where a CLAUDE.md under rules/ is a "
        "rule with no paths:, loaded at launch in every session on the machine"
    ),
    "tests/": (
        "a fixture needs a clean context, and any Read beneath this file "
        "would load it"
    ),
}
IN_A_SKILL = (
    "a skill's directory is junctioned into ~/.claude/skills/ and copied "
    "into client repos by copy-copilot.ps1, so this would ship with it"
)
MISPLACED_WHERE_TO = (
    "Put guidance a file triggers in a paths:-scoped rule, guidance for one "
    "task in a skill, and the rest in a README."
)
NESTED_WHERE_TO = (
    "Keep only what a session must know before working in this directory, "
    "and move the rest, evidence included, to its README."
)


def count_lines(path: Path) -> int:
    # splitlines() counts a final line with no newline, which wc -l does not.
    return len(path.read_text(encoding="utf-8").splitlines())


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

    lines = count_lines(path)
    if lines > MAX_LINES:
        where_to = WHERE_TO.format(ledger=ledger, rules=rules)
        print(f"{shown}:too-long: {lines} lines, over the cap of {MAX_LINES}. {where_to}")
        return False

    print(f"ok: {shown} is {lines} lines, cap {MAX_LINES}.", file=sys.stderr)
    return True


def listed_files() -> list[str] | None:
    """Every path git would commit: tracked, or untracked and not ignored."""
    try:
        out = subprocess.run(
            ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
            cwd=REPO_ROOT, capture_output=True, check=True,
        ).stdout
    except (OSError, subprocess.CalledProcessError):
        return None
    return sorted({rel for rel in out.decode("utf-8").split("\0") if rel})


def harm(rel: str) -> str | None:
    """Why a nested CLAUDE.md at rel does harm, or None where it may sit."""
    lowered = rel.lower()
    parts = lowered.split("/")
    if parts[0] == "skills" and len(parts) > 3:  # skills/<group>/<name>/...
        return IN_A_SKILL
    return next((why for prefix, why in NO_NESTED.items() if lowered.startswith(prefix)), None)


def check_nested() -> bool:
    files = listed_files()
    if files is None:
        print(f".:no-file-list: git ls-files failed in {REPO_ROOT}, so no nested file was checked.")
        return False

    top = {shown.lower() for shown, *_ in TARGETS.values()}
    passed = True
    for rel in files:
        name = rel.rsplit("/", 1)[-1].lower()
        if name not in INSTRUCTION_NAMES or rel.lower() in top:
            continue
        if name == "agents.md":
            print(
                f"{rel}:agents-md: a root CLAUDE.md keeps Claude from reading any "
                "AGENTS.md here, so this could only be a parallel file for another "
                "tool, which root CLAUDE.md forbids. Put what it says in a CLAUDE.md."
            )
            passed = False
        elif why := harm(rel):
            print(f"{rel}:misplaced: no nested CLAUDE.md here: {why}. {MISPLACED_WHERE_TO}")
            passed = False
        elif (REPO_ROOT / rel).is_file():
            lines = count_lines(REPO_ROOT / rel)
            if lines > NESTED_MAX_LINES:
                print(
                    f"{rel}:too-long: {lines} lines, over the nested cap of "
                    f"{NESTED_MAX_LINES}. {NESTED_WHERE_TO}"
                )
                passed = False
            else:
                print(f"ok: {rel} is {lines} lines, nested cap {NESTED_MAX_LINES}.", file=sys.stderr)
    return passed


def main(argv: list[str]) -> int:
    if len(argv) > 1:
        path = Path(argv[1])
        name = "user" if path.resolve().parent.name.lower() == "claude" else "root"
        _, _, ledger, rules = TARGETS[name]
        return 0 if check(path.as_posix(), path, ledger, rules, is_default=False) else 1

    passed = [check(*target, is_default=True) for target in TARGETS.values()]
    passed.append(check_nested())
    return 0 if all(passed) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
