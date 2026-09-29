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

PORTS MODE (--ports) asks the narrower question scripts/copy-copilot.ps1
needs answered: which Copilot instruction ports in copilot/instructions/
can apply in a repo. Each argument is then a Copilot directory, normally a
repo's .github, as that script's -CopilotDir is. A port is selected when
its applyTo, split on commas, matches at least one tracked file of the
repo holding that directory, leaving out the directory's own skills/ and
instructions/: those are that script's output, so a vendored skill that
shipped a .py would otherwise select the Python port wherever it went.
applyTo alone does not scope a port, because VS Code lists every available
instructions file in each agent request, matched or not; the ledger entry
of 2026-09-29 in docs/evidence/root-claude-md.md has the measurement.

The matcher errs toward shipping, and that is the safe side. DOTGLOB lets
`*` and `**` match a leading dot, which VS Code's glob does not
(claude/rules/vscode-scoping.md), so a port can be selected for a file
Copilot would never apply it to. A wrong match costs one listed entry; a
wrong miss would withhold a port that applies. A directory outside any git
repo, or in one with no tracked files left, has nothing to match against,
so every port is selected and the report says why.

Where the directory already holds instructions/.managed-instructions.json,
the report audits it too: ports it carries that match nothing, and ports
that match but are not carried. Only a copy-copilot.ps1 run changes either.

Usage:
    uv run --with pyyaml --with wcmatch python scripts/payload-coverage.py
        [--sweep] [--by-file] [--exclude GLOB]... REPO...
    uv run --with pyyaml --with wcmatch python scripts/payload-coverage.py
        --ports [--json] [--sweep] [--exclude GLOB]... COPILOT_DIR...

Examples, run from this repo's root ("..." is the first one's prefix):

    uv run --with pyyaml --with wcmatch python scripts/payload-coverage.py
        C:/Repos/Client/some-repo
    One repo's coverage table, by extension. Run it before starting work
    in a repo the payload has never seen.

    ... C:/Repos/Client/some-repo C:/Repos/Personal/other-repo
    Each repo's table, then one "uncovered across all repos scanned" total
    ranked by file count: the list to pick the next rule from.

    ... --sweep C:/Repos/Personal C:/Repos/Client
    Every git repo directly under each parent (one level, not recursive),
    with the same cross-repo total.

    ... C:/Repos/Client/some-repo
        --exclude "**/*.lock" --exclude "**/*.example"
    Drop generated and placeholder files, so they neither pad the file
    count nor list as gaps. Globs are repo-relative and match the way
    coverage does, so "**/" also matches the root: "**/*.lock" drops
    uv.lock.

    ... C:/Repos/Client/some-repo --exclude "tests/**"
    Coverage of the shipped code alone.

    ... C:/Repos/Client/some-repo --by-file
    Also list the five files the most rules and skills match. A 1 beside
    every one means no file draws overlapping guidance.

    ... --ports C:/Repos/Client/some-repo/.github
    The Copilot instruction ports copy-copilot.ps1 would ship there, each
    with its matching file count, then an audit of the ports that repo
    already carries. With --sweep, every repo's .github under each parent.
    --json prints the form copy-copilot.ps1 reads.

    uv run --no-project --with pyyaml --with wcmatch python
        C:/Repos/Personal/agent-config/scripts/payload-coverage.py .
    From inside the target repo: the payload is found from this script's
    own location, so only the paths change. Keep --no-project there, or
    a repo with a pyproject.toml has its own .venv synced first.

Reading the report: one row per extension, most files first.
    (blank)  every file is covered; the matching rules and skills follow
    ~        some are covered; one uncovered file is shown
    ->       none is covered; one is shown as "e.g."
    -        non-text (image, binary, font, archive, key): no rule expected
