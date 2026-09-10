#!/usr/bin/env python3
"""Enforce the flat skill-name namespace across both skill trees.

Claude Code addresses a skill by NAME ALONE. There is no group segment in
the address and no scope qualifier, so every skill in this repo — whichever
tree and whichever group it sits in — competes in one flat namespace. Two
skills sharing a name is therefore never a merge; it is one of them
winning. This checks the whole set at once rather than a changed file,
because a collision is a property of the pair and neither file is wrong on
its own.

THE SILENT CASE IS CROSS-SCOPE, and it is the reason this exists.
skills/<group>/ deploys to ~/.claude/skills (user scope); .claude/skills/
is read in place (project scope). User scope OUTRANKS project scope —
measured 2026-09-02, with `drift-handoff` deployed at both and a marker in
only the project-scope copy: the listing carried the user-scope text and
the marker appeared nowhere in the transcript. Project scope only ever
*adds* names user scope lacks.

So re-creating one of the seven project-scope names under skills/ does not
conflict, error, or warn. The project-scope skill simply stops being the
one that loads, and the only symptom is a skill behaving like an older
version of itself. Nothing in either deploy script can catch it:
link-claude.ps1 walks skills/ and never looks at .claude/skills, which is
correct — those skills deploy nowhere — but it means the collision is
invisible on both sides.

THE CROSS-GROUP CASE IS ALREADY LOUD, and is included because it is the
same namespace and the same data. link-claude.ps1 and copy-copilot.ps1
both throw on a duplicate name across groups, so that one cannot ship
silently. What they cannot do is fail before the commit: without this you
land the collision and discover it at the next deploy. Catching both here
costs one extra comparison.

Exits 0 if the namespace is clean, 1 if any name collides.
Output: one line per collision: <path>:<rule>: <message>
"""
from __future__ import annotations

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
PAYLOAD_ROOT = REPO_ROOT / "skills"
PROJECT_ROOT = REPO_ROOT / ".claude" / "skills"


def payload_skills() -> dict[str, list[str]]:
    """name -> repo-relative dirs, over skills/<group>/<name>/SKILL.md.

    A directory without a SKILL.md is not a skill. Skipping it here rather
    than reporting it is deliberate: lint-frontmatter.py and both deploy
    scripts already speak to that case, and duplicating the complaint would
    make this script fire on something it has no opinion about.
    """
    found: dict[str, list[str]] = {}
    if not PAYLOAD_ROOT.is_dir():
        return found
    for group in sorted(p for p in PAYLOAD_ROOT.iterdir() if p.is_dir()):
        for skill in sorted(p for p in group.iterdir() if p.is_dir()):
            if not (skill / "SKILL.md").is_file():
                continue
            found.setdefault(skill.name, []).append(
                f"skills/{group.name}/{skill.name}"
            )
    return found


def project_skills() -> dict[str, str]:
    """name -> repo-relative dir, over .claude/skills/<name>/SKILL.md."""
    found: dict[str, str] = {}
    if not PROJECT_ROOT.is_dir():
        return found
    for skill in sorted(p for p in PROJECT_ROOT.iterdir() if p.is_dir()):
        if not (skill / "SKILL.md").is_file():
            continue
        found[skill.name] = f".claude/skills/{skill.name}"
    return found


def main(argv: list[str]) -> int:
    payload = payload_skills()
    project = project_skills()
    failures: list[str] = []

    # Cross-scope: the silent one. Report against the project-scope copy,
    # since that is the file that stops loading.
    for name in sorted(set(payload) & set(project)):
        where = ", ".join(payload[name])
        failures.append(
            f"{project[name]}/SKILL.md:scope-shadow: {name!r} also exists at {where}. "
            "User scope outranks project scope, so the deployed copy would win and this "
            "one would silently stop loading. Rename one, or delete the copy you did not "
            "mean to keep."
        )

    # Cross-group: already fatal at deploy time; caught here so it fails
    # before the commit rather than after.
    for name, dirs in sorted(payload.items()):
        if len(dirs) > 1:
            failures.append(
                f"{dirs[0]}/SKILL.md:duplicate-group: {name!r} exists in more than one "
                f"group ({', '.join(dirs)}). Skill names are a flat namespace at the "
                "deploy target; rename one."
            )

    for line in failures:
        print(line)

    if not failures:
        total = len(payload) + len(project)
        print(
            f"ok: {total} skill name(s) unique across {len(payload)} in skills/ "
            f"and {len(project)} in .claude/skills/.",
            file=sys.stderr,
        )
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
