# Handoff briefs

Templates and worked examples for the brief-before-draft pattern used to
author skills and subagents in this repo.

## The pattern

Skills and subagents with non-trivial behavioral contracts — refusal
patterns, severity rubrics, scope-enforced read-only or destructive
guards — are authored brief first:

1. A structured handoff brief is written, covering frontmatter specs,
   body outline, portability caveats, and post-draft validation steps.
2. The artifact is drafted from the brief, then the post-draft
   checklist is run.

The brief is the unit that matters, not the surface that types it. The
two steps were originally split across a chat session and Claude Code,
because only one had filesystem access and only the other could drill
sources at length; Claude Code does both now, and the steps routinely
happen in one session. The brief is still worth writing — it is the
record of what was decided and what was deliberately left out, and the
excluded set is what bounds the draft.

For pure reference skills (canonical-answer content, no enforcement
contract), the pattern is overkill — real-use validation suffices.

See [Handoff discipline](../../README.md#handoff-discipline) in the
top-level README for additional context.

## What's here

- [templates/skill-handoff.md](templates/skill-handoff.md) — fill-in
  template for new skills.
- [templates/subagent-handoff.md](templates/subagent-handoff.md) — fill-in
  template for new subagents.
- [examples/](examples/) — reference briefs derived from validated
  artifacts in the repo. See [examples/README.md](examples/README.md).

Open briefs — work scoped but not yet done — wait in
[execute/](execute/). Queued right now:

- [skill-context-cost.md](execute/skill-context-cost.md) — listing and
  activation cost of the skill payload. Workstreams A and B are done;
  C (merges), D (`when_to_use`) and E (unconditional-skill cleanup) are open.
- [skill-model-policy.md](execute/skill-model-policy.md) — invocation control
  and model/effort pins. Spend, not context.
- [skill-effectiveness-telemetry.md](execute/skill-effectiveness-telemetry.md)
  — scoping for a post-session telemetry capability. Stands alone.

Those three came from consolidating four briefs into two on 2026-08-31,
because two of them had begun to contradict each other and a retracted
finding from one had already propagated into a third. **Briefs on the same
subject belong in one file** — a split that outlives its reason is how the
contradiction got in.

Five more were added on 2026-08-31 from the trigger-fixture work
(`ee0a8f5`, `9d49302`), which measured `paths:` activation for the first
time. Each is a separate file because each resolves independently and gets
deleted on its own:

- [rule-glob-gaps.md](execute/rule-glob-gaps.md) — **three rule `paths:`
  globs that never match what they target.** Take this one first:
  `coding-sparksql.md` has never fired on a Fabric notebook, and
  `coding-tsql.md` matches instead, so Spark SQL gets T-SQL conventions.
- [item-type-skill-datapipeline.md](execute/item-type-skill-datapipeline.md)
  — recommendation: **yes, author it.**
- [item-type-skill-lakehouse.md](execute/item-type-skill-lakehouse.md) —
  recommendation: a `paths:` glob on an existing skill, not a new one.
  Overlaps Workstream E in `skill-context-cost.md`; decide once.
- [item-type-skill-kqlqueryset.md](execute/item-type-skill-kqlqueryset.md)
  — recommendation: **no skill**; it is a rule-glob fix. Pairs with
  `rule-glob-gaps.md` bug 2.
- [fixture-shape-capture.md](execute/fixture-shape-capture.md) — capture
  real `.DataAgent` / `.SQLDatabase` / `.GraphModel` exports. Blocks
  `rule-glob-gaps.md` bug 3, and is a known hole in A2.

That is eight open briefs, which is more than this queue has held before.
They are not equal: `rule-glob-gaps.md` is a live wrong-guidance bug, and
the rest are scoped improvements.

**Once the change lands, the brief is deleted.** Git history is the
archive — the brief was committed when it was written, so
`git log --diff-filter=D -- 'docs/handoff-briefs/**/<name>.md'` finds the
deleting commit and `git show <sha>^:<path>` recovers it in full. A
retained copy only competes with the artifact it produced.

This is *not* the `docs/drift-audit/` rule, which gitignores its output
outright. That output is regenerable — re-run the audit and it comes
back. A brief is hand-derived: the measurements and doc citations in it
cost a research session, so it is committed when written and deleted
when spent, rather than never committed at all.

The one exception is a brief that is still *referenced* — cited by a
skill, or worth lifting as design source. That one gets promoted into
[examples/](examples/) under the `.example.md` name, and the citation
updated to the new path. Promotion is the deliberate keep-path; there is
no third "completed" state.

## For consumers cherry-picking from this repo

The templates are internal authoring tooling. You don't need to adopt
the brief pattern to use the skills or subagents — they work standalone
in any `~/.claude/`. Templates are included in case the discipline is
useful elsewhere.
