#!/usr/bin/env python3
"""Enforce that every platform skill is collapsed to name-only in this repo.

.claude/settings.json carries a `skillOverrides` block whose job is to keep
the fabric/ and powerbi/ skill descriptions out of the listing in sessions
HERE, where the subject is maintaining the payload rather than using it.
That block is a BY-NAME MAP WITH NO PATTERN FORM, so a newly authored
platform skill is not covered by it until someone types the name in — and
nothing says so. The failure is silent in the only direction that matters:
the skill loads fine, the session just pays for a description it will never
match on.

This runs over the whole set rather than the changed files, for the same
reason lint-skill-scopes.py does: coverage is a property of the SET. The
new skill's own directory is not wrong, and settings.json is not wrong
either — the pair is. No per-file hook can see that, which is exactly how
it went silent twice in a row:

  1c64590  fix(settings): cover fabric-catalog-governance in skillOverrides
           — the /author-skill run of 2026-09-12, caught only after the
           skill had already landed.
  fabric-activator, authored the same day, was uncovered exactly the same
           way. It never became a second follow-up commit only because a
           hand-written probe caught it mid-session — which is luck, not a
           mechanism, and is why this check exists instead.

WHY AN UNKNOWN GROUP IS A FAILURE. The platform/behavioural split is a
judgement this script cannot make. skills/workflow/ and skills/social/ are
deliberately NOT overridden — `commit` and `code-review` are reached by
description, so collapsing them would break the thing they are for. A new
group is therefore neither safe to require nor safe to skip, and guessing
either way would make this check quietly wrong about a whole directory.
Classify it in PLATFORM_GROUPS or BEHAVIOURAL_GROUPS instead.

WHY ORPHANS ARE ONLY REPORTED FOR NAMESPACED NAMES. An entry naming no
skill in this repo is usually a rename or deletion that left its override
behind. But `skillOverrides` addresses any skill Claude Code can see,
including plugin skills that live nowhere in this tree, so a blanket orphan
check would fail on a legitimate override of `skill-creator` or `dataviz`.
Only names carrying this repo's own platform prefixes are treated as
orphans; anything else is left alone.

Exits 0 if coverage is complete, 1 on any failure — and 1, rather than a
silent 0, if settings.json is absent or unparseable, if the skillOverrides
key is missing, or if no platform skill was found at all. A check that
compared nothing must not report a pass.
Output: one line per failure: <path>:<rule>: <message>
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
PAYLOAD_ROOT = REPO_ROOT / "skills"
SETTINGS = REPO_ROOT / ".claude" / "settings.json"
SETTINGS_REL = ".claude/settings.json"

# Groups whose skills MUST be collapsed, and groups that must not be
# required to be. Anything else fails as unclassified -- see the module
# docstring.
PLATFORM_GROUPS = {"fabric", "powerbi"}
BEHAVIOURAL_GROUPS = {"workflow", "social"}

# The one value this repo uses. Kept as a constant so a deliberate policy
# change is one edit here plus the CLAUDE.md line, rather than a drifting
# mix nothing asserts.
EXPECTED = "name-only"

# Prefixes that mark a name as this repo's own platform payload, for the
# orphan check only.
PLATFORM_PREFIXES = ("fabric-", "pbir-", "pbid-", "pbip-", "powerbi-")


def platform_skills() -> tuple[dict[str, str], list[str]]:
    """(name -> repo-relative dir) for platform groups, plus unknown groups.

    A directory without a SKILL.md is not a skill. Skipping it rather than
    reporting it is deliberate: lint-frontmatter.py and both deploy scripts
    already speak to that case.
    """
    found: dict[str, str] = {}
    unknown: list[str] = []
    for group in sorted(p for p in PAYLOAD_ROOT.iterdir() if p.is_dir()):
        if group.name in BEHAVIOURAL_GROUPS:
            continue
        if group.name not in PLATFORM_GROUPS:
            unknown.append(group.name)
            continue
        for skill in sorted(p for p in group.iterdir() if p.is_dir()):
            if not (skill / "SKILL.md").is_file():
                continue
            found[skill.name] = f"skills/{group.name}/{skill.name}"
    return found, unknown


def main(argv: list[str]) -> int:
    # THE THREE WAYS THIS CHECK COULD PASS BY SEEING NOTHING, refused up
    # front. REPO_ROOT is derived from this file's own path by two .parent
    # hops, so moving this script one directory deeper is enough to cause
    # the first two.
    if not PAYLOAD_ROOT.is_dir():
        print(
            f"skills:missing-root: expected a skill tree at {PAYLOAD_ROOT}, "
            "which is not a directory. REPO_ROOT is derived from this script's "
            "own location, so the usual cause is lint-skill-overrides.py having "
            "moved without its .parent count following."
        )
        return 1

    if not SETTINGS.is_file():
        print(
            f"{SETTINGS_REL}:missing-settings: expected project settings at "
            f"{SETTINGS}. Without it there is no skillOverrides block to check "
            "and a pass would assert nothing."
        )
        return 1

    try:
        settings = json.loads(SETTINGS.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        print(f"{SETTINGS_REL}:invalid-json: {exc}")
        return 1

    if "skillOverrides" not in settings:
        print(
            f"{SETTINGS_REL}:missing-block: no `skillOverrides` key. Every "
            "platform skill's description would be in the listing for sessions "
            "in this repo. Add the block, or delete this check and the CLAUDE.md "
            "paragraph describing it together."
        )
        return 1

    overrides = settings["skillOverrides"]
    if not isinstance(overrides, dict):
        print(
            f"{SETTINGS_REL}:malformed-block: `skillOverrides` is "
            f"{type(overrides).__name__}, expected an object mapping skill name "
            "to override."
        )
        return 1

    platform, unknown_groups = platform_skills()
    failures: list[str] = []

    for group in unknown_groups:
        failures.append(
            f"skills/{group}:unclassified-group: this script cannot tell whether "
            f"{group!r} holds platform skills that must be collapsed to "
            f"{EXPECTED!r} or behavioural ones that must not. Add it to "
            "PLATFORM_GROUPS or BEHAVIOURAL_GROUPS in this script."
        )

    # Both roots exist but the platform groups hold nothing -- a restructure,
    # or a tree emptied by mistake. Same reasoning as missing-root: refuse to
    # certify coverage this run never measured.
    if not platform and not unknown_groups:
        failures.append(
            "skills:empty-platform-set: no <name>/SKILL.md found in "
            f"{', '.join(sorted(PLATFORM_GROUPS))}, so no coverage was compared. "
            "A pass here would assert nothing."
        )

    # The silent case, and the whole reason this exists. Report against the
    # settings file, since that is the file the fix goes in.
    for name in sorted(n for n in platform if n not in overrides):
        failures.append(
            f"{SETTINGS_REL}:missing-override: {name!r} ({platform[name]}) has no "
            f"`skillOverrides` entry. Add \"{name}\": \"{EXPECTED}\" -- the block is "
            "a by-name map with no pattern form, so a new platform skill is "
            "uncovered until it is listed, and nothing else reports that."
        )

    for name in sorted(n for n in platform if n in overrides):
        if overrides[name] != EXPECTED:
            failures.append(
                f"{SETTINGS_REL}:unexpected-value: {name!r} is "
                f"{overrides[name]!r}, expected {EXPECTED!r}. Every platform skill "
                "in this repo is collapsed the same way; if that policy has "
                "changed, change EXPECTED in this script and the CLAUDE.md "
                "paragraph together."
            )

    # A rename or deletion that left its override behind. Limited to this
    # repo's own platform prefixes so an override of a plugin skill is not
    # mistaken for one -- see the module docstring.
    for name in sorted(overrides):
        if name in platform:
            continue
        if name.startswith(PLATFORM_PREFIXES):
            failures.append(
                f"{SETTINGS_REL}:orphan-override: {name!r} is overridden but no "
                "such skill exists under skills/. A rename or deletion left it "
                "behind; drop the entry."
            )

    for line in failures:
        print(line)

    if not failures:
        print(
            f"ok: {len(platform)} platform skill(s) across "
            f"{', '.join(sorted(PLATFORM_GROUPS))} all set to {EXPECTED!r}; "
            f"{len(overrides)} override(s) total.",
            file=sys.stderr,
        )
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
