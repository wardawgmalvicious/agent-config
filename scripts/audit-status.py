#!/usr/bin/env python3
"""Where every drift-audit brief stands, as a README.md in its directory.

    uv run scripts/audit-status.py                     # regenerate every index
    uv run scripts/audit-status.py --dir docs/audits/2026-09-12/skills-for-fabric
    uv run scripts/audit-status.py --check             # stale or missing? pre-commit

Each docs/audits/<date>/<source>/ directory gets one generated README.md:
a table with a row per brief giving the actions it covers, its Kind, and
its status. GitHub renders it when the directory is browsed, which is the
point -- before this existed the only way to learn which of eleven briefs
had been executed was to open eleven files.

Nothing in the index is hand-maintained. Status is DERIVED from what each
brief already carries: the metadata block /drift-handoff writes, and the
`## Execution log` that /drift-update appends. A hand-kept status column
would be a third copy of a fact that already lives in the log, and this
repo has lost enough counts to that pattern to know how it ends. So the
table is regenerated, never edited: /drift-handoff runs this after
writing a directory, /drift-update runs it after every stamp, and the
pre-commit hook runs --check so a forgotten regeneration fails instead of
rotting.

What the rows read, from each brief:

  Actions   the `**Covers recommended actions**:` metadata line, minus
            any parenthetical long enough to be prose
  Kind      the `**Kind**:` line, cut at its first clause boundary -- the
            distinction /drift-update triages on (edit, decision,
            investigation) is in those first words by convention
  Status    pending           no `## Execution log` yet
            <outcome> <date>  the `**Executed**:` line's date and leading
                              outcome word or phrase -- applied, applied
                              with deferrals, already-applied, escalated,
                              deferred -- with the rest of the line dropped
            closed <date>     appended when the log also carries a
                              `**Closed**:` line, the key a later session
                              adds when a deferral or an escalation is
                              discharged. Without it an escalated brief
                              reads as open forever, which is how the four
                              /author-skill runs that settled
                              2026-09-10/skills-for-fabric/07 left no
                              trace in the ledger.

An open row -- escalated, deferred or applied with deferrals, and not
closed -- links to docs/handoffs/execute/README.md's account of the audit
follow-up queue. handoff-status.py prints that queue from these same logs,
through follow_ups() below, grouped by the `**Needs**:` line each open log
carries. The index says what state a brief is in; the queue says what its
outstanding work needs. Neither restates the other.

Where a brief sits is derived the same way. One whose log leaves nothing
open -- applied or already-applied, or any outcome once a `**Closed**:`
line follows it -- belongs in its directory's completed/, and every other
brief at the top, so the file tree alone shows which briefs still need a
session. Regenerating moves a brief found on the wrong side, either way,
and --check fails on one, so the folder can no more drift from the logs
than the table can. A log too malformed to parse stays at the top, beside
its `unparsed` row. Nothing is deleted: the directory is still the whole
ledger entry. Added 2026-10-06, so that which briefs are open shows in the
file tree and not only in the index.

Parsing is deliberately strict about shape and loose about words: a
brief with an `## Execution log` but no `**Executed**:` line, or one whose
Executed line has no date, is reported as `unparsed` so it is visible in
the table rather than silently pending. Only stdlib is used, so the
pre-commit hook needs no extra dependency.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
AUDITS = REPO / "docs" / "audits"
QUEUE = "handoffs/execute/README.md"  # relative to docs/
QUEUE_ANCHOR = "audit-briefs-are-a-second-queue"
# Where a brief whose log leaves nothing open is filed, inside its directory.
COMPLETED = "completed"

# 00-audit-report.md, and 00b-audit-report-rerun.md when a source was
# audited twice in one day and the second report was kept beside the first.
REPORT_RE = re.compile(r"^00[a-z]?-audit-report.*\.md$")
BRIEF_RE = re.compile(r"^(\d{2})-(?!audit-report).+\.md$")
META_RE = re.compile(r"^- \*\*([^*]+)\*\*:\s*(.*)$")
EXECUTED_RE = re.compile(r"^(\d{4}-\d{2}-\d{2})\s*(?:[—–-]+\s*)?(.*)$")
# Longest first, so "applied with deferrals" wins over "applied".
OUTCOMES = ("applied with deferrals", "already-applied", "escalated", "deferred", "applied")
# Outcomes that leave work behind, open until a `**Closed**:` line.
OPEN_OUTCOMES = ("escalated", "deferred", "applied with deferrals")
NEEDS_CUT = re.compile(r"\s+(?:[—–]|--)\s+")

BANNER = (
    "<!-- Generated by scripts/audit-status.py from the briefs in this directory.\n"
    "     Do not edit by hand: re-run the script, or let /drift-update do it. -->\n"
)


@dataclass
class FollowUp:
    """An audit brief not yet run, or one whose log leaves work open."""
    path: Path
    outcome: str  # "pending" when the brief has no execution log
    date: str
    needs: list[str] | None  # None when an open log carries no Needs line


def audit_dirs(audits: Path = AUDITS) -> list[Path]:
    """Every <date>/<source> directory that holds an audit report."""
    found = []
    if not audits.is_dir():
        return found
    for date_dir in sorted(audits.iterdir()):
        if not date_dir.is_dir():
            continue
        for src_dir in sorted(date_dir.iterdir()):
            if src_dir.is_dir() and any(REPORT_RE.match(p.name) for p in src_dir.iterdir()):
                found.append(src_dir)
    return found


def briefs_in(src_dir: Path) -> list[Path]:
    """Every brief in a directory, at its top or under completed/, in number order."""
    found = [p for p in src_dir.iterdir() if BRIEF_RE.match(p.name)]
    done = src_dir / COMPLETED
    if done.is_dir():
        found += [p for p in done.iterdir() if BRIEF_RE.match(p.name)]
    return sorted(found, key=lambda p: (p.name, p.parent.name))


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8").replace("\r\n", "\n")


def metadata(lines: list[str]) -> dict[str, str]:
    """The `- **Key**: value` block under the H1, continuation lines joined."""
    meta: dict[str, str] = {}
    key = None
    for line in lines:
        if line.startswith("## "):
            break
        m = META_RE.match(line)
        if m:
            key = m.group(1).strip()
            meta[key] = m.group(2).strip()
        elif key and line.startswith("  ") and line.strip():
            meta[key] += " " + line.strip()
        elif not line.strip():
            key = None
    return meta


def execution_log(lines: list[str]) -> dict[str, str] | None:
    """The `- **Key**: value` entries under `## Execution log`, or None."""
    try:
        start = lines.index("## Execution log")
    except ValueError:
        return None
    log: dict[str, str] = {}
    key = None
    for line in lines[start + 1 :]:
        if line.startswith("## "):
            break
        m = META_RE.match(line)
        if m:
            key = m.group(1).strip()
            log[key] = m.group(2).strip()  # a repeated key keeps its last value
        elif key and line.startswith("  ") and line.strip():
            log[key] += " " + line.strip()
        elif not line.strip():
            key = None
    return log


def strip_md(text: str) -> str:
    return text.replace("**", "").strip()


def kind_summary(kind: str) -> str:
    """The Kind line up to its first clause boundary, bold stripped."""
    text = strip_md(kind)
    cut = len(text)
    for sep in (". ", " — ", " -- ", "; ", ": "):
        i = text.find(sep)
        if 0 < i < cut:
            cut = i
    text = text[:cut].rstrip(".")
    if len(text) > 90:
        text = text[:89].rsplit(" ", 1)[0] + "…"
    return text


def outcome_of(executed: str) -> tuple[str, str] | None:
    """(date, outcome) from an Executed line, or None when it has no date."""
    m = EXECUTED_RE.match(strip_md(executed))
    if not m:
        return None
    date, rest = m.group(1), m.group(2).strip().lower()
    for word in OUTCOMES:
        if rest.startswith(word):
            return date, word
    # An outcome this script does not know: keep its first words rather
    # than hide it, so the table shows what the log actually says.
    head = re.split(r"[(;,.]", rest, maxsplit=1)[0].strip()
    return date, (head or "unlabelled")


def actions_summary(actions: str) -> str:
    """The Covers line, minus any parenthetical long enough to be prose."""
    return re.sub(r"\s*\([^)]{30,}\)", "", strip_md(actions)).strip()


def status_cell(log: dict[str, str] | None, rel_queue: str) -> tuple[str, str]:
    """(table cell, tally key) for one brief's execution log."""
    if log is None:
        return "pending", "pending"
    executed = log.get("Executed")
    if not executed:
        return "unparsed — `## Execution log` has no `**Executed**:` line", "unparsed"
    parsed = outcome_of(executed)
    if parsed is None:
        return "unparsed — `**Executed**:` line carries no date", "unparsed"
    date, outcome = parsed
    cell = f"{outcome} {date}"
    closed = log.get("Closed")
    if closed:
        cm = EXECUTED_RE.match(strip_md(closed))
        cell += f" · closed {cm.group(1)}" if cm else " · closed (undated)"
        return cell, "closed"
    if outcome in OPEN_OUTCOMES:
        cell += f" · [queue]({rel_queue}#{QUEUE_ANCHOR})"
    return cell, outcome


