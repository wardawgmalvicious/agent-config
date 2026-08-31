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
name: {{skill-name}}  # repo linter requires it; upstream optional — display label only, the /command comes from the directory name; max 64 chars; lowercase/digits/hyphens; no "anthropic"/"claude"
description: {{one-sentence trigger description}}  # repo linter requires it (upstream: recommended); combined with when_to_use, the listing truncates at 1,536 chars — the linter gates there
when_to_use: {{when-to-use guidance}}  # optional; appended to description in the skill listing; counts toward the combined 1,536 cap
argument-hint: {{[arg-hint]}}  # optional; autocomplete display hint shown in / menu, e.g. [issue-number]
arguments: {{arg1 arg2}}  # optional; space-separated string or YAML list; enables $name substitution in skill body
disable-model-invocation: {{false}}  # optional; true = manual-only (/commit-style): the description leaves context entirely; also blocks subagent preloading and scheduled-task prompts
user-invocable: {{true}}  # optional; false hides from / menu for background-knowledge skills; description stays in context
allowed-tools: {{Bash(git add *) Bash(git commit *) Read Grep}}  # optional; permission pre-approval for the invoking turn only (clears on the next user message); does NOT restrict other tools; space/comma string or YAML list; write each Bash specifier in space form — `Bash(git diff *)`, never `Bash(git diff*)`, which word-boundaries differently
disallowed-tools: {{AskUserQuestion}}  # optional; removes tools from the pool while the skill is active; clears on the next user message
model: {{inherit}}  # optional; sonnet / opus / haiku / full model ID / inherit; turn-scoped — the session model resumes on the next prompt; with context: fork, sets the subagent's model instead
effort: {{medium}}  # optional; low / medium / high / xhigh / max; overrides session effort while the skill is active; availability model-dependent
context: {{inline}}  # optional; "fork" runs the skill body as a subagent's prompt — in the background by default, with the narrower background toolset, and /rewind won't undo its edits
background: {{true}}  # optional; fork only; false waits for the fork's result in the invoking turn
agent: {{general-purpose}}  # optional; fork only; Explore / Plan / general-purpose (default) / custom subagent name — Explore and Plan skip CLAUDE.md
hooks: {{null}}  # optional; registered at invocation, persist for the rest of the session; `once` supported
paths: {{src/**/*.ts}}  # optional; comma-separated string or YAML list; glob patterns for path-scoped auto-activation
shell: {{bash}}  # optional; "bash" (default) or "powershell" for !`cmd` blocks; the PowerShell tool is on by default on Windows; elsewhere needs CLAUDE_CODE_USE_POWERSHELL_TOOL=1
metadata: {{null}}  # optional; free-form YAML map for your own tooling; Claude Code ignores the contents (repo precedent: powerbi-report-authoring)
---
```

Claude Code also accepts `license` and `compatibility` (Agent Skills
spec fields) without acting on them. They matter only on the claude.ai
upload / Skills API path, which allows exactly six fields — `name`,
`description`, `license`, `compatibility`, `metadata`, `allowed-tools` —
and hard-fails on any other key.

## Description char count

> Guidance: State the count explicitly so Claude Code can re-check after draft. Repo default is 1,536 combined (`description` + `when_to_use`) — the linter gates there, matching Claude Code's listing truncation. The 1,024 spec cap matters only if the skill will go through the claude.ai upload path. Also mind the aggregate: all deployed skills share one listing character budget (default ~1% of the context window, `skillListingBudgetFraction`), and an over-budget listing gets least-invoked descriptions shortened first — put the key use case in the first sentence.

{{N}} / {{1,536 repo combined cap | 1,024 claude.ai-upload cap}}

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
