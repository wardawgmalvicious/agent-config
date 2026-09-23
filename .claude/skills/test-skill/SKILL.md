---
name: test-skill
description: "Validate a drafted skill — write its trigger fixtures, update the activation contract table, run the static and real-path activation tests, then behaviourally test it in a cold session against a `--safe-mode` baseline. Reads its inputs from disk — brief or shipped frontmatter — so it runs cold. Encodes the traps that make a broken test look like a broken glob: activation is keyed to the `Read` tool so a Bash `cat` activates nothing, it is a per-session cumulative delta so a silent second match is deduplication not failure, the transcript and the stream-json `commands_changed` record are the only witnesses (`skills-invoked.log` and `--debug-file` cannot see it), and `-SkillGroups` prunes user scope so the workflow-only prune must be restored afterwards. Skills only — rules, subagents and hooks keep the manual procedure in root CLAUDE.md."
when_to_use: "Use when asked to test, validate or verify a skill, to check whether a `paths:` glob fires, after editing a `description`, `when_to_use` or `paths:` glob, or as the follow-on to `/author-skill`."
argument-hint: "[skill-name]"
disable-model-invocation: false
model: inherit  # live here — .claude/skills is Claude Code only; see scripts/lint-frontmatter.py
effort: max
---

# Test a skill

Take a **drafted skill** and end at a validated one: its activation
contract written and passing, its behaviour checked in a cold session,
and the fixtures it ran against provably unmodified.

This is the second half of `/author-skill`, which stops at a linted
draft and writes no fixtures on purpose. The coupling between them is
the **brief on disk**, not session state — so this skill runs cold, in a
fresh session, exactly like `/drift-update`.

It also runs on a skill that shipped long ago and has since been
edited. That case has **no brief** and needs none; step 1 says where
its inputs come from instead.

Repo-relative paths are relative to the agent-config repo
(`C:\Repos\Personal\agent-config`), not the session's cwd.

## What this validates, and what it does not

**Skills only** — the same scope as `author-skill`. Rules get exercised
incidentally, because the activation harness checks `claude/rules/*.md`
alongside skills on the same fixtures, but authoring rule fixtures is
not this skill's job.

Out of scope, with their procedures elsewhere:

| Artifact | Procedure lives in |
| --- | --- |
| Subagents | `tests/agents/security-reviewer/README.md` |
| Enforcement hooks | same, plus the direct unit-test pattern in root `CLAUDE.md` |
| Rules, as authored artifacts | root `CLAUDE.md`, "Validating a change" |

## Phase A — the activation contract

Skip this phase entirely if the skill has **no `paths:` glob**. An
unconditional skill has no activation contract, so there is nothing to
fixture and nothing to assert. Say so and go to Phase B; do not
manufacture a fixture to make the phase look done.

### 1. Read the trigger contract from disk

Three entry paths, and they take their inputs from different files.
Establish which one you are on before reading anything.

**A newly drafted skill, arriving from `/author-skill`:**

```
docs/handoffs/execute/<skill-name>.md
```

Take from it the `paths:` glob, the named trigger queries, and the
scope decisions. **Read it from the file even if you wrote it an hour
ago** — the point of the disk contract is that a fresh session with no
memory of the authoring run behaves identically.

**An existing skill being retested after a `description`, `when_to_use`
or `paths:` edit:** there is no brief, and its absence is not a fault.
Briefs are deleted when spent, so a skill that shipped has none by
design — stopping here would refuse the exact case the description
advertises. Take the three inputs from the artifacts that already own
them:

| Input | Source |
| --- | --- |
| `paths:` glob | the `SKILL.md` itself — always authoritative, brief or no brief |
| scope decisions | the set's `expected_activations.md`, which **is** the committed contract |
| trigger queries | the skill's own `description` and `when_to_use` |

That last row is sound rather than a fallback: `when_to_use` is defined
upstream as "trigger phrases or example requests", so on a skill that
carries one the queries are a first-class frontmatter field, not
something to invent. Where a skill has no `when_to_use`, draw the
queries from the `description` and **say in the report which ones you
derived** — a derived query tests the skill against the trigger surface
it actually ships, which is the point, but the reader needs to know no
brief vouched for it.

