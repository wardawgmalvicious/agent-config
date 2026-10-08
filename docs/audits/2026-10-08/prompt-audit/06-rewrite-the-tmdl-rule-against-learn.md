# Handoff: rewrite the TMDL rule against Learn

- **Audit run**: 2026-10-08
- **Source**: `prompt-audit`
- **Window**: floor none, the whole payload → head `c268691`
  (2026-10-08)
- **Covers recommended actions**: findings 3, 4, 5 and 30, and decision 8
- **Kind**: correctness rewrite of a user-scope rule's syntax and
  examples, with the code-review fixture that asserts them. Reaches
  every repo at the next deploy.
- **Target**: `claude/rules/coding-tmdl.md`,
  `claude/rules/coding-dax.md`,
  `tests/skills/code-review/expected_findings.md`

## The problem

`claude/rules/coding-tmdl.md` loads on every TMDL file in a
`*.SemanticModel` folder, and teaches syntax this repo's own
`fabric-tmdl` skill calls invalid: a `displayName:` alias on every
object, the `description:` property, space indentation, and `#` lines
inside `tmdl` fences. Both load on the same files, so a session holds
the two contradicting each other, and a model copying the rule's
examples writes files that will not validate.

## Evidence

From `claude/rules/coding-tmdl.md`, read 2026-10-08, line numbers at
`c268691`:

- § "Naming and aliasing", line 35: "Pattern: **PascalCase identifier,
  aliased display name with spaces.**" The fence at 49-74 gives each
  column and measure a `displayName: "…"` line, opens with `# Good` and
  `# Bad` lines, indents with four spaces, and puts
  `lineageTag: <guid>` on a new table. Lines 83-84: "DAX always
  references display names … You write the identifier in TMDL but DAX
  consumes the display."
- § "Descriptions", line 142: "Use the `description` property on
  tables, columns, and measures", and the fence at 146-151 writes
  `description: "…"`.
- § "Relationships", lines 137-138: "Inactive relationships need a
  comment" (decision 8).
- Line 18, "TMDL is newer", and lines 156-157, "(recent feature)"
  (finding 30).

From `skills/fabric/fabric-tmdl/SKILL.md`, the same day:

- Line 15: "**TMDL uses tab indentation** — every nesting level is
  exactly one tab (`\t`), NOT spaces. Spaces cause validation errors."
- Line 20: "Descriptions use `///` placed ABOVE the object — do NOT use
  the `description` property".
- Line 204: a `//` comment is "Not supported"; "Use `///` on line above
  the object (descriptions only)".

The report adds, citing Learn, that every TMDL property is a TOM
property, that there is no display-name property, and that captions
exist only as translations; and that `fabric-tmdl` forbids `lineageTag`
on new objects. **The session that wrote this brief did not check those
against Learn.**

## Sequencing note

**Work this with `docs/handoffs/execute/rule-naming-conflicts.md`, in
one pass, after its decision.** That brief, priority 1, written by a
`/triage` of a client repo's prompt audit on 2026-10-08 (`566973a`),
owns finding 3: it re-measured the `displayName:` lines against TOM's
API reference and the TMDL reference, and puts the naming convention to
the user, with `coding-dax.md`'s table-name line. Its answer sets the
names in the same fences this brief rewrites, so neither pass should
run alone.

`d60be04` already added a paragraph after § "Copying syntax from Learn"
saying TMDL indents with one tab per level, worded to the TMDL overview
and ending "This file's examples are space-indented for display: write
tabs", and dropped "(recent feature)" from lines 156-157. That keeps
the space-indented fences, where the report rewrites them with real
tabs: choose one, and say which in the log. Re-read the rule at `HEAD`
first.

## What to change

1. **§ "Naming and aliasing"** (finding 3): owned by
   `rule-naming-conflicts.md`, as the sequencing note says. Apply its
   decision here, in the same pass, rather than rewriting the naming
   from this brief.
2. **§ "Descriptions"** (finding 4): `///` lines directly above the
   object, and no `description:` property.
3. **Every `tmdl` fence** (finding 5): indentation by the choice in the
   sequencing note, no `#` lines (put Good and Bad in the prose above
   the fence), and no `lineageTag` on a new object.
