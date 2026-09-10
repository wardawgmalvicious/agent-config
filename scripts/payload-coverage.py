#!/usr/bin/env python3
"""Report which of a repo's files activate nothing in this payload.

Every rule and every conditional skill declares ``paths:`` globs, so the
question "what does this repo contain that no rule and no skill will ever
see" is a MEASUREMENT rather than a judgement call. This runs it.

Why it exists: the gap is discovered today by tripping over it. Landing in
an unfamiliar repo -- an Azure/Bicep one, say -- nothing says which parts
of it the payload covers, so a missing rule surfaces one file at a time,
or never. This answers it in one command, before any work starts, and
re-answers it as a repo's stack shifts.

The first run (2026-09-10) found a client repo scoring ZERO: not one of
the payload's globs matched any of its 200 files. Coverage turned out to be
binary rather than gradual, which is exactly why nobody noticed -- there
was no partial coverage to be suspicious of.

Findings are candidates, not work. An uncovered extension earns a rule
only if it is hand-written, recurring, and has conventions worth stating.
NON_TEXT below encodes the easy half of that filter; the rest is a
judgement the report deliberately leaves to a person, and ranking by file
count is what makes that judgement cheap.

MATCHER: wcmatch with GLOBSTAR | DOTGLOB, which is what
scripts/activation-expect.py uses to predict activation. The two must
agree or this reports coverage the harness would not confirm. They cannot
share the code -- a hyphen in that filename makes it un-importable -- so
the flags are duplicated here deliberately. Change them together.

Usage:
    uv run --with pyyaml --with wcmatch python scripts/payload-coverage.py REPO...
    uv run --with pyyaml --with wcmatch python scripts/payload-coverage.py
        --sweep C:/Repos/Personal
    ... REPO --by-file             most-matched individual files
    ... REPO --exclude "tests/**"  drop paths from the scan
"""

from __future__ import annotations

import argparse
import pathlib
import subprocess
import sys
from collections import defaultdict

import yaml
from wcmatch import glob as wg

GLOB_FLAGS = wg.GLOBSTAR | wg.DOTGLOB

REPO = pathlib.Path(__file__).resolve().parent.parent

for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8", errors="replace")

# Extensions that cannot carry a coding convention, so their absence from
# the payload is not a gap: images, binaries, fonts, archives, signing
# material. Kept short on purpose -- anything genuinely arguable (.csv,
# .toml, .xml) stays in the uncovered list where a person decides, rather
# than being filtered into invisibility by a list nobody re-reads.
NON_TEXT = {
    ".png", ".jpg", ".jpeg", ".gif", ".ico", ".svg", ".ai", ".pdf",
    ".dll", ".exe", ".pdb", ".zip", ".7z", ".gz", ".woff", ".woff2",
    ".ttf", ".otf", ".mp4", ".webp", ".bin", ".snk", ".pfx",
}


def frontmatter(path: pathlib.Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="replace")
    if not text.startswith("---"):
        return {}
    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}
    try:
        return yaml.safe_load(parts[1]) or {}
    except yaml.YAMLError:
        return {}


def load_globs() -> dict[str, list[str]]:
    """Return {label: paths} for every path-scoped rule and skill, BOTH trees.

    Unlike activation-expect.py's loader this is not scoped to the probe
    groups: coverage is a question about the whole payload, including the
    workflow group and the project-scope skills, and whether a given skill
    is currently deployed to user scope does not change what it covers.
    """
    globs: dict[str, list[str]] = {}
    for p in sorted((REPO / "claude" / "rules").glob("*.md")):
        meta = frontmatter(p)
        if meta.get("paths"):
            globs[f"{p.stem} (rule)"] = meta["paths"]
    for pattern in ("skills/*/*/SKILL.md", ".claude/skills/*/SKILL.md"):
        for p in sorted(REPO.glob(pattern)):
            meta = frontmatter(p)
            if meta.get("paths"):
                label = meta.get("name", p.parent.name)
                globs[f"{label} (skill)"] = meta["paths"]
    return globs


