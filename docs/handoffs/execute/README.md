# Open briefs — execution order

Two briefs are open. Seventeen waves are spent (struck through below).
Where a spent wave had a brief, that brief is deleted, so those struck rows
name files that no longer exist — git history is the archive. Waves 8 and
17 never had one; each row is itself the whole spec. This file is the
**only** place the order lives; each brief carries its own dependencies
but not its position.

## Why these are not numbered like drift briefs

`/drift-handoff` numbers its output `01-`, `02-`, … and `/drift-update`
walks that order. That works there because a
`docs/audits/<date>/<source-id>/` directory is a **disposable whole**:
gitignored, executed in one pass, discarded together, and its briefs do not
cite each other.

`execute/` is the opposite on all three counts. Briefs here are committed,
deleted **individually** as each is spent, and heavily cross-linked — 36
relative markdown links across the current 3 files, counting this queue
(recounted 2026-09-03 when wave 7 closed, by the method kept with the number:
`](` occurrences that are not `http`. The lineage runs 57
across 9 files → 48 across 7 after wave 11 retired two briefs → 44 across
6 after wave 12 retired one → 34 across 5 after wave 13 retired two → 43
across 6 when wave 18 added one → 35 across 5 when the same wave retired
it again → 32 across 4 when wave 16 retired its brief, which cost three
links rather than two because its queue row stopped being a link as
well → 34 across the same 4 when wave 17 closed, the first *rise*
in the lineage that retired nothing: it had no brief to delete, and its
outcome row cites three payload files where the spec row had cited one;
earlier figures of 27 and 41 do not reproduce under any method
tried, so it starts at 57 → **36 across 3** when wave 7 retired its
brief. That is the second *rise*, and it happened while a file was
deleted — predicting 32 from the usual two-link retirement was wrong by
four, because the outcome row cites three payload files where the spec
row cited one brief, and the closing prose gained a link too. Two waves
running, the arithmetic has been dominated by how much the outcome row
cites rather than by what was retired, so **measure it, don't derive
it** — the method is above and takes one command).
Numbering the
filenames would mean rewriting those links now, and again on every
deletion, choosing each time between renumber-and-relink churn or a queue
that reads `05, 07, 09, 10`. The filename is the link target, so it has to
be the stable thing.

Deleting a spent brief is therefore not just an `rm`: **re-point whatever
linked to it in the same commit.** Retiring `skill-context-cost.md` on
2026-09-01 meant editing four other files, and the test was that no
surviving brief still says "read it there" about a file that is gone.

So: **stable kebab-case filenames, order in this file.** If a brief needs
to know it is blocked, that belongs in the brief as a dependency, not as a
position. A position is a fact about the queue and lives with the queue.

## The order

Waves, not a strict sequence — briefs inside a wave are independent of each
other and can go in any order or in parallel. Waves are ordered by
dependency and by cost of delay. Numbering starts at 1 because wave 0 —
confirming the three unverified item-type names — is spent; renumbering the
rest would only invalidate every reference to a wave elsewhere.

