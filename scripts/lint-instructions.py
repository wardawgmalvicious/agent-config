#!/usr/bin/env python3
"""Validate copilot/instructions/*.instructions.md and guard them against
drift from the claude/rules/*.md they were hand-translated from.

Three jobs in one pass, because they read the same files.

FRONTMATTER. These carry `applyTo` — a single comma-separated glob string —
where a rule carries a `paths:` list. lint-frontmatter.py *requires*
`paths:`, so it would reject every one of these and is scoped away from
them; without this they ship unlinted, and a malformed `applyTo` has no
error path at all. It simply never applies.

LEAKAGE. These files deploy into client repos. This one is personal, so a
port that leaves `agent-config` or a profile path in the prose advertises it
where it does not belong. The port strips those by hand; this makes the
stripping checkable rather than remembered.

DRIFT. Each file is a one-time hand port — frontmatter converted, and a
dozen or so lines of body prose rewritten where Claude-specific mechanics
("co-loads", `.claude/rules` override paths) are wrong or meaningless for a
Copilot reader. Nothing regenerates them, so an edit to a rule leaves its
port stale with nothing to say so. That is exactly how the two previous
parallel instruction payloads here died: a `.github/copilot-instructions.md`
and a root `AGENTS.md`, both drifted, both eventually deleted rather than
reconciled. This records a hash of each source rule as ported and fails when
one moves.

The manifest also lists rules deliberately NOT ported, so that adding a new
rule surfaces as a decision to make rather than something to be missed. It
lives at copilot/.source-hashes.json, in this repo only — the target gets
copilot/instructions/* and nothing else, and a client repo has no use for
the hash of a file it cannot see.

Usage:
    lint-instructions.py            # check; exit 1 on any problem
    lint-instructions.py --stamp    # re-record hashes after a deliberate port

Output: one line per failure: <filepath>:<rule>: <message>
"""
from __future__ import annotations

import hashlib
import importlib.util
import json
import sys
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parent.parent
RULES_DIR = REPO / "claude" / "rules"
INSTR_DIR = REPO / "copilot" / "instructions"
MANIFEST = REPO / "copilot" / ".source-hashes.json"
SUFFIX = ".instructions.md"

# README.md in claude/rules is documentation rather than a rule, and is
# excluded from the rules linter for the same reason.
NOT_A_RULE = {"README"}

REQUIRED_KEYS = ("name", "description", "applyTo")

BACKSLASH = chr(92)

# Substrings that must never reach a client repo. Bare "Claude" is
# deliberately absent: naming the tool is not a leak, and a lint that fires
# on it would be turned off. What matters is repo names and profile paths.
FORBIDDEN = (
    ("agent-config", "names this repo"),
    ("machine-config", "names another personal repo"),
    ("claude-config", "names another personal repo"),
    (".claude/rules", "override path that is wrong for a Copilot reader"),
    ("C:/Users", "hardcoded profile path"),
    ("C:/Repos", "hardcoded personal repo root"),
    ("C:" + BACKSLASH + "Users", "hardcoded profile path"),
    ("C:" + BACKSLASH + "Repos", "hardcoded personal repo root"),
)

# The round-trip glob matcher is non-obvious and already written. Reuse the
# primitives rather than restating them; the failure messages are ours,
# because check_paths() labels everything `paths[i]` and these are globs
# inside one `applyTo` string.
_spec = importlib.util.spec_from_file_location(
    "lint_frontmatter", Path(__file__).with_name("lint-frontmatter.py")
)
_lf = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_lf)


def read_normalized(path: Path) -> str:
    """Read as text with newlines normalized to LF.

    The repo pins .md to whatever .gitattributes says and checkouts differ,
    so hashing raw bytes would make the drift check fire on a line-ending
    change nobody made.
    """
    return path.read_text(encoding="utf-8").replace(chr(13) + chr(10), chr(10))


def source_hash(path: Path) -> str:
    """Hash the WHOLE rule file, frontmatter included.

    Body-only would be the tighter comparison, but a `paths:` edit is
    precisely the change that must force a re-port of `applyTo` — and that
    lives in the frontmatter.
    """
    return hashlib.sha256(read_normalized(path).encode("utf-8")).hexdigest()


def split_frontmatter(text: str):
    """Return (mapping, error) for a leading YAML frontmatter block."""
    if not text.startswith("---" + chr(10)):
        return None, "does not open with a '---' frontmatter block."
    parts = text.split("---" + chr(10), 2)
    if len(parts) < 3:
        return None, "frontmatter block is not closed with '---'."
    try:
        data = yaml.safe_load(parts[1])
    except yaml.YAMLError as exc:
        return None, f"frontmatter is not valid YAML: {exc}."
    if not isinstance(data, dict):
        return None, "frontmatter is not a mapping."
    return data, None


