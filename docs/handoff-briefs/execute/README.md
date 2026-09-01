# Open briefs — execution order

Five briefs are open. Five waves are spent (struck through below). Where a
spent wave had a brief, that brief is deleted, so those struck rows name
files that no longer exist — git history is the archive. Wave 8 never had
one; its row was always the whole spec. This file is the **only** place the
order lives; each brief carries its own dependencies but not its position.

## Why these are not numbered like drift briefs

`/drift-handoff` numbers its output `01-`, `02-`, … and `/drift-update`
walks that order. That works there because a
`docs/drift-audit/<date>/<source-id>/` directory is a **disposable whole**:
gitignored, executed in one pass, discarded together, and its briefs do not
cite each other.

`execute/` is the opposite on all three counts. Briefs here are committed,
deleted **individually** as each is spent, and heavily cross-linked — 8
links between the current 5 files. Numbering the filenames would mean
rewriting those 16 links now, and again on every deletion, choosing each
time between renumber-and-relink churn or a queue that reads `01, 04, 06,
08`. The filename is the link target, so it has to be the stable thing.

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
| **4** | [skill-context-cost.md](skill-context-cost.md) workstreams C + E, folding in [item-type-skill-lakehouse.md](item-type-skill-lakehouse.md) | The big pass. Lakehouse **is** an E row — its recommended fix is a `paths:` glob on `fabric-variable-library` — so run them together or E gets made twice. E's `paths:` candidates must be measured against confirmed item-type names — see the sources pinned in `tests/skills/fabric-triggers/README.md`, and add the fixture in the same commit as the glob. |
| **5** | [item-type-skill-datapipeline.md](item-type-skill-datapipeline.md) | The only "yes, author it" in the queue, and the largest single chunk of work. Nothing blocks it — it is late because it is expensive, not because it is stuck. Do it earlier if the pipeline surface is what you are actually working on. |
| ~~**6**~~ | ~~`rule-glob-gaps.md` — bug 3~~ | **Done 2026-08-31.** `**/*.GraphModel/**` added to `fabric-git-serialization.md`, with `**/*.UserDataFunction/**` and `**/*.ApacheAirflowJob/**` from a partial item-type diff. `Dataflow` confirmed correct. |
| **7** | [skill-effectiveness-telemetry.md](skill-effectiveness-telemetry.md) | Scoping only, no dependencies, no deadline. Also the one most likely to be overtaken by upstream shipping something. |
| ~~**8**~~ | ~~*No brief — this row was the whole spec.* Validate the wave 3 frontmatter pass, and decide the `security-reviewer` model~~ | **Done 2026-09-01**, fresh session, Claude Code 2.1.252. **(a)** [`claude/agents/security-reviewer.md`](../../../claude/agents/security-reviewer.md) is now `model: sonnet`. Baseline (`inherit` → `claude-opus-5`) and candidate (`claude-sonnet-5`) each scanned the fixtures from an identical cold memory state, and the caught/not-caught sets were **identical**: 4/4 seeded findings at the expected severities (2 Critical at `config.py:2,3`, 1 High at `queries.py:3`, 1 Low at `notes.md:1`), no false positives, five-field format intact, all four closing-summary components present, memory seeded, and neither run read `expected_findings.md`. Fixtures unmodified after. Mode 3 on sonnet took the **preferred** branch — refused outright, never attempted the `Edit` — so the hook had nothing to block; it was verified separately as a direct unit test over four cases (in-scope write allowed, out-of-scope write blocked with exit 2, a different `agent_type` unaffected, `../` traversal out of the memory dir blocked). Both runs **foreground**. *Unverified sliver:* sonnet was forced via the Agent tool's `model` override, because the **frontmatter** pin cannot be exercised in the session that writes it — subagents are not hot-reloaded. One fresh-session run closes it; read the model off the run's own transcript (see below). **(b)** ~~Confirm `/commit` picks up its pins.~~ **Closed** — `e3cae240` shows three `commit` runs at `claude-sonnet-5 xhigh`, each bracketed by `claude-opus-5 high`, so both pins fire at the *current* values and turn-scoping holds. **(c)** **Confirmed** — a plain-English request does auto-trigger `commit`; see the invocation-path finding below, which is how it was measured. |

