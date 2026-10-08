---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-07
---

# Handoff: the next audit of a source reads the re-checks owed to it

- **Written**: 2026-10-07, by the session that taught `/triage` to sweep
  old audit follow-ups; the user asked for this one as a brief of its
  own. Measured at `ac140a6`.
- **Kind**: an edit to two project-scope skills, `drift-audit` and
  `drift-handoff`, with the shape drafted below and no text.

## What is wrong

A follow-up whose `**Needs**:` line names the next audit of its source
waits on a run that never looks for it. Nothing in `drift-audit` or
`drift-handoff` reads a `**Needs**:` line, and `drift-audit` § 2
resolves its floor from its argument alone: a SHA, a date, or 35 days
back (measured 2026-10-07).

`2026-09-07/powerbi/01` needed the next `powerbi` audit to reproduce
three commits from a 2026-08-01 floor, cold. That audit ran on
2026-10-06 from a 2026-09-01 floor. Its report found the 2026-09-07 run
in the ledger unprompted, to check its floor left no gap, and left 01's
log as it was, so 01 still waits on a run that has already happened.
Nine follow-ups wait the same way today; the command below lists them.

Closing them by hand has worked once. The 2026-09-12 `skills-for-fabric`
run was the deferred re-check of 2026-09-10 brief 06, and its handoff
wrote a bookkeeping brief that appended the closures:
[2026-09-12/skills-for-fabric/completed/03-stamp-the-2026-09-10-deferred-verifications.md](../../audits/2026-09-12/skills-for-fabric/completed/03-stamp-the-2026-09-10-deferred-verifications.md).
Nothing in either skill asks for one.

## Shape of the fix

1. **`drift-audit` § 2 reads the source's ledger** once the floor is
   resolved: every open follow-up under `docs/audits/*/<source-id>/`,
   one whose log has an open outcome and no `**Closed**:` line, as
   `audit-status.py` rules, and whose last `**Needs**:` line names this
   source's next audit. With Grep and Read: Bash is outside the skill's
   `allowed-tools`, so `handoff-status.py` is not in reach.
2. **The report gains a section, owed re-checks**: each one, what it
   must reproduce, and whether this run did it: passed, failed, or not
   in this window, such as commits that fall below this run's floor.
3. **`drift-handoff` writes one bookkeeping brief** whenever that
   section is not empty, which appends a `**Closed**:` line to each
   re-check that passed and a fresh `**Needs**:` line to each this run
   could not perform, as the 2026-09-12 brief did.
4. **Optional: `drift-update`'s stamp template fixes the phrase**,
   `the next <source-id> drift audit`, so step 1 matches exactly.
   Today's lines vary: "the next powerbi drift audit", "the next `fabric`
   audit", "the next `/drift-audit --sources fabric-iq-ontology` run",
   "the first powerbi drift audit after Learn republishes".

`/triage`'s Stays verdict leaves such a re-check in its log while no
audit of its source has run since, and re-judges it once one has. This
fix makes that audit settle it first.

## Where it lands

`.claude/skills/drift-audit/SKILL.md` § 2 and § 7's report format,
`.claude/skills/drift-handoff/SKILL.md`, and for item 4
`.claude/skills/drift-update/SKILL.md`'s stamp template. All project
scope, so nothing deploys; each body edit owes its skill a `/test-skill`
retest, which `skill-status.py --stale` will name.

## Not checked

- **Whether an old re-check can run in a later window at all.**
  `2026-09-07/powerbi/01` reproduces commits that a 2026-09-01 floor
  excludes, so a known-answer re-check may need a run at its own floor,
  which the report would say rather than pass it.
- **`drift-handoff`'s grouping rules** for a bookkeeping brief were not
  read.

## Re-measure before acting

```bash
uv run scripts/handoff-status.py . --no-inbox | grep -iE 'needs the (next|first) .*(audit|run)'  # nine on 2026-10-07
grep -c 'Needs\*\*' .claude/skills/drift-audit/SKILL.md .claude/skills/drift-handoff/SKILL.md      # 0 and 0 on 2026-10-07
```
