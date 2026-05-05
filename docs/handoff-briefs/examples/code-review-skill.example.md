# Skill handoff brief: code-review

Last verified: 2026-04-24

## Artifact path

`~/.claude/skills/code-review/SKILL.md` (personal scope).

## Scope

Code review skill for data-engineering work. Inline execution — findings
stay in main conversation for iteration. Model-invocable on trigger
phrases ("review this code," "check this diff," "audit this function")
and user-invocable via `/code-review`. No path scoping — review is
user-initiated, not passive. Read-only: surfaces findings, never
modifies code.

## Frontmatter

```yaml
---
name: code-review
description: "Review code for correctness, naming conventions, style, error handling, security, and scaling concerns. Use when reviewing code, checking a diff, auditing a function, or asking about code quality. Covers Python, PySpark, SQL, KQL, DAX, and data-engineering patterns."
allowed-tools: Bash(git diff *) Bash(git status *) Bash(git log *) Read Grep Glob
model: inherit
---
```

## Description char count

266 / 1,024 portable cap. 266 / 1,536 Claude Code combined cap.
Well under both. Triggers front-loaded in first 200 chars.

## Body structure outline

1. Context gathering — run `git diff` if in a repo (or diff vs.
   specified ref); otherwise target the file/function user named; if
   neither, ask what to review.
2. Review checklist, priority-ordered:
   - Correctness — logic errors, off-by-one, null/empty handling, race
     conditions, obvious bugs
   - Security — hardcoded secrets, unparameterized SQL, unsafe
     deserialization (`pickle`, `eval`, `exec`), overly broad
     permissions, path traversal
   - Scaling — N+1 queries, unbounded loops, missing indexes, data
     skew (PySpark), `.collect()` / `.toPandas()` on large datasets,
     lazy vs. eager evaluation misuse
   - Error handling — swallowed exceptions, bare `except:`, missing
     try/except on I/O, silent failures, no logging on error paths
   - Naming & style (opinionated defaults):
     - SQL: PascalCase tables, leading commas, CTEs for complex
       queries, full column names
     - Python/PySpark: snake_case variables, full names (no `cols`,
       `df_tmp`, `join_cols`)
     - Pipeline params/activities: PascalCase
     - Notebook variables: lower_snake_case
     - TMDL: PascalCase with aliasing
   - Maintainability — docstrings on functions, testability,
     duplicated logic, magic numbers, comments explaining *why* not
     *what*
3. Output format:
   - 🔴 Critical (must fix) — correctness/security blockers
   - 🟡 Warning (should fix) — maintainability, error handling, scaling
   - 🟢 Suggestion (consider) — style, naming, minor improvements
   - Each finding: `file:line` → issue → concrete fix example (code
     snippet, not prose)
4. Explicit non-modification rule — review surfaces findings; user
   decides what to change.

## Changes from source proposal

- Swapped `TypeScript` for `KQL, DAX` in description — matches user's
  actual stack (per userPreferences), makes the skill differentiated
  rather than generic.
- Bash glob syntax uses space-separated form (`Bash(git diff *)`),
  matching docs examples. Prior proposal used `Bash(git diff*)` which
  has different word-boundary behavior.
- Tag changed from `publishable` (v1 proposal) to `personal` (v2
  default) per scope pivot — publication pipeline deferred.

## Tag

`personal`. Re-evaluate when publication pipeline reactivates. If
re-tagged `publishable` later, the opinionated naming-convention
defaults (PascalCase SQL, snake_case Python) need a README note
stating they're overridable via consuming project's CLAUDE.md.

## Portability caveats

N/A — personal scope.

Forward note for future publishable re-tagging: (a) `allowed-tools`
Bash-specifier syntax is Claude Code-specific (Agent Skills open
standard doesn't specify Bash-tool glob form), (b) `model: inherit` is
Claude Code-specific. Body is fully portable.

## Cross-reference dependencies

N/A — no cross-references to other skills/rules/subagents.

## Claude Code's post-draft checklist

- Re-verify frontmatter fields against current docs before writing.
- Re-count description chars after drafting (Windows + Edit-tool
  fragility — 266 is the target).
- `cat` the full SKILL.md after any edit (YAML hygiene rule).

## Confidence

**H.** All frontmatter specs verified against current docs. Body
outline derives from established data-engineering review practices
and matches user's stated coding preferences.
