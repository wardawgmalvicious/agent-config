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
[skill-optimization-pass.md](execute/skill-optimization-pass.md).

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
