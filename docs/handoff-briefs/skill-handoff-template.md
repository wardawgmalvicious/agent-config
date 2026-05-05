# Skill handoff brief: {{skill-name}}

Last verified: {{YYYY-MM-DD}}

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

> Guidance: Where the drafted SKILL.md lands. State personal vs. project scope and the exact path. Personal: `~/.claude/skills/{{skill-name}}/SKILL.md`. Project: `<repo-root>/.claude/skills/{{skill-name}}/SKILL.md`.

{{path}}

## Scope

> Guidance: One paragraph. What the skill does, inline vs. forked execution (`context: fork` vs. default inline), model-invocable vs. user-only (`disable-model-invocation`, `user-invocable`), path-scoped vs. not (`paths:`). No design discussion — just the what.

{{scope paragraph}}

## Frontmatter

> Guidance: Fill every field you intend to set. Delete lines for fields you're not using — don't leave them as empty placeholders. Constraint comments stay as inline YAML `#` comments so the filled brief carries its own reference.

```yaml
---
name: {{skill-name}}  # required; max 64 chars; lowercase letters/numbers/hyphens; forbidden words "anthropic"/"claude"
description: {{one-sentence trigger description}}  # required; keep under 1,024 chars for Agent Skills portability; Claude Code caps description + when_to_use combined at 1,536 chars in skill listing
when_to_use: {{when-to-use guidance}}  # optional; counts toward combined 1,536 Claude Code cap with description
argument-hint: {{[arg-hint]}}  # optional; autocomplete display hint shown in / menu, e.g. [issue-number]
arguments: {{arg1 arg2}}  # optional; space-separated string or YAML list; enables $name substitution in skill body
disable-model-invocation: {{false}}  # optional; set true for destructive/manual-only skills
user-invocable: {{true}}  # optional; set false to hide from / menu for reference-only skills
allowed-tools: {{Bash(git add *) Bash(git commit *) Read Grep}}  # optional; space-separated items; each Bash specifier uses space form inside parens; YAML list form also accepted
model: {{inherit}}  # optional; sonnet / opus / haiku / full model ID / inherit
effort: {{medium}}  # optional; low / medium / high / xhigh / max; availability model-dependent
context: {{inline}}  # optional; "fork" runs in a subagent, otherwise inline in current session
agent: {{general-purpose}}  # optional; only meaningful when context: fork; Explore / Plan / general-purpose / custom subagent name
hooks: {{null}}  # optional; skill-scoped lifecycle hooks
paths: {{src/**/*.ts}}  # optional; comma-separated string or YAML list; glob patterns for path-scoped auto-activation
shell: {{bash}}  # optional; "bash" (default) or "powershell"; powershell requires CLAUDE_CODE_USE_POWERSHELL_TOOL=1
---
```

## Description char count

> Guidance: State the count explicitly so Claude Code can re-check after draft. Pick the cap that matches your Tag (section below): publishable/open-standard → 1,024; personal/Claude Code-only → 1,536 combined.

{{N}} / {{1,024 portable cap | 1,536 Claude Code combined cap}}

## Body structure outline

> Guidance: Numbered list or subheadings — one line per section describing what belongs there. Not draft prose. The body is what Claude Code drafts after receiving this brief.

{{body-outline}}

## Changes from source proposal

> Guidance: If the brief derives from a pasted proposal or prior conversation, enumerate departures with rationale. New artifact with no prior proposal: `N/A — new artifact`.

{{changes-or-na}}

## Tag

> Guidance: `personal` / `publishable` / `client-only`. v1 default is `personal`. Tagging convention may tighten when the publication pipeline re-activates.

{{tag}}

## Portability caveats

> Guidance: Call out Claude Code-only frontmatter the author relied on — `shell: powershell`, `context: fork`, fine-grained `allowed-tools` Bash syntax, `effort` levels beyond standard, any hooks. Required content for `publishable`; `personal` can answer `N/A — personal scope`.

{{caveats-or-na}}

## Cross-reference dependencies

> Guidance: Skills, rules, or subagents this skill references. Tag each as (a) already converted, (b) pending conversion — future-edit dependency, or (c) external/standard. No cross-references: `N/A — no cross-references`.

{{dependencies-or-na}}

> Verbatim — do not edit. Brief-specific observations belong in the
> Notes section above.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit (YAML hygiene rule).
4. If batch is 3+ skills, return a proposal before writing, per batch-conversion convention.

## Notes

> Guidance: Optional. Brief-specific observations that don't fit
> elsewhere — pattern dogfooding feedback, structural decisions worth
> flagging, one-off context. Leave blank or omit heading if nothing
> to note.

{{notes-or-leave-blank}}

## Confidence

> Guidance: H / M / L with a one-line rationale. Separate confidence lines per dimension (structure vs. field specs vs. body content) are welcome when they diverge.

{{confidence}}
