#!/usr/bin/env python3
"""Validate SKILL.md and rules/*.md frontmatter against repo conventions.

Usage: lint-frontmatter.py <path>...

The kind of file is inferred from its path: anything under a `rules/`
directory is linted as a rule (`paths` required; `name`/`description` are
not), everything else as a skill (`name` and `description` required).

Glob validation deliberately does NOT check that a pattern "compiles" —
glob syntax is permissive enough that nearly every string is valid, so the
check would catch nothing. It checks the mistakes that silently make a
pattern match less than intended, which is how a rule fails in practice:
it simply never loads, with no error anywhere.

Exits 0 if every file passes, 1 if any file fails, 2 on usage error.
Output: one line per failure: <filepath>:<rule>: <message>
"""
from __future__ import annotations

import codecs
import re
import sys
from pathlib import Path, PurePosixPath

import yaml

NAME_RE = re.compile(r"^[a-z0-9-]+$")
NAME_CHAR_RE = re.compile(r"[a-z0-9-]")
RESERVED_WORDS = ("anthropic", "claude")
NAME_MAX = 64
# Claude Code truncates the combined `description` + `when_to_use` text at
# 1,536 chars in the skill listing (configurable via
# `skillListingMaxDescChars`). Truncation is silent, so the lint has to gate
# at or below it.
#
# The 1,536 is split into a fixed budget per field rather than left as one
# shared pool, so that an edit to one field can never overflow the other and
# a failure names the field to cut. `description` keeps the 1,024 Agent
# Skills spec cap — it is one of the six fields the claude.ai upload path
# accepts, so it is the half that has to stay portable. `when_to_use` is a
# Claude Code extension the spec does not carry, so its 512 is the
# Claude-Code-only remainder. 1,024 + 512 = 1,536 exactly, which makes
# LISTING_MAX an assertion rather than a third constraint: it can only fire
# if these constants are edited apart.
DESCRIPTION_MAX = 1024
WHEN_TO_USE_MAX = 512
LISTING_MAX = 1536
BODY_MAX_LINES = 500
FRONTMATTER_SCAN_LINES = 50
BOM = codecs.BOM_UTF8
BACKSLASH = "\\"

# PurePosixPath.full_match landed in 3.13. Without it the round-trip check is
# skipped rather than failing the run, so the linter still works for anyone
# cherry-picking this repo on an older interpreter. main() notes the skip on
# stderr so it is never silent.
HAVE_FULL_MATCH = hasattr(PurePosixPath, "full_match")
_skipped_round_trip = False


def instantiate(pattern: str) -> str:
    """Build a concrete path the pattern is supposed to match.

    `**` becomes one path segment, `*` becomes a token within a segment. The
    result is fed back through the matcher: a pattern that cannot match its
    own instance is malformed.
    """
    return "/".join(
        "seg" if seg == "**" else seg.replace("*", "x")
        for seg in pattern.split("/")
    )


def matches(path: str, pattern: str) -> bool:
    global _skipped_round_trip
    if not HAVE_FULL_MATCH:
        _skipped_round_trip = True
        return True
    try:
        return PurePosixPath(path).full_match(pattern)
    except (ValueError, TypeError):
        return False


def check_paths(entries: list, fail) -> None:
    seen: dict[str, int] = {}
    for i, entry in enumerate(entries):
        if not isinstance(entry, str) or entry == "":
            fail("paths-entry", f"`paths[{i}]` must be a non-empty string.")
            continue

        if entry != entry.strip():
            fail("paths-whitespace", f"`paths[{i}]` {entry!r} has leading or trailing whitespace.")

        # A Windows separator produces a pattern that is perfectly valid and
        # matches nothing at all. Bail out early; later checks assume '/'.
        if BACKSLASH in entry:
            fail("paths-separator", f"`paths[{i}]` {entry!r} contains a backslash; glob separators are always '/'.")
            continue

        if entry.startswith("/") or entry.startswith("./"):
            fail("paths-anchor", f"`paths[{i}]` {entry!r} starts with '/' or './'; patterns match unanchored.")

        # '*.ps1' matches only files at the repo root. '**/*.ps1' matches those
        # AND every nested one, so the bare form is never what was meant.
        if "/" not in entry:
            fail("paths-depth", f"`paths[{i}]` {entry!r} has no '/', so it matches root-level files only; use '**/{entry}'.")

        if entry in seen:
            fail("paths-duplicate", f"`paths[{i}]` {entry!r} duplicates `paths[{seen[entry]}]`.")
        else:
            seen[entry] = i

        probe = instantiate(entry)
        if not matches(probe, entry):
            fail("paths-unmatchable", f"`paths[{i}]` {entry!r} does not match its own instance {probe!r}.")


def is_rule(path: Path) -> bool:
    return "rules" in path.as_posix().split("/")[:-1]