def check_apply_to(value, fail) -> None:
    """`applyTo` is one comma-separated string, not a list.

    VS Code documents `applyTo: '**/*.ts,**/*.tsx'`. A YAML list parses fine
    and then matches nothing, which is the silent failure this catches.
    """
    if isinstance(value, list):
        fail(
            "applyto-type",
            "`applyTo` is a YAML list; it must be one comma-separated string "
            "(e.g. '**/*.ts,**/*.tsx'). A list matches nothing.",
        )
        return
    if not isinstance(value, str) or not value.strip():
        fail("applyto-type", "`applyTo` must be a non-empty string.")
        return

    seen: dict[str, int] = {}
    for i, raw in enumerate(value.split(",")):
        glob = raw.strip()
        if not glob:
            fail("applyto-empty", f"`applyTo` entry {i} is empty; check for a stray comma.")
            continue
        if raw != glob:
            fail(
                "applyto-whitespace",
                f"`applyTo` entry {i} {glob!r} is padded with whitespace; "
                "VS Code does not trim around the commas.",
            )
        if BACKSLASH in glob:
            fail(
                "applyto-separator",
                f"`applyTo` entry {i} {glob!r} contains a backslash; glob separators are always '/'.",
            )
            continue
        if glob.startswith("/") or glob.startswith("./"):
            fail(
                "applyto-anchor",
                f"`applyTo` entry {i} {glob!r} starts with '/' or './'; patterns match unanchored.",
            )
        if "/" not in glob:
            fail(
                "applyto-depth",
                f"`applyTo` entry {i} {glob!r} has no '/', so it matches root-level files "
                f"only; use '**/{glob}'.",
            )
        if glob in seen:
            fail("applyto-duplicate", f"`applyTo` entry {i} {glob!r} duplicates entry {seen[glob]}.")
        else:
            seen[glob] = i

        probe = _lf.instantiate(glob)
        if not _lf.matches(probe, glob):
            fail(
                "applyto-unmatchable",
                f"`applyTo` entry {i} {glob!r} does not match its own instance {probe!r}.",
            )


def lint_file(path: Path, failures: list[str]) -> None:
    def fail(rule: str, msg: str) -> None:
        failures.append(f"{path.relative_to(REPO).as_posix()}:{rule}: {msg}")

    text = read_normalized(path)

    data, err = split_frontmatter(text)
    if err:
        fail("frontmatter", err)
        return

    for key in REQUIRED_KEYS:
        if key not in data:
            fail("missing-key", f"`{key}` is required.")
    if "applyTo" in data:
        check_apply_to(data["applyTo"], fail)

    for needle, why in FORBIDDEN:
        if needle in text:
            line = next(
                (i for i, l in enumerate(text.splitlines(), 1) if needle in l), 0
            )
            fail("leak", f"line {line} contains {needle!r} — {why}. Rewrite it before shipping.")


def load_manifest() -> dict:
    if not MANIFEST.exists():
        return {"translated": {}, "deferred": []}
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    data.setdefault("translated", {})
    data.setdefault("deferred", [])
    return data


def write_manifest(data: dict) -> None:
    MANIFEST.write_text(
        json.dumps(data, indent=2, sort_keys=True) + chr(10), encoding="utf-8"
    )


def main(argv: list[str]) -> int:
    stamp = "--stamp" in argv[1:]
    unknown = [a for a in argv[1:] if a != "--stamp"]
    if unknown:
        print(f"usage: lint-instructions.py [--stamp]  (got {unknown})", file=sys.stderr)
        return 2

    if not INSTR_DIR.is_dir():
        print(f"{INSTR_DIR.relative_to(REPO).as_posix()}:missing: directory does not exist.")
        return 1

    rule_stems = {p.stem for p in RULES_DIR.glob("*.md")} - NOT_A_RULE
    instr_paths = sorted(INSTR_DIR.glob("*" + SUFFIX))
    instr_stems = {p.name[: -len(SUFFIX)] for p in instr_paths}
    manifest = load_manifest()

    if stamp:
        recorded = {}
        for stem in sorted(instr_stems):
            src = RULES_DIR / f"{stem}.md"
            if not src.is_file():
                print(f"skipped {stem}: no claude/rules/{stem}.md to hash.", file=sys.stderr)
                continue
            recorded[stem] = source_hash(src)
        manifest["translated"] = recorded
        write_manifest(manifest)
        print(f"stamped {len(recorded)} port(s) into {MANIFEST.relative_to(REPO).as_posix()}")
        untracked = sorted(rule_stems - instr_stems - set(manifest["deferred"]))
        if untracked:
            print(
                "note: not ported and not deferred — add to `deferred` by hand or port them: "
                + ", ".join(untracked),
                file=sys.stderr,
            )
        return 0

    failures: list[str] = []
    for path in instr_paths:
        lint_file(path, failures)

    rel = MANIFEST.relative_to(REPO).as_posix()
    deferred = set(manifest["deferred"])
    translated = manifest["translated"]

    for stem in sorted(instr_stems):
        src = RULES_DIR / f"{stem}.md"
        target = f"copilot/instructions/{stem}{SUFFIX}"
        if not src.is_file():
            failures.append(
                f"{target}:orphan: no claude/rules/{stem}.md — the rule it was ported "
                "from is gone. Delete this port or restore the rule."
            )
            continue
        if stem not in translated:
            failures.append(
                f"{target}:unstamped: no hash recorded in {rel}. "
                "Run scripts/lint-instructions.py --stamp after checking the port is current."
            )
            continue
        if translated[stem] != source_hash(src):
            failures.append(
                f"claude/rules/{stem}.md:drift: changed since {target} was ported from it. "
                f"Re-read both, port the change across, then run "
                f"scripts/lint-instructions.py --stamp."
            )

    for stem in sorted(translated):
        if stem not in instr_stems:
            failures.append(
                f"{rel}:stale-entry: records a port for {stem!r} but "
                f"copilot/instructions/{stem}{SUFFIX} does not exist."
            )

    for stem in sorted(rule_stems - instr_stems - deferred):
        failures.append(
            f"claude/rules/{stem}.md:untracked: neither ported to copilot/instructions/ "
            f"nor listed as deferred in {rel}. Decide which, so a new rule is never "
            "silently left behind."
        )

    for stem in sorted(deferred & instr_stems):
        failures.append(
            f"{rel}:contradiction: {stem!r} is listed as deferred but a port exists. "
            "Remove it from `deferred`."
        )

    for stem in sorted(deferred - rule_stems):
        failures.append(
            f"{rel}:stale-defer: defers {stem!r}, which is not a rule in claude/rules/."
        )

    for line in failures:
        print(line)
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
