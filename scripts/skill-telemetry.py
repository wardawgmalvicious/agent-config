#!/usr/bin/env python
"""Post-hoc telemetry for skill effectiveness: what got listed, what got used.

A skill is validated here brief-first and smoke-tested in a fresh session.
That proves *mechanics* -- it loads, it lints, it does the thing when
invoked. It does not prove **triggering**, which only fails in the wild and
never raises an error. Three failure modes look identical from inside a
session:

  * a description that never matches real phrasing,
  * a skill withheld from the listing (conditional, no matching file),
  * a skill that fired but changed nothing.

This script answers the first two from data already on disk. The third has
no clean signal and is deliberately not guessed at.

Four sources disagree, and the disagreements are the point -- so they are
shown side by side rather than averaged:

  ``~/.claude/projects/**/*.jsonl``  the only complete record. Carries the
      per-session skill listing (an ``attachment`` of type ``skill_listing``
      with ``names``, ``skillCount`` and the rendered ``content``), every
      ``Skill`` tool dispatch, every ``<command-name>`` slash expansion, and
      ``attributionSkill`` on each assistant message.
  ``~/.claude.json`` -> ``skillUsage``  per-skill lifetime counter. Counts
      both invocation paths but never resets and cannot be attributed to a
      session.
  ``~/.claude/logs/skills-invoked.log``  the PostToolUse hook. A **floor,
      not a total**: it can only see invocations routed through the ``Skill``
      tool, so a slash run the harness expands inline writes no row.
  ``skills/*/*/SKILL.md``  what exists, and whether it is conditional.

Usage:
    uv run --with pyyaml python scripts/skill-telemetry.py coverage
    uv run --with pyyaml python scripts/skill-telemetry.py listing
    uv run --with pyyaml python scripts/skill-telemetry.py triggers

Add ``--json`` to any subcommand for the same data unrounded and unsorted.
"""

from __future__ import annotations

import argparse
import collections
import json
import os
import pathlib
import re
import sys

import yaml

REPO = pathlib.Path(__file__).resolve().parent.parent
PROJECTS = pathlib.Path(os.path.expanduser("~/.claude/projects"))
CLAUDE_JSON = pathlib.Path(os.path.expanduser("~/.claude.json"))
HOOK_LOG = pathlib.Path(os.path.expanduser("~/.claude/logs/skills-invoked.log"))

for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8", errors="replace")

# A slash expansion writes <command-name>/name</command-name>. The same
# record shape carries built-in CLI commands (/compact, /model, /context),
# so a raw count here would invent skills that do not exist -- every name is
# intersected with the known-skill set before it is reported.
CMD_RE = re.compile(r"<command-name>/?([a-z0-9-]+)</command-name>")

# A non-initial skill_listing attachment is NOT reliably a `paths:` match.
# Editing a SKILL.md hot-reloads that skill and re-announces it, and a
# link-claude run re-announces everything it deployed. Both look exactly
# like an activation. These are the tool calls that mean "reload, not
# activation" when one precedes a delta naming the skill they touched.
RELOAD_TOOLS = ("Edit", "Write", "NotebookEdit")
RELOAD_CMD_RE = re.compile(r"link-claude")

# Flag thresholds. Both exist to stop a *young* skill reading as a dead one:
# a skill authored last week cannot appear in listings from last month, and
# one or two slash runs is not yet evidence that a description never matches.
LISTED_FLOOR = 50
SLASH_FLOOR = 3

# Below this many recorded sessions there is no evidence base, and every
# flag below would fire on *absence of data* rather than on a finding --
# with an empty ~/.claude/projects the rubric otherwise reports every
# conditional skill as never-activated and every unconditional one as
# evidence of listing truncation. Say "too thin" instead: a tool that
# draws confident conclusions from no data is the failure this rubric
# exists to avoid.
MIN_SESSIONS = 20


def skills_on_disk() -> dict[str, dict]:
    """Map skill name -> {group, conditional} from skills/<group>/<name>/."""
    out = {}
    root = REPO / "skills"
    for group in sorted(p for p in root.iterdir() if p.is_dir()):
        for d in sorted(p for p in group.iterdir() if p.is_dir()):
            f = d / "SKILL.md"
            if not f.is_file():
                continue
            text = f.read_text(encoding="utf-8", errors="replace")
            meta = {}
            if text.startswith("---"):
                end = text.find("\n---", 3)
                if end != -1:
                    try:
                        meta = yaml.safe_load(text[3:end]) or {}
                    except yaml.YAMLError:
                        meta = {}
            out[d.name] = {
                "group": group.name,
                # A `paths:` glob withholds the skill from the startup
                # listing, so "never listed" is expected rather than a
                # finding. Conflating the two is exactly the error that
                # produced this repo's one retracted telemetry finding.
                "conditional": bool(meta.get("paths")),
                "desc_chars": len(str(meta.get("description") or ""))
                + len(str(meta.get("when_to_use") or "")),
            }
    return out


