# Handoff briefs

Templates and worked examples for the brief-before-draft pattern used to
author skills and subagents in this repo.

## The pattern

Skills and subagents with non-trivial behavioral contracts — refusal
patterns, severity rubrics, scope-enforced read-only or destructive
guards — are authored across two surfaces:

1. A chat-Claude session produces a structured handoff brief covering
   frontmatter specs, body outline, portability caveats, and post-draft
   validation steps.
2. Claude Code drafts the artifact from the brief, then runs the
   post-draft checklist.

The two surfaces specialize: chat-Claude has more context window and is
better at structural proposal; Claude Code has filesystem access and is
better at drafting and iterating.

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

## For consumers cherry-picking from this repo

The templates are internal authoring tooling. You don't need to adopt
the brief pattern to use the skills or subagents — they work standalone
in any `~/.claude/`. Templates are included in case the discipline is
useful elsewhere.
