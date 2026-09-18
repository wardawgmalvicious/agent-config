#!/usr/bin/env python3
"""What handoff work is open in every repo on this machine, in one view.

    uv run scripts/handoff-status.py              # every repo under C:/Repos
    uv run scripts/handoff-status.py ROOT...      # a parent, or one repo
    uv run scripts/handoff-status.py --check      # exit 1 on any finding

Each repo keeps its own handoff index and the inbox keeps one directory per
repo, so answering "what is open, anywhere" meant opening every index and
listing every inbox directory by hand. Nothing aggregated them, and work got
lost between them: on 2026-09-18 an estate repo's index was found to have
answered two open questions in this repo's own queue two days earlier, and
nobody had read it. This sweeps them all and prints one section per repo
that has anything, in each index's own order.

Everything is DERIVED, as in audit-status.py -- no state is kept here:

  Rows      every table row or list item in a README.md under docs/handoffs/
            whose FIRST element is a link to a brief. Links elsewhere in a
            row, and links in prose, are not rows.
  State     the row's first **bold** span, which is where every index here
            puts it; failing that, the heading the row sits under.
  Touched   the date of the last commit to touch the brief, from one
            `git log` per repo (a spawn costs ~0.4 s here, so never one per
            file). `uncommitted` when no commit has touched it.
  Inbox     ~/handoff-inbox/<repo>/, keyed on the repo directory's name,
            which is what the inbox README tells a writer to use. The age is
            read from the note's date prefix.

A brief is any .md under docs/handoffs/ other than a README.md, and other
than anything under templates/ or examples/, which are reference material
rather than work.

Findings, which --check turns into exit 1:

  unindexed   a brief no index row links to -- invisible to the one file a
              session is told to read first
  dangling    a row whose brief is gone -- spent but never struck
  loose       a note in the inbox root, addressed to no repo
  orphan      an inbox directory matching no repo swept, e.g. a misspelling

A date or position in a brief's FILENAME is reported but is not a finding:
it breaks the common core's stable-filename rule, but a repo's own convention
outranks that core, so this says so and leaves it there.

Stdlib only. Reads other repos and never writes to them.
"""

from __future__ import annotations

import argparse
import datetime as dt
import pathlib
import re
import subprocess
import sys
from dataclasses import dataclass, field

REPO = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_ROOT = REPO.parents[1]
INBOX = pathlib.Path.home() / "handoff-inbox"
HANDOFFS = pathlib.PurePosixPath("docs/handoffs")
REFERENCE_DIRS = {"templates", "examples"}

# A row is a table row or list item that OPENS with a link to a .md file.
ROW_LINK = re.compile(
    r"^\s*(?:\||[-*]|\d+\.)\s*\[[^\]]*\]\(([^)\s#]+\.md)(?:#[^)]*)?\)")
BOLD = re.compile(r"\*\*(.+?)\*\*")
HEADING = re.compile(r"^#{1,6}\s+(.*)")
DATED_NAME = re.compile(r"^(\d{4}-\d{2}-\d{2}|\d{1,3})[-_]")
NOTE_DATE = re.compile(r"^(\d{4}-\d{2}-\d{2})-")
STATE_WIDTH = 46

for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8", errors="replace")


@dataclass
class Row:
    index: pathlib.Path
    target: pathlib.Path
    state: str


@dataclass
class RepoReport:
    repo: pathlib.Path
    rows: list[Row] = field(default_factory=list)
    briefs: list[pathlib.Path] = field(default_factory=list)
    touched: dict[str, str] = field(default_factory=dict)
    notes: list[pathlib.Path] = field(default_factory=list)

    @property
    def unindexed(self) -> list[pathlib.Path]:
        linked = {row.target for row in self.rows}
        return [b for b in self.briefs if b not in linked]

    @property
    def dangling(self) -> list[Row]:
        return [row for row in self.rows if not row.target.exists()]

    @property
    def empty(self) -> bool:
        return not (self.rows or self.briefs or self.notes)


def find_repos(roots: list[pathlib.Path]) -> list[pathlib.Path]:
    """Return each root that is a repo, else repos up to two levels below it.

    Two levels because repos here sit under a grouping directory
    (C:/Repos/<group>/<repo>), and --sweep in payload-coverage.py, which
    goes one level, would find none of them from C:/Repos.
    """
    found: list[pathlib.Path] = []
    for root in roots:
        root = root.resolve()
        if not root.is_dir():
            print(f"not a directory, skipped: {root}", file=sys.stderr)
            continue
        if (root / ".git").exists():
            found.append(root)
            continue
        for child in sorted(root.iterdir()):
            if not child.is_dir() or child.name.startswith("."):
                continue
            if (child / ".git").exists():
                found.append(child)
                continue
            found += sorted(g for g in child.iterdir()
                            if g.is_dir() and (g / ".git").exists())
    return found


def is_reference(path: pathlib.Path, tree: pathlib.Path) -> bool:
    return bool(REFERENCE_DIRS & set(path.relative_to(tree).parts[:-1]))


def is_brief(path: pathlib.Path, tree: pathlib.Path) -> bool:
    return (path.suffix == ".md" and path.name.lower() != "readme.md"
            and not is_reference(path, tree))


def read_rows(index: pathlib.Path, tree: pathlib.Path) -> list[Row]:
    rows: list[Row] = []
    heading = ""
    text = index.read_text(encoding="utf-8", errors="replace")
    for line in text.splitlines():
        if match := HEADING.match(line):
            heading = match.group(1).strip()
            continue
        match = ROW_LINK.match(line)
        if not match:
            continue
        target = (index.parent / match.group(1)).resolve()
        if not target.is_relative_to(tree) or not is_brief(target, tree):
            continue
        bold = BOLD.search(line[match.end():])
        state = bold.group(1) if bold else heading or "(no state)"
        rows.append(Row(index, target, state.strip().rstrip(".:;,")))
    return rows


