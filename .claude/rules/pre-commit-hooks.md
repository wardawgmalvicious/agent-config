---
paths:
  - "**/.pre-commit-config.yaml"
  - "scripts/lint-*.py"
---

# Pre-commit hooks and the linters

- The hooks are depth-pinned. `lint-skills` matches
  `^(skills/[^/]+|\.claude/skills)/[^/]+/SKILL\.md$`: the first arm takes a
  group segment and the second none, so `skills/<group>/<name>/SKILL.md` and
  `.claude/skills/<name>/SKILL.md` match and nothing else does. A skill
  placed flat, or a level deeper, is skipped by the linter and invisible to
  Claude Code's one-level discovery: two silent failures from one
  misplacement. `lint-rules` is flat the same way and misses a nested rule.
- A `files:` pattern that matches nothing prints
  `(no files to check) Skipped`, which reads as a pass, so a widened pattern
  proves nothing until both arms are run:
  `pre-commit run lint-skills --files .claude/skills/author-skill/SKILL.md`
  must say `Passed`, and the same with
  `--files skills/author-skill/SKILL.md` must say `Skipped`. `author-skill`
  is the example because its subject is this repo's own authoring, which
  makes it the project skill least likely to become payload; if it moves,
  repoint the example to whatever is still in `.claude/skills/` and re-run
  both arms.
- A change to `reaches_copilot()` in `lint-frontmatter.py` is proved the
  same way, with one `SKILL.md` carrying an active `model:`: it must fail at
  `skills/workflow/…` and pass at `.claude/skills/…` and at
  `skills/meta/learn/SKILL.md`, then fail there with `.no-copilot` removed,
  which shows the marker, not the group name, doing the work (2026-09-15).
- Skill names are one flat namespace across both trees, since Claude Code
  addresses a skill by name alone. `scripts/lint-skill-scopes.py` runs over
  the whole set because a collision belongs to a pair. A name in both trees
  is the silent case: user scope wins, the project copy stops loading, and
  the only symptom is the skill behaving like an older version of itself. A
  name repeated across `skills/` groups would fail both deploy scripts
  anyway; this fails it before the commit.
- Any check whose defect belongs to a pair — names, `skillOverrides`
  coverage, routing, test stamps, audit indexes, Copilot ports — runs over
  the whole set with `pass_filenames: false`, since no per-file hook can see
  a pair.
- Only `tests/` is gitleaks-allowlisted, because its fixtures hold fake
  credential-shaped strings. `docs/` is scanned (2026-09-07): if a doc ever
  needs an exemption, allowlist that path, never the tree.
