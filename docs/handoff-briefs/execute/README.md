# Open briefs — execution order

Four briefs are open. Eight waves are spent (struck through below). Where
a spent wave had a brief, that brief is deleted, so those struck rows name
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
deleted **individually** as each is spent, and heavily cross-linked — 12
links across the current 5 files, counting this queue. Numbering the
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
| **5** | [item-type-skill-datapipeline.md](item-type-skill-datapipeline.md) | The only "yes, author it" in the queue, and the largest single chunk of work. Nothing blocks it — it is late because it is expensive, not because it is stuck. Do it earlier if the pipeline surface is what you are actually working on. |
| ~~**6**~~ | ~~`rule-glob-gaps.md` — bug 3~~ | **Done 2026-08-31.** `**/*.GraphModel/**` added to `fabric-git-serialization.md`, with `**/*.UserDataFunction/**` and `**/*.ApacheAirflowJob/**` from a partial item-type diff. `Dataflow` confirmed correct. |
| **7** | [skill-effectiveness-telemetry.md](skill-effectiveness-telemetry.md) | Scoping only, no dependencies, no deadline. Also the one most likely to be overtaken by upstream shipping something. |
| ~~**8**~~ | ~~*No brief — this row was the whole spec.* Validate the wave 3 frontmatter pass, and decide the `security-reviewer` model~~ | **Done 2026-09-01**, fresh session, Claude Code 2.1.252. **(a)** [`claude/agents/security-reviewer.md`](../../../claude/agents/security-reviewer.md) is now `model: sonnet`. Baseline (`inherit` → `claude-opus-5`) and candidate (`claude-sonnet-5`) each scanned the fixtures from an identical cold memory state, and the caught/not-caught sets were **identical**: 4/4 seeded findings at the expected severities (2 Critical at `config.py:2,3`, 1 High at `queries.py:3`, 1 Low at `notes.md:1`), no false positives, five-field format intact, all four closing-summary components present, memory seeded, and neither run read `expected_findings.md`. Fixtures unmodified after. Mode 3 on sonnet took the **preferred** branch — refused outright, never attempted the `Edit` — so the hook had nothing to block; it was verified separately as a direct unit test over four cases (in-scope write allowed, out-of-scope write blocked with exit 2, a different `agent_type` unaffected, `../` traversal out of the memory dir blocked). Both runs **foreground**. The **frontmatter** pin — which those two runs could not exercise, since sonnet was forced by an Agent-tool override and a subagent is not hot-reloaded into the session that edits it — was confirmed separately the same day from a fresh session (`83089e9f`, started 25 minutes after the pin landed): an un-overridden spawn ran `claude-sonnet-5` while its parent session sat on Opus. **Wave 8(a) is fully closed.** **(b)** ~~Confirm `/commit` picks up its pins.~~ **Closed** — `e3cae240` shows three `commit` runs at `claude-sonnet-5 xhigh`, each bracketed by `claude-opus-5 high`, so both pins fire at the *current* values and turn-scoping holds. **(c)** **Confirmed** — a plain-English request does auto-trigger `commit`; see the invocation-path finding below, which is how it was measured. |
| ~~**9**~~ | ~~`activation-cleanroom-null.md`~~ | **Done 2026-09-01.** The clean room was never the variable — **the `Read` tool is**. Activation is keyed to file access through `Read`; a Bash `cat` or a `Grep` over the same file activates nothing, and this machine defaults every session to auto mode, which prefers `cat`. Measured as a 2x2 (Read/`cat` x in-repo/scratch): `Read` activated the same 3 skills and loaded the same rule in **both** directories, `cat` in **neither**. The original report's correlation was luck — all 8 clean-room probes chose `cat`, both in-repo controls chose `Read`; re-reading those transcripts confirms it retroactively. Every directory hypothesis is ruled out by its own probe: git repo, `AppData/Local/Temp`, missing `.claude/settings.json`, 8.3 short path, and fixture depth. Negative control clean. Written into root [`CLAUDE.md`](../../../CLAUDE.md) and both trigger READMEs. **Wave 10 is unblocked** — it may run anywhere, and must pin `--allowedTools Read --disallowedTools Bash …` and fail on a non-`Read` tool call. |
| ~~**10**~~ | ~~`activation-test-harness.md`~~ | **Done 2026-09-02.** [`scripts/test-activation.ps1`](../../../scripts/test-activation.ps1) runs the real-path test for a named set in one command — static check, deploy to a throwaway probe outside the repo, one cold session, transcript assertion, teardown in a `finally`. Expectations come from [`scripts/activation_expect.py`](../../../scripts/activation_expect.py). **Both sets PASS**: pbip 16/16, fabric 56/56, skills *and* rules. See the finding below for the open question it answered. |
| **11** | [item-type-skill-operationsagent.md](item-type-skill-operationsagent.md) | The second "yes, author it", and much cheaper than wave 5 — the definition file is 2 KB with a live schema, and the overlap check is short because nothing else globs `**/*.OperationsAgent/**`. Independent of everything above. Carries a free side-fix (a `fabric-git-serialization.md` glob gap, same shape as wave 6) that should land even if the skill decision goes the other way. |

`skill-context-cost.md` is **retired as of 2026-09-01** — A, B, D's policy
half and E all landed, and C was declined, so nothing in it remained open.
Per the [lifecycle](#lifecycle) the file is deleted and git history is the
archive; the queue rows above carry the outcomes. Recover it with
`git log --diff-filter=D -- 'docs/handoff-briefs/execute/skill-context-cost.md'`
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
rather than 19/25, and **C** was declined, so no conditional skill is
renamed or merged out of existence. The `pbir-*` trio survives intact —
which *sharpens* the brief rather than shrinking it, since three
permanently co-firing conditional skills are exactly where `when_to_use`
disambiguation earns its keep, and the field is near-free on conditional
skills.

Cost still shapes the other half: adding the field to all 20 unconditional
skills would put ~3,800 tokens onto a listing already sitting at ~9,900
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
session model. And a `model:` pin on any of the 37 platform skills would be
inert by construction, since those trigger by description and never by
slash. All 37 are `model: inherit` today, so nothing is broken — but a
future pin there would do nothing, silently.

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

**Waves are not a priority order past this point.** 9 and 10 are both
spent; 5 is the biggest single piece of work in the queue and is late only
because it is expensive. Nothing in the queue now blocks anything else —
take whichever fits the session you have.

## Two briefs are decisions, not edits

[item-type-skill-datapipeline.md](item-type-skill-datapipeline.md) and
[item-type-skill-operationsagent.md](item-type-skill-operationsagent.md)
both open with a recommendation rather than an edit list. A third,
`item-type-skill-lakehouse.md`, is spent — the "no" landed on 2026-09-01
and the brief is deleted. `/drift-update` treats a decision-kind brief as
something to put back to the user rather than execute; the same applies
here. Landing a
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