**An executed drift brief in `docs/audits/<date>/<source>/`, whose
execution log deferred behavioural confirmation to a fresh session:**
`/drift-update` cannot exercise a skill it just edited, so its log ends
with the deferral and this skill is the follow-on. Inputs come from the
shipped artifacts exactly as in the row above — it is not an
`/author-skill` brief and names no trigger queries — but its *What to
change* section names the one thing the edit added, and **that is the
discriminating claim for Phase B**: the detail only the skill makes.
The brief is a ledger entry and is never deleted (step 10). First run
2026-09-12 on `fabric-semantic-model-ai-instructions` from brief 05.

Such a brief is a **content** edit by construction — Kind says so and
the `paths:` glob is untouched — so the activation stamp stands and
**Phase A needs only its static half**. `skill-status.py` says
`retest-activation` when a glob really moved; trust it over re-running.

The one thing you may never do is invent expectations the skill was
never written to meet. Reading them off the shipped frontmatter is not
that; making them up is.

### 2. Pick the fixture set

The glob decides it:

| Glob targets | Set |
| --- | --- |
| Fabric item folders (`**/*.DataPipeline/**`, `.Notebook`, `.Eventhouse`, …) | `tests/skills/fabric-triggers/` |
| PBIP / report / semantic-model paths | `tests/skills/pbip-triggers/` |

The two sets are **disjoint and jointly exhaustive** over the payload's
conditional skills. Don't restate the count here — it was duplicated
into six files, checked by nothing, and had drifted three different ways
by 2026-09-02, one of them two generations stale. Each set's
`expected_activations.md` owns its own figure; derive the total when you
actually need it:

```powershell
./scripts/test-activation.ps1 -Set fabric -StaticOnly   # then -Set pbip
```

A skill whose glob spans both sets is a design smell — raise it rather
than splitting fixtures across sets.

### 3. Write or extend the fixtures

Add files under that set's `fixtures/` directory, modelled on real
exports. Keep them minimal but structurally faithful: the test asserts
*which globs match*, so a file needs the right path and enough content
to be plausible, not real data.

**Mark any fixture built on an unverified shape.** The fabric set's
README has a dedicated section for these, and a fixture invented from a
guess will happily pass a test that asserts nothing true.

### 4. Update `expected_activations.md`

One row per fixture file, naming the skills that must fire. This is the
**contract**, and the static check compares globs against it in both
directions — a skill that fires and is not listed fails just as loudly
as one listed and not firing.

**A row that reads *(none)* and should now name your skill is the
assertion being changed.** Say that explicitly in the commit message,
because the diff on its own looks like a table edit rather than a
retired negative assertion.

Check whether the set's prose sections still hold too. The fabric set
carries a "Fabric item types with no skill at all" section that names
examples; a new skill can make one of them stale.

### 5. Static check — always, before spending a session

```powershell
./scripts/test-activation.ps1 -Set fabric -StaticOnly
```

No session, no tokens, no deploy. It compares frontmatter globs against
the contract table and exits non-zero on any mismatch. `-Set` is
mandatory and takes `pbip` or `fabric`.

You cannot skip it by accident — the full run executes it first and
refuses to continue past a failure — but run it alone while iterating,
because it is the whole feedback loop for steps 3 and 4.

**Run the rules pass too.** Rules carry `paths:` globs and load on the
same files, so a fixture with no *skill* may still pull a rule. Doing
only the skills pass is how the first version of the fabric set reported
"activates nothing" for files that load `fabric-git-serialization`. The
snippet is in `tests/skills/fabric-triggers/README.md` — same code,
`claude/rules/*.md` instead of `skills/*/*/SKILL.md`, keyed on `p.stem`.

### 6. Real-path test — does the harness agree?

```powershell
./scripts/test-activation.ps1 -Set fabric
```

Deploys to a throwaway probe outside the repo, opens **one** cold
session, has it Read every fixture, asserts the transcript, and tears
down in a `finally`.

**One session covers the whole set** — activation is a per-session
cumulative delta, so 56 fixtures cost one session rather than 56. That
is what makes this affordable enough to actually run.

