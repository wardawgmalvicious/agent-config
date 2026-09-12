#!/usr/bin/env python3
"""Which skills have been tested, and what has changed in each since.

    uv run --with pyyaml scripts/skill-status.py            # the table
    uv run --with pyyaml scripts/skill-status.py --stale    # rows needing action
    uv run --with pyyaml scripts/skill-status.py --check    # orphans only; pre-commit
    uv run --with pyyaml scripts/skill-status.py --stamp <skill> --phase activation,behaviour
    uv run --with pyyaml scripts/skill-status.py --stamp <skill> --phase real-use
    uv run --with pyyaml scripts/skill-status.py --stamp <skill> --phase activation
        --at <commit> --date YYYY-MM-DD                     # record a run from earlier

Nothing here is hand-maintained. The README once listed four skills as
untested; by the time anyone looked, every one had been edited since and
the prose above the list was four months old. A list of tested skills is
a status fact per skill, and this repo has already lost three of those to
drift (the conditional-skill total, the skillOverrides count, the queue
rows). So the record is a STAMP -- written by /test-skill at its last
step, the way lint-instructions.py --stamp records a port -- and the list
is DERIVED from the stamp plus what the skill looks like now.

The manifest is tests/skills/.tested.json. Each stamp records the date,
the commit, and a hash of the part of the skill that phase tested:

  activation  the paths: globs -- Phase A of /test-skill, the trigger
              contract in expected_activations.md. Unconditional skills
              have no such contract, and refusing to stamp one is the
              same rule as Phase A being skipped rather than faked.
  behaviour   the routing text (description + when_to_use), the SKILL.md
              body, and every other file in the skill dir -- Phase B, the
              cold session against a --safe-mode baseline.
  real-use    a date only. Nothing derives it; it means the skill was
              used for real work and held. /learn is its natural writer,
              since folding in a learning from real use is the evidence.

The verdict then says which part moved since the stamp, and that is the
answer to "does this edit need a new test":

  retest-activation   a glob changed; run Phase A, static then real-path
  retest-routing      description or when_to_use changed; the trigger
                      queries in Phase B are what test those
  retest-behaviour    the body changed on a BEHAVIOURAL skill, one with a
                      procedure, a refusal or a guard -- run Phase B
  review-body         the body changed on a REFERENCE skill; the README's
                      rule is that real use validates those, not a cold
                      session, so this is a note rather than a debt
  refs-only           only references/ changed; no test covers that
  current             nothing tested has changed
  untested-behaviour  Phase A ran and Phase B never did
  untested            no stamp at all

Kind is by tree and group: everything in .claude/skills/ and in the
workflow and social groups is behavioural, the platform groups are
reference, and BEHAVIOURAL_PLATFORM names the platform skills that carry
a guard or a procedure and have their own fixture suite to prove it.

A stamp with no skill on disk is an ORPHAN and fails both modes -- the
skill was renamed or deleted and the stamp did not follow. That is the one
thing the pre-commit hook enforces. "Untested" is not a failure:
/author-skill commits before /test-skill runs, by design, so a new skill
is legitimately untested for a commit or two. The honesty mechanism for
that state is the queue README telling every session to run this first.
"""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from datetime import date
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
PAYLOAD_ROOT = REPO_ROOT / "skills"
PROJECT_ROOT = REPO_ROOT / ".claude" / "skills"
MANIFEST = REPO_ROOT / "tests" / "skills" / ".tested.json"
MANIFEST_REL = MANIFEST.relative_to(REPO_ROOT).as_posix()

PHASES = ("activation", "behaviour", "real-use")

# Groups whose skills carry a procedure, a refusal pattern or a guard, so a
# body edit changes what the skill DOES and Phase B is the test. Project
# scope (.claude/skills/) is behavioural by construction -- every skill
# there is this repo's own operating procedure.
BEHAVIOURAL_GROUPS = {"workflow", "social"}

