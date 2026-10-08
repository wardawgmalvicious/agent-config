# Handoff: refresh the editing-skills rule

- **Audit run**: 2026-10-08
- **Source**: `prompt-audit`
- **Window**: floor none, the whole payload → head `c268691`
  (2026-10-08)
- **Covers recommended actions**: findings 19, 20 and 21
- **Kind**: wording in a project-scope rule, plus one cost ratio to
  re-measure. No behavior changes.
- **Target**: `.claude/rules/editing-skills.md`

## The problem

`.claude/rules/editing-skills.md` states two facts relative to an
earlier state ("no longer"), and prices the Fable pin at twice the Opus
tier, a ratio the audit puts at 2.5 times.

## Evidence

Read 2026-10-08:

- § "Name and listing budget", finding 19: "A `skills/workflow/` skill
  reaches Copilot only as a copy, and the copy is no longer refreshed".
- § "Invocation and spend fields", finding 20: "A top-level
  `effortLevel` in user settings no longer counts for Opus 5.5 or
  later".
- The same section, finding 21: "Pin `fable` only where judgment is
  irreducible … because it costs twice the Opus tier (2026-09-12)." The
  report: "Fable at $10/$50 against Opus 5.5 at $4/$20 is 2.5 times",
  from the bundled model table cached 2026-09-25, not a pricing page.

## What to change

1. Finding 19: state the current fact, that the copy is not refreshed
   while the Copilot payload is retired, without "no longer".
2. Finding 20: state which setting counts for Opus 5.5 and later,
   without "no longer".
3. Finding 21: re-measure the ratio on the live pricing page, then
   write the ratio found, dated. Where the page and the report differ,
   the page wins.

The patch's `editing-skills.md` hunks carry all three, plus finding 2's
(brief 01): apply these by hand, or apply the file and keep only this
brief's hunks.

## Constraint on the fix

Do not copy the report's dollar figures without the page: they come
from a cached table, and a price is the claim most likely to have
moved.

## Verification

1. The pricing page, read the day of the fix, and that date in the
   rewritten sentence.
2. `grep -n 'no longer' .claude/rules/editing-skills.md`: neither of
   the two passages remains.
3. The evidence for each changed claim in
   `docs/evidence/root-claude-md.md`, under the root heading the rule
   came from (`editing-rules.md`).
4. `pre-commit run --all-files`.

## Provenance

Findings 19 to 21, medium confidence, from `/doctor prompt-audit` run
in this repo on 2026-10-08. The session that wrote this brief read all
three passages the same day.
