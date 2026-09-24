---
paths:
  - ".claude/settings.json"
  - "scripts/lint-skill-overrides.py"
---

# The skillOverrides block

- `.claude/settings.json`'s `skillOverrides` collapses every platform skill
  description — `skills/fabric/` and `skills/powerbi/` — to `name-only` in
  sessions here. It stays even though the workflow-only prune keeps those
  skills out of `~/.claude/skills`: it keeps them auditable from this repo
  and the shape ready for a future edit.
- Never collapse `workflow`, `social` or `meta`: `commit`, `code-review` and
  the rest are reached by description. The lint skips those groups, so a
  collapsed behavioural skill passes pre-commit.
- The block is a by-name map with no pattern form, so a new platform skill
  is uncovered until `scripts/lint-skill-overrides.py` fails in pre-commit.
  It runs over the whole set, since the defect is a pair — a new skill and a
  settings file nobody changed — that no per-file hook sees. It also fails a
  value other than `name-only`, an override a rename left behind (for
  platform prefixes only), and a group it cannot classify: add a new group
  to `PLATFORM_GROUPS` or `BEHAVIOURAL_GROUPS`.
- A policy change is the script's `EXPECTED` and root's paragraph, edited
  together. Never write down how many skills are collapsed.