# Platform skills that are behavioural despite their group: each has a
# guard or a procedure and a fixture suite under tests/ proving it. Add a
# platform skill here when it grows one, not because it is long.
BEHAVIOURAL_PLATFORM = {"fabric-semantic-model-audit"}

FRONTMATTER_SCAN_LINES = 80
LF = chr(10)
CRLF = chr(13) + chr(10)


def die(msg: str):
    print(f"skill-status: {msg}", file=sys.stderr)
    sys.exit(2)


def git(*args: str) -> str:
    proc = subprocess.run(
        ["git", *args], cwd=REPO_ROOT, capture_output=True, text=True, encoding="utf-8"
    )
    if proc.returncode != 0:
        die(f"git {' '.join(args)} failed: {proc.stderr.strip()}")
    return proc.stdout


# --- discovery -------------------------------------------------------------


def discover() -> dict[str, dict]:
    """name -> {dir (repo-relative posix), kind}. Both trees, one namespace.

    lint-skill-scopes.py already fails a name held in both trees, so a
    collision here is not this script's finding; the last one seen wins
    and the scopes linter says which.
    """
    found: dict[str, dict] = {}
    if not PAYLOAD_ROOT.is_dir() or not PROJECT_ROOT.is_dir():
        die("a skills root is missing; refusing to report on an empty set.")
    for group in sorted(p for p in PAYLOAD_ROOT.iterdir() if p.is_dir()):
        for skill in sorted(p for p in group.iterdir() if p.is_dir()):
            if not (skill / "SKILL.md").is_file():
                continue
            behavioural = group.name in BEHAVIOURAL_GROUPS or skill.name in BEHAVIOURAL_PLATFORM
            found[skill.name] = {
                "dir": f"skills/{group.name}/{skill.name}",
                "kind": "behavioural" if behavioural else "reference",
            }
    for skill in sorted(p for p in PROJECT_ROOT.iterdir() if p.is_dir()):
        if not (skill / "SKILL.md").is_file():
            continue
        found[skill.name] = {"dir": f".claude/skills/{skill.name}", "kind": "behavioural"}
    if not found:
        die("no skills found under either tree; refusing to report on an empty set.")
    return found


# --- hashing ---------------------------------------------------------------


def normalize(raw: bytes) -> str:
    # The repo pins .md line endings by .gitattributes and checkouts differ,
    # so a CRLF checkout must hash the same as the LF blob git stores.
    return raw.decode("utf-8").replace(CRLF, LF)


def sha(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]


def split_frontmatter(text: str, label: str) -> tuple[dict, str]:
    lines = text.split(LF)
    if not lines or lines[0] != "---":
        die(f"{label}: no opening --- ; lint-frontmatter.py should have caught this.")
    closing = next(
        (i for i in range(1, min(FRONTMATTER_SCAN_LINES, len(lines))) if lines[i] == "---"),
        None,
    )
    if closing is None:
        die(f"{label}: no closing --- within {FRONTMATTER_SCAN_LINES} lines.")
    fm = yaml.safe_load(LF.join(lines[1:closing]))
    if not isinstance(fm, dict):
        die(f"{label}: frontmatter is not a mapping.")
    return fm, LF.join(lines[closing + 1 :])


def canonical(value) -> str:
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(",", ":"))


