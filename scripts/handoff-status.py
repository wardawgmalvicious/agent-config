#!/usr/bin/env python3
"""What handoff work is open in every repo on this machine, in one view.

    uv run scripts/handoff-status.py              # every repo under C:/Repos
    uv run scripts/handoff-status.py ROOT...      # a parent, or one repo
    uv run scripts/handoff-status.py --check      # exit 1 on any finding
    uv run scripts/handoff-status.py . --check --no-inbox   # this repo's briefs alone

Each repo keeps its own handoff index and the inbox keeps one directory per
repo, so answering "what is open, anywhere" meant opening every index and
listing every inbox directory by hand. Nothing aggregated them, and work got
lost between them: on 2026-09-18 an estate repo's index was found to have
answered two open questions in this repo's own queue two days earlier, and
nobody had read it. This sweeps them all and prints one section per repo
that has anything, in each index's own order.

Everything is DERIVED, as in audit-status.py -- no state is kept here.
A brief states its own state in frontmatter, or an index states it:

  Frontmatter  a brief opening with `---` carries its state, and no index
            row is needed: agent-config's queue since 2026-09-27, when a
            hand-kept table proved to be what made two sessions collide.
            The grammar is a strict YAML subset, `key: value` or
            `key: [a, b]`, so this stays stdlib and GitHub renders it:
              status       open | deferred
              priority     1 | 2 | 3, buckets with no order inside one
              needs        [user, tenant, ...]; empty means a session can act
              blocked-by   [brief.md, ...], each a file beside this one
              reopen-when  the trigger, required when deferred
              written      YYYY-MM-DD, the tiebreak within a bucket
            Such briefs print grouped -- ready, needs you, needs something
            else, blocked, deferred -- by bucket, then oldest first, and
            one is "in flight" while a git worktree is named after it.
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
  Audits    docs/audits/<date>/<source>/, the drift-audit ledger, where a
            repo keeps one: a brief not yet run, or one whose execution log
            leaves work open -- escalated, deferred or applied with
            deferrals -- and carries no **Closed** line. Its **Needs** line
            groups it as frontmatter's needs does, `none` reading as ready.
            The rule and the log parser are audit-status.py's, loaded from
            beside this file, so the directory index and this view agree.

A brief is any .md under docs/handoffs/ other than a README.md or an
instruction file, a CLAUDE.md or AGENTS.md, and other than anything under
templates/ or examples/, which are reference material rather than work.

Findings, which --check turns into exit 1:

  unindexed   a brief with no frontmatter that no index row links to --
              invisible to the one file a session is told to read first
  dangling    a row whose brief is gone -- spent but never struck
  frontmatter a value missing, unknown, or one a real YAML parser would
              misread, such as one opening with a backtick
  blocker     a blocked-by naming a brief that is gone: the landing that
              deleted it should have deleted the name too
  audit       an audit brief left open with no **Needs** line, which no
              view can place: its work was stranded in its own log before
  loose       a note in the inbox root, addressed to no repo
  orphan      an inbox directory matching no repo swept, e.g. a misspelling

--no-inbox skips the last two and the inbox listing, which lets pre-commit
check one repo's briefs without calling every other repo's inbox an orphan.

A date or position in a brief's FILENAME is reported but is not a finding:
it breaks the common core's stable-filename rule, but a repo's own convention
outranks that core, so this says so and leaves it there.

Stdlib only. Reads other repos and never writes to them.
"""

from __future__ import annotations

import argparse
import datetime as dt
import importlib.util
import pathlib
import re
import subprocess
import sys
from dataclasses import dataclass, field

# Which audit briefs are open is decided where their index is built. Put in
# sys.modules before it runs, as importlib's recipe does: a dataclass in a
# module missing from there fails on its string annotations.
_spec = importlib.util.spec_from_file_location(
    "audit_status", pathlib.Path(__file__).with_name("audit-status.py"))
audit_status = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = audit_status
_spec.loader.exec_module(audit_status)

REPO = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_ROOT = REPO.parents[1]
INBOX = pathlib.Path.home() / "handoff-inbox"
HANDOFFS = pathlib.PurePosixPath("docs/handoffs")
AUDITS = pathlib.PurePosixPath("docs/audits")
REFERENCE_DIRS = {"templates", "examples"}
# An index, and the instruction files a directory may keep for its readers.
NOT_BRIEFS = {"readme.md", "claude.md", "agents.md"}

# A row is a table row or list item that OPENS with a link to a .md file.
ROW_LINK = re.compile(
    r"^\s*(?:\||[-*]|\d+\.)\s*\[[^\]]*\]\(([^)\s#]+\.md)(?:#[^)]*)?\)")
