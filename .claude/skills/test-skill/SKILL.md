---
name: test-skill
description: "Validate a drafted skill — write its trigger fixtures, update the activation contract table, run the static and real-path activation tests, then behaviourally test it in a cold session against a `--safe-mode` baseline. Reads its inputs from disk — brief or shipped frontmatter — so it runs cold. Encodes the traps that make a broken test look like a broken glob: activation is keyed to the `Read` tool so a Bash `cat` activates nothing, it is a per-session cumulative delta so a silent second match is deduplication not failure, the transcript and the stream-json `commands_changed` record are the only witnesses (`skills-invoked.log` and `--debug-file` cannot see it), and `-SkillGroups` prunes user scope so the standing prune must be restored afterwards. Skills only — rules, subagents and hooks keep the manual procedure in root CLAUDE.md."
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

**Pin a fixture whose bytes are part of its shape.** This repo's
`.gitattributes` commits a CRLF fixture as LF, warning only at
`git add`, and `git status` reads clean after. Give the folder `-text`
in the fixture's own commit, as `SampleESS.EventSchemaSet` has. Before
staging, `git hash-object --path=<f> <f>` and its `--no-filters` form
must match; after, `git ls-files --eol <f>` reads `i/crlf` (2026-10-01).

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

### 7. Load a platform skill in the probe — never in user scope

A platform skill needs this step. So does a **new** skill in `workflow`,
`social` or `meta`, which has no junction until the standing form runs
once, `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`,
never bare (root `CLAUDE.md`, Commands); the rest of those groups is
deployed already, and `.claude/skills/` is read in place.
**In a linked worktree, stop instead** for a skill in those three groups:
step 8 would test the main checkout's copy, silently. Land it first.

Copy the skill's whole group into the payload probe's **project scope**,
outside this repo; give the baseline a sibling with no `.claude/`, since
`--safe-mode` stops a skill loading, not a `Read` of its file.

```powershell
$probe = '<a scratch directory outside this repo>'
New-Item -ItemType Directory "$probe/payload/.claude/skills", "$probe/baseline" | Out-Null
Get-ChildItem skills/fabric -Directory | ForEach-Object {   # or skills/powerbi
    Copy-Item $_.FullName "$probe/payload/.claude/skills" -Recurse }
```

User scope serves every live session and this touches none; copies make
teardown a plain delete, with no junction to follow back into this repo.
Re-copy after an edit. Measured 2026-10-01 on `fabric-event-schema-set`:
`init` listed the group's 11 unconditional skills, a matching `Read`
brought the new one in, then `Skill`. The user-scope deploy this step
used to make is in `references/reading-a-failure.md`.

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
Read the baseline before naming the claim that separates: the sharpest
one on paper is often one the baseline volunteers (`land`, 2026-09-17).

**`--safe-mode` does not strip the web tools.** A baseline can fetch the
Learn pages a skill was drilled from and re-derive it — a second reason
it comes back close. Add `--disallowedTools WebFetch,WebSearch` **to
both runs**, the payload side too, or a pass cannot separate "the skill
delivered it" from "the model fetched the page the skill cites"; or
compare on synthesis that sits on **no single page** (2026-09-12).

**Those two flags do not turn the web off on this machine, and the gap
is one-sided.** `microsoft-learn-mcp` is **user scope**, so a payload
probe reaches Learn through it whatever `--disallowedTools` says, while
`--safe-mode` strips MCP with the payload and the baseline cannot —
leaving the very confound the flags were meant to remove. Add
`--strict-mcp-config` to the payload arm (with no `--mcp-config` it
drops every server) and check that the `init` record's `tools` count
matches the baseline's (`fabric-eventstream`, 2026-09-13).

**Prove the baseline actually stripped the payload.** A `--safe-mode`
run that silently kept the skill is indistinguishable from one where the
base model already knew the answer — both read as "the skill adds
nothing". In a `-p` probe the `system`/`init` record names
`slash_commands` and `tools`: assert the skill is absent from it and
that the count dropped (`fabric-catalog-governance`, 2026-09-12).