def needs_of(log: dict[str, str]) -> list[str] | None:
    """The Needs line as a list, cut at its first dash; [] when it says none."""
    raw = log.get("Needs")
    if raw is None:
        return None
    head = NEEDS_CUT.split(strip_md(raw), maxsplit=1)[0]
    items = [item.strip() for item in head.split(",") if item.strip()]
    return [] if items == ["none"] else items


def finished(log: dict[str, str] | None) -> bool:
    """Whether a log leaves nothing open, which files its brief under completed/.

    The complement of follow_ups() for every log this script can parse. One
    it cannot is neither, and stays at the top beside its `unparsed` row.
    """
    if log is None:
        return False
    parsed = outcome_of(log.get("Executed", ""))
    if parsed is None:
        return False
    return "Closed" in log or parsed[1] not in OPEN_OUTCOMES


def follow_ups(audits: Path = AUDITS) -> list[FollowUp]:
    """Every brief not yet run, or whose log leaves work open and unclosed.

    handoff-status.py prints these as the audit follow-up queue, so the rule
    for what is open lives here, beside the index built from the same logs,
    and in no second parser. The log decides, not the folder: an open brief
    moved under completed/ by hand is still listed.
    """
    found = []
    for src_dir in audit_dirs(audits):
        for brief in briefs_in(src_dir):
            log = execution_log(read_text(brief).split("\n"))
            if log is None:
                found.append(FollowUp(brief, "pending", "", None))
                continue
            parsed = outcome_of(log.get("Executed", ""))
            if parsed and not finished(log):
                found.append(FollowUp(brief, parsed[1], parsed[0], needs_of(log)))
    return found