BOLD = re.compile(r"\*\*(.+?)\*\*")
HEADING = re.compile(r"^#{1,6}\s+(.*)")
DATED_NAME = re.compile(r"^(\d{4}-\d{2}-\d{2}|\d{1,3})[-_]")
NOTE_DATE = re.compile(r"^(\d{4}-\d{2}-\d{2})-")
STATE_WIDTH = 46

FM_KEYS = ("status", "priority", "needs", "blocked-by", "reopen-when", "written")
FM_LISTS = {"needs", "blocked-by"}
FM_LINE = re.compile(r"^([a-z][a-z-]*):[ \t]*(.*?)[ \t]*$")
STATUSES = ("open", "deferred")
PRIORITIES = ("1", "2", "3")
# A plain YAML scalar may not open with an indicator, nor hold ": " or " #".
YAML_INDICATORS = tuple("`@&*!|>%{}[],#?'\"")
GROUPS = ("ready", "needs you", "needs something else", "blocked", "deferred")
OUTCOME_WIDTH = len("applied with deferrals 2026-01-01")

for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8", errors="replace")


@dataclass
class Row:
    index: pathlib.Path
    target: pathlib.Path
    state: str


@dataclass
class Brief:
    """A brief that states its own state in frontmatter."""
    path: pathlib.Path
    meta: dict[str, str | list[str]]
    problems: list[tuple[str, str]] = field(default_factory=list)

    def get(self, key: str) -> str:
        value = self.meta.get(key, "")
        return value if isinstance(value, str) else ""

    def items(self, key: str) -> list[str]:
        value = self.meta.get(key, [])
        return value if isinstance(value, list) else []

    @property
    def blockers(self) -> list[str]:
        return [b for b in self.items("blocked-by") if (self.path.parent / b).is_file()]

    @property
    def group(self) -> str:
        if self.get("status") == "deferred":
            return "deferred"
        if self.blockers:
            return "blocked"
        return needs_group(self.items("needs"))

    @property
    def sort_key(self) -> tuple[str, str, str]:
        return (self.get("priority") or "9", self.get("written"), self.path.name)


def needs_group(needs: list[str]) -> str:
    """The group a list of needs puts work in, as frontmatter's needs does."""
    if "user" in needs:
        return "needs you"
    return "needs something else" if needs else "ready"


@dataclass
class RepoReport:
    repo: pathlib.Path
    rows: list[Row] = field(default_factory=list)
    briefs: list[pathlib.Path] = field(default_factory=list)
    stated: list[Brief] = field(default_factory=list)
    worktrees: set[str] = field(default_factory=set)
    touched: dict[str, str] = field(default_factory=dict)
    notes: list[pathlib.Path] = field(default_factory=list)
    audits: list = field(default_factory=list)  # audit_status.FollowUp

    @property
    def stated_paths(self) -> set[pathlib.Path]:
        return {brief.path for brief in self.stated}

    @property
    def open_audits(self) -> list:
        return [a for a in self.audits if a.outcome != "pending"]

    @property
    def unplaced_audits(self) -> list:
        return [a for a in self.open_audits if a.needs is None]

    @property
    def unindexed(self) -> list[pathlib.Path]:
        linked = {row.target for row in self.rows} | self.stated_paths
        return [b for b in self.briefs if b not in linked]

    @property
    def problems(self) -> list[tuple[Brief, str, str]]:
        return [(b, kind, text) for b in self.stated for kind, text in b.problems]

    @property
    def dangling(self) -> list[Row]:
        return [row for row in self.rows if not row.target.exists()]

    @property
    def empty(self) -> bool:
        return not (self.rows or self.briefs or self.notes or self.audits)


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
    return (path.suffix == ".md" and path.name.lower() not in NOT_BRIEFS
            and not is_reference(path, tree))


def yaml_unsafe(value: str) -> bool:
    return (value.startswith(YAML_INDICATORS) or value.startswith("- ")
            or ": " in value or " #" in value)