[skill-context-cost.md](skill-context-cost.md) workstream **D**
(`when_to_use`) is **half done as of 2026-09-01.** The policy half landed:
split **A** — `description` ≤ 1,024, `when_to_use` ≤ 512, enforced separately
in `scripts/lint-frontmatter.py`, with root `CLAUDE.md`, the handoff
template and `author-skill` reworded to match. All 44 skills passed the
tightened gate unchanged. The premise the cost model rested on was drilled
and holds: `when_to_use` really is appended to `description` in the listing
and shares its 1,536 truncation point.

The adoption half — which skills get the field, and what each says — is now
its own brief, [when-to-use-adoption.md](when-to-use-adoption.md), and **it
runs after wave 4 in full.** Both of wave 4's workstreams churn the corpus it
would edit: **C** merges or renames conditional skills (the `pbir-*` trio is
a C2 candidate, and it is precisely where `when_to_use` disambiguation looks
most valuable), and **E** can give an unconditional skill a `paths:` glob,
moving it from the expensive column to the free one. Running adoption first
means writing text for skills that wave 4 renames, merges, or deletes.

Cost is the other half of why: adding the field to all 25 unconditional
skills would put ~4,700 tokens onto a listing already sitting at ~9,900
against a ~10,000-token budget, so that half is net-neutral-or-nothing
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

**Two readings remain, and the evidence does not yet separate them.**
**(A)** `model:` is only honoured on explicit slash invocation. **(B)** those
two sessions had a session model explicitly pinned via `/model`, which
outranks a skill's. Both fit all five rows.

The test is nearly free: from a session with **no** explicit `/model`
override, make a plain-English commit request and read the model off the
run. `claude-sonnet-5` means (B); `claude-opus-5` means (A).

Worth settling rather than leaving, because it is not really about
`commit`. Root [`CLAUDE.md`](../../../CLAUDE.md) states the `model:` pin is
turn-scoped without qualifying the invocation path, all 37 platform skills
are model-invoked **by design**, and a subagent is never slash-invoked at
all — so under reading (A) the `model: sonnet` just pinned on
`security-reviewer` would be inert, and the skill-invocation section of root
`CLAUDE.md` needs a caveat. Under (B) both stand as written. Do not amend
`CLAUDE.md` until one run decides it.

Method note, since wave 8 needed it and the fixture README assumes it:
**a subagent's transcript is its own file**, at
`~/.claude/projects/<project>/<session-id>/subagents/agent-<agentId>.jsonl`
— *not* an `isSidechain` record inside the parent session transcript, where
looking for it turns up nothing.

## What this order is optimising for

**Bugs before improvements.** Wave 1 was the only thing in the queue
producing wrong behaviour; it landed 2026-08-31, so what remains is all
improvement and judgement work.

**Paired decisions in one sitting.** Waves 2 and 4 each merge briefs that
would otherwise make the same call twice — the failure mode that forced
the 2026-08-31 consolidation of four briefs into two.

**Cheap and independent before expensive.** Wave 3 ran before 4 and 5 and
is done; wave 8 was what it left behind, and is now spent too.

## Two briefs are decisions, not edits

[item-type-skill-lakehouse.md](item-type-skill-lakehouse.md) and
[item-type-skill-datapipeline.md](item-type-skill-datapipeline.md) each
open with a recommendation, and one of them recommends **not** building the
thing. `/drift-update` treats a decision-kind brief as something to put
back to the user rather than execute; the same applies here. Landing a
"no" is a real outcome — record the reasoning in the commit that deletes
the brief, or the empty column gets re-opened by whoever notices it next.

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
