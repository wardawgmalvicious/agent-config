#!/usr/bin/env python
"""Expectation engine for the conditional-activation harness.

Three things must agree about which conditional skills and rules a fixture
file pulls in:

  1. the ``paths:`` globs in ``skills/*/*/SKILL.md`` and ``claude/rules/*.md``
  2. the curated table in ``tests/skills/<set>-triggers/expected_activations.md``
  3. what Claude Code actually loads when the file is opened with ``Read``

``static`` checks 1 against 2 and needs no session. ``check`` compares 3
against 1 by reading a session transcript. ``scripts/test-activation.ps1``
drives both; this file has no side effects and can be run on its own.

Activation is a **per-session cumulative delta**: an attachment names only
what was not already active, for rules as well as skills. So expectations
are computed against the read order actually observed in the transcript
rather than against a read order we asked for -- which keeps the assertion
correct even if the model reads the fixtures out of order or in batches,
and means ``expected_activations.md`` stays a plain per-file table.

Usage:
    uv run --with pyyaml --with wcmatch python scripts/activation-expect.py \
        static --set pbip
    uv run --with pyyaml --with wcmatch python scripts/activation-expect.py \
        check --set pbip --transcript <session>.jsonl --fixtures-root <dir>
"""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import sys

import yaml
from wcmatch import glob as wg

GLOB_FLAGS = wg.GLOBSTAR | wg.DOTGLOB

REPO = pathlib.Path(__file__).resolve().parent.parent

# Fixture rows quote paths elided with U+2026; a cp1252 console would throw
# on the way out and lose the report.
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8", errors="replace")

SETS = {
    "pbip": "tests/skills/pbip-triggers",
    "fabric": "tests/skills/fabric-triggers",
}

# Skill groups the probe must deploy. BOTH are needed for EITHER set:
# the pbip fixtures activate fabric-tmdl* on their .SemanticModel files,
# and the fabric set's headline negative assertion -- that
# pbip-project-structure must NOT fire on SampleNB.Notebook/.platform --
# is vacuous unless pbip-project-structure is actually deployed.
PROBE_GROUPS = ("fabric", "powerbi")


# --------------------------------------------------------------------------
# payload


def load_skills():
    """{name: paths} for conditional skills, plus the unconditional names."""
    conditional, unconditional = {}, []
    for p in sorted(REPO.glob("skills/*/*/SKILL.md")):
        if p.parts[len(REPO.parts)] != "skills":
            continue
        group = p.relative_to(REPO).parts[1]
        if group not in PROBE_GROUPS:
            continue
        meta = yaml.safe_load(p.read_text(encoding="utf-8").split("---", 2)[1])
        if meta.get("paths"):
            conditional[meta["name"]] = meta["paths"]
        else:
            unconditional.append(meta["name"])
    return conditional, sorted(unconditional)


def load_rules():
    """{filename.md: paths} for every path-scoped rule."""
    rules = {}
    for p in sorted((REPO / "claude" / "rules").glob("*.md")):
        text = p.read_text(encoding="utf-8")
        if not text.startswith("---"):
            continue
        meta = yaml.safe_load(text.split("---", 2)[1]) or {}
        if meta.get("paths"):
            rules[p.name] = meta["paths"]
    return rules


def predict(rel_posix: str, globs: dict[str, list[str]]) -> set[str]:
    return {n for n, pats in globs.items()
            if wg.globmatch(rel_posix, pats, flags=GLOB_FLAGS)}


# --------------------------------------------------------------------------
# fixtures and the contract table


def fixture_files(set_name: str) -> list[str]:
    base = REPO / SETS[set_name] / "fixtures"
    return sorted(f.relative_to(base).as_posix()
                  for f in base.rglob("*") if f.is_file())