**Skip this step when the activation stamp is already current.** The
stamp hashes `paths:` alone, so on a retest after a body or
`description` edit `scripts/skill-status.py` still rates activation
current and a cold session would re-prove an unchanged fact; the static
check in step 5 is the whole regression, and the Phase B probe witnesses
activation anyway because a conditional skill is unreachable until a
matching file is Read. First applied 2026-09-12 on
`fabric-semantic-model-ai-instructions` — activation stamped
2026-09-01, static 16/16, no session spent.

The script already refuses the dangerous shapes, so do not re-implement
guards around it: it rejects a `ProbeRoot` inside this repo, refuses
user scope as a deploy target, and will not reuse a directory lacking
its `.activation-probe` marker. Other parameters: `-ProbeRoot`,
`-Model` (default `opus[1m]`), `-KeepProbe` to leave the probe for
inspection.

## Phase B — behaviour

### 7. Deploy the groups — and restore the prune

**This is the one step that can damage the machine.** Everything else
is confined to `tests/` and a throwaway directory; this writes to
`~/.claude/skills`, which serves every session here. Only a platform
skill needs it — `workflow` and `social` are deployed already and
`.claude/skills/` is read in place — so skip to step 8 unless the skill
is **new**, which has no junction until the standing form below runs once.

```powershell
./scripts/link-claude.ps1 -SkillGroups workflow,social,meta,fabric   # or ...,powerbi
```

`-SkillGroups` **prunes** — a group not listed is removed. This
machine's standing state is workflow and social only, so you are
temporarily undoing a deliberate prune and must put it back:

```powershell
./scripts/link-claude.ps1 -SkillGroups workflow,social,meta
ls ~/.claude/skills | Select-String '^(fabric|pbir|pbid)-'   # must return nothing
```

**Never run the script bare.** Omitting `-SkillGroups` deploys every
group and silently undoes the prune — it happened on 2026-08-31, and the
run reported `Linked` 37 times and ended `Done. All links verified.`
There is no output line that reads as wrong. The `ls` above is the only
check that catches it.

**Don't read the exit code as the verdict.** `link-claude.ps1` returns
non-zero whenever any warning fires, and the standing `MCP_DOCKER` drift
on this machine means a wholly successful deploy *and* a successful
restore both exit 1. Read the `Skills N linked ...; M pruned` line and
the `ls` above instead.

### 8. The cold behavioural session

**Cold, always.** Skills hot-reload, but subagents, commands and rules
do not, and accumulated context can mask a co-load failure.

Establish the baseline first:

```bash
claude --safe-mode
```

That starts with the entire payload off — `CLAUDE.md`, skills, hooks,
MCP, commands, agents — and is the control condition that separates
behaviour the payload produces from behaviour the base model produces.
It is a flag you type, never something to wire into `settings.json`.

**A close baseline is not a failed skill.** Where the base model already
knows the domain, `--safe-mode` reproduces most of a good answer, so
"the payload run answered well" measures nothing by itself. Compare a
detail that is a claim **only the skill makes**. Measured 2026-09-04 on
`pbir-filters`: both runs got `SourceRef.Source` and doubled quotes; only
the payload wrote the skill's 20-char hex `name` (baseline: a 32-char GUID).

**`--safe-mode` does not strip the web tools.** A baseline can fetch the
Learn pages a skill was drilled from and re-derive it — a second reason
it comes back close. Add `--disallowedTools WebFetch,WebSearch` **to
both runs**, the payload side too, or a pass cannot separate "the skill
delivered it" from "the model fetched the page the skill cites"; or
compare on synthesis that sits on **no single page**. Measured 2026-09-12
on `fabric-deployment-pipelines` (`references/reading-a-failure.md`).

**Those two flags do not turn the web off on this machine, and the gap
is one-sided.** `microsoft-learn-mcp` is **user scope**, so a payload
probe reaches Learn through it whatever `--disallowedTools` says, while
`--safe-mode` strips MCP with the payload and the baseline cannot —
leaving the very confound the flags were meant to remove. Add
`--strict-mcp-config` to the payload arm (with no `--mcp-config` it
drops every server) and check the `init` record's `tools` count: 29 with
the servers, 22 without, matching the baseline. Measured 2026-09-13:
`fabric-eventstream`'s first payload run blocked both web tools and
still fetched all four drilled Learn pages.