class Snapshot:
    """The hashable parts of one skill, read from the worktree or a commit.

    Worktree is the default because /test-skill runs against the uncommitted
    SKILL.md -- the stamp must describe what was tested, not what HEAD had.
    """

    def __init__(self, name: str, skill_dir: str, at: str | None):
        self.name = name
        skill_md = f"{skill_dir}/SKILL.md"
        if at is None:
            raw = (REPO_ROOT / skill_md).read_bytes()
            files = sorted(
                p.relative_to(REPO_ROOT).as_posix()
                for p in (REPO_ROOT / skill_dir).rglob("*")
                if p.is_file() and p.name != "SKILL.md"
            )
            blobs = {f: (REPO_ROOT / f).read_bytes() for f in files}
        else:
            raw = self._show(at, skill_md)
            listing = git("ls-tree", "-r", "--name-only", at, "--", skill_dir).split(LF)
            files = sorted(f for f in listing if f and not f.endswith("/SKILL.md"))
            blobs = {f: self._show(at, f) for f in files}
        fm, body = split_frontmatter(normalize(raw), skill_md)
        self.paths = fm.get("paths")
        self.conditional = bool(self.paths)
        routing = {"description": fm.get("description"), "when_to_use": fm.get("when_to_use")}
        self.hashes = {
            "paths": sha(canonical(self.paths)) if self.conditional else None,
            "routing": sha(canonical(routing)),
            "body": sha(body),
            "references": sha(canonical([[f, sha(self._text(b))] for f, b in blobs.items()])),
        }

    @staticmethod
    def _show(at: str, path: str) -> bytes:
        proc = subprocess.run(
            ["git", "show", f"{at}:{path}"], cwd=REPO_ROOT, capture_output=True
        )
        if proc.returncode != 0:
            die(f"{path} does not exist at {at}: {proc.stderr.decode(errors='replace').strip()}")
        return proc.stdout

    @staticmethod
    def _text(raw: bytes) -> str:
        try:
            return normalize(raw)
        except UnicodeDecodeError:
            return raw.hex()


# --- manifest --------------------------------------------------------------

MANIFEST_NOTE = (
    "Written by scripts/skill-status.py --stamp and read by the same script. "
    "Do not hand-edit: each entry hashes the part of a skill that a test phase "
    "covered, and the verdict is derived by comparing it with the skill now."
)


def load_manifest() -> dict:
    if not MANIFEST.is_file():
        return {"_note": MANIFEST_NOTE, "skills": {}}
    try:
        data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        die(f"{MANIFEST_REL} is not valid JSON: {e}")
    if not isinstance(data, dict) or not isinstance(data.get("skills"), dict):
        die(f"{MANIFEST_REL} has no 'skills' mapping.")
    return data


def save_manifest(data: dict) -> None:
    data["_note"] = MANIFEST_NOTE
    data["skills"] = dict(sorted(data["skills"].items()))
    # Bytes, not write_text: on Windows text mode turns every LF into CRLF,
    # and .gitattributes pins this file to LF -- so each stamp would flip the
    # working copy and git would warn "CRLF will be replaced by LF" on add.
    MANIFEST.write_bytes((json.dumps(data, indent=2, ensure_ascii=False) + LF).encode("utf-8"))


# --- verdicts --------------------------------------------------------------

STALE = (
    "untested",
    "untested-behaviour",
    "retest-activation",
    "retest-routing",
    "retest-behaviour",
)


def verdict(snap: Snapshot, kind: str, entry: dict | None) -> str:
    if not entry:
        return "untested"
    act = entry.get("activation")
    beh = entry.get("behaviour")
    if snap.conditional and (not act or act.get("paths") != snap.hashes["paths"]):
        return "retest-activation"
    if not beh:
        # Phase A ran and Phase B never did. Both kinds get a cold session
        # from /test-skill, so this is a gap for a reference skill too.
        return "untested-behaviour"
    if beh.get("routing") != snap.hashes["routing"]:
        return "retest-routing"
    if beh.get("body") != snap.hashes["body"]:
        return "retest-behaviour" if kind == "behavioural" else "review-body"
    if beh.get("references") != snap.hashes["references"]:
        return "refs-only"
    return "current"


