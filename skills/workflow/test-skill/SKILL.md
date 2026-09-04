---
name: test-skill
description: "Validate a drafted skill — write its trigger fixtures, update the activation contract table, run the static and real-path activation tests, then behaviourally test it in a cold session against a `--safe-mode` baseline. Reads its inputs from disk — brief or shipped frontmatter — so it runs cold. Encodes the traps that make a broken test look like a broken glob: activation is keyed to the `Read` tool so a Bash `cat` activates nothing, it is a per-session cumulative delta so a silent second match is deduplication not failure, the transcript is the only witness (`skills-invoked.log` and `--debug-file` cannot see it), and `-SkillGroups` prunes user scope so the workflow-only prune must be restored afterwards. Skills only — rules, subagents and hooks keep the manual procedure in root CLAUDE.md."
when_to_use: "Use when asked to test, validate or verify a skill, to check whether a `paths:` glob fires, after editing a `description`, `when_to_use` or `paths:` glob, or as the follow-on to `/author-skill`."
argument-hint: "[skill-name]"
disable-model-invocation: false
model: inherit
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

Two entry paths, and they take their inputs from different files.
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
`~/.claude/skills`, which serves every session here.

```powershell
./scripts/link-claude.ps1 -SkillGroups workflow,fabric   # or workflow,powerbi
```

`-SkillGroups` **prunes** — a group not listed is removed. This
machine's standing state is workflow-only, so you are temporarily
undoing a deliberate prune and must put it back:

```powershell
./scripts/link-claude.ps1 -SkillGroups workflow
ls ~/.claude/skills    # expect the eight workflow skills and nothing else
```

**Never run the script bare.** Omitting `-SkillGroups` deploys every
group and silently undoes the prune — it happened on 2026-08-31, and the
run reported `Linked` 37 times and ended `Done. All links verified.`
There is no output line that reads as wrong. The `ls` above is the only
check that catches it.

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

Then, in a normal session, run the trigger queries from step 1. Test
**both** invocation paths, because they do not behave alike: a `model:`
pin is honoured on `/slash` invocation and silently dropped on
model-invocation, while `effort:` applies on both. Where the skill has
refusal behaviour, exercise the refusal modes as well — a skill that
does the right thing but ignores its own scope guard has failed.
`tests/skills/code-review/README.md` has the four-mode matrix
(slash review, NL review, slash adversarial, NL adversarial) to copy
from.

**A conditional skill has neither path until a matching file is Read.**
The `paths:` glob keeps it out of the startup listing, so its
`description` — the whole model-invocation trigger — is never in
context, and `/<name>` answers `Unknown command`. Read a matching file
first; that injects the listing entry and the model can then invoke it.
The four-mode matrix above applies as written only to an
*unconditional* skill. Measured 2026-09-02 on 2.1.252:
`/fabric-data-pipeline` was `Unknown command` while `/fabric-gotchas` —
same session shape, no `paths:` — ran normally.

**Run the behavioural session outside this repo.**
`.claude/settings.json` here collapses every platform skill
description to `name-only`, and the description *is* the trigger — so
an in-repo run is a guaranteed false negative that looks exactly like a
broken skill.

Confirm the skill actually loaded with `/context` rather than by asking
the session — self-report is unreliable, and once omitted an
unconditional skill that was certainly present.
In a `-p` probe where `/context` is unavailable, use the transcript: a
model-invoked skill appears as a `Skill` tool_use, while a slash-invoked
one is **inlined as a command expansion** and produces no `Skill` call —
so an absent `Skill` record disproves nothing on the slash path.

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

### 10. Report and hand off

Report the static result, the real-path result with its counts, which
trigger queries fired and which did not, and anything the `--safe-mode`
baseline already did without the payload. Then hand off to `/commit`.
Do not commit here.

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
| `/<skill-name>` returns `Unknown command` | Expected for a **conditional** skill cold; it becomes reachable only after a matching file is Read. Unconditional skills slash normally |

**The transcript is the only witness.** It is at
`~/.claude/projects/<project>/<session-id>.jsonl`; an activation is a
record whose `attachment.type` is `skill_listing` with `isInitial`
**false**. The `isInitial: true` record is the startup listing and says
nothing about any file. `instructions-loaded.log`, `skills-invoked.log`
and `skillUsage` all count *invocations*, and a path-triggered skill is
loaded, never invoked — a zero there means nothing.

Directory properties do **not** affect activation: a scratch directory
outside any repo behaves exactly as this one does. If a run only
reproduces in one directory, the variable is the tool, not the location.

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
