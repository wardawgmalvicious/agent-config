# Skill handoff brief: {{skill-name}}

Last verified: {{YYYY-MM-DD}}

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

> Guidance: Where the drafted SKILL.md lands, and where it deploys. In this repo a skill is authored at `skills/<group>/{{skill-name}}/SKILL.md` — `<group>` is `fabric`, `powerbi`, or `workflow` — and `scripts/link-claude.ps1` junctions it to `~/.claude/skills/{{skill-name}}/SKILL.md`, one junction per skill. The group directory is not optional and its absence has no error path: the pre-commit hook matches `^skills/[^/]+/[^/]+/SKILL\.md$`, and Claude Code discovers skills exactly one level under the skills root, so a file placed flat at `skills/{{skill-name}}/SKILL.md` is both unlinted and undiscoverable. A skill authored straight into a client repo instead takes the project-scope path `<repo-root>/.claude/skills/{{skill-name}}/SKILL.md`.

{{path}}

## Scope

> Guidance: One paragraph. What the skill does, inline vs. forked execution (`context: fork` vs. default inline), model-invocable vs. user-only (`disable-model-invocation`, `user-invocable`), path-scoped vs. not (`paths:`). No design discussion — just the what.

{{scope paragraph}}

## Sources drilled

> Guidance: What was read during this run, and — the half that gets lost — what was deliberately not read. The undrilled set is what bounds the draft: a brief that says "the REST surface was not drilled; nothing in this skill describes it" is what stops the next reader treating the omission as an oversight. Cite each source as a URL or repo path plus what it established. If this brief replaces one already at the target path, carry the prior undrilled set forward rather than restarting it.

Drilled: {{sources-and-what-each-established}}

Not drilled: {{deliberate-omissions-and-why}}

## Frontmatter

> Guidance: Fill every field you intend to set. `model`, `effort` and `disable-model-invocation` are **always present**, even where the value is the default — the point is that the flip point for each lever is visible in the file instead of being an absent field (`effort` may be carried as a commented-out placeholder, which is how a skill inherits the session level). Delete lines only for the *other* optional fields you are not using — don't leave those as empty placeholders. Constraint comments stay as inline YAML `#` comments so the filled brief carries its own reference.

```yaml
---
name: {{skill-name}}  # repo linter requires it; upstream optional — display label only, the /command comes from the directory name; max 64 chars; lowercase/digits/hyphens; no "anthropic"/"claude"
description: {{one-sentence trigger description}}  # repo linter requires it (upstream: recommended); the linter measures this field alone and gates at 1,536 — see Description char count
when_to_use: {{when-to-use guidance}}  # optional; appended to description in the skill listing and counts toward the same 1,536 truncation point, but the linter does NOT measure it — budget it by hand
argument-hint: {{[arg-hint]}}  # optional; autocomplete display hint shown in / menu, e.g. [issue-number]
arguments: {{arg1 arg2}}  # optional; space-separated string or YAML list; enables $name substitution in skill body
disable-model-invocation: {{false}}  # ALWAYS PRESENT; true = manual-only (/commit-style): the description leaves context entirely; also blocks subagent preloading and scheduled-task prompts. Repo policy: false everywhere
user-invocable: {{true}}  # optional; false hides from / menu for background-knowledge skills; description stays in context
allowed-tools: {{Bash(git add *) Bash(git commit *) Read Grep}}  # optional; permission pre-approval for the invoking turn only (clears on the next user message); does NOT restrict other tools; space/comma string or YAML list; write each Bash specifier in space form — `Bash(git diff *)`, never `Bash(git diff*)`, which word-boundaries differently
disallowed-tools: {{AskUserQuestion}}  # optional; removes tools from the pool while the skill is active; clears on the next user message
model: {{inherit}}  # ALWAYS PRESENT; sonnet / opus / haiku / full model ID / inherit; turn-scoped — the session model resumes on the next prompt; with context: fork, sets the subagent's model instead. Repo policy: inherit everywhere except commit (sonnet)
effort: {{max}}  # ALWAYS PRESENT, as a value or a commented-out placeholder — there is no `inherit` value, so omitting the field IS the inherit; low / medium / high / xhigh / max, an unsupported level silently falls back to the highest supported one below it, and `ultracode` is not a level. Repo policy: max on the workflow skills that drive this repo, commented on platform skills
context: {{inline}}  # optional; "fork" runs the skill body as a subagent's prompt — in the background by default, with the narrower background toolset, and /rewind won't undo its edits
background: {{true}}  # optional; fork only; false waits for the fork's result in the invoking turn
agent: {{general-purpose}}  # optional; fork only; Explore / Plan / general-purpose (default) / custom subagent name — Explore and Plan skip CLAUDE.md
hooks: {{null}}  # optional; registered at invocation, persist for the rest of the session; `once` supported
paths: {{src/**/*.ts}}  # optional; comma-separated string or YAML list; glob patterns for path-scoped auto-activation. A wrong glob has no error path — the skill just never loads — so the linter rejects the silent narrowers: a backslash separator, a leading `/`, and a bare `*.ext` (which matches repo-root files only; `**/*.ext` matches those and nested ones)
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

> Guidance: State the counts explicitly so Claude Code can re-check after draft. `scripts/lint-frontmatter.py` measures `description` **alone** against `DESCRIPTION_MAX = 1536`; the listing truncates `description` + `when_to_use` combined at that same point, so a long `when_to_use` passes lint and is silently truncated anyway. Give both numbers whenever `when_to_use` is set. House practice targets ≤ 1,024 for the description — the Agent Skills spec cap, and where every skill in the repo sits today — treating the 1,536 gate as headroom rather than a target; the spec cap is hard only on the claude.ai upload path. Also mind the aggregate: all deployed skills share one listing character budget (default ~1% of the context window, `skillListingBudgetFraction`), and an over-budget listing gets least-invoked descriptions shortened first — put the key use case in the first sentence.

- `description`: {{N}} / 1,024 house target (1,536 linter gate)
- `when_to_use`: {{N | N/A — not set}}; combined {{N}} against the 1,536 listing truncation

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

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief; brief-specific observations belong in Notes below.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

> Guidance: Optional. Brief-specific observations that don't fit
> elsewhere — pattern dogfooding feedback, structural decisions worth
> flagging, one-off context. Leave blank or omit heading if nothing
> to note.

{{notes-or-leave-blank}}

## Confidence

> Guidance: H / M / L with a one-line rationale. Separate confidence lines per dimension (structure vs. field specs vs. body content) are welcome when they diverge.

{{confidence}}