4. **Line 18** (finding 30): drop "TMDL is newer". Lines 156-157 were
   fixed in `d60be04`.
5. **§ "Relationships"** (decision 8): an inactive relationship cannot
   carry a comment. Say where its reason goes instead, such as a `///`
   description or the measure that activates it, or drop the line. The
   report left this to the user at low confidence, so record the
   choice in the log.
6. **Dependents**: `claude/rules/coding-dax.md:24-26`, whose table-name
   line points at the alias pattern, goes with
   `rule-naming-conflicts.md`. `tests/skills/code-review/expected_findings.md`
   asserts the `displayName` pattern where the report says (243-274,
   283 and 316-321), and changes in whichever pass removes it.

The patch's hunks for these files are a starting point only. Its
`coding-tmdl.md` hunks no longer apply after `d60be04`: re-derive them
from `HEAD`. If the fences take tabs, write the bytes with a tool that
keeps them, and check them (step 3 below).

## Constraint on the fix

- **Learn first.** Read the TMDL overview before writing any syntax
  claim. The rule's own § "Copying syntax from Learn" says
  `microsoft_docs_fetch` joins tab-indented lines: `curl -s` the page
  and read its `lang-tmdl` block.
- Where Learn and `fabric-tmdl` disagree, stop and say so: then one of
  them is wrong as well.
- The rule and `coding-dax.md` have frozen Copilot ports. Leave the
  ports as they are (`editing-rules.md`).

## Verification

1. The Learn page's URL and the date it was read, in the log.
2. `grep -n 'displayName\|description:\|^# Good\|^# Bad' claude/rules/coding-tmdl.md`
   finds nothing but prose that names them as invalid.
3. If the fences take tabs: inside each `tmdl` fence, every indented
   line starts with a tab (`grep -nP '^ +\S' claude/rules/coding-tmdl.md`
   lists no line inside a fence).
4. The code-review fixture test, per `tests/skills/code-review/README.md`,
   against the corrected `expected_findings.md`.
5. `uv run --with pyyaml scripts/lint-instructions.py --stamp`, which
   the two ported rules need before pre-commit's `drift` check passes.
6. `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`, then
   diff the deployed rule against the repo's.
7. `pre-commit run --all-files`.

## Provenance

Findings 3, 4 and 5 (high) and 30 (medium), and decision 8 (low), from
`/doctor prompt-audit` run in this repo on 2026-10-08, which ranked
this the first of its three most serious problems. The session that
wrote this brief checked the rule's text and the `fabric-tmdl` lines
the same day, not Learn.

## Execution log

- **Executed**: 2026-10-08 — escalated
- **Session**: fresh (no audit or handoff run in this session; the whole
  pass, in its own worktree)
- **Files changed**: none
- **Verification**: none of the brief's steps ran. Its sequencing note
  binds it to `docs/handoffs/execute/rule-naming-conflicts.md`, "in one
  pass, after its decision", and that brief is `open` with
  `needs: [user]` at `26f8582` and on `main` at `4ee3a7a`: the naming
  decision is unmade and its `displayName:` deserialization probe unrun.
  The quotes, re-measured at `26f8582` for that pass: the alias pattern
  at line 39, 35 at `c268691`, below `d60be04`'s tab paragraph, now at
  35; six `displayName:` lines; `description:` at 153; "TMDL is newer"
  at 18; the inactive-relationship line at 141; `# Good` and `# Bad` at
  54, 74 and 99; "(recent feature)" gone; `coding-dax.md:24-26` as
  quoted.
- **Deferred**: the whole brief, to the joint pass: findings 3, 4, 5
  and 30, decision 8 and the indentation choice, then steps 1 to 7.
  Decision 8 was not put to the user here: whether a relationship can
  carry a `///` description is a Learn question the pass answers first,
  under this brief's own "Learn first" constraint.
- **Deviations**: none
- **Needs**: user — the naming decision in
  `docs/handoffs/execute/rule-naming-conflicts.md`; then that brief and
  this one in one pass, in its worktree, which puts decision 8 to the
  user once Learn says where a relationship's reason can go.