def scan_transcripts() -> list[dict]:
    """One record per session transcript. Cheap enough to always run whole.

    Reading every transcript with jq takes minutes on Windows because of
    per-file process startup; in-process this is ~1s for a few hundred
    files, which is why this is Python and not another `instructions-log`
    subcommand.
    """
    sessions = []
    if not PROJECTS.is_dir():
        return sessions
    for path in PROJECTS.rglob("*.jsonl"):
        initial = None
        deltas = []
        attrib = collections.Counter()
        slash = collections.Counter()
        tooluse = collections.Counter()
        # Skill names whose SKILL.md was written, or whose deployment was
        # re-run, earlier in this session -- so a later delta naming them is
        # a reload rather than a glob match.
        reloaded: set[str] = set()
        redeployed = False
        try:
            fh = path.open(encoding="utf-8", errors="replace")
        except OSError:
            continue
        with fh:
            for line in fh:
                # The scan is dominated by JSON parsing, so skip lines that
                # cannot possibly matter before paying for json.loads.
                interesting = (
                    "skill_listing" in line
                    or "attributionSkill" in line
                    or "command-name" in line
                    or '"Skill"' in line
                    or "SKILL.md" in line
                    or "link-claude" in line
                )
                if not interesting:
                    continue
                for name in CMD_RE.findall(line):
                    slash[name] += 1
                try:
                    obj = json.loads(line)
                except (ValueError, TypeError):
                    continue
                att = obj.get("attachment")
                if isinstance(att, dict) and att.get("type") == "skill_listing":
                    rec = {
                        "names": list(att.get("names") or []),
                        "count": att.get("skillCount"),
                        "chars": len(att.get("content") or ""),
                    }
                    if att.get("isInitial") is True:
                        initial = rec
                    else:
                        rec["reload_suspect"] = sorted(
                            n for n in rec["names"] if redeployed or n in reloaded
                        )
                        deltas.append(rec)
                name = obj.get("attributionSkill")
                if name:
                    attrib[name] += 1
                content = (obj.get("message") or {}).get("content")
                if not isinstance(content, list):
                    continue
                for blk in content:
                    if not isinstance(blk, dict) or blk.get("type") != "tool_use":
                        continue
                    tool = blk.get("name")
                    inp = blk.get("input") or {}
                    if tool == "Skill":
                        got = inp.get("skill")
                        if got:
                            tooluse[got] += 1
                    elif tool in RELOAD_TOOLS:
                        fp = str(inp.get("file_path") or "").replace("\\", "/")
                        if fp.endswith("SKILL.md"):
                            reloaded.add(pathlib.PurePosixPath(fp).parent.name)
                    elif tool in ("Bash", "PowerShell"):
                        if RELOAD_CMD_RE.search(str(inp.get("command") or "")):
                            redeployed = True
        sessions.append(
            {
                "path": str(path),
                "project": path.parent.name,
                "initial": initial,
                "deltas": deltas,
                "attrib": dict(attrib),
                "slash": dict(slash),
                "tooluse": dict(tooluse),
            }
        )
    return sessions


def skill_usage() -> dict[str, int]:
    try:
        blob = json.loads(CLAUDE_JSON.read_text(encoding="utf-8", errors="replace"))
    except (OSError, ValueError):
        return {}
    out = {}
    for name, val in (blob.get("skillUsage") or {}).items():
        out[name] = val.get("usageCount", 0) if isinstance(val, dict) else (val or 0)
    return out


def hook_log() -> dict[str, int]:
    counts: collections.Counter = collections.Counter()
    if not HOOK_LOG.is_file():
        return dict(counts)
    # The hook appends with `>>`, which MSYS does not make atomic, so a torn
    # record is possible; drop it rather than losing the whole query.
    for line in HOOK_LOG.read_text(encoding="utf-8", errors="replace").splitlines():
        try:
            counts[json.loads(line)["skill"]] += 1
        except (ValueError, TypeError, KeyError):
            continue
    return dict(counts)


