# Handoff: narrow the Local-removal claim to the setting that still carries it

- **Audit run**: 2026-10-16
- **Source**: `vscode-agent`
- **Window**: floor `c642b585` (2026-10-01, the 2026-10-06 run's head) →
  head `e6026c88` (2026-10-16)
- **Covers recommended actions**: 2 and 3
- **Kind**: factual correction to one claim held in two files: the root
  `README.md`, which deploys nowhere, and the user-scope rule
  `claude/rules/vscode-scoping.md`, live machine-wide once
  `link-claude.ps1` copies it. No behaviour changes.
- **Target**: `README.md` (lines 198–203),
  `claude/rules/vscode-scoping.md` (lines 82–97)

## The problem

Two files say VS Code's docs mark the Local harness and its
`chat.*Locations` settings for removal. On 2026-10-01 the docs said so
on four settings and on two pages. On 2026-10-16 they say it once, on
`chat.agentSkillsLocations`'s row of the AI settings reference; the
other three rows and both pages dropped the sentence during the window.
All four settings are still marked deprecated.

## Evidence

**The claims**, as of 2026-10-16.

`README.md:198-203`, the **Local** sub-bullet of "VS Code's chat":

> - **Local**, VS Code's own harness, reads Claude's formats beside
>   Copilot's wherever its `chat.*Locations` settings leave them on, as
>   every profile here does since 2026-10-08. The docs mark those
>   settings and the harness for removal "in a future release", and
>   [vscode-scoping.md](claude/rules/vscode-scoping.md) has the traps in
>   them.

`claude/rules/vscode-scoping.md:95-97`, the close of the gotcha "These
switches govern the Local harness alone, and an experiment can move a
new chat off it":

> A Claude-target pick is unaffected; the docs mark Local and these
> switches for removal together, so plan for the Claude target.

**The docs at the floor and at head.** In `microsoft/vscode-docs`,
`docs/agents/reference/ai-settings.md` at `c642b585` gave each of the
four deprecated location settings the sentence "This setting and the
Local agent will be removed in a future release." At `e6026c88` one
keeps it:

| Setting | Row at floor | Row at head | Sentence at head |
| --- | --- | --- | --- |
| `chat.instructionsFilesLocations` | `:314` | `:334` | gone |
| `chat.promptFilesLocations` | `:333` | `:353` | gone |
| `chat.agentFilesLocations` | `:340` | `:360` | gone |
| `chat.agentSkillsLocations` | `:349` | `:369` | kept |

At the floor two pages said it in prose too,
`docs/agent-customization/overview.md:198` and `prompt-files.md:28`:
"They continue to work with the Local agent for now, but the Local agent
will be removed in a future release." Neither does at head.

The row that keeps it, at head, verbatim:

```text
| `setting(chat.agentSkillsLocations)` _(Deprecated)_<br/>Configure agent skill locations for the Local harness. This setting and the Local agent will be removed in a future release. Use [customization migration](/docs/agent-customization/migrate-customizations.md#move-customizations-from-configured-locations) to move skills to supported locations. | `{ ".agents/skills": true, ".github/skills": true, ".claude/skills": true, "~/.agents/skills": true, "~/.copilot/skills": true, "~/.claude/skills": true }` |
```

A row that dropped it, at head, verbatim:

```text
| `setting(chat.instructionsFilesLocations)` _(Deprecated)_<br/>Configure custom instruction locations for the Local harness. Use [customization migration](/docs/agent-customization/migrate-customizations.md#move-customizations-from-configured-locations) to move instructions to supported locations. | `{ ".github/instructions": true, ".claude/rules": true, "~/.copilot/instructions": true, "~/.claude/rules": true }` |
```

Two in-window landings touch a line of `ai-settings.md` carrying the
sentence: `2264a3af4` (2026-10-08, the migration guide's merge, #10410)
and `fdf324630` (2026-10-13, "Simplify agent terminology", #10452).
Which removed it from which row was not traced. A `git grep -i` at head
over every `docs/**/*.md` page and `release-notes/v1_141.md` and
`v1_142.md`, for "Local agent" or "Local harness" within 120 characters
of "removed" or "removal", hits only `ai-settings.md:369`.

## What to change

1. **`README.md`**, the **Local** sub-bullet, the sentence beginning
   "The docs mark those settings and the harness for removal" (lines
   200–201). Narrow it to what the docs say when re-read: the settings
   are deprecated, and one row, `chat.agentSkillsLocations`'s, still
   says the setting and the Local agent will be removed in a future
   release. Date it.
2. **`claude/rules/vscode-scoping.md`**, the clause "the docs mark Local
   and these switches for removal together" (line 96). The same
   narrowing. The advice after it, "so plan for the Claude target", is
   the rule's own and the audit did not flag it: keep it unless the
   narrowed clause no longer supports it, and say which in the commit
   message.

**One home or two.** The audit flagged that this fact lives in two
files ("consider one home for it") without choosing. Correct both in
place, or keep the fact in the rule, which loads whenever a VS Code
settings file is edited, and let README's sentence point there, as it
already does for the rule's traps. `coding-markdown.md`'s "One fact,
one home" argues for the second; README's reader, who may never load
the rule, for the first. Choose at execution and say which in the
commit message.

## Constraint on the fix

- Re-read the live page first,
  https://code.visualstudio.com/docs/agents/reference/ai-settings, since
  the audit read the docs repo at head and the site can lag it. Date the
  narrowed claim to that read.
- **Narrow the claim; do not invert it.** The evidence shows the
  sentence leaving three rows and two pages and staying on one. It does
  not show VS Code dropping its plan to remove the Local harness, so
  write neither that nor that the docs no longer mention removal.
- Keep "deprecated": all four settings still carry _(Deprecated)_ at
  head.

## Out of scope

`claude/rules/agent-instructions-scoping.md:188-191` says three
instruction settings are "only used by the Local agent harness",
"whose removal the bundle announces". That cites VS Code's own setting
text in 1.139.1, read 2026-09-26, not the docs, and this window did not
read the bundle. Leave it.

## Verification

1. `grep -n -i "removal\|removed" README.md claude/rules/vscode-scoping.md`
   — no hit says the docs mark the settings, plural, or Local and its
   switches together, for removal; any hit on the topic names
   `chat.agentSkillsLocations` and is dated 2026-10-16 or later.
2. From the main checkout, in pwsh,
   `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`. Then,
   in Git Bash,
   `diff --strip-trailing-cr claude/rules/vscode-scoping.md ~/.claude/rules/vscode-scoping.md`
   — no output.
3. `uv run --with pyyaml scripts/lint-frontmatter.py claude/rules/vscode-scoping.md`.
4. `pre-commit run --all-files`.

## Sequencing note

Brief 01 edits the same README bullet's opening sentence, lines
187–189. Kept apart because each is checked against a different
upstream page, and this one alone deploys a rule. Either order works:
find each target by its quoted text, since the other's edit can move
its lines.

## Provenance

Recommended actions 2 and 3 of the 2026-10-16 `/drift-audit
vscode-agent` run. The audit found the narrowing in
`docs/agents/reference/ai-settings.md`, outside the source's `path`, by
a targeted read it took because both files cite the docs for the claim;
brief 03 carries that gap in the registry entry. The base pages'
wording, the landing attribution and the whole-tree grep were read from
the run's scratchpad clone while this brief was written.