def misplaced(src_dir: Path) -> list[tuple[Path, Path]]:
    """(where it is, where its log puts it) for every brief on the wrong side."""
    moves = []
    for brief in briefs_in(src_dir):
        done = finished(execution_log(read_text(brief).split("\n")))
        home = src_dir / COMPLETED if done else src_dir
        if brief.parent != home:
            moves.append((brief, home / brief.name))
    return moves


def render(src_dir: Path) -> str:
    date, source = src_dir.parent.name, src_dir.name
    # Up to docs/, then down: docs/audits/<date>/<source>/ is three below it.
    depth = len(src_dir.relative_to(REPO / "docs").parts)
    rel_queue = "../" * depth + QUEUE
    reports = sorted(p.name for p in src_dir.iterdir() if REPORT_RE.match(p.name))
    briefs = briefs_in(src_dir)

    rows = []
    tally: dict[str, int] = {}
    for brief in briefs:
        lines = read_text(brief).split("\n")
        title = next((ln[2:] for ln in lines if ln.startswith("# ")), brief.stem)
        title = re.sub(r"^Handoff:\s*", "", title)
        meta = metadata(lines)
        number = BRIEF_RE.match(brief.name).group(1)
        actions = actions_summary(meta.get("Covers recommended actions", "?"))
        kind = kind_summary(meta.get("Kind", "?"))
        status, head = status_cell(execution_log(lines), rel_queue)
        tally[head] = tally.get(head, 0) + 1
        link = brief.relative_to(src_dir).as_posix()
        rows.append(f"| [{number} {title}]({link}) | {actions} | {kind} | {status} |")

    report_links = ", ".join(f"[{r}]({r})" for r in reports)
    summary = " · ".join(f"{k} {v}" for k, v in sorted(tally.items()))
    out = [
        BANNER,
        f"# Audit index — {source}, {date}",
        "",
        f"Report: {report_links}",
        "",
        f"Briefs: {len(briefs)}" + (f" — {summary}" if summary else ""),
        "",
        "| Brief | Actions | Kind | Status |",
        "| --- | --- | --- | --- |",
        *rows,
        "",
    ]
    return "\n".join(out)


def rel(path: Path) -> str:
    return path.relative_to(REPO).as_posix()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dir", action="append", type=Path, help="one audit directory; repeatable")
    ap.add_argument("--check", action="store_true",
                    help="fail if any README.md is missing or stale, or a brief sits on the wrong side")
    args = ap.parse_args()

    dirs = [d.resolve() for d in args.dir] if args.dir else audit_dirs()
    if not dirs:
        print("no audit directories under docs/audits/")
        return 0

    stale = []
    moved = 0
    for src_dir in dirs:
        if not src_dir.is_dir():
            print(f"not a directory: {src_dir}", file=sys.stderr)
            return 2
        moves = misplaced(src_dir)
        if args.check:
            stale += [f"misplaced: {rel(old)}, whose log puts it in {rel(new.parent)}/"
                      for old, new in moves]
        else:
            # A brief on both sides is two copies to reconcile by hand; a
            # move would overwrite one of them.
            clashes = [(old, new) for old, new in moves if new.exists()]
            for old, new in clashes:
                print(f"both exist, so nothing moved: {rel(old)} and {rel(new)}", file=sys.stderr)
            if clashes:
                return 2
            for old, new in moves:
                new.parent.mkdir(exist_ok=True)
                old.rename(new)
                print(f"moved {rel(old)} -> {rel(new)}")
                moved += 1
            done = src_dir / COMPLETED
            if done.is_dir() and not any(done.iterdir()):
                done.rmdir()
        target = src_dir / "README.md"
        wanted = render(src_dir)
        current = read_text(target) if target.exists() else None
        if args.check:
            if current != wanted:
                stale.append(f"stale or missing: {rel(target)}")
        elif current != wanted:
            target.write_text(wanted, encoding="utf-8", newline="\n")
            print(f"wrote {rel(target)}")
        else:
            print(f"current {rel(target)}")

    if moved:
        print("note: a path naming a moved brief's old place now finds nothing. Re-point "
              "the live ones (git grep -n <filename>), never a stamped brief's own text.")
    if args.check and stale:
        for line in stale:
            print(line)
        print("regenerate with: uv run scripts/audit-status.py")
        return 1
    if args.check:
        print(f"{len(dirs)} audit index(es) current, every brief where its log puts it")
    return 0


if __name__ == "__main__":
    sys.exit(main())