def aggregate(sessions):
    agg = {
        "listed": collections.Counter(),
        "delta": collections.Counter(),
        "delta_clean": collections.Counter(),
        "attrib": collections.Counter(),
        "slash": collections.Counter(),
        "tooluse": collections.Counter(),
    }
    for s in sessions:
        if s["initial"]:
            for n in set(s["initial"]["names"]):
                agg["listed"][n] += 1
        for d in s["deltas"]:
            suspect = set(d.get("reload_suspect") or ())
            for n in d["names"]:
                agg["delta"][n] += 1
                if n not in suspect:
                    agg["delta_clean"][n] += 1
        for key in ("attrib", "slash", "tooluse"):
            for n, c in s[key].items():
                agg[key][n] += c
    return agg


def cmd_coverage(args):
    disk = skills_on_disk()
    sessions = scan_transcripts()
    agg = aggregate(sessions)
    usage, hook = skill_usage(), hook_log()
    nsessions = sum(1 for s in sessions if s["initial"])

    rows = []
    for name in sorted(disk):
        info = disk[name]
        listed = agg["listed"][name]
        chosen = (
            agg["attrib"][name]
            + agg["tooluse"][name]
            + agg["slash"][name]
            + usage.get(name, 0)
        )
        rows.append(
            {
                "skill": name,
                "group": info["group"],
                "conditional": info["conditional"],
                "listed_in": listed,
                "activations": agg["delta_clean"][name],
                "reload_deltas": agg["delta"][name] - agg["delta_clean"][name],
                "slash": agg["slash"][name],
                "skill_tool": agg["tooluse"][name],
                "usage_count": usage.get(name, 0),
                "hook_rows": hook.get(name, 0),
                "flag": verdict(info, listed, chosen, agg, name, nsessions),
            }
        )
    if args.json:
        print(json.dumps({"sessions": nsessions, "rows": rows}, indent=2))
        return
    print(f"{nsessions} sessions with a recorded listing, {len(disk)} skills on disk")
    if nsessions < MIN_SESSIONS:
        print(
            f"\nToo few sessions to flag anything (need {MIN_SESSIONS}). Counts\n"
            "below are real; the flag column is suppressed rather than filled\n"
            "with findings that only reflect missing history.\n"
        )
    else:
        print()
    head = (
        f'{"skill":<38}{"cond":>5}{"listed":>7}{"activ":>6}'
        f'{"slash":>6}{"tool":>5}{"usage":>6}  flag'
    )
    print(head)
    print("-" * len(head))
    for r in rows:
        print(
            f'{r["skill"]:<38}{("y" if r["conditional"] else "-"):>5}'
            f'{r["listed_in"]:>7}{r["activations"]:>6}{r["slash"]:>6}'
            f'{r["skill_tool"]:>5}{r["usage_count"]:>6}  {r["flag"]}'
        )
    print()
    print(legend())


def verdict(info, listed, chosen, agg, name, nsessions):
    """Flags describe evidence, never a recommendation.

    "Zero invocations" is not disuse. A conditional skill withheld all
    session is expected; a rare-but-critical skill is doing its job. So
    nothing here says "delete" -- the flags name which question to ask.
    """
    if nsessions < MIN_SESSIONS:
        return ""
    if info["conditional"]:
        if listed:
            # It carries a glob *now*. Those listings predate the glob --
            # five skills moved unconditional -> conditional in one pass --
            # so this is history, not a live listing cost.
            tail = "; was unconditional then" if chosen == 0 else ""
            return f"conditional now, listed in {listed} earlier sessions{tail}"
        if agg["delta_clean"][name] == 0:
            return "WITHHELD-NEVER-ACTIVATED  glob never matched a Read file"
        return "conditional; activated by path"
    # Unconditional: it is in every listing it can be, so a listing cost is
    # being paid continuously. LISTED_FLOOR keeps a recently authored skill
    # off this flag -- it cannot have accumulated sessions it did not exist for.
    if listed >= LISTED_FLOOR and chosen == 0:
        return f"LISTED-NEVER-CHOSEN  in {listed} listings, never once used"
    if agg["tooluse"][name] == 0 and agg["slash"][name] >= SLASH_FLOOR:
        return "SLASH-ONLY  reached by name only; description never matched"
    return ""


def legend():
    return (
        "cond   = carries a `paths:` glob, so it is withheld from the startup\n"
        "         listing by design. Never-listed is expected, not a finding.\n"
        "activ  = non-initial listing attachments, EXCLUDING those a SKILL.md\n"
        "         write or a link-claude run in the same session can explain.\n"
        "         A raw delta count over-reports badly in this repo.\n"
        "slash  = <command-name> expansions;  tool = Skill-tool dispatches.\n"
        "usage  = ~/.claude.json skillUsage, lifetime, never reset.\n"
        "No flag recommends deleting anything -- see `verdict` in this file."
    )