def parse_table(set_name: str, files: list[str]) -> tuple[dict, list[str]]:
    """Parse expected_activations.md into {fixture_rel: {skills}}.

    Rows elide long paths with a leading U+2026, so a row is resolved by
    unique suffix match against the real fixture list rather than by
    reconstructing the prefix. An ambiguous or unmatched row is an error --
    silently dropping it would turn a contract row into a passing test.
    """
    md = REPO / SETS[set_name] / "expected_activations.md"
    table, errors = {}, []
    in_table = False
    for raw in md.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line.startswith("|"):
            in_table = False
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) < 2:
            continue
        if cells[0].lower().startswith("fixture file"):
            # Both files carry a second "Fixture file" table under "Rules
            # load here too", whose rows are prose summaries rather than
            # fixture paths. Only the skills table is the contract here.
            in_table = cells[1].lower().startswith("activates")
            continue
        if not in_table or set(cells[0]) <= set("- :"):
            continue

        name = cells[0].replace("**", "").replace("`", "").strip()
        suffix = name.lstrip("…").lstrip("/")
        hits = [f for f in files if f == suffix or f.endswith("/" + suffix)]
        if len(hits) != 1:
            errors.append(
                f"table row {name!r} matched {len(hits)} fixture files "
                f"({hits or 'none'}) -- make the row unambiguous")
            continue

        activates = cells[1].replace("**", "").strip()
        skills = set() if "(none)" in activates else {
            s.strip().strip("`") for s in activates.split(",") if s.strip()
        }
        if hits[0] in table:
            errors.append(f"fixture {hits[0]!r} appears in the table twice")
        table[hits[0]] = skills

    for f in files:
        if f not in table:
            errors.append(f"fixture {f!r} has no row in expected_activations.md")
    return table, errors


# --------------------------------------------------------------------------
# transcript


def read_transcript(path: pathlib.Path):
    records = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line:
            try:
                records.append(json.loads(line))
            except json.JSONDecodeError:
                pass
    return records


def batch_transcript(records, fixtures_root: pathlib.Path, known: list[str]):
    """Group the session into flush groups: reads -> the attachments they produced.

    Attachments are NOT emitted after every read. Claude queues them and
    flushes the batch at some later point, so a run of several reads can be
    followed by one flush covering all of them. A group therefore runs from
    the first read after a flush up to the next flush, and the assertion is
    over the UNION of that group's files. Attributing a flush to the most
    recent read instead makes every activation look one or two reads late.

    Granularity follows the model's own turn shape: when it emits text
    between reads it tends to flush per read, giving per-file resolution;
    when it chains reads silently a group can cover many files, and an
    activation can then only be attributed to the group. cmd_check reports
    which happened.

    Paths are matched case-insensitively (Windows) but resolved back to the
    fixture's on-disk casing: the globs themselves ARE case-sensitive, so a
    lowercased path would silently stop matching `**/*.Report/.platform`
    and turn a working glob into a reported failure.
    """
    # realpath, not abspath: $env:TEMP hands out the 8.3 short form
    # (C:\Users\<USER>~1\...) while Claude records the long one, and a plain
    # string prefix test then rejects every read as "outside the root".
    root = os.path.realpath(str(fixtures_root))
    canon = {f.lower(): f for f in known}
    startup = {"skills": [], "present": False}
    batches = []
    cur = None
    flushed = False

    def new_group():
        g = {"files": [], "outside": [], "bad_tools": [],
             "skills": set(), "rules": set()}
        batches.append(g)
        return g

    for rec in records:
        rtype = rec.get("type")

        if rtype == "assistant":
            calls = [c for c in rec.get("message", {}).get("content", [])
                     if c.get("type") == "tool_use"]
            if not calls:
                continue
            # A read arriving after a flush opens the next group; reads that
            # follow one another with no flush in between stay in this one.
            if cur is None or flushed:
                cur = new_group()
                flushed = False
            for c in calls:
                if c.get("name") != "Read":
                    cur["bad_tools"].append(c.get("name"))
                    continue
                fp = (c.get("input") or {}).get("file_path")
                if not fp:
                    cur["bad_tools"].append("Read(no file_path)")
                    continue
                full = os.path.realpath(fp)
                inside = os.path.normcase(full).startswith(
                    os.path.normcase(root) + os.sep)
                # Slice by length rather than relpath() so the remainder
                # keeps the casing the caller used.
                rel = full[len(root) + 1:].replace(os.sep, "/")
                if inside and rel.lower() in canon:
                    cur["files"].append(canon[rel.lower()])
                else:
                    cur["outside"].append(fp)

        elif rtype == "attachment":
            att = rec.get("attachment") or {}
            atype = att.get("type")
            if atype == "skill_listing" and att.get("isInitial") is True:
                startup["present"] = True
                startup["skills"] = list(att.get("names") or [])
            elif cur is None:
                continue
            elif atype == "skill_listing" and att.get("isInitial") is False:
                cur["skills"].update(att.get("names") or [])
                flushed = True
            elif atype == "nested_memory":
                p = att.get("path")
                if p:
                    cur["rules"].add(pathlib.PurePath(p).name)
                flushed = True

    return startup, batches


