---
paths:
  - "claude/rules/*.md"
  - ".claude/rules/*.md"
  - "copilot/instructions/*.md"
---

# Editing a rule, or its Copilot port

- A rule carries only `paths:`, and loads when a file matching it is Read.
  So it never loads for a `cat`, `sed` or heredoc edit, and it cannot govern
  creating a file, since the first file in a directory has nothing to Read:
  guidance about making something belongs in a skill description or a hook
  (reasoned 2026-09-16, not measured).
- A wrong glob has no error path; the rule just never loads.
  `scripts/lint-frontmatter.py` rejects the mistakes that silently narrow a
  pattern: a backslash, a leading `/` or `./`, and a bare `*.ext` with no
  `/`, which matches root-level files only (`**/*.ext` matches nested ones
  too). Lint with `uv run --with pyyaml scripts/lint-frontmatter.py <rule>`;
  pre-commit's `lint-rules` runs it on both rule trees.
- Every rule in `claude/rules/` says a same-named project copy "supersedes
  this one", and that sentence is what does the overriding: Claude Code
  loads both sets, and its docs say "Neither set overrides the other"
  (2026-09-23). Write the sentence into every new user-scope rule, and never
  name a rule in `.claude/rules/` after one in `claude/rules/`: the
  collision would silently switch that rule off in this repo.
- A rule in `.claude/rules/` is this repo's own: project scope, deployed
  nowhere, no deploy step. It is read when a matching file is Read, so a new
  one loads at its next matching Read even mid-session, and an edit to one
  already loaded reaches the session as a change notice (2026-09-24,
  2.1.268). It must carry `paths:`, since an unscoped rule loads at launch
  like `CLAUDE.md` and undoes the split, and no glob may reach
  `tests/**/fixtures/**`, where fixture tests need a clean context. Write it
  terse, one date per claim, with no history; its evidence goes to
  `docs/evidence/root-claude-md.md` under the root heading it came from. An
  HTML comment costs no context but shows on every Read, so use one only for
  a note to the next editor, never for evidence.
- A rule with a port in `copilot/instructions/` needs the port redone by
  hand after an edit, then
  `uv run --with pyyaml scripts/lint-instructions.py --stamp`; pre-commit
  fails the rule edit until the port follows (`copilot-payload.md`).
