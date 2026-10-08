# Prompt audit: Claude Code configuration for agent-config

The audit found 46 instructions that no longer fit the model, the repo or each other. I've written fixes for all 46 as a patch and applied none of it; the repo is untouched. Eight more need your decision, listed below with suggested text.

**Scope**
- **Audited:** root `CLAUDE.md`, the nested `docs/handoffs/CLAUDE.md`, the nine `.claude/rules/` files and the six `.claude/skills/` files. At user scope: `~/.claude/CLAUDE.md`, 21 rules, the `security-reviewer` subagent and the 8 junctioned skills. The deployed copies are byte-identical to their repo sources, so I read and patched the sources.
- **Read for reporting only:** 4 installed plugins and 15 account-synced skills.
- **Not present:** ancestor `CLAUDE.md`, `CLAUDE.local.md`, `AGENTS.md`, `.claude/CLAUDE.md`, commands, output styles, a managed-policy file, and any `@` imports.
- **Not read:** settings files, `.mcp.json` and `~/.claude.json`.
- **Not loaded here:** `claude/CLAUDE.md`'s nested copy, which `claudeMdExcludes` keeps from loading a second time in this repo.

**Target model:** Opus 5.5, the model running this session. Files that pin their own model were audited against it: `author-skill`, `drift-audit` and `learn` against Fable 5.1, and `security-reviewer` against Sonnet 5.5.

**Line numbers** are as of HEAD `c268691`. A peer session committed triage and handoff changes during the audit; I told it this session was read-only, and the patch still applies cleanly at that commit.

**†** marks a file under `claude/` or `skills/{workflow,meta,social}/`. Those reach every project: the `skills/` ones the moment the patch is applied, the `claude/` ones at the next deploy.

## Summary

Three problems matter most:

- **`coding-tmdl.md` teaches TMDL that won't validate.** Its examples use a `displayName:` alias, the `description:` property and space indentation. TMDL has no display-name property (Learn); it uses `///` descriptions and tab indentation. The newer `fabric-tmdl` skill says the same, and both load on every `*.SemanticModel` file. Opus 5.5 copies examples closely, so it writes these broken files.
- **`drift-audit` misfiles every Fabric and Power BI change.** It looks for skills under `~/.claude/skills`, but the platform skills are pruned from user scope, so every such drift lands as a "new skill" candidate. Its MCP actions also point at deployed copies, which the next deploy overwrites.
- **Two guards say a risky state is safe.**
  - Root `CLAUDE.md:42`'s "must print nothing" check misses the `pbip-` and `powerbi-` prefixes. Three such skills exist, so the check passes with them leaked to user scope.
  - `git-identity-scoping.md` says a `-NoProfile` pwsh acts as the keyring's GitHub account. The newer global `CLAUDE.md` says `~/scripts/gh.ps1` covers that shell.

**Counts by group:**

| Group | Fixed in the patch | Notes |
| --- | --- | --- |
| 1, dated prompt text | 13 | Mostly "used to / no longer" phrasing and examples that contradict their own rule |
| 2, stale facts and conflicting files | 33 | |
| 3, tool descriptions | 0 | Skill descriptions are routing text, and none was flagged |
| 4, request code | — | Not applicable: there is no request code, and the one subagent duplicates nothing |

On top of those: 8 items flagged for your decision and 22 low-confidence notes.

## High confidence (16)