(none) holds extensionless files and dotfiles: Dockerfile, .gitignore.
In --ports mode, one row per port: "ship" or "hold", then its file count.
"""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import subprocess
import sys
from collections import defaultdict

import yaml
from wcmatch import glob as wg

GLOB_FLAGS = wg.GLOBSTAR | wg.DOTGLOB

REPO = pathlib.Path(__file__).resolve().parent.parent
PORTS = REPO / "copilot" / "instructions"
# What copy-copilot.ps1 writes under its target, so never evidence that a
# port applies there.
PAYLOAD_DIRS = ("skills", "instructions")
PORT_MANIFEST = pathlib.PurePath("instructions", ".managed-instructions.json")

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


def load_ports() -> dict[str, list[str]]:
    """Return {port name: applyTo globs} for every Copilot instruction port.

    applyTo is one comma-separated string, as lint-instructions.py enforces.
    A port without one would match nothing and so be silently withheld
    everywhere, which is exactly the failure this mode exists to prevent:
    stop instead.
    """
    ports: dict[str, list[str]] = {}
    for p in sorted(PORTS.glob("*.instructions.md")):
        apply_to = frontmatter(p).get("applyTo")
        if not isinstance(apply_to, str) or not apply_to.strip():
            raise SystemExit(f"error: {p.name} has no applyTo string; "
                             "run scripts/lint-instructions.py")
        ports[p.name.removesuffix(".instructions.md")] = [
            g.strip() for g in apply_to.split(",") if g.strip()]
    if not ports:
        raise SystemExit(f"error: no *.instructions.md in {PORTS}")
    return ports


def locate(target: pathlib.Path) -> tuple[pathlib.Path, str] | None:
    """Return (repo root, target's repo-relative prefix), or None outside git.

    The target need not exist yet, since copy-copilot.ps1 creates it, so git
    is asked from the nearest directory that does, and the missing tail is
    added to the prefix git reports ("" at the root, else ".github/").
    """
    probe, tail = target, []
    while not probe.is_dir():
        if probe.parent == probe:
            return None
        tail.insert(0, probe.name)
        probe = probe.parent
    result = subprocess.run(
        ["git", "-C", str(probe), "rev-parse", "--show-toplevel", "--show-prefix"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None
    top, prefix = (result.stdout.split("\n") + ["", ""])[:2]
    return pathlib.Path(top), prefix + "".join(f"{part}/" for part in tail)


def read_port_manifest(target: pathlib.Path) -> list[str] | None:
    """Return the ports copy-copilot.ps1 recorded at the target, or None."""
    path = target / PORT_MANIFEST
    if not path.is_file():
        return None
    try:
        names = json.loads(path.read_text(encoding="utf-8")).get("instructions") or []
    except (json.JSONDecodeError, AttributeError) as exc:
        print(f"warning: {path} is not a readable manifest: {exc}", file=sys.stderr)
        return None
    return [n["name"] if isinstance(n, dict) else n for n in names]


def port_selection(target: pathlib.Path, ports: dict[str, list[str]],
                   exclude: list[str]) -> dict:
    """Work out which ports ship to one Copilot directory, and audit it."""
    target = pathlib.Path(os.path.abspath(target))
    entry: dict = {"target": str(target), "repo": None, "files": 0,
                   "excluded": 0, "matchable": True, "reason": "",
                   "ports": [], "select": [], "manifest": read_port_manifest(target)}
    located = locate(target)
    files: list[str] = []
    if located is None:
        entry["matchable"] = False
        entry["reason"] = "not inside a git repository, so nothing to match against"
    else:
        repo, prefix = located
        entry["repo"] = str(repo)
        tracked = tracked_files(repo, exclude) or []
        own = tuple(f"{prefix}{d}/" for d in PAYLOAD_DIRS)
        files = [f for f in tracked if not f.startswith(own)]
        entry["files"], entry["excluded"] = len(files), len(tracked) - len(files)
        if not files:
            entry["matchable"] = False
            entry["reason"] = "no tracked files outside the target's own payload"
    for name, globs in ports.items():
        hits = [f for f in files if wg.globmatch(f, globs, flags=GLOB_FLAGS)]
        entry["ports"].append({"name": name, "files": len(hits),
                               "example": hits[0] if hits else None})
        if hits or not entry["matchable"]:
            entry["select"].append(name)
    return entry


def print_ports(entry: dict) -> None:
    """Print one target's selection, then audit the ports it already carries."""
    if entry["repo"] is None:
        print(f"== {entry['target']}: {entry['reason']}; every port ships ==")
    else:
        print(f"== {entry['target']}: {entry['files']} tracked files, "
              f"{entry['excluded']} left out as the target's own payload ==")
        if not entry["matchable"]:
            print(f"  {entry['reason']}; every port ships")
    for port in entry["ports"]:
        verb = "ship" if port["name"] in entry["select"] else "hold"
        example = f"   e.g. {port['example']}" if port["example"] else ""
        print(f"  {verb}  {port['name']:<22}{port['files']:>5}{example}")
    carried = entry["manifest"]
    if carried is None:
        print(f"  no {PORT_MANIFEST.as_posix()}: no ports vendored here yet")
    else:
        known = {p["name"] for p in entry["ports"]}
        findings = [
            ("carried, matching nothing",
             [n for n in carried if n in known and n not in entry["select"]]),
            ("carried, no longer ported", [n for n in carried if n not in known]),
            ("matching, not carried", [n for n in entry["select"] if n not in carried]),
        ]
        for label, names in findings:
            if names:
                print(f"  audit: {label}: {', '.join(names)}")
        if not any(names for _, names in findings):
            print("  audit: the ports carried here are exactly those that match")
    print()


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Report which of a repo's files activate no rule and no skill.",
        # --help ends with the docstring's examples, as Get-Help -Examples
        # does for link-claude.ps1, so that text must read on its own: no
        # "above" or "below". index(), not find(): a renamed heading should
        # fail loudly rather than print an empty epilog.
        epilog=__doc__[__doc__.index("\nExamples") + 1:],
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("repos", nargs="+", type=pathlib.Path,
                    help="repo paths (Copilot directories with --ports), "
                         "or parent directories with --sweep")
    ap.add_argument("--sweep", action="store_true",
                    help="treat each argument as a parent and scan every repo under it")
    ap.add_argument("--by-file", action="store_true",
                    help="also list the most-matched individual files")
    ap.add_argument("--exclude", action="append", default=[], metavar="GLOB",
                    help="drop matching paths from the scan (repeatable)")
    ap.add_argument("--ports", action="store_true",
                    help="each argument is a Copilot directory: report which "
                         "instruction ports match its repo, and audit its manifest")
    ap.add_argument("--json", action="store_true",
                    help="with --ports, print the selection as JSON, for copy-copilot.ps1")
    args = ap.parse_args()
    if args.json and not args.ports:
        ap.error("--json needs --ports")
    if args.by_file and args.ports:
        ap.error("--by-file has no meaning with --ports")

    targets: list[pathlib.Path] = []
    for arg in args.repos:
        if args.sweep:
            if not arg.is_dir():
                print(f"not a directory, skipped: {arg}", file=sys.stderr)
                continue
            found = sorted(c for c in arg.iterdir()
                           if c.is_dir() and (c / ".git").exists())
            targets += [c / ".github" for c in found] if args.ports else found
        else:
            targets.append(arg)

    if args.ports:
        ports = load_ports()
        entries = [port_selection(t, ports, args.exclude) for t in targets]
        if args.json:
            print(json.dumps(entries, indent=1))
            return 0
        print(f"ports: {len(ports)} Copilot instruction ports\n")
        for entry in entries:
            print_ports(entry)
        return 0

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
