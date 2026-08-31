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

- [skill-handoff-template.md](skill-handoff-template.md) — fill-in
  template for new skills.
- [subagent-handoff-template.md](subagent-handoff-template.md) — fill-in
  template for new subagents.
- [examples/](examples/) — reference briefs derived from validated
  artifacts in the repo. See [examples/README.md](examples/README.md).

Open briefs — work scoped but not yet done — sit at this level alongside
the templates, and are deleted once the change lands. Open right now:
[author-skill.md](author-skill.md) and
[fabric-mirroring.md](fabric-mirroring.md). Also sitting here:
[drift-handoff-skill.md](drift-handoff-skill.md), whose change has
already landed — it is pending deletion or promotion into
[examples/](examples/), and is the standing evidence that the
delete-once-landed rule does not enforce itself.

## For consumers cherry-picking from this repo

The templates are internal authoring tooling. You don't need to adopt
the brief pattern to use the skills or subagents — they work standalone
in any `~/.claude/`. Templates are included in case the discipline is
useful elsewhere.