def read_frontmatter(path: pathlib.Path) -> Brief | None:
    """Parse a brief's frontmatter, or return None when it has none."""
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    if not lines or lines[0].rstrip() != "---":
        return None
    brief = Brief(path, {})
    end = next((i for i in range(1, len(lines)) if lines[i].rstrip() == "---"), None)
    if end is None:
        brief.problems.append(("frontmatter", "opens with --- and never closes"))
        return brief
    for number, line in enumerate(lines[1:end], start=2):
        if not line.strip():
            continue
        match = FM_LINE.match(line)
        if not match:
            brief.problems.append(("frontmatter", f"line {number} is not `key: value`"))
            continue
        key, raw = match.groups()
        if key not in FM_KEYS:
            brief.problems.append(("frontmatter", f"unknown key `{key}`"))
        elif key in brief.meta:
            brief.problems.append(("frontmatter", f"`{key}` is given twice"))
        elif key in FM_LISTS:
            if not (raw.startswith("[") and raw.endswith("]")):
                brief.problems.append(("frontmatter", f"`{key}` is not a list, [a, b]"))
                continue
            items = [item.strip() for item in raw[1:-1].split(",") if item.strip()]
            if any(yaml_unsafe(item) for item in items):
                brief.problems.append(("frontmatter", f"`{key}` holds an item YAML would misread"))
            brief.meta[key] = items
        else:
            if yaml_unsafe(raw):
                brief.problems.append(
                    ("frontmatter", f"`{key}` would not parse as plain YAML; reword its opening"))
            brief.meta[key] = raw
    validate(brief)
    return brief


def validate(brief: Brief) -> None:
    status = brief.get("status")
    if status not in STATUSES:
        brief.problems.append(("frontmatter", f"status is {status or 'missing'}; "
                                              "want open or deferred"))
    if brief.get("priority") not in PRIORITIES:
        brief.problems.append(("frontmatter", f"priority is {brief.get('priority') or 'missing'}; "
                                              "want 1, 2 or 3"))
    try:
        dt.date.fromisoformat(brief.get("written"))
    except ValueError:
        brief.problems.append(("frontmatter", "written is not a YYYY-MM-DD date"))
    if status == "deferred" and not brief.get("reopen-when"):
        brief.problems.append(("frontmatter", "a deferred brief needs reopen-when"))
    for name in brief.items("blocked-by"):
        if not (brief.path.parent / name).is_file():
            brief.problems.append(("blocker", f"blocked-by names {name}, which does not exist"))


def worktree_names(repo: pathlib.Path) -> set[str]:
    """Directory names of the repo's linked worktrees, each a claim on a brief."""
    result = subprocess.run(
        ["git", "-C", str(repo), "worktree", "list", "--porcelain"],
        capture_output=True, text=True, encoding="utf-8", errors="replace")
    paths = [line[len("worktree "):] for line in result.stdout.splitlines()
             if line.startswith("worktree ")]
    return {pathlib.PurePath(p).name for p in paths[1:]}  # the first is the main checkout


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


def scan(repo: pathlib.Path, inbox_root: pathlib.Path | None) -> RepoReport:
    report = RepoReport(repo)
    tree = (repo / HANDOFFS).resolve()
    if tree.is_dir():
        for path in sorted(tree.rglob("*.md")):
            if path.name.lower() == "readme.md" and not is_reference(path, tree):
                report.rows += read_rows(path, tree)
            elif is_brief(path, tree):
                report.briefs.append(path)
                if (brief := read_frontmatter(path)) is not None:
                    report.stated.append(brief)
        if report.briefs or report.rows:
            report.touched = last_touched(repo)
        if report.stated:
            report.worktrees = worktree_names(repo)
    report.audits = audit_status.follow_ups(repo / AUDITS)
    inbox = inbox_root / repo.name if inbox_root else None
    if inbox and inbox.is_dir():
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


def detail(brief: Brief, report: RepoReport) -> str:
    """What a brief is waiting on, and whether a worktree has claimed it."""
    parts = []
    if brief.path.stem in report.worktrees:
        parts.append("in flight")
    if brief.group in ("needs you", "needs something else"):
        parts.append("needs " + ", ".join(brief.items("needs")))
    elif brief.group == "blocked":
        parts.append("blocked by " + ", ".join(brief.blockers))
    elif brief.group == "deferred":
        parts.append("reopen when " + shorten(brief.get("reopen-when"), 64))
    return "".join(f"  {part}" for part in parts)