def cmd_listing(args):
    """Blind spot 2: deployed but not offered, as a standing check."""
    disk = skills_on_disk()
    sessions = scan_transcripts()
    withlisting = [s for s in sessions if s["initial"]]
    by_project: dict[str, dict] = {}
    for s in withlisting:
        cur = by_project.setdefault(
            s["project"], {"n": 0, "max_chars": 0, "max_count": 0, "names": set()}
        )
        cur["n"] += 1
        cur["max_chars"] = max(cur["max_chars"], s["initial"]["chars"])
        cur["max_count"] = max(cur["max_count"], s["initial"]["count"])
        cur["names"] |= set(s["initial"]["names"])
    if args.json:
        print(
            json.dumps(
                {
                    k: {**v, "names": sorted(v["names"])}
                    for k, v in by_project.items()
                },
                indent=2,
            )
        )
        return
    biggest = max((s["initial"]["chars"] for s in withlisting), default=0)
    print(f"largest listing ever rendered: {biggest} chars\n")
    print(f'{"project":<52}{"sessions":>9}{"maxSkills":>10}{"maxChars":>9}')
    print("-" * 80)
    for proj, v in sorted(by_project.items(), key=lambda kv: -kv[1]["max_chars"]):
        print(f'{proj:<52}{v["n"]:>9}{v["max_count"]:>10}{v["max_chars"]:>9}')
    unconditional = {n for n, i in disk.items() if not i["conditional"]}
    ever = set().union(*(v["names"] for v in by_project.values())) if by_project else set()
    missing = sorted(unconditional - ever)
    print()
    if len(withlisting) < MIN_SESSIONS:
        print(
            f"Only {len(withlisting)} recorded sessions (need {MIN_SESSIONS}) --"
            " not enough to\nconclude anything about truncation. With no history"
            " every skill looks\nnever-listed, which is missing data rather than"
            " a dropped skill."
        )
    elif missing:
        print("Unconditional skills that have NEVER appeared in a listing:")
        for m in missing:
            print(f"  {m}")
        print("\nThat is the truncation signal -- an unconditional skill has no")
        print("other reason to be absent. Check it deployed before concluding.")
    else:
        print("Every unconditional skill on disk has appeared in some listing.")
        print("No evidence of listing truncation.")


def cmd_triggers(args):
    """Slash vs auto, per skill. A slash-only skill is a description that
    is not earning its trigger -- the user reached for it by name because
    the model never offered it."""
    disk = skills_on_disk()
    sessions = scan_transcripts()
    agg = aggregate(sessions)
    known = set(disk) | set(agg["listed"])
    rows = []
    for name in sorted(known):
        s, t = agg["slash"][name], agg["tooluse"][name]
        if not (s or t):
            continue
        rows.append({"skill": name, "slash": s, "skill_tool": t, "total": s + t})
    if args.json:
        print(json.dumps(rows, indent=2))
        return
    print(f'{"skill":<38}{"slash":>7}{"auto":>6}{"auto%":>7}   note')
    print("-" * 76)
    for r in sorted(rows, key=lambda r: -r["total"]):
        pct = 100 * r["skill_tool"] / r["total"]
        note = ""
        if r["skill_tool"] == 0 and r["slash"] >= 3:
            note = "never auto-triggered"
        elif pct < 25 and r["total"] >= 8:
            note = "mostly reached by name"
        print(
            f'{r["skill"]:<38}{r["slash"]:>7}{r["skill_tool"]:>6}{pct:>6.0f}%   {note}'
        )
    print()
    print("auto = Skill-tool dispatch, i.e. the description matched.")
    print("Built-in CLI commands (/compact, /model) are excluded: a raw")
    print("<command-name> count invents skills that do not exist.")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name, fn, helptext in (
        ("coverage", cmd_coverage, "per-skill: listed, activated, invoked"),
        ("listing", cmd_listing, "listing size per project; truncation check"),
        ("triggers", cmd_triggers, "slash vs auto-trigger ratio per skill"),
    ):
        p = sub.add_parser(name, help=helptext)
        p.add_argument("--json", action="store_true", help="machine-readable output")
        p.set_defaults(func=fn)
    args = ap.parse_args()
    args.func(args)
    return 0


if __name__ == "__main__":
    sys.exit(main())