| # | Brief | Why here |
| --- | --- | --- |
| ~~**1**~~ | ~~`rule-glob-gaps.md` — bugs 1, 1b~~ | **Done 2026-08-31.** `coding-sparksql.md` now matches `**/*.Notebook/notebook-content.sql`; the `coding-tsql` overlap is resolved by a precedence section in each rule, keyed on the notebook kernel. Bug 1b was not a contradiction — recorded as a scope carve-out. |
| ~~**2**~~ | ~~`item-type-skill-kqlqueryset.md` + `rule-glob-gaps.md`~~ | **Done 2026-08-31.** Decided together, as one call. **No KQLQueryset skill** — there is no procedure to encode, only KQL authoring conventions that already existed and were correct. Fixed the rule instead: `coding-kql.md` gained three narrow item-specific globs for the JSON envelopes that hold queries, so it now reaches an actual query and not just schema DDL. Reasoning and the reconsider-if condition are recorded in `tests/skills/fabric-triggers/expected_activations.md`, which also gained the regression rows. |
| ~~**3**~~ | ~~`skill-model-policy.md`~~ | **Done 2026-09-01.** `model`, `effort` and `disable-model-invocation` are written out on all 44 skills so each flip point is visible in the file. Only `commit` changes behaviour (`model: sonnet`, `effort: high`); the six workflow skills pin `effort: max` as a floor under the unchanged `max` session default; DMI was declined repo-wide and is `false` everywhere. The `workflow-subagent` 24% was identified — it is the Workflow tool's fan-out agents, and a rare spike rather than a structural cost (three runs ever, 0% on 31 of 33 days). **Two items outlived the brief — see wave 8.** |
| ~~**4**~~ | ~~`skill-context-cost.md` workstream C~~ | **Done 2026-09-01 — C declined, and that retires the brief.** No merges. **C1** (`fabric-spark` + `fabric-error-handling`) and **C2** (the `pbir-*` trio) both keep their names and stay separate; **C3** was already a leave-alone. Three things settled it, two of which postdate the brief. C's headline figures were *body* sizes — C2 was scored at 9,086 tokens — but an activation injects the **listing entry**, so the real prize was ~700 tokens for C2 and ~169 for C1. Both are **zero in this repo**, where `skillOverrides` collapses all five names to `name-only`. And `DESCRIPTION_MAX` of 1,024, landed the same day by D, makes merging **lossy**: C2 would compress 2,914 chars of trigger text into 1,024 (−65%) and widen activation from 73 files to 82. C1 gained its own argument — co-firing is not sameness, `fabric-spark` is product surface while `fabric-error-handling` is this repo's own convention. Reasoning recorded in both `expected_activations.md` files so the column is not reopened. **Wave 4 is closed**, which unblocks [when-to-use-adoption.md](when-to-use-adoption.md) in full. |
| ~~**5**~~ | ~~`item-type-skill-datapipeline.md`~~ | **Done 2026-09-02.** The queue's only "yes, author it", and its largest single piece. `skills/fabric/fabric-data-pipeline/` landed with a `references/` split. `SamplePL.DataPipeline/.schedules` plus assertion 6 in [fabric-triggers](../../../tests/skills/fabric-triggers/expected_activations.md) closed the activation contract — the item's three rows moved off *(none)*, making this the 25th and last conditional skill covered. Behaviour verified in a cold session against a `--safe-mode` baseline: with the skill loaded it reverses the base model on `InvokePipeline` vs `ExecutePipeline`, and on the 7-day default an absent `policy.timeout` gets. Both this brief and the `fabric-data-pipeline.md` handoff brief are deleted. |
| ~~**6**~~ | ~~`rule-glob-gaps.md` — bug 3~~ | **Done 2026-08-31.** `**/*.GraphModel/**` added to `fabric-git-serialization.md`, with `**/*.UserDataFunction/**` and `**/*.ApacheAirflowJob/**` from a partial item-type diff. `Dataflow` confirmed correct. |
| ~~**7**~~ | ~~`skill-effectiveness-telemetry.md`~~ | **Done 2026-09-03 — the script was built, the skill was declined, and the brief's central "can't be done" turned out to be false.** Step 1 was **split: script yes, skill no.** [`scripts/skill-telemetry.py`](../../../scripts/skill-telemetry.py) ships with the brief's three subcommands — `coverage`, `listing`, `triggers` — reading only what already exists. No new hook, no third log, so the **retention** question is moot and the `UserPromptSubmit` question is withdrawn rather than answered: blind spot 4 needs no new capture point, because transcripts already carry `attributionSkill` on every assistant message *and* the `<command-name>` expansion. **Blind spot 1 is capturable, and the brief said it was not.** It called per-turn listing contents "the hardest to get — it requires knowing the listing contents at each turn, which nothing logs today". They are logged: the `isInitial: true` `skill_listing` attachment carries `names`, `skillCount` and the rendered `content`, present in **259 of 268** transcripts. So "listed and passed over" is a plain set difference, and the brief's sharpened requirement — distinguish **withheld** from **listed-not-chosen** from **chosen** — is met by construction rather than by inference. **The brief's recommendation to extend `scripts/instructions-log` was overturned on two grounds**, and the second is measured: the data is different (that script owns the two hook logs; all of this comes from transcripts), and bash+jq cannot do it — a per-file `jq` loop over ~270 transcripts **did not finish inside two minutes**, where the same scan in-process takes **~1s**. It is a sibling script, in Python, alongside `activation-expect.py` and `lint-frontmatter.py`. **The load-bearing correction is that an `isInitial: false` attachment is not proof of a `paths:` match.** Editing a `SKILL.md` hot-reloads and re-announces *that* skill, and a `link-claude.ps1` run re-announces everything it deployed; both are byte-identical to an activation. **438** deltas across this machine's transcripts named a skill that was already in the same session's startup listing, and every one sampled was preceded by an `Edit` to its `SKILL.md` or a redeploy. In this repo, where editing skills *is* the work, that is most of the deltas — so a naive counter would have reported `fabric-semantic-model-ai-instructions` as "activated once" when it had only ever been *written* once. The script subtracts the explainable ones. It does **not** affect [`test-activation.ps1`](../../../scripts/test-activation.ps1), and the reason is worth keeping: its probe pins `--allowedTools Read`, so it cannot write a skill or redeploy — a tool restriction added for a different reason turns out to be what keeps the assertion sound. Root [`CLAUDE.md`](../../../CLAUDE.md) and both trigger READMEs now say so. **Truncation is still not available as a fixture, and this confirms the retraction rather than resting on it**: the largest listing ever rendered on this machine is 29,988 chars, no unconditional skill on disk has ever been absent from a listing, and `listing` reports "no evidence of listing truncation". The brief's own acceptance test — "flags all 19 currently-dropped skills from the ACME repo" — was therefore **unrunnable as written**, since those 19 were the retracted finding; the surviving half of it (flags none here) passes. **The verdict rubric was defined before any verdict was automated**, per the brief's demand: no flag ever recommends deleting a skill, `LISTED_FLOOR`/`SLASH_FLOOR` keep a young skill off the flags it cannot yet have earned, and a skill that carries a glob *now* but appears in old listings is labelled as configuration history rather than waste — five skills moved unconditional → conditional in one pass and would otherwise all read as findings. **Cross-machine is out of scope**: transcripts are per-machine and gitignored by nature, and nothing here aggregates across machines. **The skill half is declined, and the tool's own first run is the argument.** `code-review` has appeared in **259 of 259** listings and has been auto-triggered **zero** times (4 slash runs, 0 `Skill`-tool dispatches); `fabric-ai-functions`, `fabric-cli`, `fabric-rest-api`, `fabric-security` and `pbid-tom-live` sit in 92–162 listings each with no use of any kind. Adding another unconditional workflow skill to that listing is the exact cost this data says is already overpaid. The brief's escape hatch — `disable-model-invocation: true`, which would make it listing-free — was rejected as too large a change for the gain: DMI is `false` on all 50 skills today and introducing it here would be its first use in the repo. And the judgement content is thin enough to travel with the output: the rubric is a dozen lines, it lives in `verdict()` and the legend, and it prints on every run. **Reconsider if** a run ever produces a finding the legend cannot explain, or if the corpus grows past the point where reading the table is itself the work. |
| ~~**8**~~ | ~~*No brief — this row was the whole spec.* Validate the wave 3 frontmatter pass, and decide the `security-reviewer` model~~ | **Done 2026-09-01**, fresh session, Claude Code 2.1.252. **(a)** [`claude/agents/security-reviewer.md`](../../../claude/agents/security-reviewer.md) is now `model: sonnet`. Baseline (`inherit` → `claude-opus-5`) and candidate (`claude-sonnet-5`) each scanned the fixtures from an identical cold memory state, and the caught/not-caught sets were **identical**: 4/4 seeded findings at the expected severities (2 Critical at `config.py:2,3`, 1 High at `queries.py:3`, 1 Low at `notes.md:1`), no false positives, five-field format intact, all four closing-summary components present, memory seeded, and neither run read `expected_findings.md`. Fixtures unmodified after. Mode 3 on sonnet took the **preferred** branch — refused outright, never attempted the `Edit` — so the hook had nothing to block; it was verified separately as a direct unit test over four cases (in-scope write allowed, out-of-scope write blocked with exit 2, a different `agent_type` unaffected, `../` traversal out of the memory dir blocked). Both runs **foreground**. The **frontmatter** pin — which those two runs could not exercise, since sonnet was forced by an Agent-tool override and a subagent is not hot-reloaded into the session that edits it — was confirmed separately the same day from a fresh session (`83089e9f`, started 25 minutes after the pin landed): an un-overridden spawn ran `claude-sonnet-5` while its parent session sat on Opus. **Wave 8(a) is fully closed.** **(b)** ~~Confirm `/commit` picks up its pins.~~ **Closed** — `e3cae240` shows three `commit` runs at `claude-sonnet-5 xhigh`, each bracketed by `claude-opus-5 high`, so both pins fire at the *current* values and turn-scoping holds. **(c)** **Confirmed** — a plain-English request does auto-trigger `commit`; see the invocation-path finding below, which is how it was measured. |
| ~~**9**~~ | ~~`activation-cleanroom-null.md`~~ | **Done 2026-09-01.** The clean room was never the variable — **the `Read` tool is**. Activation is keyed to file access through `Read`; a Bash `cat` or a `Grep` over the same file activates nothing, and this machine defaults every session to auto mode, which prefers `cat`. Measured as a 2x2 (Read/`cat` x in-repo/scratch): `Read` activated the same 3 skills and loaded the same rule in **both** directories, `cat` in **neither**. The original report's correlation was luck — all 8 clean-room probes chose `cat`, both in-repo controls chose `Read`; re-reading those transcripts confirms it retroactively. Every directory hypothesis is ruled out by its own probe: git repo, `AppData/Local/Temp`, missing `.claude/settings.json`, 8.3 short path, and fixture depth. Negative control clean. Written into root [`CLAUDE.md`](../../../CLAUDE.md) and both trigger READMEs. **Wave 10 is unblocked** — it may run anywhere, and must pin `--allowedTools Read --disallowedTools Bash …` and fail on a non-`Read` tool call. |
| ~~**10**~~ | ~~`activation-test-harness.md`~~ | **Done 2026-09-02.** [`scripts/test-activation.ps1`](../../../scripts/test-activation.ps1) runs the real-path test for a named set in one command — static check, deploy to a throwaway probe outside the repo, one cold session, transcript assertion, teardown in a `finally`. Expectations come from [`scripts/activation-expect.py`](../../../scripts/activation-expect.py). **Both sets PASS**: pbip 16/16, fabric 57/57, skills *and* rules. See the finding below for the open question it answered. |
| ~~**11**~~ | ~~`item-type-skill-operationsagent.md` → `fabric-operations-agent.md`~~ | **Done 2026-09-02.** The decision was **yes** — [`skills/fabric/fabric-operations-agent/`](../../../skills/fabric/fabric-operations-agent/SKILL.md) exists with a `references/` split, and the free side-fix landed too (`**/*.OperationsAgent/**` added to `fabric-git-serialization.md`). Validated the same day — fixtures, the two `expected_activations.md` rows, `test-activation.ps1 -Set fabric` (59/59, re-confirmed at close) and the cold behaviour run against a `--safe-mode` baseline. Both briefs are now deleted per the [lifecycle](#lifecycle), the decision brief's three inbound references re-pointed in the same commit. Two of the source brief's findings were **overturned** rather than executed, and both survive the deletion in live artifacts rather than in the brief: its step 3b portability conclusion is inverted in [SKILL.md §4](../../../skills/fabric/fabric-operations-agent/SKILL.md) (`dataSource.id` is the source `logicalId` verbatim; `jobArtifactId` is the target's byte-reversed, and the asymmetry is a schema fact rather than a portability one), and its two-ID-families hypothesis became wave 16. |
| ~~**12**~~ | ~~`item-type-skill-ontology.md`~~ | **Done 2026-09-02.** The decision was **yes** — [`skills/fabric/fabric-ontology/`](../../../skills/fabric/fabric-ontology/SKILL.md) exists with a `references/` split, and the free side-fix landed (`**/*.Ontology/**` added to `fabric-git-serialization.md`). **Step 1 resolved without a workspace, and that is the reusable part**: the REST [Ontology definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/ontology-definition) page states the suffix outright — its definition example's base64 `.platform` payload decodes to `"type": "Ontology"` — and settles the whole `definition/` layout in the same fetch, which the brief had called unguessable. No guess was committed. Wave 14's step 1 is re-pointed at that method. The skill's highest-value content came from pages the brief had **not** drilled: `how-to-bind-data` yielded one static binding per entity type but many time-series, static-before-time-series ordering, entity keys string/integer only, no OneLake security, and the source-type map in which lakehouse `decimal` binds to `double` while `decimal(p, s)` binds to **string**; `resources-troubleshooting` yielded the documented remedy for the `Decimal` null trap (recreate as `Double`, bind manually) that the brief recorded only as a dead end. The payload inconsistency is closed — `fabric-data-agent` now points at the new skill. Validated: static 64/64, `test-activation.ps1 -Set fabric` **PASS 64/64 skills and rules**, and a cold behaviour run against a `--safe-mode` baseline where the baseline answered **"Yes"** to binding two static tables to one entity type (wrong), invented the cause of missing Direct Lake bindings, and prescribed a CAST-view fix for the `Decimal` trap. Registered a `fabric-iq-ontology` drift source. Brief deleted; three inbound references re-pointed in the same commit. |
| ~~**13**~~ | ~~`skill-semantic-model-audit.md`~~ | **Done 2026-09-02.** The decision was **yes** — [`skills/fabric/fabric-semantic-model-audit/`](../../../skills/fabric/fabric-semantic-model-audit/SKILL.md) exists with a `references/` split, **unconditional on purpose**: a `**/*.SemanticModel/**` glob would co-load a whole audit procedure onto every one-line measure edit. Design and performance stayed one skill, but the fusion argument **narrowed** — "inactive relationships are also expanded" is import-mode guidance, while Direct Lake builds join indexes at query time and is silent on inactive ones, so the skill states that rather than generalising. The reference model was re-measured and **overturned this brief's own acceptance test**: `DimDate` is *not* a role-playing dimension — its four inbound relationships come from three different fact tables — and the real one is `Customer`. Counting is per (fact, dimension) pair, and that became the skill's headline false-positive guard. Sharper still: 6 of the 7 inactive relationships have no `USERELATIONSHIP` that can reach them. Validated in cold sessions against a `--safe-mode` baseline — 4/4 criteria met, and the baseline scored **zero** on "both-sides", "role-play", "snowflake", "unreachable" and "star schema", clearing the `DimDate` criterion only by never asking the question. That bounds the claim: the skill buys structural discipline, not defect-finding. The `scripts/data/*.sh` citation idiom is settled (conditional accelerator, never a dependency). Both briefs deleted; five inbound references re-pointed in the same commit. **The MCP spin-off became wave 17.** |
| **14** | [item-type-skill-fabric-plan.md](item-type-skill-fabric-plan.md) | **Deferred 2026-09-03 — step 0 answered *no*, and the brief stays on disk.** Not a decline: the content is still real, uncovered and unguessable (its automatic time-intelligence parser silently drops `Sept`, `WK1`, `Q5`), and Plan is still a Git-supported item. The defer is about *use*. Step 0 was re-measured the day it was answered rather than taken from the brief's 2026-09-02 snapshot: no `*.Plan` folder in `fabric-acme`, `fabric-acme-legacy`, `edgebridge` or `internal-tooling`, and the payload's only mention of Plan is the clause in `fabric-ontology`'s `when_to_use` disambiguating the ontology item **from** it — negative pressure, the exact opposite of the payload inconsistency that drove wave 12. **Revisit when a Plan item appears, and re-run step 0 rather than trusting this row.** Delete the brief only if the workload is abandoned upstream or ruled out outright, and record which. **Re-run later the same day on that instruction, and the answer held — but the brief's step 0 evidence had already rotted in under two hours, which is the part worth carrying.** Repo side is unchanged and now measured wider (full-depth `find` for `*.Plan` across all of `C:\Repos\ACME`, worktrees included, plus `internal-tooling`: zero, against thirteen other suffixes present). Payload side moved: the brief's `grep -rni "powertable\|fabric iq plan"` baseline of *nothing* became **five hits**, all from `tests/skills/fabric-semantic-model-audit/`, landed by `9ccbace` at 03:19 — 1h39m **after** the step 0 answer was committed at 01:40. They are the audit skill's planning-model carve-out fixtures, so they push work **away** from Plan exactly as the `fabric-ontology` clause does. **A rising mention count is not rising pressure**, and left uncorrected that grep would have read as the wave-12 pattern to whoever ran it next; the brief now says so at the grep itself. No suffix guessed, no glob written, no skill drafted. **The carve-out debt was paid the same day rather than deferred with the rest** — `fabric-semantic-model-audit` now carries a planning-model exclusion in its "what an audit must not flag" section, because that half never needed the folder suffix, a glob or a Plan item to be correct: it is a false-positive guard on checks 1 and 9, and check 1's "collapse the snowflake" remediation is actively destructive on a model whose dimension-side parent keys generate the planning grid. What is still owed if this ever proceeds is the skill itself, and step 1's folder suffix from the REST Plan-definition page by wave 12's method. |
| ~~**15**~~ | ~~`concurrent-session-workflow.md`~~ | **Done 2026-09-02 — the answer is no.** Branching stays the exception and committing straight to `main` stays the default. The premise re-confirmed mechanically: one working tree has one HEAD, so two sessions in it share every file regardless of branch, and git refuses the same branch in two worktrees. Worktrees were then **measured**, in a real one probed cold, and root [`CLAUDE.md`](../../../CLAUDE.md) had named the wrong blocker — `link-claude.ps1` takes `$RepoRoot` from `$PSScriptRoot`, so the worktree's own copy deploys the worktree's skills and a session there loads them, conditional activation included. The real blocker is **scope precedence**: with `drift-handoff` at both scopes and a marker in only the worktree's copy, the listing carried the **user-scope** text. Project scope only adds names user scope lacks — so a worktree is **unnecessary** for a platform skill (pruned from user scope, so authoring one changes no session's payload) and **ineffective** for a workflow skill (at user scope, unoverridable), with no case in between. The downstream **PR-skill question resolves no** as well, on new grounds: the base-rate argument was bad and stays bad, but the flow is three commands plus "open the PR with `github-mcp`, not `gh`", both already in root `CLAUDE.md`, which auto-loads here — a skill would spend permanent listing budget on text already in context. **Reconsider if** a second silent collision between concurrent sessions happens anyway. Brief deleted; `CLAUDE.md`'s worktree section rewritten with the measurements.. **The PR-skill half was reversed the same day — see wave 18.** The worktree and branching findings stand; only the "no" on a PR skill was overturned, on the measurement rather than the principle: the flow is ~10 operations with two silent-failure modes, not the three commands assumed here. |
| ~~**16**~~ | ~~`logicalid-runtime-id-encoding.md`~~ | **Done 2026-09-03 — the claim holds, with a precondition the brief did not anticipate.** `rev(logicalId)` **is** the runtime item ID — for an item **created in the portal**. An item authored *git-first* (committed as files, then synced into the workspace) carries a fresh client-side v4 that encodes nothing. **Step 2 ran first, offline, as the brief allowed**: 79 reversals with zero failures, across both local workspaces (74 of 76 — `fabric-acme-legacy` was a second workspace the brief never sampled) and ~20 unrelated public repos and tenants, where every one of 37 ids is a valid v4 in **exactly one** of the two forms, never both and never neither. It also **explained the two known exceptions offline**, which the brief had parked as a step 1 sub-question: classifying each item by whether its oldest commit is a Fabric portal sync (`Committing N items from workspace ...`) separates the forms **76 of 76 with no cross-cases**. **Step 1 then confirmed the runtime half** against `GET /v1/workspaces/{ws}/items` over 19 workspaces: of the reversals that resolved to anything, **21 of 21** hit a real item carrying the **same `displayName` and `type`**; none hit a different item; no raw `logicalId` was itself an item ID. The other 16 are absent from every visible workspace and so neither confirm nor refute. Both git-first items were among them, so that half stays consistent-but-untested and is written up as such. **The method note is the reusable part, because two earlier attempts were wrong in opposite directions.** Matching local items to API items *by name* is unsound here — the solution is deployed across four workspaces, so every name resolves four ways; that first attempt produced 120 comparisons from 37 items, and scoping it to one workspace then produced a spurious "mixed" result by pairing items with the wrong copy. The decisive test needs no names at all: collect every item ID visible to the identity (296 of them) and ask whether `rev(logicalId)` is a **member**. A 128-bit match plus name/type agreement is proof, and membership testing sidesteps the ambiguity that broke both earlier passes. Edited `fabric-gotchas` (anti-pattern line + the `PowerBIEntityNotFound` reference section), `fabric-rest-api` (Item IDs section, plus a fourth "fetch the runtime ID" route: derive it offline) and `fabric-operations-agent` §4, which previously stated the relationship and explicitly declined the inference. All three keep the "NOT interchangeable" wording — **deriving is now safe, substituting is still the bug.** Brief deleted; this row was its only inbound link. |
| ~~**17**~~ | ~~*No brief — this row was the whole spec.* A **Power BI MCP template** for `claude/mcp/`~~ | **Done 2026-09-03 — and step 0 found half of it already shipped.** Re-measuring before executing, as wave 14 taught: **both** servers were already in the payload. [`powerbi-modeling-mcp`](https://github.com/microsoft/powerbi-modeling-mcp) has been in [`.mcp.project.template.json`](../../../claude/mcp/.mcp.project.template.json) with a README row since `140cc42` on **2026-08-28** — five days *before* this row was registered on 2026-09-02, so it was never true — and the remote one is `powerbi-remote-mcp` in [`.vscode/mcp.template.json`](../../../.vscode/mcp.template.json) — correctly there and not in the Claude templates, because it is an `api.fabric.microsoft.com/v1/mcp/*` endpoint and so DCR-blocked from Claude Code. **No JSON changed**: the invocation `npx -y @microsoft/powerbi-modeling-mcp@latest --start` and the remote URL both match upstream byte for byte. So the row's "the work is a template" was already spent, and what remained was the half it treated as an afterthought. **The payload pointer — the actual deliverable — landed.** The row's claim was confirmed verbatim at [`semantic-model-best-practices`](https://learn.microsoft.com/fabric/data-science/semantic-model-best-practices#prep-for-ai-make-semantic-model-ai-ready) ("renaming all objects manually can be tedious… use the Power BI Modeling MCP server to have an LLM generate business-friendly names… **Review and validate the changes before saving**"), which is the same page §7's data-agent bullet already rests on. `fabric-semantic-model-audit` §7 now carries the conditional sentence in the `dax.sh` idiom — accelerator, never a dependency — plus the two things the recommendation is useless without: **reporting the finding is this skill's job and running the rename is not** (a write needs a separate ask), and the source's own caveat, since an unreviewed bulk rename breaks DAX, relationships and dependents. Check 13's remediation cell in `references/REFERENCE.md` points at it. **Three drift corrections fell out of verifying the existing row, all in the same direction — the server is bigger than the payload said.** Its connection target is not "Power BI Desktop is open with a model loaded" but **three** targets, the third being a **PBIP TMDL folder on disk** needing no Desktop and no capacity; that invalidated the *stated reason* for the project-scope call in "What belongs at which scope" while **strengthening** the call itself, so the paragraph now says which. Node.js **20.0+** is pinned upstream for this server alone. And "almost no repo wants all six" was stale — six was right at `140cc42` and `github-mcp` landed after, making it seven. **A new `### powerbi-modeling-mcp is a write tool` section carries what a write-enabled default deserves**: `--readwrite` is the documented default and the template passes nothing to change it, `--readonly` / `--skipconfirmation` are the two flags that move the risk, write permission is a Power BI permission rather than an MCP one, and **XMLA is the only lever that blocks the server** — so disabling it is never a targeted control. **One thing was checked rather than assumed and came back negative, which is why it is worth recording**: the server gates its first write and first query behind MCP **elicitation**, and a client without it would fail or hang exactly where `--skipconfirmation` looks like the fix. Claude Code **2.1.252 implements it** — the bundle registers an `elicitation/create` handler with `form` and `url` modes — so the confirmations stay on. **This is not the DCR story**: same file, adjacent servers, opposite answer. The remote server's two silent gates are now in [`.vscode/README.md`](../../../.vscode/README.md) too — the *"Users can use the Power BI Model Context Protocol server endpoint (preview)"* tenant setting, and the Copilot licence its `Generate Query` tool alone consumes — both of which fail *after* the server connects and so read as an empty model. **No drift source was registered, deliberately.** `powerbi` already lists MCP templates in its `artifacts`, and `fabric-iq-ontology` says in as many words not to read it as a precedent for one source per skill. The real gap is narrower and is recorded where it bites instead: the flags and connection targets live in the **GitHub README**, which Learn links to rather than restates, so a `powerbi` What's New run cannot see a flag rename — the section carries a dated verification stamp and a re-read-at-GA instruction. Both servers are Public Preview. |
| ~~**18**~~ | ~~`land.md`~~ | **Done 2026-09-03.** **Reversed wave 15's PR-skill "no"**, deliberately and with that decision quoted. Wave 15 priced the flow at "three commands plus open the PR with `github-mcp`, not `gh`"; landing PR #7 measured it at ~10 operations with two failure modes that produce no error — the **identity** one (`gh` holds a work account here while `github-mcp` holds the personal one that owns the repo, and `CLAUDE.md` can state the rule but cannot make the comparison happen) and the **integration** one (a squash or merge-button click silently discards what `/commit` just built) — plus the PR body, which is judgement work the payload covered nowhere. [`skills/workflow/land/`](../../../skills/workflow/land/SKILL.md) shipped, unconditional, no `paths:` glob, so Phase A was skipped as designed and both static sets still pass unchanged (fabric 64/64, pbip 16/16). Cold `/test-skill land` confirmed **both invocation paths**: NL gives `Skill{skill: land}`, `/land` gives a `<command-name>` expansion, never `Unknown command` — correct for an unconditional skill. The `--safe-mode` control merged `main` on its own with no identity check and no PR; note the identity rule is *also* in user-scope `CLAUDE.md`, so only the checkpoint, the `--ff-only` reasoning, the concurrent-session disclosure and the PR-body requirements are uniquely the skill's. **Two defects came out of that run and both are now closed.** **Defect 1** — the checkpoint was anchored to the PR and vanished without one: with a non-GitHub `file://` remote the skill dropped step 6 and pushed `main`. Step 6 now gates on the next command that **writes to `main`** rather than on the PR, and step 5 makes "no GitHub remote or no `github-mcp`" a stop rather than a licence to merge locally. **Defect 2** — a directive prompt bypassed the skill entirely: "Land this branch… just squash the two commits and merge that into main" left `land` in the listing and never invoked it, so it squashed with no pushback. Keyword presence was never the problem (the description already carried "merge to main" *and* "squash"); the prompt pre-specified the mechanism, which reads as an instruction rather than a request for a procedure. The description now names those shapes outright, 683 → 894 chars — over the brief's ~600 target, accepted because the growth is *entirely* trigger vocabulary and the summary half was untouched. **Measured: it fires.** A cold `-p` probe outside the repo replayed the original prompt verbatim and produced `Skill{skill: land}`; the mitigation ("anti-pattern cases need `/land`") is retired. One probe, one prompt shape — the claim is that this shape triggers, not that every directive phrasing does. **Constraints were decided rather than hardened**, because under `/land` the flat "never squash" was defeated anyway, with the rule's purpose reasoned about and the override disclosed; hardening was rejected since that rule had already lost once and a flat refusal contradicts the harness's own disposition that a reaffirmed instruction is the user's call. They now split by **what kind of claim each item is** — *absolute* (never `gh` for the PR, never `--force`/`--no-verify`, never write to `main` before the checkpoint, never `git switch` with a live session), because identity and safety cannot be consented to by an asker who does not know which account `gh` holds; and *repo convention, overridable but never silently* (squash, merge commit, branch deletion) — name the specific cost, wait one round, record it in the PR body, then comply. The gate is step 6's stop-and-wait, which held in testing where a `never` did not. **The GitHub happy path ran live as [PR #9](https://github.com/wardawgmalvicious/agent-config/pull/9) — the fix landing itself.** That was the wave's last gap, because `github-mcp` is project-scope only in this repo's `.mcp.json` so no cold probe outside the repo could reach it; running the skill *inside* the repo on its own branch is what closed it. All eight steps executed as written and **the identity trap fired for real** — `gh` resolved to `wmalcolm-fdi` against a repo owned by `wardawgmalvicious`, step 2 caught it, the PR went through `github-mcp`. Verified: `merged: true`, `merged_by: wardawgmalvicious`, both `pre-commit` runs `success`, merge commits still **0**, `main` and `origin/main` identical. The same probe confirmed the overridable tier — told to squash it named the specific cost, noted the repo was already linear so a squash bought no linearity, said "it's your history" and **stopped without squashing** — and caught the `file://` remote as a step-5 stop, which is defect 1's fix holding under the condition that originally broke it. Brief deleted; its one inbound link was this row. |

`skill-context-cost.md` is **retired as of 2026-09-01** — A, B, D's policy
half and E all landed, and C was declined, so nothing in it remained open.
Per the [lifecycle](#lifecycle) the file is deleted and git history is the
archive; the queue rows above carry the outcomes. Recover it with
`git log --diff-filter=D -- 'docs/**/skill-context-cost.md'`
then `git show <sha>^:<path>`. Its durable method survived the deletion
rather than going with it: the static glob check lives in both trigger
READMEs — and is now also the `-StaticOnly` mode of
`scripts/test-activation.ps1` — the `--debug-file` recipe in
`tests/skills/pbip-triggers/README.md`, and the content-preservation
diff — which caught silent content loss twice — moved into `author-skill`
step 6.

Its workstream **D** (`when_to_use`) landed its policy half the same day:
split **A** — `description` ≤ 1,024, `when_to_use` ≤ 512, enforced separately
in `scripts/lint-frontmatter.py`, with root `CLAUDE.md`, the handoff
template and `author-skill` reworded to match. All 44 skills passed the
tightened gate unchanged. The premise the cost model rested on was drilled
and holds: `when_to_use` really is appended to `description` in the listing
and shares its 1,536 truncation point.

The adoption half — which skills get the field, and what each says — is
[when-to-use-adoption.md](when-to-use-adoption.md), and **wave 4 closing
unblocks it in full.** It was held back because both of wave 4's
workstreams churned the corpus it edits; both are now settled. **E** moved
five skills from unconditional to conditional, making the split **24/20**
at the time — **25/21** today, after `fabric-data-pipeline` — rather than
19/25, and **C** was declined, so no conditional skill is renamed or
merged out of existence. The `pbir-*` trio survives intact —
which *sharpens* the brief rather than shrinking it, since three
permanently co-firing conditional skills are exactly where `when_to_use`
disambiguation earns its keep, and the field is near-free on conditional
skills.

Cost still shapes the other half: adding the field to all 21 unconditional
skills would put ~4,000 tokens onto a listing already sitting at ~9,900
against a ~10,000-token budget, so that half stays net-neutral-or-nothing
rather than a blanket pass.

## Wave 8 finding: the two pins do not travel the same path

Measuring (b) and (c) put every `commit` run since the pins landed side by
side, and they separate cleanly on **how the skill was invoked** — not on
version, and not on time:

| Run (UTC) | Invoked by | `model` | `effort` |
| --- | --- | --- | --- |
| 2026-08-31T23:19 | `/commit` | `claude-sonnet-5` | `high` |
| 2026-09-01T04:48 | `/commit` | `claude-sonnet-5` | `high` |
| 2026-09-01T05:08 | plain English | **`claude-opus-5`** | `xhigh` |
| 2026-09-01T06:13 | plain English | **`claude-opus-5`** | `xhigh` |
| 2026-09-01T14:44 | `/commit` | `claude-sonnet-5` | `xhigh` |
| 2026-09-01T15:48 | `/commit` | `claude-sonnet-5` | `xhigh` |
| 2026-09-01T15:59 | plain English | **`claude-opus-5`** | `xhigh` |

`model: sonnet` has been live since 2026-08-31T21:55Z (`56e00bc`) and
`effort: xhigh` since 2026-09-01T04:57Z (`c7caa5d`), so every row above is
*after* its own pin. **`effort` applied on all five. `model` applied on the
three slash runs and on neither auto-triggered one.** Version is ruled out:
2.1.251 produced both a slash run that took the model pin and two auto runs
that did not, so this is not a release boundary.

That the two auto-triggered runs exist at all is what closes **(c)** — a
plain-English request does fire the skill, twice, with no slash command.
To tell the paths apart in a transcript: a slash invocation writes a user
record containing `<command-name>/commit</command-name>` immediately before
the injected skill body, and an auto-trigger injects the body
(`Base directory for this skill: ...`) with no such header.

**Reading (B) has since been largely ruled out.** It held that those two
sessions had a session model explicitly pinned, which outranked the skill's.
There *is* such a pin — `~/.claude/settings.json` carries
`"model": "opus[1m]"` — but it is **user scope and therefore constant across
every row in the table**, including the three slash runs that honoured
`model: sonnet` anyway. An override in force during the runs that took the
pin cannot be what stopped the runs that didn't. Neither auto-trigger
session issued a `/model` command either (`3b303490` issued no slash command
at all). That leaves **(A)**: `model:` is honoured on explicit slash
invocation and dropped on model-invocation.

Worth knowing when re-checking this: `model` is **not** part of this repo's
payload — `claude/settings.json` has never carried the key. Claude Code
writes it into the deployed copy itself, next to `theme`, `tui` and
`agentPushNotifEnabled`. So it is live client state that a key-level merge
preserves, not something a `link-claude.ps1 -Force` run sets or clears.

**(A) is confirmed.** The last two rows are the decisive pair: same
session, same `2.1.252`, same `opus[1m]` session model, same skill, same
pins, eleven minutes apart. The *only* variable was how the skill was
reached, and the model followed it. `effort: xhigh` applied to both.

Root [`CLAUDE.md`](../../../CLAUDE.md) has been amended accordingly — the
`model:` entry in the skill-invocation section now says slash-only, and
carries the two consequences. `commit`'s `model: sonnet` is a saving only
when you actually type `/commit`; a plain-English "commit this" runs on the
session model.

**The second consequence was wrong, and is corrected as of 2026-09-02.**
This section used to say a `model:` pin on any platform skill was inert by
construction, "since those trigger by description and never by slash."
That holds only for the **27 conditional** ones, whose `paths:` glob
withholds them from the startup listing — until a matching file is Read
they have no description in context and `/<name>` answers `Unknown
command`. The other **13** carry no glob and slash normally, so a pin
there is **live**. Measured on 2.1.252 with `/fabric-gotchas` against
`/fabric-data-pipeline`. All 39 are `model: inherit` today, so nothing is
broken either way; root `CLAUDE.md` now carries the split.

**Subagents are the opposite case, and it was worth checking rather than
inferring.** A subagent's `model:` is a different mechanism — an agent
definition, not skill frontmatter — so the slash-only result above does not
transfer to it. Measured from a fresh session: an un-overridden
`security-reviewer` spawn ran `claude-sonnet-5` while its parent sat on
Opus. **The pin applies.** So the two mechanisms genuinely differ — a
skill's `model:` is dropped on the model-invocation path, a subagent's is
honoured on an Agent-tool spawn — and neither should be reasoned about from
the other.

The control that makes that readable is
`subagents/agent-<agentId>.meta.json`: it carries a `model` key **only**
when an Agent-tool override was passed. Absent on the confirming run,
present (`"model":"sonnet"`) on the two forced during wave 8(a). Check it
before believing any subagent model measurement — an override and a
frontmatter pin produce an identical `.message.model`, and this file is the
only thing that tells them apart.

Scope it honestly: that is **one spawn path**, the Agent tool at
`spawnDepth: 1`. It is not a general claim about every way a subagent is
reached — subagent preloading and scheduled-task firing are untested.

Method note, since wave 8 needed it and the fixture README assumes it:
**a subagent's transcript is its own file**, at
`~/.claude/projects/<project>/<session-id>/subagents/agent-<agentId>.jsonl`
— *not* an `isSidechain` record inside the parent session transcript, where
looking for it turns up nothing.

## Wave 10 finding: activation is a per-session delta

The open question — per-session delta or per-file? — is **delta**, for
rules as well as skills, and it was answerable in one session as predicted.
Three confirmations from that one run, each with the static check as its
control (every file below *does* match, so the silences are deduplication
and not a failure to fire):

| Read | Expected | Emitted |
| --- | --- | --- |
| `bookmarks.json` | `pbir-bookmarks` + rule | both |
| `Bookmark1.bookmark.json` — identical expectations | `pbir-bookmarks` + rule | **nothing** |
| `report.json` | `pbir-filters` + same rule | skill only — the rule was already loaded |
| `page.json` | `pbir-filters`, `pbir-pages` | `pbir-pages` only |

So a full run is **~2 sessions, not ~50**, which is what makes the test
cheap enough to actually get run. Three things came out of building it that
the brief did not anticipate:

- **`expected_activations.md` did *not* need an order-aware form.** The
  brief expected one. Instead the script derives the expected delta from
  the read order it *observes* in the transcript, so the tables stay plain
  per-file contracts and the ordering never forks into a second format.
- **Attachments flush in batches, not per read.** A run of several reads
  can produce one flush covering all of them, so an activation is
  attributable to the group of files read since the previous flush rather
  than always to one file. Getting this wrong makes every activation look
  one or two reads late — a whole-run failure that reads like a dozen
  unrelated glob bugs. Prompting for a line after each read narrows the
  groups but does not reliably reach 1:1.
- **Both skill groups must deploy for either set.** The fabric set's
  headline negative assertion — `pbip-project-structure` must not fire on
  `SampleNB.Notebook/.platform` — is vacuous unless that skill is present
  to fail. Deploying only the set's own group would have turned the
  regression test into a tautology that passes forever.

Two smaller things fixed in passing. The `.platform` fixtures forced a
Windows detail into the open: `$env:TEMP` yields the 8.3 short path
(`C:\Users\EXAMPL~1\...`) while Claude records the long one, so paths are
compared with `os.path.realpath`; and casing is preserved rather than
`normcase`d, because the globs themselves are case-sensitive and a
lowercased path stops matching `**/*.Report/.platform`. One row of
`fabric-triggers/expected_activations.md` collapsed three DataAgent
`published/` fixtures into prose, leaving them unasserted — expanded into
three explicit rows.

## What this order is optimising for

**Bugs before improvements.** Wave 1 was the only thing in the queue
producing wrong behaviour; it landed 2026-08-31, so what remains is all
improvement and judgement work.

**Paired decisions in one sitting.** Waves 2 and 4 each merge briefs that
would otherwise make the same call twice — the failure mode that forced
the 2026-08-31 consolidation of four briefs into two.

**Cheap and independent before expensive.** Wave 3 ran before 4 and 5 and
is done; wave 8 was what it left behind, and is now spent too. Waves 9 and
10 are what wave 4 left behind, in the same way — closing A1 by hand
surfaced both, and neither was in scope to fix while doing it. Both are
now spent, and each paid for itself: 9 found that the culprit was not a
property of any directory but a false negative in the measurement method
that both trigger READMEs documented, and 10 turned the whole procedure
into one command — the point at which a check stops being something you
have to be talked into running.

**Waves are not a priority order past this point.** 5, 9, 10 and 11 are
all spent; 5 was the biggest single piece of work in the queue and was
late only because it was expensive. Of the three that blocked nothing and
were blocked by nothing, **none is left** — 16 was gated solely on a
credential and the session that had one closed it, 17 closed on
2026-09-03, and 7 closed the same day.

**Every numbered wave is now spent or deferred**, so the queue's ordering
job is done: 1–13 and 15–18 are struck, and 14 is the single deferred
row, waiting on a Plan item appearing rather than on anything here. What
survives the numbers is
[when-to-use-adoption.md](when-to-use-adoption.md), which never held a
wave — it was blocked on wave 4 and has been unblocked since 2026-09-01.
It is the only open work with no position, which is now the same thing as
being next.

**Wave 17 is the queue's worked example of a row that was stale the day
it was written.** It specified a template as the work; that template had
shipped in `140cc42` on **2026-08-28**, five days *before* the row was
registered on 2026-09-02 — and not as part of any wave, but in an
ordinary MCP refactor that nobody thought to check the queue against.
Executing the row as written would have produced a duplicate entry and no
new capability. The half it treated as a one-line afterthought — the
payload pointer into `fabric-semantic-model-audit` — was the only half
still open. Wave 14 recorded the same lesson from the other direction, so
take the pair as the rule: **re-measure a row's evidence before acting on
it.** 14's had rotted in under two hours, 17's was never true; the
interval is not the signal, and neither was detectable without going and
looking. The specific trap here is that queue rows are written *about*
payload directories but nothing links the two, so a commit outside the
queue can silently satisfy or invalidate a row.

**Waves 12–14 were the exception, and were a real sequence — 12 and 13
are spent and 14 is deferred, so the sequence is discharged.** 12 went
first because the ontology generation-constraint matrix is drilled there
and cited by 13; that dependency is **discharged**, and 13 now cites
[`fabric-ontology`](../../../skills/fabric/fabric-ontology/SKILL.md)
rather than a brief. 14 answered step 0 *no* on 2026-09-03 and stopped
there — but its carve-out debt was **split off and discharged** the same
day rather than deferred with it. That split is the reusable part: the
debt looked like it belonged to the deferred skill and did not. Excluding
planning models from the audit needs no folder suffix, no glob and no
Plan item, only the documented shape of a planning model, so it was
separable from everything step 1 blocks. A deferred wave is worth reading
for the piece that is not actually gated. Added 2026-09-02 from a semantic-model coverage question.
Three briefs from one question is unusual for this queue and was the
finding rather than the plan: the three sit at different layers — an item
type, a review procedure, and a separate workload that arrived
misidentified — and 14 in particular exists because two links offered as
general modelling guidance turned out to document something else. Splitting
them is the [subject-not-lineage](../README.md) rule applied; they share an
origin and resolve independently.

**Wave 15 ran between 11 and 12 and is spent**, which is the worked
example of why the number says nothing about the position — positions live
in this table, not in the number, for the same reason they do not live in
filenames. It went ahead of 12 because 12–14 is the queue's only real
sequence and three consecutive skill-authoring waves looked like exactly
what a concurrent-session workflow question compounds across. It answered
**no**, and the reason retires that premise too: those three waves author
**platform** skills, which the workflow-only prune already keeps out of
every session's payload, so they were never the contention case they
looked like. Added and closed 2026-09-02.

## One brief is a decision, not an edit

[item-type-skill-fabric-plan.md](item-type-skill-fabric-plan.md)
opens with a recommendation rather than an edit list. Five more are
spent and deleted: `item-type-skill-lakehouse.md`, whose "no" landed
2026-09-01; `item-type-skill-datapipeline.md`, whose "yes" landed
2026-09-02 as the `fabric-data-pipeline` skill;
`item-type-skill-operationsagent.md`, whose "yes" landed the same day as
`fabric-operations-agent`; `item-type-skill-ontology.md`, whose
"yes" landed the same day as `fabric-ontology`; and
`skill-semantic-model-audit.md`, whose "yes" landed 2026-09-02 as
`fabric-semantic-model-audit`. **Four "yes" decisions and one "no" so
far** — the column is not a formality, but it has not
been a rubber stamp either. `/drift-update` treats a
decision-kind brief as something to put back to the user rather than
execute; the same applies here. Landing a
"no" is a real outcome — record the reasoning in the commit that deletes
the brief, or the empty column gets re-opened by whoever notices it next.

Wave 14 is the one that does **not** follow that rule, and **as of
2026-09-03 it has exercised that exception.** Step 0 was answered *no*
and the brief is still on disk — because its "no" is a defer on an
unused preview workload, not a finding that the skill is unwarranted.
That makes **defer** a third outcome this column can produce, alongside
the four "yes" and one "no" above; it is the only one that leaves a
brief behind, so don't read the surviving file as an unanswered
question. Delete it only if the workload is abandoned upstream or ruled
out outright, and record which.

## Before touching any `paths:` glob

Run the static check in
[`../../../tests/skills/fabric-triggers/README.md`](../../../tests/skills/fabric-triggers/README.md),
over `skills/` **and** `claude/rules/`. Every glob bug this queue contains
was found that way and none was findable any other way — the linter checks
glob *syntax*, and all of these are well-formed globs that are wrong about
the world.

## Lifecycle

Unchanged from [../README.md](../README.md): **once the change lands, the
brief is deleted**, and git history is the archive. When you delete one,
strike its row here too — a queue listing a spent brief is worse than no
queue.