def print_report(report: RepoReport, today: dt.date) -> None:
    repo = report.repo
    stated = report.stated_paths

    def rel(path: pathlib.Path) -> str:
        return path.relative_to(repo).as_posix()

    def touched(path: pathlib.Path) -> str:
        return report.touched.get(rel(path), "uncommitted")

    print(f"== {repo.name} ==  {repo.as_posix()}")
    for index in dict.fromkeys(row.index for row in report.rows):
        listed = [r for r in report.rows
                  if r.index == index and r.target.exists() and r.target not in stated]
        if not listed:
            continue
        print(f"  index: {rel(index)}")
        for row in listed:
            dated = "   (dated filename)" if DATED_NAME.match(row.target.name) else ""
            print(f"    {shorten(row.state):<{STATE_WIDTH}}  {touched(row.target)}  "
                  f"{row.target.name}{dated}")
    if any(b not in stated for b in report.briefs) and not report.rows:
        print("  index: none")
    for directory in dict.fromkeys(b.path.parent for b in report.stated):
        print(f"  queue: {rel(directory)}/  (each brief's own frontmatter)")
        here = [b for b in report.stated if b.path.parent == directory]
        for group in GROUPS:
            members = sorted((b for b in here if b.group == group), key=lambda b: b.sort_key)
            if members:
                print(f"    {group}")
            for brief in members:
                print(f"      P{brief.get('priority') or '?'}  {brief.path.name:<46}  "
                      f"written {brief.get('written') or '?':<10}  "
                      f"touched {touched(brief.path)}{detail(brief, report)}")
    if report.audits:
        print_audits(report)
    for row in report.dangling:
        print(f"  ! dangling   {rel(row.index)} links {row.target.name}, "
              f"which does not exist")
    for brief in report.unindexed:
        print(f"  ! unindexed  {rel(brief)}   touched {touched(brief)}")
    for brief, kind, text in report.problems:
        print(f"  ! {kind:<11} {rel(brief.path)}: {text}")
    for item in report.unplaced_audits:
        print(f"  ! {'audit':<11} {rel(item.path)}: {item.outcome} and not closed, "
              f"with no **Needs** line")
    if report.notes:
        print(f"  inbox: {len(report.notes)} note(s) in "
              f"~/handoff-inbox/{repo.name}/")
        for note in report.notes:
            print(f"    {age(note, today):>8}  {note.name}")
    print()


def print_audits(report: RepoReport) -> None:
    """The audit follow-up queue: open briefs by need, then unrun directories."""
    root = report.repo / AUDITS
    print(f"  audit follow-ups: {AUDITS}/  (each brief's execution log)")
    placed = [a for a in report.open_audits if a.needs is not None]
    for group in GROUPS:
        members = [a for a in placed if needs_group(a.needs) == group]
        if members:
            print(f"    {group}")
        for item in members:
            needs = f"  needs {', '.join(item.needs)}" if item.needs else ""
            print(f"      {item.outcome + ' ' + item.date:<{OUTCOME_WIDTH}}  "
                  f"{item.path.relative_to(root).as_posix()}{needs}")
    pending: dict[pathlib.Path, int] = {}
    for item in report.audits:
        if item.outcome == "pending":
            pending[item.path.parent] = pending.get(item.path.parent, 0) + 1
    if pending:
        print("    not executed: /drift-update")
    for directory, count in pending.items():
        print(f"      {directory.relative_to(root).as_posix()}/  {count} brief(s)")


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
                    help="exit 1 on any finding: unindexed, dangling, frontmatter, "
                         "blocker, audit, loose or orphan")
    ap.add_argument("--no-inbox", action="store_true",
                    help="skip the inbox, its notes and its loose and orphan findings")
    args = ap.parse_args()

    today = dt.date.today()
    repos = find_repos(args.roots)
    inbox = None if args.no_inbox else args.inbox
    reports = [scan(r, inbox) for r in repos]
    for report in reports:
        if not report.empty:
            print_report(report, today)

    loose, orphans = inbox_findings(repos, inbox) if inbox else ([], [])
    for name in loose:
        print(f"! loose note in ~/handoff-inbox/: {name} -- addressed to no repo")
    for name in orphans:
        print(f"! orphan inbox directory ~/handoff-inbox/{name}/ -- "
              f"no repo of that name was swept")

    open_rows = sum(1 for r in reports for row in r.rows
                    if row.target.exists() and row.target not in r.stated_paths)
    stated = sum(len(r.stated) for r in reports)
    unindexed = sum(len(r.unindexed) for r in reports)
    dangling = sum(len(r.dangling) for r in reports)
    problems = sum(len(r.problems) for r in reports)
    audits = sum(len(r.open_audits) for r in reports)
    unplaced = sum(len(r.unplaced_audits) for r in reports)
    notes = sum(len(r.notes) for r in reports)
    active = sum(not r.empty for r in reports)
    print(f"{len(repos)} repos swept, {active} with handoff work: "
          f"{open_rows} indexed brief(s), {stated} with frontmatter, {unindexed} unindexed, "
          f"{dangling} dangling row(s), {problems} frontmatter finding(s), "
          f"{audits} audit follow-up(s), {unplaced} without Needs, "
          f"{notes} inbox note(s), {len(loose)} loose, {len(orphans)} orphan director(ies)")

    findings = unindexed + dangling + problems + unplaced + len(loose) + len(orphans)
    return 1 if args.check and findings else 0


if __name__ == "__main__":
    sys.exit(main())