**Assert on a name only the payload provides.** `code-review` stays
listed under `--safe-mode` because the CLI ships a built-in of that
name, so a grep for it reads as a leaked payload — and when
`code-review` itself is under test, its absence cannot be read off the
list at all; assert its sibling payload names instead (measured
2026-09-13, `references/reading-a-failure.md`).

Then, in a normal session, run the trigger queries from step 1, and
**scope the arms to what the edit touched**: an arm tests only what its
invocation path reads. A `description` or `when_to_use` edit wants a
model-invoked trigger query and its `Skill` call, which a slash arm
never reads; a body edit, a query that reaches the edited section, plus
the slash arm if `model:` pins a model, which model-invocation drops; a
`model:` edit, the slash arm; a first test or a `name:` edit, both
paths. Exercise the refusal modes too — ignoring its own scope guard is
a fail; `tests/skills/code-review/README.md` has the four-mode matrix.

**Allowlist the tools when a trigger query names a destructive action.**
A behavioural probe runs with this machine's credentials — an `az login`
survives across tool calls — so "Delete the Marketing domain" or a bulk
label write can reach a real tenant, and the skill's own refusal is the
only thing in the way. Don't rely on it: pass `--tools Skill`, plus
`Read` where a conditional skill needs its matching file, and
`--strict-mcp-config`, since `--tools` governs only built-in tools. A
deny list goes stale as the CLI adds tools: on 2.1.282 the one this
step used to give left `Workflow`, `EnterWorktree`, `CronCreate` and
`RemoteTrigger` (`references/reading-a-failure.md`, 2026-09-29).

**What is measured is what the skill *says*, not whether it can call an
API** — free on a query that asks for an explanation, and a real cost on
one that asks the skill to *act*: it stops at the first command it
cannot issue, and every later step goes unmeasured on that arm. Phrase
one arm as a walkthrough ("the exact commands, start to finish");
`land`, 2026-09-13, is the measurement. A step that decides on a
command's output needs it run: `Bash`, writes denied by rule, `auto`
mode, never `dontAsk` (`references/reading-a-failure.md`, 2026-10-01).

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
The slash arm needs that Read **in its own process**: send it, then
`/<name>`, as two messages to one `--input-format stream-json` print
session. A `--resume` still answered `Unknown command` (`fabric-dataflow`,
2026-09-12); one process expanded it (2026-10-01, in the reference).
The four-mode matrix above applies as written only to an
*unconditional* skill (`fabric-data-pipeline`, 2026-09-02).

**Run the behavioural session outside this repo — for a platform
skill.** `.claude/settings.json` here collapses every platform skill
description to `name-only`, and the description *is* the trigger — so
an in-repo run is a guaranteed false negative that looks exactly like a
broken skill. **A project-scope skill must run here**, where the payload
is on disk and root `CLAUDE.md` may repeat it: give both arms
`--tools Skill`, so neither can read the payload off disk, then add a
third arm with `--tools CronList` — **model-invoked, never slash**, or
the expansion inlines the body straight past the denial and the arm is
inert. Never `--tools ""`: with no tool declared, the model writes its
calls as text and invents their results; one read-only tool avoids it.
`references/reading-a-failure.md`, 2026-09-13 and 2026-09-29.

**Parallel arms read each other as peers**, and only payload arms look:
keep `ListAgents` and `SendMessage` out of every arm, as `--tools` does
by construction. A skill that reads peers itself (`commit`, `land`,
`triage`) keeps `ListAgents`, and its arms launch one at a time (2026-09-29).

**Never stop an arm for silence alone.** At max effort an arm streams
only `thinking_tokens` until its first block closes, most of a 17-minute
baseline run: pace it against the baseline, never the payload arm, and
bound spend at launch with `--max-budget-usd` instead (2026-09-29).

Confirm the skill actually loaded with `/context` rather than by asking
the session — self-report is unreliable, and once omitted an
unconditional skill that was certainly present.
In a `-p` probe where `/context` is unavailable, use the transcript: a
model-invoked skill appears as a `Skill` tool_use, while a slash-invoked
one is **inlined as a command expansion** and produces no `Skill` call —
so an absent `Skill` record disproves nothing on the slash path.
The positive witness is a slash run on a query the NL arm answered
itself through `Skill`: carrying the skill's detail with **no** `Skill`
call proves the expansion (`references/reading-a-failure.md`).
`--output-format stream-json --verbose` is the cheaper route to those
records — it carries the `tool_use` blocks, the `init` record and, for a
conditional skill, the `commands_changed` record that witnesses the
matching `Read` (`references/reading-a-failure.md`) inline, so nothing
has to locate a session id under `~/.claude/projects/`. Read the answers
rather than grepping them (2026-09-12), and only the first `result`: a
peer's message can run in an arm as a second turn (2026-09-29).

