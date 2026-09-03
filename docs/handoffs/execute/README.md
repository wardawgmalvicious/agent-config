# Open briefs — execution order

Five briefs are open. Thirteen waves are spent (struck through below).
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
deleted **individually** as each is spent, and heavily cross-linked — 43
relative markdown links across the current 6 files, counting this queue
(recounted 2026-09-02 when wave 18 added a brief, by the method kept with
the number: `](` occurrences that are not `http`. The lineage runs 57
across 9 files → 48 across 7 after wave 11 retired two briefs → 44 across
6 after wave 12 retired one → 34 across 5 after wave 13 retired two → 43
across 6 when wave 18 added one; earlier figures of 27 and 41 do not
reproduce under any method tried, so it starts at 57).
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
| **7** | [skill-effectiveness-telemetry.md](skill-effectiveness-telemetry.md) | Scoping only, no dependencies, no deadline. Also the one most likely to be overtaken by upstream shipping something. |
| ~~**8**~~ | ~~*No brief — this row was the whole spec.* Validate the wave 3 frontmatter pass, and decide the `security-reviewer` model~~ | **Done 2026-09-01**, fresh session, Claude Code 2.1.252. **(a)** [`claude/agents/security-reviewer.md`](../../../claude/agents/security-reviewer.md) is now `model: sonnet`. Baseline (`inherit` → `claude-opus-5`) and candidate (`claude-sonnet-5`) each scanned the fixtures from an identical cold memory state, and the caught/not-caught sets were **identical**: 4/4 seeded findings at the expected severities (2 Critical at `config.py:2,3`, 1 High at `queries.py:3`, 1 Low at `notes.md:1`), no false positives, five-field format intact, all four closing-summary components present, memory seeded, and neither run read `expected_findings.md`. Fixtures unmodified after. Mode 3 on sonnet took the **preferred** branch — refused outright, never attempted the `Edit` — so the hook had nothing to block; it was verified separately as a direct unit test over four cases (in-scope write allowed, out-of-scope write blocked with exit 2, a different `agent_type` unaffected, `../` traversal out of the memory dir blocked). Both runs **foreground**. The **frontmatter** pin — which those two runs could not exercise, since sonnet was forced by an Agent-tool override and a subagent is not hot-reloaded into the session that edits it — was confirmed separately the same day from a fresh session (`83089e9f`, started 25 minutes after the pin landed): an un-overridden spawn ran `claude-sonnet-5` while its parent session sat on Opus. **Wave 8(a) is fully closed.** **(b)** ~~Confirm `/commit` picks up its pins.~~ **Closed** — `e3cae240` shows three `commit` runs at `claude-sonnet-5 xhigh`, each bracketed by `claude-opus-5 high`, so both pins fire at the *current* values and turn-scoping holds. **(c)** **Confirmed** — a plain-English request does auto-trigger `commit`; see the invocation-path finding below, which is how it was measured. |
| ~~**9**~~ | ~~`activation-cleanroom-null.md`~~ | **Done 2026-09-01.** The clean room was never the variable — **the `Read` tool is**. Activation is keyed to file access through `Read`; a Bash `cat` or a `Grep` over the same file activates nothing, and this machine defaults every session to auto mode, which prefers `cat`. Measured as a 2x2 (Read/`cat` x in-repo/scratch): `Read` activated the same 3 skills and loaded the same rule in **both** directories, `cat` in **neither**. The original report's correlation was luck — all 8 clean-room probes chose `cat`, both in-repo controls chose `Read`; re-reading those transcripts confirms it retroactively. Every directory hypothesis is ruled out by its own probe: git repo, `AppData/Local/Temp`, missing `.claude/settings.json`, 8.3 short path, and fixture depth. Negative control clean. Written into root [`CLAUDE.md`](../../../CLAUDE.md) and both trigger READMEs. **Wave 10 is unblocked** — it may run anywhere, and must pin `--allowedTools Read --disallowedTools Bash …` and fail on a non-`Read` tool call. |
| ~~**10**~~ | ~~`activation-test-harness.md`~~ | **Done 2026-09-02.** [`scripts/test-activation.ps1`](../../../scripts/test-activation.ps1) runs the real-path test for a named set in one command — static check, deploy to a throwaway probe outside the repo, one cold session, transcript assertion, teardown in a `finally`. Expectations come from [`scripts/activation-expect.py`](../../../scripts/activation-expect.py). **Both sets PASS**: pbip 16/16, fabric 57/57, skills *and* rules. See the finding below for the open question it answered. |
| ~~**11**~~ | ~~`item-type-skill-operationsagent.md` → `fabric-operations-agent.md`~~ | **Done 2026-09-02.** The decision was **yes** — [`skills/fabric/fabric-operations-agent/`](../../../skills/fabric/fabric-operations-agent/SKILL.md) exists with a `references/` split, and the free side-fix landed too (`**/*.OperationsAgent/**` added to `fabric-git-serialization.md`). Validated the same day — fixtures, the two `expected_activations.md` rows, `test-activation.ps1 -Set fabric` (59/59, re-confirmed at close) and the cold behaviour run against a `--safe-mode` baseline. Both briefs are now deleted per the [lifecycle](#lifecycle), the decision brief's three inbound references re-pointed in the same commit. Two of the source brief's findings were **overturned** rather than executed, and both survive the deletion in live artifacts rather than in the brief: its step 3b portability conclusion is inverted in [SKILL.md §4](../../../skills/fabric/fabric-operations-agent/SKILL.md) (`dataSource.id` is the source `logicalId` verbatim; `jobArtifactId` is the target's byte-reversed, and the asymmetry is a schema fact rather than a portability one), and its two-ID-families hypothesis became wave 16. |
| ~~**12**~~ | ~~`item-type-skill-ontology.md`~~ | **Done 2026-09-02.** The decision was **yes** — [`skills/fabric/fabric-ontology/`](../../../skills/fabric/fabric-ontology/SKILL.md) exists with a `references/` split, and the free side-fix landed (`**/*.Ontology/**` added to `fabric-git-serialization.md`). **Step 1 resolved without a workspace, and that is the reusable part**: the REST [Ontology definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/ontology-definition) page states the suffix outright — its definition example's base64 `.platform` payload decodes to `"type": "Ontology"` — and settles the whole `definition/` layout in the same fetch, which the brief had called unguessable. No guess was committed. Wave 14's step 1 is re-pointed at that method. The skill's highest-value content came from pages the brief had **not** drilled: `how-to-bind-data` yielded one static binding per entity type but many time-series, static-before-time-series ordering, entity keys string/integer only, no OneLake security, and the source-type map in which lakehouse `decimal` binds to `double` while `decimal(p, s)` binds to **string**; `resources-troubleshooting` yielded the documented remedy for the `Decimal` null trap (recreate as `Double`, bind manually) that the brief recorded only as a dead end. The payload inconsistency is closed — `fabric-data-agent` now points at the new skill. Validated: static 64/64, `test-activation.ps1 -Set fabric` **PASS 64/64 skills and rules**, and a cold behaviour run against a `--safe-mode` baseline where the baseline answered **"Yes"** to binding two static tables to one entity type (wrong), invented the cause of missing Direct Lake bindings, and prescribed a CAST-view fix for the `Decimal` trap. Registered a `fabric-iq-ontology` drift source. Brief deleted; three inbound references re-pointed in the same commit. |
| ~~**13**~~ | ~~`skill-semantic-model-audit.md`~~ | **Done 2026-09-02.** The decision was **yes** — [`skills/fabric/fabric-semantic-model-audit/`](../../../skills/fabric/fabric-semantic-model-audit/SKILL.md) exists with a `references/` split, **unconditional on purpose**: a `**/*.SemanticModel/**` glob would co-load a whole audit procedure onto every one-line measure edit. Design and performance stayed one skill, but the fusion argument **narrowed** — "inactive relationships are also expanded" is import-mode guidance, while Direct Lake builds join indexes at query time and is silent on inactive ones, so the skill states that rather than generalising. The reference model was re-measured and **overturned this brief's own acceptance test**: `DimDate` is *not* a role-playing dimension — its four inbound relationships come from three different fact tables — and the real one is `Customer`. Counting is per (fact, dimension) pair, and that became the skill's headline false-positive guard. Sharper still: 6 of the 7 inactive relationships have no `USERELATIONSHIP` that can reach them. Validated in cold sessions against a `--safe-mode` baseline — 4/4 criteria met, and the baseline scored **zero** on "both-sides", "role-play", "snowflake", "unreachable" and "star schema", clearing the `DimDate` criterion only by never asking the question. That bounds the claim: the skill buys structural discipline, not defect-finding. The `scripts/data/*.sh` citation idiom is settled (conditional accelerator, never a dependency). Both briefs deleted; five inbound references re-pointed in the same commit. **The MCP spin-off became wave 17.** |
| **14** | [item-type-skill-fabric-plan.md](item-type-skill-fabric-plan.md) | **Gated, not scheduled.** Fabric IQ Plan is a Git-supported item with genuinely unguessable content (its automatic time-intelligence parser silently drops `Sept`, `WK1`, `Q5`). But nothing here uses Plan and no payload inconsistency pushes on it, so step 0 asks whether the workload is in play before anything else runs. A "no" is a defer that **keeps** the brief rather than deleting it — the one exception to the lifecycle below. If it does proceed, it must land a carve-out in wave 13, or the audit will report a correct planning model as a defective reporting one. |
| ~~**15**~~ | ~~`concurrent-session-workflow.md`~~ | **Done 2026-09-02 — the answer is no.** Branching stays the exception and committing straight to `main` stays the default. The premise re-confirmed mechanically: one working tree has one HEAD, so two sessions in it share every file regardless of branch, and git refuses the same branch in two worktrees. Worktrees were then **measured**, in a real one probed cold, and root [`CLAUDE.md`](../../../CLAUDE.md) had named the wrong blocker — `link-claude.ps1` takes `$RepoRoot` from `$PSScriptRoot`, so the worktree's own copy deploys the worktree's skills and a session there loads them, conditional activation included. The real blocker is **scope precedence**: with `drift-handoff` at both scopes and a marker in only the worktree's copy, the listing carried the **user-scope** text. Project scope only adds names user scope lacks — so a worktree is **unnecessary** for a platform skill (pruned from user scope, so authoring one changes no session's payload) and **ineffective** for a workflow skill (at user scope, unoverridable), with no case in between. The downstream **PR-skill question resolves no** as well, on new grounds: the base-rate argument was bad and stays bad, but the flow is three commands plus "open the PR with `github-mcp`, not `gh`", both already in root `CLAUDE.md`, which auto-loads here — a skill would spend permanent listing budget on text already in context. **Reconsider if** a second silent collision between concurrent sessions happens anyway. Brief deleted; `CLAUDE.md`'s worktree section rewritten with the measurements.. **The PR-skill half was reversed the same day — see wave 18.** The worktree and branching findings stand; only the "no" on a PR skill was overturned, on the measurement rather than the principle: the flow is ~10 operations with two silent-failure modes, not the three commands assumed here. |
| **16** | [logicalid-runtime-id-encoding.md](logicalid-runtime-id-encoding.md) | **Gated on a credential, not on a wave.** Fell out of wave 11: a `.platform` `logicalId` appears to be a runtime item ID with its 16 bytes reversed — 33 of 35 in one repo reverse to valid RFC-4122 v4, and one item's cross-reference matched exactly. Confirming needs one read-only `GET /v1/workspaces/{ws}/items`, and no `az login` existed during wave 11. Run it in **any** session that has one — it blocks nothing and nothing blocks it. Its step 2 half, reversing public Git-synced exports offline, needs no credential at all and can go first. Touches `fabric-gotchas`, `fabric-rest-api` and `fabric-operations-agent` §4, which today states the relationship and declines the inference. |
| **17** | *No brief — this row is the whole spec.* A **Power BI MCP template** for `claude/mcp/` | Fell out of wave 13, which scoped it out deliberately: different artifact, directory and deployment path. Two servers exist — [`powerbi-modeling-mcp`](https://github.com/microsoft/powerbi-modeling-mcp) (local, VS Code) and a remote one, both documented under `power-bi/developer/mcp/`. The data-agent guidance recommends the local one for bulk renaming of non-descriptive objects under LLM review — which is exactly a [`fabric-semantic-model-audit`](../../../skills/fabric/fabric-semantic-model-audit/SKILL.md) finding (check 13) with no remediation path in the payload today. This repo already ships templates in Claude's `mcpServers` schema, so the work is a template plus a `claude/mcp/README.md` row, **not a skill**. If it lands, the audit skill gains one conditional sentence pointing at it, exactly like the `dax.sh` idiom. Blocks nothing and is blocked by nothing. Registered 2026-09-02 when wave 13's briefs were deleted. |
| **18** | [land.md](land.md) | **Reverses wave 15's PR-skill "no"**, deliberately and with that decision quoted. Wave 15 priced the flow at "three commands plus open the PR with `github-mcp`, not `gh`"; landing PR #7 measured it at ~10 operations with two failure modes that produce no error. The **identity** one fired live — `gh` holds a work account here while `github-mcp` holds the personal one that owns the repo, and `CLAUDE.md` can state the rule but cannot make the comparison happen. The **integration** one is that a squash or a merge-button click silently discards what `/commit` just built. Plus the PR body, which is judgement work the payload covered nowhere. `skills/workflow/land/` is drafted, linted at 683 chars and deployed (9 workflow junctions). **Open until a cold `/test-skill land` runs** — it was dogfooded on its own landing, which tests the procedure but not the trigger, and not cold. Registered 2026-09-02. |

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
late only because it was expensive. Of what remains, **7, 16, 17 and 18 block
nothing and are blocked by nothing** — take whichever fits the session
you have. 16 is the cheaper of the two and is gated only on a credential,
so it fits a session that already has an `az login` and no appetite for
authoring.

**Waves 12–14 were the exception, and were a real sequence — 12 and 13
are now spent, leaving only 14.** 12 went first because the ontology
generation-constraint matrix is drilled there and cited by 13; that
dependency is **discharged**, and 13 now cites
[`fabric-ontology`](../../../skills/fabric/fabric-ontology/SKILL.md)
rather than a brief. 14 stays gated on its own step 0 and, if it
proceeds, **still owes the carve-out** — now to a shipped skill rather
than a brief, which makes the debt concrete: the audit exists to be
wrong about a planning model. Added 2026-09-02 from a
semantic-model coverage question.
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

Wave 14 is the one that does **not** follow that rule. Its "no" is a
defer on an unused preview workload, not a finding that the skill is
unwarranted, so the brief stays on disk with the step 0 answer and its
date recorded in the queue row. Delete it only if the workload is
abandoned upstream or ruled out outright, and record which.

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
