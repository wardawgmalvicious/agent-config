#!/usr/bin/env python3
"""Measure skills as PAIRS: routing integrity, trigger overlap, co-activation.

Every other checker here looks at one skill, or one file, at a time --
lint-frontmatter.py caps a description, payload-coverage.py asks what matches
a file, skill-telemetry.py asks whether a skill was listed and used. But
consolidation is a property of a pair, the way a name collision is: neither
file is wrong on its own. This asks the pairwise questions.

    routing        a skill names a skill that is not installed
    overlap        two descriptions half-match the same request
    coactivation   two conditional skills whose globs always fire together

ROUTING IS THE ONLY ONE THAT IS A BUG BY DEFAULT, and only in a description.
A description naming a missing skill strands the request at the surface
triggers are matched against, so that exits non-zero and can gate a commit.
The same name in prose is weaker -- a body may legitimately discuss a skill
that was deliberately not installed -- so body hits are reported and never
fail. Upstream shipped exactly this fix in microsoft/skills-for-fabric
0.3.14, where three skills "pointed you at skills that no longer exist".

The signal is only as good as its allowlist, because most prefixed names in
this payload are not skills at all: MCP servers, rules, CLIs, GitHub repos,
drift-audit source ids, and names this repo's own catalog invents to explain
a name it did NOT choose. On 2026-09-15 that was 17 of 19 raw hits. So the
allowlist is DERIVED wherever a machine source exists (see allowlist()) and
hand-kept only where none does -- a list that grows by hand is a list that
goes stale silently, which is the failure this whole script is about.

Usage:
    uv run --with pyyaml python scripts/skill-overlap.py routing
    uv run --with pyyaml python scripts/skill-overlap.py overlap
    uv run --with pyyaml python scripts/skill-overlap.py overlap --skill NAME
    uv run --with pyyaml python scripts/skill-overlap.py overlap --usage
    uv run --with pyyaml --with wcmatch python scripts/skill-overlap.py
        coactivation C:/Repos/Personal/some-repo

Add --json to any subcommand. NO OUTPUT LINE RECOMMENDS DELETING ANYTHING --
the same contract skill-telemetry.py's verdict() keeps. Rarely used is not
unused, and two skills overlapping is a question for a person.
"""

from __future__ import annotations

import argparse
import json
import math
import pathlib
import re
import subprocess
import sys

import _skill_inventory
from _skill_inventory import REPO

for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8", errors="replace")

# The namespace prefixes this payload gives platform skills. A behavioural
# skill (commit, learn, land) is named as the verb you invoke and has no
# prefix, so it cannot be recognised in prose without matching every English
# word -- routing integrity is therefore a platform-skill check by
# construction, not by choice.
PREFIXES = ("fabric", "pbir", "pbid", "pbip", "powerbi")
NAME_RE = re.compile(r"`((?:" + "|".join(PREFIXES) + r")-[a-z0-9-]+)`")

# Trees scanned for prose mentions. claude/rules/ is in scope because a rule
# can route to a skill; claude/CLAUDE.md is not, because it deliberately
# names things that are not skills.
SCAN_ROOTS = ("skills", ".claude/skills", "claude/rules")

# skills/README.md is the catalog index, and its bullets explain names this
# repo considered and rejected -- `fabric-pipeline`, `fabric-reflex`,
# `fabric-governance`, and the SINGULAR `fabric-deployment-pipeline` against
# the plural skill that exists. One more arrives with every authoring run, so
# listing them would be a hand-kept allowlist that grows forever. Excluded by
# path instead: a README routes a human, not a request, so it is not a
# routing surface. A stale link here is a broken link, and that is a
# different check.
EXCLUDED_PATHS = ("skills/README.md",)

# Names with no machine source. Kept deliberately short, and grouped so that
# a reader can tell whether a new entry belongs here at all -- if it has a
# source, derive it in allowlist() instead of adding a line.
HAND_ALLOWLIST = {
    # CLIs
    "powerbi-desktop": "CLI",
    "powerbi-report-author": "CLI",
    # Upstream skill BUNDLES, not skills. Two of these now, so this is a
    # class rather than the one-off it was first taken for.
    "fabric-skills": "upstream bundle",
    "powerbi-authoring": "upstream bundle",
    # GitHub repositories referred to by bare name in prose.
    "powerbi-docs": "GitHub repo",
    "powerbi-docs-powershell": "GitHub repo",
    "fabric-toolbox": "GitHub repo",
}

