# Handoff brief examples

Reference briefs derived from validated artifacts now in the repo. Each
example is a complete brief — the same shape Claude Code would have
received to draft the artifact in question.

## What's here

- [code-review-skill.example.md](code-review-skill.example.md) — brief
  for [skills/code-review/](../../../skills/code-review/SKILL.md).
- [security-reviewer-agent.example.md](security-reviewer-agent.example.md)
  — brief for [agents/security-reviewer.md](../../../agents/security-reviewer.md).

## How to use them

When authoring a new skill or subagent, find the closest example by
shape (multi-language reference skill, behavioral subagent with hooks,
read-only contract, etc.) and lift it as design source. The new brief
notes that lineage in its `Changes from source proposal` section:

> N/A — design lifted directly from
> `docs/handoff-briefs/examples/<path>`. No design changes; example is
> the design.

This avoids re-narrating the example's design rationale and keeps the
new brief focused on what (if anything) deviates from the example.