def last_touched(repo: pathlib.Path) -> dict[str, str]:
    """Map each path under docs/handoffs to the date of its latest commit."""
    result = subprocess.run(
        ["git", "-C", str(repo), "log", "--format=%x00%cs", "--name-only",
         "--", str(HANDOFFS)],
        capture_output=True, text=True, encoding="utf-8", errors="replace")
    touched: dict[str, str] = {}
    date = ""
    for line in result.stdout.splitlines():
        if line.startswith("\x00"):
            date = line[1:]
        elif line.strip():
            touched.setdefault(line.strip(), date)
    return touched


def scan(repo: pathlib.Path, inbox_root: pathlib.Path) -> RepoReport:
    report = RepoReport(repo)
    tree = (repo / HANDOFFS).resolve()
    if tree.is_dir():
        for path in sorted(tree.rglob("*.md")):
            if path.name.lower() == "readme.md" and not is_reference(path, tree):
                report.rows += read_rows(path, tree)
            elif is_brief(path, tree):
                report.briefs.append(path)
        if report.briefs or report.rows:
            report.touched = last_touched(repo)
    inbox = inbox_root / repo.name
    if inbox.is_dir():
        report.notes = sorted(n for n in inbox.iterdir()
                              if n.is_file() and n.name.lower() != "readme.md")
    return report


def age(note: pathlib.Path, today: dt.date) -> str:
    match = NOTE_DATE.match(note.name)
    if not match:
        return "undated"
    try:
        days = (today - dt.date.fromisoformat(match.group(1))).days
    except ValueError:
        return "undated"
    return f"{days}d"


def shorten(text: str, width: int = STATE_WIDTH) -> str:
    return text if len(text) <= width else text[:width - 3] + "..."


def print_report(report: RepoReport, today: dt.date) -> None:
    repo = report.repo

    def rel(path: pathlib.Path) -> str:
        return path.relative_to(repo).as_posix()

    def touched(path: pathlib.Path) -> str:
        return report.touched.get(rel(path), "uncommitted")

    print(f"== {repo.name} ==  {repo.as_posix()}")
    for index in dict.fromkeys(row.index for row in report.rows):
        print(f"  index: {rel(index)}")
        for row in (r for r in report.rows if r.index == index):
            if not row.target.exists():
                continue
            dated = "   (dated filename)" if DATED_NAME.match(row.target.name) else ""
            print(f"    {shorten(row.state):<{STATE_WIDTH}}  {touched(row.target)}  "
                  f"{row.target.name}{dated}")
    if report.briefs and not report.rows:
        print("  index: none")
    for row in report.dangling:
        print(f"  ! dangling   {rel(row.index)} links {row.target.name}, "
              f"which does not exist")
    for brief in report.unindexed:
        print(f"  ! unindexed  {rel(brief)}   touched {touched(brief)}")
    if report.notes:
        print(f"  inbox: {len(report.notes)} note(s) in "
              f"~/handoff-inbox/{repo.name}/")
        for note in report.notes:
            print(f"    {age(note, today):>8}  {note.name}")
    print()


def inbox_findings(repos: list[pathlib.Path],
                   inbox: pathlib.Path) -> tuple[list[str], list[str]]:
    """Return (loose notes, orphan directories) in the inbox root."""
    if not inbox.is_dir():
        return [], []
    names = {r.name for r in repos}
    loose = sorted(p.name for p in inbox.iterdir()
                   if p.is_file() and p.name.lower() != "readme.md")
    orphans = sorted(p.name for p in inbox.iterdir()
                     if p.is_dir() and p.name not in names)
    return loose, orphans


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Show open handoff briefs and inbox notes across every repo.")
    ap.add_argument("roots", nargs="*", type=pathlib.Path,
                    default=[DEFAULT_ROOT],
                    help=f"repos, or parents of repos (default: {DEFAULT_ROOT.as_posix()})")
    ap.add_argument("--inbox", type=pathlib.Path, default=INBOX,
                    help="inbox directory (default: ~/handoff-inbox); for tests")
    ap.add_argument("--check", action="store_true",
                    help="exit 1 if anything is unindexed, dangling, loose or orphaned")
    args = ap.parse_args()

    today = dt.date.today()
    repos = find_repos(args.roots)
    reports = [scan(r, args.inbox) for r in repos]
    for report in reports:
        if not report.empty:
            print_report(report, today)

    loose, orphans = inbox_findings(repos, args.inbox)
    for name in loose:
        print(f"! loose note in ~/handoff-inbox/: {name} -- addressed to no repo")
    for name in orphans:
        print(f"! orphan inbox directory ~/handoff-inbox/{name}/ -- "
              f"no repo of that name was swept")

    open_rows = sum(len(r.rows) - len(r.dangling) for r in reports)
    unindexed = sum(len(r.unindexed) for r in reports)
    dangling = sum(len(r.dangling) for r in reports)
    notes = sum(len(r.notes) for r in reports)
    active = sum(not r.empty for r in reports)
    print(f"{len(repos)} repos swept, {active} with handoff work: "
          f"{open_rows} indexed brief(s), {unindexed} unindexed, "
          f"{dangling} dangling row(s), {notes} inbox note(s), "
          f"{len(loose)} loose, {len(orphans)} orphan director(ies)")

    findings = unindexed + dangling + len(loose) + len(orphans)
    return 1 if args.check and findings else 0


if __name__ == "__main__":
    sys.exit(main())