| # | Location | Evidence | Pattern | Why it's wrong now | Action |
| --- | --- | --- | --- | --- | --- |
| 1 | [CLAUDE.md:42](CLAUDE.md#L42) | the post-deploy grep checks only the `fabric`, `pbir`, `pbid` and `msix` prefixes, "must print nothing" | G2 stale fact | `PLATFORM_PREFIXES` also has `pbip-` and `powerbi-`, and three such skills exist. The line was written 2026-10-01, after those skills | rewrite: add `pbip` and `powerbi` |
| 2 | [.claude/rules/editing-skills.md:16-18](.claude/rules/editing-skills.md#L16) | "`fabric-`, `pbir-`/`pbid-`/`pbip-` or `msix-`" | G2 | Leaves out `powerbi-`, which two skills use | rewrite: point to `PLATFORM_PREFIXES` |
| 3 | [claude/rules/coding-tmdl.md:33-84](claude/rules/coding-tmdl.md#L33)† | "PascalCase identifier, aliased display name", plus `displayName:` lines | G2 conflict | Learn says every TMDL property is a TOM property and captions exist only as translations. The newer `fabric-tmdl` skill names objects with spaces | rewrite the Naming section; same fix in `coding-dax.md:24-26` and `expected_findings.md` |
| 4 | [coding-tmdl.md:140-151](claude/rules/coding-tmdl.md#L140)† | "Use the `description` property" | G2 conflict | `fabric-tmdl` says to use `///` above the object, never the property | rewrite |
| 5 | [coding-tmdl.md](claude/rules/coding-tmdl.md#L49) fences at 49-74, 94-108, 146-151† | 4-space indents, `# Good` inside the `tmdl` fences, `lineageTag` on a new table | G1c examples copied | TMDL uses one tab per level and has no comments, and `fabric-tmdl` forbids `lineageTag` on new objects | rewrite the fences with real tabs |
| 6 | [coding-python.md:206-218](claude/rules/coding-python.md#L206)† | "`notebookutils.runtime.context` parameters", and `source_schema or SourceSchema` | G2 + G1c | `fabric-spark` documents `runtime.context` as an identity dict. The example never reads `SourceSchema`, because `"raw"` is truthy | rewrite: parameters cell plus `globals().get` |
| 7 | [git-identity-scoping.md:111-118](claude/rules/git-identity-scoping.md#L111)† | "a `-NoProfile` `pwsh` acts as the keyring's active account" | G2 conflict | The newer `claude/CLAUDE.md:108-113` and the ledger say three wrappers cover both tool shells | rewrite; the `gh api user` confirm step stays |
| 8 | [learn/SKILL.md:95-97, 122, 240-247](skills/meta/learn/SKILL.md#L95)† | "the fix is the skill's `description`" | G2 (Fable 5.1) | `learn`'s own triggers sit in `when_to_use`, which has its own 512-character cap | rewrite to cover both fields and both caps |
| 9 | [drift-audit/SKILL.md:115](.claude/skills/drift-audit/SKILL.md#L115) | "`Glob ~/.claude/skills/*/SKILL.md`" | G2 (Fable 5.1) | Platform skills are pruned from there, so none ever matches | rewrite: search the repo's skill trees |
| 10 | [drift-audit:118, 174](.claude/skills/drift-audit/SKILL.md#L174) | proposed action "add to ~/.claude/mcp/…" | G2 conflict | The global file says "Edit the repo, never `~/.claude`", and the next deploy overwrites such an edit | rewrite to `claude/mcp/` |
| 11 | [drift-update:289-292](.claude/skills/drift-update/SKILL.md#L289) | "does not reliably reload mid-session" | G2 conflict | `editing-skills.md:34-38` records hot reload, verified 2026-08-31 and 2026-09-02 | rewrite the reason; the conclusion stays |
| 12 | [author-skill:460-464](.claude/skills/author-skill/SKILL.md#L460) | it proposes deleting briefs "whose skill … now exists" | G2 conflict (Fable 5.1) | `docs/handoffs/CLAUDE.md:53` says such a brief means `/test-skill` hasn't run yet | add a bullet: keep it queued |
| 13 | [author-skill:289-291](.claude/skills/author-skill/SKILL.md#L289) | "The other two examples predate…" | G2 | Only `author-skill.example.md` remains | rewrite |
| 14 | [author-skill:78](.claude/skills/author-skill/SKILL.md#L78) | `templates/subagent-handoff.md` | G2 | The file is at `docs/handoffs/templates/` | fix the path |
| 15 | [test-skill:197-198](.claude/skills/test-skill/SKILL.md#L197) | "56 fixtures" | G2 | 74 + 16 are tracked now, and the file itself says never to restate counts | rewrite without a count |
| 16 | [coding-sparksql.md:147-148](claude/rules/coding-sparksql.md#L147)† | "no variables (`DECLARE`), no `IF`/`WHILE`" | G2 | Fabric Runtime 2.0 (Spark 4.1, GA) adds session variables (Learn). Databricks has `DECLARE VARIABLE` and SQL scripting | rewrite per runtime |

## Medium confidence (30)

| # | Location | Evidence | Pattern | Why | Action |
| --- | --- | --- | --- | --- | --- |
| 17 | [CLAUDE.md:49-50](CLAUDE.md#L49) | the `copy-copilot.ps1` lines read as routine commands | G2 conflict | The newer freeze (`copilot-payload.md:60-64`) loads only when a file under `copilot/` is read; root loads every session | mark them frozen; root keeps its 200 lines |
| 18 | [claude/CLAUDE.md:179](claude/CLAUDE.md#L179)† | "GitHub Copilot no longer inherits this payload" | G1d "used to" phrasing | Written relative to an earlier state | rename the heading and the ledger heading. Better landed through `copilot-payload-retirement.md:427`, which already rewrites this section; two briefs cite the old heading |
| 19 | [editing-skills.md:39-42](.claude/rules/editing-skills.md#L39) | "no longer refreshed" | G1d | | rewrite |
| 20 | [editing-skills.md:80](.claude/rules/editing-skills.md#L80) | "no longer counts for Opus 5.5" | G1d | | rewrite |
| 21 | [editing-skills.md:62-63](.claude/rules/editing-skills.md#L62) | "costs twice the Opus tier (2026-09-12)" | G2, a pinned model | Fable at $10/$50 against Opus 5.5 at $4/$20 is 2.5 times. The source is the bundled model table, cached 2026-09-25 | rewrite |
| 22 | [claude/rules/README.md:165-166](claude/rules/README.md#L165)† | "never on Grep or a subagent's Read" | G2 conflict | The same file (lines 22-23) and `agent-instructions-scoping.md` say a subagent's Read loads the file into that subagent | rewrite |
| 23 | [fabric-git-serialization.md:165-166](claude/rules/fabric-git-serialization.md#L165)† | `Engineering/** -text`, presented without a label | G1c | One estate's folder names shown as if they were the answer | label them as an example |
| 24 | [security-reviewer.md:16](claude/agents/security-reviewer.md#L16)† | "the `mode` parameter that used to pin it…" | G1d (Sonnet 5.5) | | rewrite; needs a re-run of its test |
| 25 | [coding-powershell.md:182-183](claude/rules/coding-powershell.md#L182)† | "Scripts here run `Set-StrictMode`" | G2 | The rule loads in every repo. Only one script in this repo calls it, and the file's own template leaves it out | make it conditional, or add it to the template if it's house style |
| 26 | [coding-tsql.md:56-57](claude/rules/coding-tsql.md#L56)† | "Aliases: PascalCase" | G1c, examples contradict the rule | Every example table alias is lowercase (`c`, `line`, `prod`, `cust`) | rewrite to match the examples, or reverse it |
| 27 | [coding-bash.md:210-214](claude/rules/coding-bash.md#L210)† | "until machine-config fixed it … (`c9a2ed4`)" | G2 history | "until fixed" reads as solved | rewrite to the symptom |
| 28 | [coding-bash.md:311-314](claude/rules/coding-bash.md#L311)† | "the probe this example once carried" | G1d | | rewrite |
| 29 | [coding-python.md:174-194](claude/rules/coding-python.md#L174)† | "operations are lazy", "`MEMORY_AND_DISK` by default" | G2 verbose | Textbook Spark, paid on every `.py` load, and the cache default is imprecise | trim to the house choices; headings kept |
| 30 | [coding-tmdl.md:18, 156-157](claude/rules/coding-tmdl.md#L18)† | "TMDL is newer", "(recent feature)" | G1d | | rewrite |
| 31 | [coding-expressions.md:9, 15](claude/rules/coding-expressions.md#L9)† | "ADF / Synapse … no auto-load" | G2 | The rule's own `**/pipeline/*.json` glob is where ADF and Synapse Git integration writes pipelines | rewrite |
| 32 | [coding-ci-workflows.md:66-69](claude/rules/coding-ci-workflows.md#L66)† | "in evaluate mode now" | G2 time-sensitive | Becomes false on 2026-11-02 | anchor it to the date |
| 33 | [coding-kql.md:117-118](claude/rules/coding-kql.md#L117)† | "Default changed historically" | G2 history | The real reason is that `innerunique` dedupes the left side | rewrite |
| 34 | [learn:297-303](skills/meta/learn/SKILL.md#L297)† | "**Sources, cited by kind.**" | G2 conflict (Fable 5.1) | The newer contract in `triage/references/formats.md:114-117` uses **Scrubbing** | rewrite |
| 35 | [learn:290](skills/meta/learn/SKILL.md#L290)† | "the doorbell this replaced" | G1d | | rewrite |
| 36 | [linkedin-highlights:253, 262-265](skills/social/linkedin-highlights/SKILL.md#L253)† | `wc -l < "$TERMS"` after `rm -f "$TERMS"` | G2 | Shells are fresh per call, so a failed count reads as a clean scrub | print the count inside the snippet |
| 37 | [linkedin-highlights:353](skills/social/linkedin-highlights/SKILL.md#L353)† | `uv run python -c` | G2 conflict | Without `--no-project`, uv syncs the user's repo, which breaks the skill's read-only promise | add `--no-project` |
| 38 | [recreate-repo:78](skills/workflow/recreate-repo/SKILL.md#L78)† | "exit 0: a current snapshot is committed" | G2 | `-Check` compares disk with the live repo and never checks git | fix the comment |
| 39 | [commit:249](skills/workflow/commit/SKILL.md#L249)† | `rules/fabric-git-serialization.md` | G2 | The path resolves nowhere | `~/.claude/rules/…` |
| 40 | [commit:165-168](skills/workflow/commit/SKILL.md#L165)† | "could not answer before" | G1d | | rewrite |
| 41 | [land:326-327](skills/workflow/land/SKILL.md#L326)† | "the half … that used to be missing" | G1d | | remove the sentence |
| 42 | [author-skill:415-424](.claude/skills/author-skill/SKILL.md#L415) | step 8 lists three catalogue sections | G2 | Project-scope entries go in `.claude/skills/README.md`, and Meta, Social and Windows apps sections now exist | rewrite |
| 43 | [author-skill:466-470](.claude/skills/author-skill/SKILL.md#L466) | "a skill under `skills/` … cannot run in a worktree" | G2 conflict | The newer `test-skill:227-239` probes platform groups from a worktree | narrow it to `workflow`, `social` and `meta` |
| 44 | [test-skill:26-27](.claude/skills/test-skill/SKILL.md#L26) | paths pinned to `C:\Repos\Personal\agent-config` | G2 conflict | Briefs are worked in worktrees, so this sends writes to the main checkout | rewrite |
| 45 | [drift-audit:24, 78, 86](.claude/skills/drift-audit/SKILL.md#L24) | "this line previously read…" | G1d (Fable 5.1) | Line 78 puts back a claim the file itself calls wrong | rewrite or remove |
| 46 | [drift-update:384-386](.claude/skills/drift-update/SKILL.md#L384) | "Found 2026-09-11 … until the view replaced it" | G2 history | | remove |

## Needs your decision (no patch)

1. **[prune-branches:249-251](skills/workflow/prune-branches/SKILL.md#L249)† (medium).** The rescue runs `git switch` with no check for a live session. `land:487-489`, `commit:33-35` and root `CLAUDE.md:127-129` all forbid that while a peer is live. I didn't patch it because the fix adds a command (`ListAgents`). Suggested text: *"Before either switch, run `ListAgents` and read every row; with anyone else live, cut the rescue in a linked worktree (`git worktree add -b <branch> <path> main`) instead."*
2. **[vscode-scoping.md:61-64](claude/rules/vscode-scoping.md#L61)† against `claude/CLAUDE.md:181-182` (medium).** The rule says plain "Copilot" inherits `~/.claude`; the global file says Copilot never reads it. The ledger (`user-claude-md.md:1029-1034`) shows the global "never" is false for the Azure profile. Settle both in the retirement brief.
3. **`commit:25-35` against `claude/CLAUDE.md:136-139`†.** They branch on different triggers: `commit` only when the repo lands by pull request, the global file whenever the work runs to more than one commit. Both lines date from the same day, so history can't say which is current.
4. **`test-skill:447-454` with `drift-update:342-352` (medium).** `/test-skill` never writes a `**Closed**:` line, so a confirmed audit brief stays in the queue. The fix adds an `audit-status.py` call, and the ledger policy changed today in `bde833c`.
5. **[claude/CLAUDE.md:3](claude/CLAUDE.md#L3)† (low).** "…asking for clarification rather than fabricating specifics" is a "do not hallucinate" line. It's the file's oldest line, older than the platform-skill prune.
6. **[claude/CLAUDE.md:199](claude/CLAUDE.md#L199)† (low).** "userPreferences has the summary", but no userPreferences block reached this session.
7. **`author-skill:7` and `drift-audit:8` (low).** Both pin `effort: max` on Fable 5.1. The migration guide suggests starting Fable at `high`; `editing-skills.md:85` requires `max`.
8. **`coding-tmdl.md:137-138`† (low).** "Inactive relationships need a comment", but TMDL has no comments.

**Low, reported only:**
- `claude-config-scoping.md:45-46, 89-90`: version-relative wording.
- `claude/rules/README.md` measurement history at 60-63, 72-74, 97-104, 112-118 and 170-177.
- `coding-bash.md` names files from another repo (lines 16, 32, 36-37, 105, 337). Its "now blocks" at 262-266 and the undated incident at 288-290 are also history.
- `coding-dax.md:109-110, 272-273`: strategy coaching.
- Measurement stories in `coding-ci-workflows.md:20-25` and `coding-bicep.md:20-26`.
- `coding-expressions.md:30-31` against 154-155: the same rule at two strengths.
- `coding-bicep.md:126`: an undated "is being deprecated".
- `coding-m.md:186`: the typo `PrasedAmount` in a "Good" example.
- `learn:77-78`: confirms with the user whenever there is more than one item.
- `prune-branches:23-26`: "not going away".
- `drift-update:144-146`: history.
- `commit:97`: its subject format leaves out a scope.

## Plugins and synced skills (report only)

None of the 4 installed plugins (`plugin-dev`, `skill-creator`, `claude-md-management`, `claude-code-setup`) appears in this session's skill or agent listing, so they don't load here. The 15 account-synced `anthropic-skills:*` do load. The notable problems:

- **High:** `plugin-dev` `hook-development` gives two different shapes for `hooks.json` (lines 62-100 against 344-381).
- **High:** `agent-creator.md:136` says "500-3,000 words" where `agent-development:265` says characters.
- **Medium:**
  - Three `plugin-dev` agents end with leaked chatter: "Excellent work! … Would you like me to create more agents".
  - The `skill-creator` plugin and synced copies both carry "take your time and really mull things over" at line 306, prose that steers thinking depth.
  - `create-plugin.md` says "all 7 phases" but defines 8, and line 97 has "CRITICAL … DO NOT SKIP".
  - `claude-md-management` uses `.claude.local.md` where the file is `CLAUDE.local.md`.
  - The synced `pdf` skill restates basic pypdf and reportlab usage.

**No findings:**
- Rules: `agent-instructions-scoping`, `coding-csharp`, `coding-xaml`, `coding-markdown`, and eight of the nine project rules (all but `editing-skills.md`).
- `docs/handoffs/CLAUDE.md`.
- Skills: `drift-handoff`, `triage` (an auditor saw a retention conflict mid-edit, and the committed text resolves it), `code-review` and `find-session`.

## The proposed patch

The patch has 56 hunks across 28 files, one finding per hunk where possible. Root and global `CLAUDE.md` stay at 200 lines. To try it, or take only some files, run from the repo:

```bash
git apply --include='claude/rules/coding-tmdl.md' <patch>
```

- **Dependent edits are included:** findings 3 and 4 also change `coding-dax.md:24-26` and `tests/skills/code-review/expected_findings.md`, which asserted the `displayName` pattern. Finding 18 also renames the ledger heading.
- **Deliberately left out:**
  - The frozen Copilot ports. Editing the `coding-dax`, `coding-python`, `coding-tsql` and `coding-tmdl` rules will fail pre-commit's `drift` check until the hash is re-recorded.
  - The evidence ledgers. `root-claude-md.md:356` records the old grep; by the repo's own rule it gets a new dated entry, not an in-place fix.
- **Retests:** finding 24 needs the `security-reviewer` test, and the skill edits need the usual `skill-status.py` retest.

Files are in the scratchpad:
- `~\AppData\Local\Temp\claude\c--Repos-Personal-agent-config\3fd79015-b5a8-4ad3-9859-875818eb4800\scratchpad\prompt-audit.patch`