# A missing skill that is missing ON PURPOSE. The pair was vendored from
# upstream in 1fa3061 (2026-08-25) with the note "The largely-overlapping
# planning and management skills were not vendored", and each skill's own
# Local vendoring note routes to pbir-report-workflow instead. Vendoring
# them now would put two descriptions on one request, which is precisely what
# `overlap` exists to flag -- so the override stays and the gate must not
# fail on it. Editing the vendored description text is not an alternative:
# the note says to re-apply only that section on re-sync, so a description
# edit is silently lost the next time upstream is pulled.
ACCEPTED = {
    "powerbi-report-planning": "not vendored on purpose (1fa3061); see Local vendoring note",
    "powerbi-report-management": "not vendored on purpose (1fa3061); see Local vendoring note",
}


def _rel(p: pathlib.Path) -> str:
    return p.relative_to(REPO).as_posix()


def allowlist() -> dict[str, str]:
    """Prefixed names that are legitimately not skills, with where each came from.

    Derived wherever a machine source exists, so a new rule, MCP server or
    drift-audit source needs no edit here. Only HAND_ALLOWLIST is kept by
    hand, and only because those three classes have no such source.
    """
    out = {name: f"hand list ({why})" for name, why in HAND_ALLOWLIST.items()}

    for p in sorted((REPO / "claude" / "rules").glob("*.md")):
        out.setdefault(p.stem, "rule")

    # MCP server names, from the templates this repo deploys and from its own
    # project-scope config. `fabric-kqlendpoint` reaches the allowlist this
    # way rather than by hand. glob("*.json") does not match a leading dot on
    # Windows or POSIX, and both templates are dotfiles, so they are globbed
    # explicitly.
    mcp_files = list((REPO / "claude" / "mcp").glob("*.json"))
    mcp_files += list((REPO / "claude" / "mcp").glob(".*.json"))
    mcp_files += [REPO / ".mcp.json"]
    for f in mcp_files:
        if not f.is_file():
            continue
        try:
            data = json.loads(f.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            continue
        for server in data.get("mcpServers") or {}:
            out.setdefault(server, "MCP server")

    # drift-audit source ids, from the `### <id>` headings in its registry.
    sources = REPO / ".claude/skills/drift-audit/references/sources.md"
    if sources.is_file():
        for sid in re.findall(
            r"^### `([a-z0-9-]+)`", sources.read_text(encoding="utf-8"), re.M
        ):
            out.setdefault(sid, "drift-audit source id")

    return out


def _body(path: pathlib.Path) -> str:
    """File text with any frontmatter block removed.

    Frontmatter is scanned separately and per field, so leaving it here would
    report every description hit twice -- once as the bug it is and once as a
    body mention that does not fail.
    """
    text = path.read_text(encoding="utf-8", errors="replace")
    if not text.startswith("---"):
        return text
    end = text.find("\n---", 3)
    return text if end == -1 else text[end + 4 :]


def _scan_files() -> list[pathlib.Path]:
    out = []
    for root in SCAN_ROOTS:
        for p in sorted((REPO / root).rglob("*.md")):
            if _rel(p) not in EXCLUDED_PATHS:
                out.append(p)
    return out


def cmd_routing(args) -> int:
    inv = _skill_inventory.skills()
    known = {s.name for s in inv}
    allowed = allowlist()

    def classify(name):
        if name in known or name in allowed:
            return None
        return "accepted" if name in ACCEPTED else "unknown"

    # Hits in the SURFACE TRIGGERS ARE MATCHED AGAINST. These are the ones
    # that can fail a commit.
    surface = []
    for s in inv:
        for field in ("description", "when_to_use"):
            for name in sorted(set(NAME_RE.findall(getattr(s, field)))):
                kind = classify(name)
                if kind:
                    surface.append(
                        {
                            "name": name,
                            "kind": kind,
                            "skill": s.name,
                            "field": field,
                            "file": s.rel,
                        }
                    )

    # Hits in prose. Reported, never failed.
    body = []
    for p in _scan_files():
        for i, line in enumerate(_body(p).splitlines(), 1):
            for name in sorted(set(NAME_RE.findall(line))):
                kind = classify(name)
                if kind:
                    body.append(
                        {"name": name, "kind": kind, "file": _rel(p), "line": i}
                    )

    failures = [h for h in surface if h["kind"] == "unknown"]

    if args.json:
        print(
            json.dumps(
                {"surface": surface, "body": body, "failures": len(failures)},
                indent=2,
            )
        )
        return 1 if failures else 0

    print(f"{len(inv)} skills on disk, {len(allowed)} allowlisted non-skill names")
    print()

    if failures:
        print("FAIL -- a description routes to a skill that is not installed:")
        for h in failures:
            print(f"  {h['file']} ({h['field']}) -> `{h['name']}`")
        print()

    accepted = [h for h in surface if h["kind"] == "accepted"]
    if accepted:
        print("Accepted overrides in descriptions (not failures):")
        for h in accepted:
            print(f"  {h['skill']} ({h['field']}) -> `{h['name']}`")
            print(f"      {ACCEPTED[h['name']]}")
        print()

    if body:
        print("Prose mentions of names that are not installed skills:")
        for h in body:
            print(f"  {h['file']}:{h['line']}: `{h['name']}`  [{h['kind']}]")
        print()

    if not failures:
        print("PASS -- every description routes to a skill that exists.")
    print()
    print("A description hit fails; a prose hit never does -- a body may")
    print("discuss a skill that was deliberately not installed.")
    return 1 if failures else 0


# Words too common across this payload's descriptions to distinguish two
# skills. Deliberately small: an aggressive stoplist hides the product nouns
# that are the whole signal, and inverse document frequency already discounts
# anything that appears everywhere.
STOPWORDS = {
    "the", "and", "for", "use", "when", "with", "that", "this", "not", "its",
    "from", "into", "onto", "over", "each", "one", "two", "are", "was", "has",
    "have", "than", "then", "them", "they", "you", "your", "what", "which",
    "how", "why", "who", "whom", "does", "doing", "done", "can", "cannot",
    "will", "would", "should", "may", "might", "must", "but", "only", "also",
    "any", "all", "every", "some", "more", "most", "less", "least", "other",
    "another", "same", "such", "per", "via", "out", "off", "down",
    "asked", "asking", "ask", "using", "used", "run", "runs", "running",
    "skill", "skills", "been", "being",
    # Function words the list above missed.
    "before", "after", "instead", "rather", "without", "already", "still",
    "never", "always", "whether", "because", "since", "while", "during",
    "both", "either", "neither", "once", "yet", "here", "there", "where",
    # VOCABULARY ABOUT INVOKING A SKILL rather than about its subject. Every
    # description carries some of this, because every description is written
    # to say when to reach for the thing -- so it distinguishes nothing, and
    # left in it ranks cross-domain pairs above real ones. Measured
    # 2026-09-15: drift-update and powerbi-report-authoring scored 10.28 on
    # `verify, edit, brief, first, user` alone, above four of the five pbir-*
    # skills that genuinely compete with powerbi-report-authoring.
    "verify", "verifies", "verified", "validate", "validates", "validated",
    "check", "checks", "checking", "edit", "edits", "editing",
    "write", "writes", "writing", "written", "brief", "briefs",
    "first", "next", "last", "user", "users", "request", "requests",
    "want", "wants", "need", "needs", "session", "sessions",
}


def distinctive_tokens(s: _skill_inventory.Skill) -> set[str]:
    """Tokens from the routing text, with backticked and quoted terms kept whole.

    Deterministic and dependency-free ON PURPOSE. An embedding score cannot be
    re-run and reviewed the way this can, and the output here is a ranked list
    for a person rather than a verdict.
    """
    text = f"{s.description} {s.when_to_use}"
    toks: set[str] = set()
    for m in re.findall(r"`([^`]{2,60})`", text):
        toks.add("`" + m.strip().lower() + "`")
    for m in re.findall(r"'([^']{3,60})'", text) + re.findall(r'"([^"]{3,60})"', text):
        toks.add("'" + m.strip().lower() + "'")
    for w in re.findall(r"[A-Za-z][A-Za-z0-9-]{2,}", text):
        w = w.lower()
        if w not in STOPWORDS:
            toks.add(w)
    return toks


def _usage_by_name() -> dict[str, dict]:
    """skill-telemetry.py coverage --json, joined by name.

    Shelled out rather than imported: a hyphen in that filename makes it
    un-importable. sys.executable is reused so this inherits the interpreter
    that already has pyyaml, instead of shelling back out through uv.
    """
    try:
        r = subprocess.run(
            [
                sys.executable,
                str(REPO / "scripts" / "skill-telemetry.py"),
                "coverage",
                "--json",
            ],
            capture_output=True,
            text=True,
            timeout=300,
        )
        rows = json.loads(r.stdout)["rows"]
    except (OSError, subprocess.SubprocessError, ValueError, KeyError):
        return {}
    return {row["skill"]: row for row in rows}


USAGE_CAVEATS = (
    "Telemetry is THIS MACHINE ONLY. Platform skills have been pruned from\n"
    "user scope here since 2026-08-31, and they reach teammates through\n"
    "copy-copilot.ps1, where no transcript exists. Most LISTED-NEVER-CHOSEN\n"
    "listings predate that prune. A `proj` row is counted against this\n"
    "repo's sessions alone -- never compare `listed` across scopes.\n"
    "Rarely used is not unused, and nothing here says delete."
)


def cmd_overlap(args) -> int:
    inv = _skill_inventory.skills()
    toks = {s.name: distinctive_tokens(s) for s in inv}
    by_name = {s.name: s for s in inv}
    n = len(inv)

    df: dict[str, int] = {}
    for t in toks.values():
        for tok in t:
            df[tok] = df.get(tok, 0) + 1
    # A token in one skill only cannot be shared, so it never scores; one in
    # every skill scores ~0. The weight is what makes "eventstream" count for
    # more than "data".
    weight = {tok: math.log(n / d) for tok, d in df.items()}

    pairs = []
    names = sorted(by_name)
    for i, a in enumerate(names):
        for b in names[i + 1 :]:
            shared = toks[a] & toks[b]
            if not shared:
                continue
            score = sum(weight[t] for t in shared)
            if score < args.floor:
                continue
            ca, cb = by_name[a].conditional, by_name[b].conditional
            # Overlap between a conditional and an unconditional skill is
            # ASYMMETRIC and the report has to say so: the conditional one
            # competes only after a matching Read, while the other is in
            # every listing. Two unconditional skills compete every time.
            if ca and cb:
                shape = "both conditional"
            elif ca or cb:
                shape = "asymmetric (one conditional)"
            else:
                shape = "both always listed"
            pairs.append(
                {
                    "a": a,
                    "b": b,
                    "score": round(score, 2),
                    "shape": shape,
                    "shared": sorted(shared, key=lambda t: -weight[t])[:8],
                }
            )

    pairs.sort(key=lambda p: -p["score"])
    if args.skill:
        pairs = [p for p in pairs if args.skill in (p["a"], p["b"])]
    pairs = pairs[: args.top]

    usage = _usage_by_name() if args.usage else {}

    if args.json:
        for p in pairs:
            if usage:
                p["usage"] = {k: usage.get(k, {}) for k in (p["a"], p["b"])}
        print(json.dumps({"skills": n, "pairs": pairs}, indent=2))
        return 0

    scope = f" for {args.skill}" if args.skill else ""
    print(f"{n} skills, {len(pairs)} pairs shown{scope} (score floor {args.floor})")
    print()
    for p in pairs:
        print(f"{p['score']:>7.2f}  {p['a']} + {p['b']}   [{p['shape']}]")
        print(f"         shared: {', '.join(p['shared'])}")
        for k in (p["a"], p["b"]) if usage else ():
            u = usage.get(k)
            if u:
                # A conditional skill is withheld from the startup listing by
                # design, so `listed 0` is expected rather than a finding.
                # Saying so on the line is cheaper than hoping the legend is
                # read -- conflating the two is the error that produced this
                # repo's one retracted telemetry finding.
                cond = ", conditional" if by_name[k].conditional else ""
                print(
                    f"         {k}: listed {u['listed_in']}"
                    f" of {u['sessions_possible']} ({u['scope']}{cond})"
                )
    print()
    print("Score is summed inverse-document-frequency of shared distinctive")
    print("tokens -- deterministic, so it can be re-run and reviewed. A high")
    print("score is a question for a person, not a verdict, and nothing here")
    print("recommends deleting or merging anything.")
    if usage:
        print()
        print(USAGE_CAVEATS)
    return 0


def cmd_coactivation(args) -> int:
    flags = _skill_inventory.glob_flags()
    from wcmatch import glob as wg

    inv = [s for s in _skill_inventory.skills() if s.conditional]
    if not inv:
        print("No conditional skills on disk.")
        return 0

    # Skill-skill pairs only. A rule and a skill co-activating is the design
    # -- rules carry conventions, skills carry procedures -- so including
    # those would bury the signal this is looking for.
    hits: dict[str, set[str]] = {s.name: set() for s in inv}
    scanned = 0
    for repo in args.repos:
        r = subprocess.run(
            ["git", "-C", str(repo), "ls-files"], capture_output=True, text=True
        )
        if r.returncode != 0:
            print(f"skipped (not a git repo): {repo}", file=sys.stderr)
            continue
        for f in r.stdout.splitlines():
            if not f:
                continue
            scanned += 1
            key = f"{repo}::{f}"
            for s in inv:
                if wg.globmatch(f, s.paths, flags=flags):
                    hits[s.name].add(key)

    rows = []
    names = sorted(n for n in hits if hits[n])
    for i, a in enumerate(names):
        for b in names[i + 1 :]:
            both = hits[a] & hits[b]
            if not both:
                continue
            # A subset relation is the strong finding: if every file matching
            # A also matches B, the harness never sees A apart from B.
            # Identical sets are reported as their own case rather than as a
            # subset either way round -- "A is a subset of B" sends a reader
            # looking for the files where B fires alone, and there are none.
            if hits[a] == hits[b]:
                rel = f"{a} and {b} match an IDENTICAL set"
            elif hits[a] < hits[b]:
                rel = f"{a} is a SUBSET of {b}"
            elif hits[b] < hits[a]:
                rel = f"{b} is a SUBSET of {a}"
            else:
                rel = "partial"
            rows.append(
                {
                    "a": a,
                    "b": b,
                    "both": len(both),
                    "a_total": len(hits[a]),
                    "b_total": len(hits[b]),
                    "relation": rel,
                }
            )
    rows.sort(key=lambda r: -r["both"])

    if args.json:
        print(json.dumps({"files_scanned": scanned, "pairs": rows}, indent=2))
        return 0

    print(f"{scanned} tracked files scanned across {len(args.repos)} repo(s)")
    print(f"{len(names)} conditional skills matched something")
    print()
    for r in rows:
        noun = "file " if r["both"] == 1 else "files"
        print(
            f"{r['both']:>5} {noun}  {r['a']} ({r['a_total']})"
            f" + {r['b']} ({r['b_total']})   {r['relation']}"
        )
    if not rows:
        print("No conditional skill pair matched the same file.")
    print()
    print("A subset relation means the harness never sees that skill apart")
    print("from the other one. That is a question about the globs, not a")
    print("recommendation to remove either skill.")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("routing", help="a skill names a skill that is not installed")
    p.add_argument("--json", action="store_true")
    p.set_defaults(fn=cmd_routing)

    p = sub.add_parser("overlap", help="two descriptions half-match one request")
    p.add_argument("--json", action="store_true")
    p.add_argument("--skill", metavar="NAME", help="only pairs involving this skill")
    p.add_argument("--top", type=int, default=25, help="pairs to show (default 25)")
    p.add_argument("--floor", type=float, default=8.0, help="minimum score")
    p.add_argument(
        "--usage", action="store_true", help="join skill-telemetry.py coverage by name"
    )
    p.set_defaults(fn=cmd_overlap)

    p = sub.add_parser(
        "coactivation", help="conditional skills whose globs fire together"
    )
    p.add_argument("repos", nargs="+", type=pathlib.Path)
    p.add_argument("--json", action="store_true")
    p.set_defaults(fn=cmd_coactivation)

    args = ap.parse_args()
    return args.fn(args)


if __name__ == "__main__":
    sys.exit(main())