def lint_file(path: Path) -> list[str]:
    failures: list[str] = []

    def fail(rule: str, msg: str) -> None:
        failures.append(f"{path}:{rule}: {msg}")

    raw = path.read_bytes()
    if raw.startswith(BOM):
        fail("no-bom", "BOM detected; remove.")
        raw = raw[len(BOM):]

    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as e:
        fail("utf-8", f"file is not valid UTF-8: {e}")
        return failures

    lines = text.splitlines()

    if not lines or lines[0] != "---":
        fail("frontmatter", "missing or malformed YAML frontmatter (no opening ---).")
        return failures

    closing = None
    for i in range(1, min(FRONTMATTER_SCAN_LINES, len(lines))):
        if lines[i] == "---":
            closing = i
            break
    if closing is None:
        fail("frontmatter", f"missing or malformed YAML frontmatter (no closing --- within first {FRONTMATTER_SCAN_LINES} lines).")
        return failures

    fm_text = "\n".join(lines[1:closing])
    try:
        fm = yaml.safe_load(fm_text)
    except yaml.YAMLError as e:
        fail("frontmatter-yaml", f"YAML parse error: {e}")
        return failures

    if not isinstance(fm, dict):
        fail("frontmatter-yaml", "frontmatter is not a YAML mapping.")
        return failures

    rule_mode = is_rule(path)

    if not rule_mode:
        name = fm.get("name")
        if name is None:
            fail("name-required", "missing required field `name`.")
        elif not isinstance(name, str):
            fail("name-type", f"`name` must be a string, got {type(name).__name__}.")
        elif name == "":
            fail("name-empty", "`name` is empty.")
        else:
            if len(name) > NAME_MAX:
                fail("name-length", f"`name` length {len(name)} exceeds {NAME_MAX}.")
            if not NAME_RE.match(name):
                bad = sorted({c for c in name if not NAME_CHAR_RE.match(c)})
                fail("name-charset", f"`name` contains disallowed character(s): {bad!r}; allowed: lowercase letters, digits, hyphens.")
            lowered = name.lower()
            for word in RESERVED_WORDS:
                if word in lowered:
                    fail("name-reserved", f"`name` contains reserved word {word!r}.")

        desc = fm.get("description")
        if desc is None:
            fail("description-required", "missing required field `description`.")
        elif not isinstance(desc, str):
            fail("description-type", f"`description` must be a string, got {type(desc).__name__}.")
        elif len(desc) > DESCRIPTION_MAX:
            fail("description-length", f"`description` length {len(desc)} exceeds {DESCRIPTION_MAX}.")

        when = fm.get("when_to_use")
        if when is not None:
            if not isinstance(when, str):
                fail("when-to-use-type", f"`when_to_use` must be a string, got {type(when).__name__}.")
            else:
                if len(when) > WHEN_TO_USE_MAX:
                    fail("when-to-use-length", f"`when_to_use` length {len(when)} exceeds {WHEN_TO_USE_MAX}.")
                # Claude Code appends `when_to_use` to `description` in the
                # listing and truncates the pair. Unreachable while the two
                # field caps sum to LISTING_MAX; it exists so that editing
                # either constant upward cannot silently reopen the gap.
                if isinstance(desc, str) and len(desc) + len(when) > LISTING_MAX:
                    fail("listing-length", f"`description` + `when_to_use` length {len(desc) + len(when)} exceeds the {LISTING_MAX} listing truncation point.")

    # A rule with no `paths` never loads, which is the whole point of a rule.
    if rule_mode and "paths" not in fm:
        fail("paths-required", "missing required field `paths`; without it the rule never auto-loads.")

    if "paths" in fm:
        paths_field = fm["paths"]
        if isinstance(paths_field, str):
            fail("paths-type", "`paths` must be a YAML list, not a string.")
        elif not isinstance(paths_field, list):
            fail("paths-type", f"`paths` must be a YAML list, got {type(paths_field).__name__}.")
        elif not paths_field:
            fail("paths-empty", "`paths` is an empty list.")
        else:
            check_paths(paths_field, fail)

    body_lines = lines[closing + 1:]
    if len(body_lines) > BODY_MAX_LINES:
        fail("body-length", f"body length {len(body_lines)} lines exceeds {BODY_MAX_LINES}.")

    return failures


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: lint-frontmatter.py <SKILL.md|rules/*.md>...", file=sys.stderr)
        return 2

    all_failures: list[str] = []
    for arg in argv[1:]:
        path = Path(arg)
        if not path.is_file():
            all_failures.append(f"{path}:file: not a file.")
            continue
        all_failures.extend(lint_file(path))

    for line in all_failures:
        print(line)

    if _skipped_round_trip:
        print(
            f"note: glob round-trip check skipped (needs Python 3.13+, running "
            f"{sys.version_info.major}.{sys.version_info.minor}).",
            file=sys.stderr,
        )

    return 0 if not all_failures else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