**Prove the baseline actually stripped the payload.** A `--safe-mode`
run that silently kept the skill is indistinguishable from one where the
base model already knew the answer — both read as "the skill adds
nothing". In a `-p` probe the `system`/`init` record names
`slash_commands` and `tools`: assert the skill is absent from it and
that the count dropped. Measured 2026-09-12 on
`fabric-catalog-governance` — 21 commands with the skill absent against
33 with it present — which is what made "the baseline reproduced this
finding unaided" a result rather than a guess.

**Assert on a name only the payload provides.** `code-review` stays
listed under `--safe-mode` because the CLI ships a built-in of that
name, so a grep for it reads as a leaked payload — and when
`code-review` itself is under test, its absence cannot be read off the
list at all; assert its sibling payload names instead (measured
2026-09-13, `references/reading-a-failure.md`).

Then, in a normal session, run the trigger queries from step 1. Test
**both** invocation paths, because they do not behave alike: a `model:`
pin is honoured on `/slash` invocation and silently dropped on
model-invocation, while `effort:` applies on both. Where the skill has
refusal behaviour, exercise the refusal modes as well — a skill that
does the right thing but ignores its own scope guard has failed.
`tests/skills/code-review/README.md` has the four-mode matrix
(slash review, NL review, slash adversarial, NL adversarial) to copy
from.

**Disable write tools when a trigger query names a destructive action.**
A behavioural probe runs with this machine's credentials — an `az login`
survives across tool calls — so "Delete the Marketing domain" or a bulk
label write can reach a real tenant, and the skill's own refusal is the
only thing in the way. Don't rely on it: pass
`--disallowedTools "Bash,PowerShell,Monitor,Agent,Edit,Write,NotebookEdit"`
plus `--strict-mcp-config`. The shell tools are not the only way out —
`Monitor` runs its `command` in Bash's own shell environment, `Agent`
spawns a subagent with its own tools, and the user-scope `MCP_DOCKER`
gateway re-exports `merge_pull_request` and `push_files` — and two
`land` probes run with the shorter list proved the point by declining
to abuse `Monitor` unprompted (`references/reading-a-failure.md`).
Added 2026-09-12, after `fabric-catalog-governance`'s own brief
supplied both of those queries.

**What is measured is what the skill *says*, not whether it can call an
API** — free on a query that asks for an explanation, and a real cost on
one that asks the skill to *act*: it stops at the first command it
cannot issue, and every later step goes unmeasured on that arm. Phrase
one arm as a walkthrough ("the exact commands, start to finish");
`land`, 2026-09-13, is the measurement.

**Give a trigger query enough context to be answerable.** A bare
imperative in an empty probe directory routes to file exploration
rather than to a skill: "Deploy my data pipeline to production." sent
the session hunting for a pipeline on disk and loaded nothing, while
the same sentence framed with a dev workspace reached the skill. The
first measures the harness's file-hunting instinct, not the trigger
surface. Measured 2026-09-12 on `fabric-deployment-pipelines`.

**A conditional skill has neither path until a matching file is Read.**
The `paths:` glob keeps it out of the startup listing, so its
`description` — the whole model-invocation trigger — is never in
context, and `/<name>` answers `Unknown command`. Read a matching file
first; that injects the listing entry and the model can then invoke it.
The four-mode matrix above applies as written only to an
*unconditional* skill. Measured 2026-09-02 on 2.1.252:
`/fabric-data-pipeline` was `Unknown command` while `/fabric-gotchas` —
same session shape, no `paths:` — ran normally.

**Run the behavioural session outside this repo — for a platform
skill.** `.claude/settings.json` here collapses every platform skill
description to `name-only`, and the description *is* the trigger — so
an in-repo run is a guaranteed false negative that looks exactly like a
broken skill. **A project-scope skill must run here**, where the payload
is on disk and root `CLAUDE.md` duplicates it: disallow the file tools
(`Read,Glob,Grep,ToolSearch`) on both arms, then add a third arm with
`Skill` disallowed too — **model-invoked, never slash**, or the
expansion inlines the body straight past the denial and the arm is
inert. `references/reading-a-failure.md`, 2026-09-13.

