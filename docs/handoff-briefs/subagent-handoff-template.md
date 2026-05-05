# Subagent handoff brief: {{agent-name}}

Last verified: {{YYYY-MM-DD}}

> Subagents are Claude Code-only (not part of the Agent Skills open standard). Subagents cannot spawn other subagents. The `memory:` field requires Claude Code v2.1.33 or later.

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

> Guidance: Where the drafted agent file lands. State personal vs. project scope and the exact path. Personal: `~/.claude/agents/{{agent-name}}.md`. Project: `<repo-root>/.claude/agents/{{agent-name}}.md`.

{{path}}

## Scope

> Guidance: One paragraph. What the subagent does, when it's routed (description-driven auto-invocation vs. explicit `--agent` launch), whether it runs foreground / background / in a worktree, whether it carries memory across invocations. No design discussion — just the what.

{{scope paragraph}}

## Frontmatter

> Guidance: Fill every field you intend to set. Delete lines for fields you're not using — don't leave them as empty placeholders. Constraint comments stay as inline YAML `#` comments so the filled brief carries its own reference.

```yaml
---
name: {{agent-name}}  # required; max 64 chars; lowercase letters/numbers/hyphens
description: {{routing description}}  # required; no formal cap — it's a routing hint, not Agent Skills metadata. Still, long descriptions cost context; keep concise but specific enough to route reliably
tools: {{Read, Grep, Glob, Bash}}  # optional; comma-separated bare tool names. Fine-grained Bash control (e.g. Bash(git add *)) via tools is NOT shown in docs examples — use a PreToolUse hook or permissions.allow rules for that
disallowedTools: {{}}  # optional; deny list; composes with tools allow list
model: {{inherit}}  # optional; sonnet / opus / haiku / full model ID / inherit (default when omitted)
permissionMode: {{default}}  # optional; default / acceptEdits / auto / dontAsk / bypassPermissions / plan
maxTurns: {{}}  # optional; integer cap on agentic turns before stopping
skills: {{}}  # optional; list of skills to preload (full content injected at startup)
mcpServers: {{}}  # optional; MCP servers scoped to this subagent; inline or reference
hooks: {{}}  # optional; subagent-scoped hooks
memory: {{local}}  # optional; user (cross-project) / project (git-tracked) / local (git-ignored); requires Claude Code v2.1.33+
background: {{false}}  # optional; true to always run as background task
effort: {{medium}}  # optional; low / medium / high / xhigh / max; availability model-dependent
isolation: {{worktree}}  # optional; only valid value is "worktree" — blast-radius control
color: {{blue}}  # optional; red / blue / green / yellow / purple / orange / pink / cyan. NOT arbitrary strings
initialPrompt: {{}}  # optional; auto-submitted first turn when agent runs as main session via --agent
---
```

## Description char count

> Guidance: No formal cap, but count anyway — long descriptions still cost context. State the count for tracking.

{{N}} chars

## Body structure outline

> Guidance: The subagent body IS the system prompt. Outline the sections it will contain — numbered list or subheadings, one line per section. Typical sections: role statement, structured workflow on invocation, per-finding / per-result output format, memory hygiene (if `memory:` is set), closing summary expectations. Not draft prose.

{{body-outline}}

## Changes from source proposal

> Guidance: If the brief derives from a pasted proposal or prior conversation, enumerate departures with rationale. New artifact with no prior proposal: `N/A — new artifact`.

{{changes-or-na}}

## Tag

> Guidance: `personal` / `publishable` / `client-only`. v1 default is `personal`. Tagging convention may tighten when the publication pipeline re-activates.

{{tag}}

## Portability caveats

> Guidance: Subagents are Claude Code-only by construction — they are not part of the Agent Skills open standard. Caveats to call out: minimum Claude Code version (e.g., `memory:` requires v2.1.33+), overlap with bundled agents (e.g., `/security-review` built-in vs. a custom `security-reviewer`), dependence on a specific host model, skills preloaded via `skills:`.

{{caveats-or-na}}

## Cross-reference dependencies

> Guidance: Skills, rules, or subagents this subagent references or preloads. Tag each as (a) already converted, (b) pending conversion — future-edit dependency, or (c) external/standard. No cross-references: `N/A — no cross-references`.

{{dependencies-or-na}}

> Verbatim — do not edit. Brief-specific observations belong in the
> Notes section above.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief.

1. Re-verify frontmatter fields against current docs before writing — the subagent surface is still moving (notably `memory:`, `skills:`, `initialPrompt:`).
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full agent file after any edit (YAML hygiene rule).
4. Confirm the agent file lives directly under `agents/` (no subdirectories — the directory is flat).
5. If routing via description, read the filled description aloud to check it's specific enough to distinguish from bundled agents.

## Notes

> Guidance: Optional. Brief-specific observations that don't fit
> elsewhere — pattern dogfooding feedback, structural decisions worth
> flagging, one-off context. Leave blank or omit heading if nothing
> to note.

{{notes-or-leave-blank}}

## Confidence

> Guidance: H / M / L with a one-line rationale. Separate confidence lines per dimension (structure vs. field specs vs. body content) are welcome when they diverge.

{{confidence}}