# --------------------------------------------------------------------------
# commands


def cmd_static(args) -> int:
    files = fixture_files(args.set)
    skills, _ = load_skills()
    rules = load_rules()
    table, errors = parse_table(args.set, files)

    print(f"Static check: {args.set} ({len(files)} fixtures)\n")
    mismatches = 0
    for f in files:
        got = predict(f, skills)
        want = table.get(f)
        if want is None:
            continue
        rule_hits = sorted(predict(f, rules))
        if got == want:
            print(f"  ok   {f}")
        else:
            mismatches += 1
            print(f"  FAIL {f}")
            print(f"         table: {sorted(want) or '(none)'}")
            print(f"         globs: {sorted(got) or '(none)'}")
        if args.show_rules and rule_hits:
            print(f"         rules: {rule_hits}")

    for e in errors:
        print(f"  ERROR {e}")

    print()
    if mismatches or errors:
        print(f"FAILED - {mismatches} glob/table mismatch(es), "
              f"{len(errors)} table error(s)")
        return 1
    print(f"PASS - globs and expected_activations.md agree on all {len(files)} "
          "fixtures")
    return 0


def cmd_files(args) -> int:
    for f in fixture_files(args.set):
        print(f)
    return 0


def cmd_check(args) -> int:
    files = fixture_files(args.set)
    skills, unconditional = load_skills()
    rules = load_rules()
    fixtures_root = pathlib.Path(args.fixtures_root)

    records = read_transcript(pathlib.Path(args.transcript))
    startup, batches = batch_transcript(records, fixtures_root, files)

    failures: list[str] = []
    print(f"Real-path check: {args.set}")
    print(f"  transcript {args.transcript}")
    print(f"  {len(records)} records, {len(batches)} tool batches\n")

    # -- setup assertions ---------------------------------------------------
    # Trap 1: skills not deployed reports "nothing loaded", which is
    # byte-identical to a broken glob. The startup listing separates them.
    if not startup["present"]:
        failures.append("no initial skill_listing attachment - "
                        "transcript is not a normal session")
    else:
        seen = set(startup["skills"])
        missing = [s for s in unconditional if s not in seen]
        if missing:
            failures.append(
                "skills are NOT deployed to the probe: the startup listing is "
                f"missing {len(missing)} unconditional skill(s) that the "
                f"fabric+powerbi groups should have put there, e.g. "
                f"{missing[:4]}. Every fixture would report 'nothing loaded'.")
        else:
            print(f"  ok  startup listing carries all {len(unconditional)} "
                  "unconditional fabric+powerbi skills (deploy succeeded)")
        leaked = sorted(seen & set(skills))
        if leaked:
            failures.append(
                f"conditional skills present in the STARTUP listing: {leaked}. "
                "They should only arrive on a matching Read.")
        else:
            print(f"  ok  no conditional skill in the startup listing")

    # -- per-batch delta assertions ----------------------------------------
    print()
    active_s: set[str] = set()
    active_r: set[str] = set()
    read: set[str] = set()

    for i, b in enumerate(batches, 1):
        if b["bad_tools"]:
            # A cat/Grep fallback reports exactly what a broken glob does.
            failures.append(
                f"batch {i}: non-Read tool(s) {b['bad_tools']} - pin "
                "--allowedTools Read --disallowedTools Bash PowerShell Glob "
                "Grep Agent. This is a harness failure, NOT 'no activation'.")
        for o in b["outside"]:
            failures.append(f"batch {i}: read outside the fixture root: {o}")
        if not b["files"]:
            continue

        exp_s: set[str] = set()
        exp_r: set[str] = set()
        for f in b["files"]:
            read.add(f)
            exp_s |= predict(f, skills)
            exp_r |= predict(f, rules)

        new_s, new_r = exp_s - active_s, exp_r - active_r
        label = (b["files"][0] if len(b["files"]) == 1
                 else f"{b['files'][0]} (+{len(b['files']) - 1} more in this flush group)")
        ok = new_s == b["skills"] and new_r == b["rules"]
        print(f"  {'ok  ' if ok else 'FAIL'} {label}")
        if not ok:
            if len(b["files"]) > 1:
                for extra in b["files"][1:]:
                    print(f"         also in group: {extra}")
            for kind, want, got in (("skills", new_s, b["skills"]),
                                    ("rules", new_r, b["rules"])):
                if want != got:
                    print(f"         expected new {kind}: {sorted(want) or '(none)'}")
                    print(f"         observed new {kind}: {sorted(got) or '(none)'}")
                    if got - want:
                        print(f"         unexpected: {sorted(got - want)}")
                    if want - got:
                        print(f"         missing:    {sorted(want - got)}")
            failures.append(f"batch {i} ({label}): delta mismatch")

        # Advance by expected|observed so one miss is reported once rather
        # than cascading into every later file that shares the skill.
        active_s |= exp_s | b["skills"]
        active_r |= exp_r | b["rules"]

    unread = [f for f in files if f not in read]
    if unread:
        failures.append(
            f"{len(unread)} fixture(s) never read: {unread[:6]}"
            f"{' ...' if len(unread) > 6 else ''}")

    # Resolution is whatever the model's turn shape gave us. A group holding
    # several files can only attribute an activation to the group, so say so
    # rather than letting a coarse run read as a per-file result.
    multi = [b for b in batches if len(b["files"]) > 1]
    print()
    if multi:
        widest = max(len(b["files"]) for b in multi)
        print(f"  note: {len(read)} reads arrived in "
              f"{len([b for b in batches if b['files']])} flush groups "
              f"({len(multi)} covering several files, widest {widest}). "
              "Activations are asserted per group, not per file.")
    else:
        print(f"  note: per-file resolution - every read flushed on its own.")

    print()
    if failures:
        print(f"FAILED - {len(failures)} problem(s):")
        for f in failures:
            print(f"  - {f}")
        return 1
    print(f"PASS - {len(read)}/{len(files)} fixtures read, every activation "
          "delta matched (skills and rules)")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("static", help="globs vs expected_activations.md")
    p.add_argument("--set", required=True, choices=sorted(SETS))
    p.add_argument("--show-rules", action="store_true")
    p.set_defaults(func=cmd_static)

    p = sub.add_parser("files", help="list fixture files, one per line")
    p.add_argument("--set", required=True, choices=sorted(SETS))
    p.set_defaults(func=cmd_files)

    p = sub.add_parser("check", help="transcript vs globs")
    p.add_argument("--set", required=True, choices=sorted(SETS))
    p.add_argument("--transcript", required=True)
    p.add_argument("--fixtures-root", required=True)
    p.set_defaults(func=cmd_check)

    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