def tracked_files(repo: pathlib.Path, exclude: list[str]) -> list[str] | None:
    """Return the repo's tracked paths, or None if it is not a git repo."""
    result = subprocess.run(
        ["git", "-C", str(repo), "ls-files"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None
    files = [f for f in result.stdout.split("\n") if f.strip()]
    if exclude:
        files = [f for f in files
                 if not wg.globmatch(f, exclude, flags=GLOB_FLAGS)]
    return files


def matches(rel_posix: str, globs: dict[str, list[str]]) -> set[str]:
    return {label for label, pats in globs.items()
            if wg.globmatch(rel_posix, pats, flags=GLOB_FLAGS)}


def summarize(labels: set[str], cap: int = 4) -> str:
    """Join matcher names, truncated -- a .json file can match 24 of them."""
    names = sorted(labels)
    if len(names) <= cap:
        return ", ".join(names)
    return f"{', '.join(names[:cap])} (+{len(names) - cap} more)"


def report(repo: pathlib.Path, globs: dict[str, list[str]],
           exclude: list[str], by_file: bool) -> dict[str, int]:
    """Print one repo's coverage table. Returns {ext: count} for real gaps."""
    repo = repo.resolve()
    files = tracked_files(repo, exclude)
    if files is None:
        print(f"== {repo}: not a git repository, skipped ==\n")
        return {}
    if not files:
        print(f"== {repo.name}: no tracked files ==\n")
        return {}

    by_ext: dict[str, list[str]] = defaultdict(list)
    for f in files:
        by_ext[pathlib.PurePosixPath(f).suffix.lower() or "(none)"].append(f)

    covered_files = 0
    uncovered: dict[str, int] = {}
    rows = []
    for ext, group in sorted(by_ext.items(), key=lambda kv: -len(kv[1])):
        # Per FILE, never per extension. Counting an extension as covered
        # because ANY of its files match hides the common case: one
        # claude/rules/README.md matching `claude/rules/*.md` made 230
        # uncovered .md files in this very repo read as covered.
        hits: set[str] = set()
        hit_count = 0
        miss = None
        for f in group:
            f_hits = matches(f, globs)
            if f_hits:
                hits |= f_hits
                hit_count += 1
            elif miss is None:
                miss = f
        covered_files += hit_count
        gap = len(group) - hit_count
        if gap == 0:
            rows.append(("  ", ext, len(group), summarize(hits)))
        elif ext in NON_TEXT:
            rows.append(("- ", ext, len(group), "(non-text, no rule expected)"))
        else:
            uncovered[ext] = gap
            note = f"{gap} of {len(group)} uncovered   e.g. {miss}"
            if hits:
                rows.append(("~ ", ext, len(group),
                             f"{note}   partial: {summarize(hits, 3)}"))
            else:
                rows.append(("->", ext, len(group), note))

    pct = 100 * covered_files / len(files)
    print(f"== {repo.name}: {len(files)} files, "
          f"{covered_files} covered ({pct:.0f}%) ==")
    for mark, ext, count, note in rows:
        print(f"{mark}{ext:<12}{count:>6}  {note}")

    if by_file:
        scored = sorted(((len(matches(f, globs)), f) for f in files),
                        reverse=True)
        print("\n  most-matched files:")
        for n, f in scored[:5]:
            print(f"  {n:>3}  {f}")
    print()
    return uncovered


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Report which of a repo's files activate no rule and no skill.")
    ap.add_argument("repos", nargs="+", type=pathlib.Path,
                    help="repo paths, or parent directories with --sweep")
    ap.add_argument("--sweep", action="store_true",
                    help="treat each argument as a parent and scan every repo under it")
    ap.add_argument("--by-file", action="store_true",
                    help="also list the most-matched individual files")
    ap.add_argument("--exclude", action="append", default=[], metavar="GLOB",
                    help="drop matching paths from the scan (repeatable)")
    args = ap.parse_args()

    targets: list[pathlib.Path] = []
    for arg in args.repos:
        if args.sweep:
            if not arg.is_dir():
                print(f"not a directory, skipped: {arg}", file=sys.stderr)
                continue
            targets += sorted(c for c in arg.iterdir()
                              if c.is_dir() and (c / ".git").exists())
        else:
            targets.append(arg)

    globs = load_globs()
    total_globs = sum(len(v) for v in globs.values())
    print(f"payload: {len(globs)} path-scoped rules and skills, "
          f"{total_globs} globs\n")

    totals: dict[str, int] = defaultdict(int)
    for repo in targets:
        found = report(repo, globs, args.exclude, args.by_file)
        for ext, count in found.items():
            totals[ext] += count

    if len(targets) > 1 and totals:
        print("== uncovered across all repos scanned, by weight ==")
        for ext, count in sorted(totals.items(), key=lambda kv: -kv[1]):
            print(f"  {ext:<12}{count:>6}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