def report(only_stale: bool) -> int:
    skills = discover()
    manifest = load_manifest()
    orphans = sorted(set(manifest["skills"]) - set(skills))
    rows = []
    for name, info in skills.items():
        snap = Snapshot(name, info["dir"], None)
        entry = manifest["skills"].get(name) or {}
        v = verdict(snap, info["kind"], entry)
        if only_stale and v not in STALE:
            continue

        def when(phase: str) -> str:
            if phase == "activation" and not snap.conditional:
                return "n/a"
            e = entry.get(phase)
            return e["date"] if e else "-"

        rows.append((name, info["kind"], when("activation"), when("behaviour"), when("real-use"), v))

    header = ("skill", "kind", "activation", "behaviour", "real-use", "verdict")
    widths = [max(len(r[i]) for r in [header, *rows]) for i in range(len(header))]
    for r in [header, *rows]:
        print("  ".join(c.ljust(w) for c, w in zip(r, widths)).rstrip())
    counts: dict[str, int] = {}
    for r in rows:
        counts[r[-1]] = counts.get(r[-1], 0) + 1
    print()
    print(f"{len(skills)} skills; " + ", ".join(f"{k} {v}" for k, v in sorted(counts.items())))
    return orphan_report(orphans)


def orphan_report(orphans: list[str]) -> int:
    for name in orphans:
        print(
            f"{MANIFEST_REL}:orphan: stamp for {name!r} but no skill by that name on disk. "
            "Renamed or deleted? Move or remove the entry.",
            file=sys.stderr,
        )
    return 1 if orphans else 0


def check() -> int:
    skills = discover()
    manifest = load_manifest()
    return orphan_report(sorted(set(manifest["skills"]) - set(skills)))


def stamp(name: str, phases: list[str], at: str | None, on: str | None) -> int:
    skills = discover()
    if name not in skills:
        die(f"no skill named {name!r} in either tree.")
    bad = [p for p in phases if p not in PHASES]
    if bad:
        die(f"unknown phase(s) {bad}; choose from {list(PHASES)}.")
    if at is not None and on is None:
        die("--at records a run in the past; say when it ran with --date YYYY-MM-DD.")
    on = on or date.today().isoformat()
    commit = git("rev-parse", "--short", at or "HEAD").strip()
    snap = Snapshot(name, skills[name]["dir"], at)
    manifest = load_manifest()
    entry = manifest["skills"].setdefault(name, {})
    for phase in phases:
        if phase == "activation":
            if not snap.conditional:
                die(
                    f"{name} has no paths: glob, so it has no activation contract to stamp. "
                    "Phase A is skipped for it, not faked; stamp behaviour instead."
                )
            entry["activation"] = {"date": on, "commit": commit, "paths": snap.hashes["paths"]}
        elif phase == "behaviour":
            entry["behaviour"] = {
                "date": on,
                "commit": commit,
                "routing": snap.hashes["routing"],
                "body": snap.hashes["body"],
                "references": snap.hashes["references"],
            }
        else:
            entry["real-use"] = {"date": on, "commit": commit}
    save_manifest(manifest)
    print(f"stamped {name}: {', '.join(phases)} at {commit} on {on} -> {MANIFEST_REL}")
    return 0


def main(argv: list[str]) -> int:
    args = list(argv)

    def take(flag: str) -> str | None:
        if flag not in args:
            return None
        i = args.index(flag)
        if i + 1 >= len(args):
            die(f"{flag} needs a value.")
        value = args[i + 1]
        del args[i : i + 2]
        return value

    target = take("--stamp")
    phase = take("--phase")
    at = take("--at")
    on = take("--date")
    leftover = [a for a in args if a not in ("--check", "--stale")]
    if leftover:
        die(f"unexpected argument(s) {leftover}; see the docstring.")
    if target is not None:
        if phase is None:
            die("--stamp needs --phase activation,behaviour,real-use (any subset).")
        return stamp(target, [p.strip() for p in phase.split(",") if p.strip()], at, on)
    if phase or at or on:
        die("--phase, --at and --date only mean something with --stamp.")
    if "--check" in args:
        return check()
    return report("--stale" in args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
