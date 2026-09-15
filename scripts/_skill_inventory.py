#!/usr/bin/env python3
"""One inventory of both skill trees, for scripts that need more than names.

Six scripts here walk ``skills/<group>/<name>/SKILL.md`` and
``.claude/skills/<name>/SKILL.md``, and until this module each walked it its
own way. That was tolerable while every walker wanted a different slice --
file hashes for skill-status.py, group membership for
lint-skill-overrides.py, ``paths:`` globs for payload-coverage.py. It stopped
being tolerable when skill-overlap.py needed the records skill-telemetry.py
already builds, because the next copy would have been the third walker
pulling ``description`` out of frontmatter.

THIS RETURNS A LIST, NOT A DICT KEYED BY NAME, and that is not a style
choice. lint-skill-scopes.py exists to find two skills sharing one name, so a
name-keyed inventory silently drops one of every pair it is looking for.
Keying is left to the caller that knows it is safe -- ``by_name()`` is there
for callers that do, since pre-commit gates uniqueness.

DEPENDENCIES: pyyaml and nothing else. ``glob_flags()`` imports wcmatch
lazily rather than exposing a ``GLOB_FLAGS`` constant, because wcmatch is an
extra that only the glob-matching callers pass to ``uv run``. A module-scope
import would make every pyyaml-only caller fail on a dependency it never
uses.
"""

from __future__ import annotations

import dataclasses
import pathlib

import yaml

REPO = pathlib.Path(__file__).resolve().parent.parent

# Claude Code discovers a skill at <skills-root>/<name>/SKILL.md -- one level,
# no group directory in between. So the deployable tree carries a group
# segment that the deploy script flattens away, while the project-scope tree
# is already flat because it is read in place.
USER_TREE = REPO / "skills"
PROJECT_TREE = REPO / ".claude" / "skills"


@dataclasses.dataclass
class Skill:
    """One skill on disk. ``name`` is the directory, which is how it is addressed."""

    name: str
    scope: str  # "user" (deployed machine-wide) | "project" (this repo only)
    group: str | None  # None at project scope -- that tree has no group segment
    path: pathlib.Path  # the SKILL.md itself
    description: str
    when_to_use: str
    paths: list[str]

    @property
    def conditional(self) -> bool:
        """Withheld from the startup listing until a matching file is Read.

        A conditional skill being absent from every listing is the design, not
        a finding. Conflating the two produced this repo's one retracted
        telemetry finding.
        """
        return bool(self.paths)

    @property
    def listing_chars(self) -> int:
        """What the startup listing spends on this skill.

        description + when_to_use is the whole of what loads up front --
        the body loads only on invocation. This is the per-skill quantity a
        catalog-wide budget check would sum; nothing sums it yet.
        """
        return len(self.description) + len(self.when_to_use)

    @property
    def rel(self) -> str:
        """Repo-relative posix path, for diagnostics a person has to click."""
        return self.path.relative_to(REPO).as_posix()


def frontmatter(path: pathlib.Path) -> dict:
    """Frontmatter of one markdown file, or {} if it has none or is malformed.

    A malformed block reads as empty rather than raising: lint-frontmatter.py
    owns that failure, and an inventory that dies on one bad file cannot
    report on the rest. Terminated by a line-leading ``---`` rather than by
    splitting on the first one anywhere, so a ``---`` inside a description
    does not truncate the block.
    """
    text = path.read_text(encoding="utf-8", errors="replace")
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        return {}
    try:
        return yaml.safe_load(text[3:end]) or {}
    except yaml.YAMLError:
        return {}


def _as_list(value) -> list[str]:
    """Normalize a scalar-or-sequence frontmatter value to a list of strings."""
    if not value:
        return []
    if isinstance(value, str):
        return [value]
    return [str(v) for v in value]


def _load(d: pathlib.Path, scope: str, group: str | None) -> Skill | None:
    """One skill directory, or None if it holds no SKILL.md.

    A directory without one is not a skill -- references/, a stray folder.
    Skipping it is what keeps this in step with Claude Code's own discovery.
    """
    f = d / "SKILL.md"
    if not f.is_file():
        return None
    meta = frontmatter(f)
    return Skill(
        name=d.name,
        scope=scope,
        group=group,
        path=f,
        description=str(meta.get("description") or ""),
        when_to_use=str(meta.get("when_to_use") or ""),
        paths=_as_list(meta.get("paths")),
    )


def skills() -> list[Skill]:
    """Every skill in both trees, user scope first, each tree sorted by name."""
    out: list[Skill] = []
    if USER_TREE.is_dir():
        for group in sorted(p for p in USER_TREE.iterdir() if p.is_dir()):
            for d in sorted(p for p in group.iterdir() if p.is_dir()):
                s = _load(d, scope="user", group=group.name)
                if s is not None:
                    out.append(s)
    if PROJECT_TREE.is_dir():
        for d in sorted(p for p in PROJECT_TREE.iterdir() if p.is_dir()):
            s = _load(d, scope="project", group=None)
            if s is not None:
                out.append(s)
    return out


def by_name(inventory: list[Skill] | None = None) -> dict[str, Skill]:
    """Map name -> skill. ONLY for callers that are not looking for collisions.

    Safe because lint-skill-scopes.py fails the commit when two skills share a
    name; if that gate is ever removed this quietly hides one of each pair.
    """
    return {s.name: s for s in (skills() if inventory is None else inventory)}


def glob_flags():
    """wcmatch flags for matching ``paths:`` globs against repo-relative paths.

    GLOBSTAR | DOTGLOB is what activation-expect.py predicts activation with,
    and payload-coverage.py duplicates for the same reason. Those two must
    agree with each other or they report coverage the harness would not
    confirm, so the value lives here once.

    payload-coverage.py's docstring records the duplication as unavoidable --
    "a hyphen in that filename makes it un-importable". That is backwards: a
    hyphenated script cannot be imported FROM, but it can import. Neither
    script is migrated here, since neither needs anything else this module
    offers; the constant is simply no longer forced to be copied again.
    """
    from wcmatch import glob as wg

    return wg.GLOBSTAR | wg.DOTGLOB
