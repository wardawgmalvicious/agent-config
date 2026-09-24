---
paths:
  - "**/CLAUDE.md"
  - "docs/evidence/*.md"
---

# Editing a CLAUDE.md, or its evidence ledger

- Root `CLAUDE.md` loads in every session in this repo, and is re-read from
  disk after `/compact`. `claude/CLAUDE.md` deploys to `~/.claude/CLAUDE.md`
  and loads in every session on the machine. Each holds only what a session
  needs before it has Read anything: root, this repo's conventions;
  `claude/CLAUDE.md`, the machine environment and pointers.
- An instruction in either carries three things: the rule, what its failure
  looks like (the error text, or the silence) and one date. Its evidence —
  how it was measured, what was believed before, counts, SHAs — goes to that
  file's ledger under the same heading: `docs/evidence/root-claude-md.md`
  for root and `.claude/rules/`, `docs/evidence/user-claude-md.md` for
  `claude/CLAUDE.md`. Move it verbatim, as whole paragraphs, in the commit
  that cuts it, so `git blame -C` still reaches the commit that wrote each
  line.
- A ledger's entries are dated and never corrected in place: a rule that
  changes gets a new entry at the end of its heading, opening with its date
  in bold. A ledger's headings mirror its file's.
- Guidance a file triggers goes to a `paths:`-scoped rule — `.claude/rules/`
  for root, `claude/rules/` for `claude/CLAUDE.md` — and guidance for one
  task to a skill. Never an unscoped rule, an `@import` or a subdirectory
  `CLAUDE.md`: the first two load at launch anyway, and the third on any
  Read beneath it.
- `scripts/lint-claude-md.py` caps `claude/CLAUDE.md` in pre-commit. A
  learning that does not fit moves something out; the cap never rises.
- A count, or a list of which skills a group holds, goes stale: write the
  command that derives it instead.
- An HTML comment costs no context but shows on every Read: use one only for
  a note to the next editor, never for evidence.
- `claude/CLAUDE.md` is a copy: after an edit, deploy it with
  `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`,
  never bare.
