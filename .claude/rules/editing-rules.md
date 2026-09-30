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
- A rule's whole body is paid again after each compaction, at the next
  matching Read, not once a session: without a compaction no rule loaded
  more than twice, with them one loaded 21 times, and one client session
  paid 574 KB of user rules in 77 loads across 12 compactions, against
  71 KB had each loaded once (164 sessions, seven repos, 2026-09-30). A
  section only some matching files need costs every other one on each
  load: a narrower glob is the rule's own lever.
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
- A rule with a port in `copilot/instructions/` leaves the port as it is:
  the Copilot payload is being retired, and no port is redone
  (2026-09-30). Pre-commit still fails the rule edit, with `drift`, until
  `uv run --with pyyaml scripts/lint-instructions.py --stamp` records the
  new hash, and fails a new rule as `untracked` until
  `copilot/.source-hashes.json` lists it under `deferred`
  (`docs/handoffs/execute/copilot-payload-retirement.md`).