Confirm the skill actually loaded with `/context` rather than by asking
the session — self-report is unreliable, and once omitted an
unconditional skill that was certainly present.
In a `-p` probe where `/context` is unavailable, use the transcript: a
model-invoked skill appears as a `Skill` tool_use, while a slash-invoked
one is **inlined as a command expansion** and produces no `Skill` call —
so an absent `Skill` record disproves nothing on the slash path.
The positive witness is the pair: run the slash probe on the query the
NL arm answered through a `Skill` call, and a slash run with **no**
`Skill` call that still carries the skill's own detail has proved the
expansion — without it the model would have had to call `Skill` as the
NL run did. Use a query the skill answers itself: on one it delegates,
the only `Skill` call is the delegate's and the run reads as ambiguous.
Measured 2026-09-13 on `fabric-cli` — NL 3 turns with `Skill
fabric-cli`, slash 1 turn with none, the same GUID-vs-friendly-name
table in both; the first slash run, on a section that hands off to
`fabric-deployment-pipelines`, showed only that skill's call.
`--output-format stream-json --verbose` is the cheaper route to those
records — it carries the `tool_use` blocks, the `init` record and, for a
conditional skill, the `commands_changed` record that witnesses the
matching `Read` (`references/reading-a-failure.md`) inline, so nothing
has to locate a session id under `~/.claude/projects/`. Read
the answers rather than grepping them for expected phrases: on
2026-09-12 an `/owns|owned/` scan missed "items you own" and nearly
recorded a passing assertion as a failure.

**Launch a slash probe from PowerShell**, not the Bash tool. MSYS2
rewrites a leading-slash argument to `C:/Program Files/Git/<name>`, so
`claude -p "/my-skill ..."` never reaches the slash path — and the
failure is invisible, because the model reads the mangled text, still
recognises the skill name, and invokes it via the Skill tool. The run
then looks like a passing slash test while measuring model-invocation.
`MSYS2_ARG_CONV_EXCL='*'` works too. Measured 2026-09-02.

### 9. Confirm the fixtures are unmodified

```bash
git status
```

Expect no modifications. Fixtures are read-only by validation contract;
a run that edits its own inputs invalidates every later comparison. If
one changed, revert it and find out which mode did it.

### 10. Stamp, retire the brief, report and hand off

**Stamp the run first**, so the record does not depend on this
session's report ever being read:

```bash
uv run --with pyyaml scripts/skill-status.py --stamp <skill-name> --phase activation,behaviour
```

Name only the phases that ran: an unconditional skill stamps
`behaviour` alone, and the script refuses `activation` for it with the
same reason Phase A was skipped. The stamp hashes what each phase tested
from the **working tree** — which is what this skill ran against — and
`scripts/skill-status.py` derives from it whether a later edit needs a
retest. Nothing else records a test, so a run without a stamp did not
happen as far as the next session can tell.

**The stamp is a working-tree write that another live session's commit
can discard**, staged or not — twice on 2026-09-12, before a re-stamp
chained into `git add` and `git commit` landed. Hand `/commit` the stamp
command to re-run before staging, and again once the tested edit
commits, so `commit` names the commit that holds it (root `CLAUDE.md`,
Branching and concurrent sessions; the re-stamp in the reference).

**Then delete the brief — if it is still there.** An `/author-skill`
brief stays queued in `docs/handoffs/execute/` until this test runs,
and nothing else removes it: on 2026-09-12 a brief whose skill had been
tested and landed that morning was still on disk that afternoon,
reading as "authored, untested". Grep for links to it and re-point them
in the same change. An **edit** brief runs the other way — the queue
retires it in the commit that lands its work, so its absence is correct
and the edited skill carries no "untested" marker on disk at all;
`skill-status.py --stale` is the only thing that says so. `land`,
2026-09-13: `31d2f4f` implemented `land-branch-cleanup.md` and deleted
it in one commit, and the skill went twelve commits unstamped.