**Launch a slash probe from PowerShell**, not the Bash tool. MSYS2
rewrites a leading-slash argument to `C:/Program Files/Git/<name>`, so
`claude -p "/my-skill ..."` never reaches the slash path — and the
failure is invisible, because the model reads the mangled text, still
recognises the skill name, and invokes it via the Skill tool. The run
then looks like a passing slash test while measuring model-invocation.
Measured 2026-09-02. From Bash, set `MSYS2_ARG_CONV_EXCL='/my-skill'`,
never `'*'`: the arm's own shell inherits it, and its native `jq` breaks
(`references/reading-a-failure.md`, 2026-10-01).

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
can discard**, staged or not (2026-09-12, in the reference). Hand
`/commit` the stamp command to re-run before staging, and again once the
tested edit commits, so `commit` names the commit that holds it. **In a
linked worktree, stamp on `main` once the fast-forward lands**, since
the rebase rewrites the worktree's commits; the brief goes in that commit.

**Then delete the brief — if it is still there.** An `/author-skill`
brief stays queued in `docs/handoffs/execute/` until this test runs,
and nothing else removes it (`references/reading-a-failure.md`). Grep
for links to it and re-point them in the same change. An **edit** brief
goes in the commit that finishes its work, so it is still here when this
run is its last check; otherwise its absence is correct and the edited
skill carries no "untested" marker on disk at all, and
`skill-status.py --stale` is the only thing that says so.

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
| Nothing activated, any fixture | The platform skills are not deployed — `~/.claude/skills` carries only the standing `workflow`, `social` and `meta` groups |
| Nothing activated, probe looks fine | The probe read with `cat`. Activation is keyed to the **`Read` tool**; Bash `cat` and `Grep` touch the same bytes and activate nothing. This machine defaults to auto mode, which prefers `cat` |
| The second matching file activates nothing | Correct behaviour. Activation is a **cumulative delta** — an attachment names only what was not already active |
| An activation looks one or two reads late | Attachments **flush in batches**; attribute it to the group read since the last flush, not to one file |
| A negative assertion always passes | The skill it is asserting *against* is not deployed. Both groups must deploy for either set |
| The debug log shows nothing | `--debug-file` emits its skill lines before any Read runs, so it can never witness an activation |
| The session answers *well* but the skill never loaded | A conditional skill is absent from the startup listing, so a plain-English query cannot reach it. Better answers were base-model variance — confirm a `Skill` tool_use before believing a pass |
| `/<skill-name>` returns `Unknown command` | Expected for a **conditional** skill cold; it becomes reachable only after a matching file is Read in that same process: a `--resume` answered it too (2026-09-12). Unconditional skills slash normally — unless the skill is new and the linker has not run since `/author-skill` wrote it (step 7; `prune-branches` had no junction on 2026-09-14) |
| The baseline scores nearly as high as the payload | It read the payload off disk, root `CLAUDE.md` carries the same claims, or the session-start git log names them, which `--safe-mode` keeps. Allowlist `--tools Skill` on both arms, then ablate with `--tools CronList`. Set `CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS=1` on every arm but a commit or PR skill's (`commit`, `land`): it also removes the built-in commit and PR instructions, so read the log for the claim there instead |
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
- **Never deploy a platform group to user scope** to test it: step 7's
  probe copy is enough, and user scope serves every live session.
- **Fixtures are inputs, not outputs.** Do not edit a fixture to make a
  test pass; change the contract table or the glob, and say which.
- **Phase A is skipped, not faked**, for an unconditional skill.
- **No commit**, no push. Hand off to `/commit`.
- **This skill has no Phase A of its own** — it has no `paths:` glob, so
  there is nothing to fixture. `/test-skill test-skill` runs Phase B
  only, and that is correct rather than a gap.