**A `docs/audits/` brief is recorded, not deleted.** That directory is
a ledger (`docs/audits/README.md`) — deleting from it loses the entry.
Append a `**Behavioural confirmation**:` bullet to the brief's execution
log naming the date, the probe design, which claim separated from the
baseline, and that the stamp was written; if the brief deferred a
collision or open question, say whether the run made it visible and
leave it deferred. Commit shape: `test(<skill>): …` over the brief and
the manifest.

**An untracked brief is recorded first, then retired.** `/author-skill`
may not have committed it, and deleting it on the spot keeps the
drilling record — above all the table checking each upstream claim
against the docs — out of history entirely, which is the half the
finished skill cannot reconstruct. Hand `/commit` both steps as two
commits, the shape `8fdf2ac` and `7be05e3` gave the fabric-dataflow
brief 49 seconds apart. A brief already tracked is simply deleted.

Report the static result, the real-path result with its counts, which
trigger queries fired and which did not, and anything the `--safe-mode`
baseline already did without the payload. Then hand off to `/commit`,
naming the manifest and the deleted — or, for a ledger brief, the
appended — brief among the paths. Do not commit here.

## Reading a failure

Several different bugs produce the identical symptom "nothing
activated". Work down this table before touching a glob:

| Symptom | Real cause |
| --- | --- |
| Nothing activated, any fixture | The platform skills are not deployed — `~/.claude/skills` carries workflow only |
| Nothing activated, probe looks fine | The probe read with `cat`. Activation is keyed to the **`Read` tool**; Bash `cat` and `Grep` touch the same bytes and activate nothing. This machine defaults to auto mode, which prefers `cat` |
| The second matching file activates nothing | Correct behaviour. Activation is a **cumulative delta** — an attachment names only what was not already active |
| An activation looks one or two reads late | Attachments **flush in batches**; attribute it to the group read since the last flush, not to one file |
| A negative assertion always passes | The skill it is asserting *against* is not deployed. Both groups must deploy for either set |
| The debug log shows nothing | `--debug-file` emits its skill lines before any Read runs, so it can never witness an activation |
| The session answers *well* but the skill never loaded | A conditional skill is absent from the startup listing, so a plain-English query cannot reach it. Better answers were base-model variance — confirm a `Skill` tool_use before believing a pass |
| `/<skill-name>` returns `Unknown command` | Expected for a **conditional** skill cold; it becomes reachable only after a matching file is Read. Unconditional skills slash normally — unless the skill is new and the linker has not run since `/author-skill` wrote it (step 7; `prune-branches` had no junction on 2026-09-14) |
| The baseline scores nearly as high as the payload | It read the payload off disk, or root `CLAUDE.md` carries the same claims. Disallow the file tools on both arms, then ablate with `Skill` disallowed |
| The payload arm changed since the last stamp | Not yet the edit's doing. Run the pre-edit body as `<name>-old` at project scope in the probe directory on the same query; a check-shaped edit ("if X, do Y") also needs the no-X arm |

The witnesses behind that table — the transcript record, the `-p`
`commands_changed` record, which *model* served a turn, and why the
directory is not the variable — are in
[references/reading-a-failure.md](references/reading-a-failure.md).

## Constraints

- **Read the brief from disk.** Never take the skill's globs or trigger
  queries from session context, even when this session drafted them.
- **Static before session.** A failing static check means the globs and
  the contract disagree; a session cannot resolve that and costs tokens
  to say so.
- **Restore the prune** before finishing, and verify it with `ls`. An
  interrupted run that left platform skills linked silently changes what
  every later session on this machine sees.
- **Fixtures are inputs, not outputs.** Do not edit a fixture to make a
  test pass; change the contract table or the glob, and say which.
- **Phase A is skipped, not faked**, for an unconditional skill.
- **No commit**, no push. Hand off to `/commit`.
- **This skill has no Phase A of its own** — it has no `paths:` glob, so
  there is nothing to fixture. `/test-skill test-skill` runs Phase B
  only, and that is correct rather than a gap.
