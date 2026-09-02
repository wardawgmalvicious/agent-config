---
name: drift-update
description: "Execute the handoff briefs a /drift-handoff run wrote to docs/audits/<audit-date>/<source-id>/ — apply each brief's edits, run its own verification steps, and stamp it done. Use when the user says to execute, apply, action, or work through the drift handoffs or briefs, or points at a docs/audits directory. Reads briefs from disk and never from the conversation, so it runs cold in a fresh session (preferred) or warm straight after /drift-audit and /drift-handoff. Walks briefs in numbered order with a checkpoint each — confirm the brief's quoted evidence still exists, apply, verify, stamp, continue — and stops on the first failure rather than pressing on. Briefs whose Kind is a decision rather than an edit are put back to the user, never executed. Skips briefs already carrying an execution log, so an interrupted run resumes where it stopped. Hands off to /commit at the end."
argument-hint: "[audit-date | source-id | path] [brief-number]"
allowed-tools: Read Edit Write Glob Grep Bash
model: inherit
effort: max
disable-model-invocation: false
context: inline
---

# Drift update

Execute the briefs on disk. `/drift-audit` finds the drift, `/drift-handoff`
writes it down, and this skill is the third turn: it applies what the briefs
specify, verifies with the steps the briefs supply, and records that it ran.

The briefs are the instruction set. This skill contributes the loop around
them — resolution, a staleness gate, triage, checkpointing, and a stamp — not
the content of any edit.

**Read every brief from disk, every time.** Never reconstruct one from the
conversation, from memory of an audit, or from a summary, even when this
session produced it. The file is the contract; the transcript is not.

Repo-relative paths below are relative to the agent-config repo
(`C:\Repos\Personal\agent-config`), not the session's cwd. `~/.claude/skills`
is a junction into that repo, so this skill can fire from a session in any
repo — resolve paths against agent-config regardless of where it fired.

## 1. Preconditions and session posture

**Fresh session is the intended way to run this.** A brief is written to be
read cold; running cold is what proves it was written well.

Check whether a `/drift-audit` report is present in the conversation — its own
structure (`## Audit window` plus `## Recommended actions`), not a mention of
one. If it is, this is a **warm** run. Warm is allowed, with two limits:

- **Refuse a brief whose targets include `skills/drift-audit/`,
  `skills/drift-handoff/`, or `skills/drift-update/`.** Editing the skill that
  produced the briefs, in the session that produced them, is the one case where
  warm is actually unsound. Name the brief, say why it was skipped, and tell
  the user to run it from a fresh session.
- **Cap the run at three briefs.** The audit turn is the expensive one; its
  fetched sources and artifact sweep are still resident. Apply the first three
  eligible briefs, stop, and report the remainder as pending a fresh session.
  The cap counts briefs this run **applies**; one that 4.2 stamps as
  `already-applied` costs a grep and an append, so it does not consume the
  budget. Compaction part-way through an edit is worse than a restart, because a
  compacted session is a lossy warm one — strictly worse than a cold one.

Say which posture the run used in the closing report. A warm run that does not
announce itself looks like a cold one that skipped work.

## 2. Resolve the brief set

The target is a directory: `docs/audits/<audit-date>/<source-id>/`.

Argument forms, all optional:

- **A path** — `docs/audits/2026-08-29/fabric`, in either slash style.
  Use it directly. This is the shape of the hand-written invocation this skill
  replaces, so it must keep working.
- **ISO date** (`YYYY-MM-DD`) — that run's directory. If it holds more than one
  source directory, apply the multi-source rule below.
- **Source id** (`fabric`, `powerbi`, `vscode-agent`, `claude-code`, …) — that
  source under the most recent audit date that has one.
- **Trailing integer** — restrict the run to that single numbered brief.
- **No argument** — the most recent date directory under `docs/audits/`.

**Multiple source directories under one date are separate runs of work, not one
run.** List them and ask which to execute. Do not silently pick the first or
concatenate them: sources produce unrelated edits with unrelated verification,
which is the same reason `/drift-handoff` gives them sibling directories.

Then, in the resolved directory:

- `Glob` the numbered briefs. `00-audit-report.md` is not a brief; it is
  evidence, and step 4 governs when to open it.
- **Skip any brief already carrying an `## Execution log` section.** That is
  the resume mechanism. Report skipped-as-done briefs by name so a short run is
  never mistaken for an empty one.
- If every brief is already stamped, say so and stop. Nothing to do is a
  result, not a failure.

If the directory does not exist, **stop**:

> No briefs at `<path>`. This skill executes briefs that `/drift-handoff`
> already wrote; it does not derive work from an audit report. Run
> `/drift-audit` then `/drift-handoff` first, or name an existing directory
> under `docs/audits/`.

## 3. Triage — which briefs this skill may execute

Read each brief's **Kind** line before doing anything with it. It is the
metadata block's most load-bearing field and it classifies the brief:

- **Edit** — "factual correction to committed prose", "rewrite the lineage
  section", "propagate a GA status". Execute it.
- **Decision** — the Kind says the output is a decision, a scoping call, or
  that no file is corrected by this brief. The worked case is a brief reading
  `Kind: scoping decision, not an edit`, whose body then says it exists to make
  the decision makeable, not to make it. **Never execute one.** Present the
  brief's problem and evidence to the user, ask the question it poses, and
  record the answer per step 4.6. A skill that cheerfully writes a new skill
  because a brief mentioned one has misread its only instruction.
- **Self-referential** — the target is the drift skills' own machinery, most
  often `skills/drift-audit/references/sources.md`. Apply it, but understand
  what verification is available: such a brief typically specifies "verified by
  re-running an audit, not by grepping prose", and this skill cannot re-run an
  audit against its own just-edited registry. Run the gates that do apply, then
  record the behavioural check as **deferred to the next `/drift-audit` run**
  in the execution log and in the closing report.

A sub-sectioned brief (`## D-1`, `## D-2`, …) is triaged per defect. A defect
carrying an **Open question** blocks that defect only — ask the user about it,
apply the rest of the brief, and note the deferral in the execution log.

## 4. The per-brief loop

One brief at a time, in numbered order — that order encodes dependency where
one exists. Each brief runs the full loop before the next one starts. **Stop
the whole run on the first failure**; do not skip ahead to an easier brief.

### 4.1 Read the brief

In full, from disk. Honour every section, not just **What to change**:

- **Constraint on the fix** bounds the edit. It usually names what the evidence
  does *not* establish, precisely so the fix does not overreach. Obey it even
  when a broader change looks obviously right.
- **Not fixable** / **Out of scope** describes what survives the fix on
  purpose. Do not attempt those parts, and do not report them as incomplete.

### 4.2 Staleness gate

Briefs are executed days or weeks after they are written, and the tree moves.
Before editing, confirm each target in **What to change** still looks like the
brief says it does: `Grep` for the quoted offending line at the named path.

- **Quote found** — proceed to 4.3.
- **Quote absent** — **do not guess and do not search for something similar.**
  Grep once more at the same path, this time for the brief's intended
  *post-fix* text. A missing quote means one of two opposite things, and that
  second grep is the only cheap way to tell them apart:
  - **Corrected text present** — the fix is already in the tree, applied by
    hand or by an earlier unstamped run, and the brief's intent is satisfied.
    Skip 4.3 and 4.4, go straight to **4.5 and stamp it `already-applied`**.
    Nothing is edited, but the brief is now done and a later run passes over
    it. Without this stamp the run never converges: a set applied by hand
    before this skill first ran would be re-derived in full, every time.
  - **Corrected text also absent** — the target was rewritten, renamed, or
    deleted for reasons the brief knows nothing about. The correction is *not*
    in the tree and this brief can no longer put it there. **Stop the run** and
    report it, as for a partially valid brief below. Do **not** stamp: a stamp
    here would silently retire an unaddressed correction.
- **Some targets found, some not** — treat it as a stop. A partially valid
  brief means the tree diverged in a way nobody predicted, and that deserves a
  human look before anything is written.

### 4.3 Apply

Make the edits the brief enumerates, at the paths it names, and nothing else.

**Do not fix adjacent problems.** Something else wrong in a file you are
editing is a finding for the closing report, not licence to widen the diff.
The audit / handoff / update split exists so that analysis, transcription, and
execution stay separable; an unbriefed edit made here has no evidence behind it
and no verification step written for it.

Equally, **do not re-open the brief's reasoning.** If the brief looks wrong,
stop the run and say so in chat rather than improving it in passing — the same
rule `/drift-handoff` follows when transcribing.

### 4.4 Verify

Run the brief's own **Verification** section, in order, as commands. It is
numbered and runnable for exactly this reason, and the shared-verification test
is what decided the brief's boundaries in the first place.

Two adjustments to the repo's standard gates:

- `uv run --with pyyaml scripts/lint-frontmatter.py <file>` — run per brief, on
  any skill or rule file it touched.
- `pre-commit run --all-files` — run **once at the end of the whole run**, not
  per brief. It is repo-wide and slow, and per-brief runs tell you nothing
  extra. Skip it altogether when the run wrote nothing: a brief set that came
  back wholly already-stamped or already-applied leaves no diff for it to
  check, and running it anyway is a slow repo-wide no-op.

A failed verification stops the run. Report the command, its output, and the
state of the tree; leave the edits in place rather than reverting, so the user
can see what happened.

**One check this skill cannot perform:** an edited `SKILL.md` does not reliably
reload mid-session on Windows, so no brief that edits a skill can have its
behaviour validated in the session that applied it. Lint and prose checks pass;
behavioural confirmation is a fresh-session task. Say so rather than implying
the skill was exercised.

### 4.5 Stamp

Append to the brief file:

```markdown

## Execution log

- **Executed**: <ISO date> — <applied | applied with deferrals |
  already-applied | escalated>
- **Session**: <fresh | warm>
- **Files changed**: `<path>`, `<path>`
- **Verification**: <which steps ran and passed>
- **Deferred**: <what could not be checked here, and what would check it>
- **Deviations**: <anything done differently from the brief, and why — or none>
```

An `already-applied` stamp uses the same shape with different content:
**Files changed** is `none`, and **Verification** is the confirming grep from
4.2 — the post-fix text, found at the named path — rather than the brief's own
steps, which were never run.

Append; never rewrite the brief above it. The brief as written is the record of
what was decided, and the log is the record of what happened — keeping them
distinct is what makes the pair auditable.

`docs/audits/` is gitignored, so these stamps are working state, not
history. They exist to make a re-run resumable, not to document the change —
the commit message does that.

### 4.6 Checkpoint

Emit one line — brief number, outcome, files touched — then continue. Do not
batch the reporting to the end; a run that fails at brief five should already
have shown what briefs one through four did.

For an escalated decision brief, the checkpoint is the question itself. Put the
brief's problem and evidence in front of the user, ask, and stamp the answer
into the execution log as `escalated`. Whatever work the answer implies is a
separate task, started deliberately — not something to fold into this run.

## 5. Report and hand off

Close with:

1. **Per-brief outcomes**, one line each: applied, escalated,
   already-applied, already-stamped, or not-reached. Keep the last three
   distinct: *applied* is a change this run wrote, *already-applied* is one
   4.2 found already in the tree and stamped now, *already-stamped* is one a
   previous run had already logged before this one started.
2. **Session posture**, and anything the posture cost — briefs held back by
   the warm cap or the self-referential refusal.
3. **Deferred verification** — every check that needs a fresh session or a
   later `/drift-audit` run, named with what would perform it.
4. **Adjacent findings** — problems seen but deliberately not fixed.
5. **Brief-format defects.** If a brief could not be executed without opening
   `00-audit-report.md`, say which one and what was missing from it. A brief is
   supposed to be sufficient cold; every fallback to the report is evidence
   that `/drift-handoff` under-specified one, and this is the only place that
   failure is observable.
6. `pre-commit run --all-files` result — or that it was skipped because the
   run made no edits.

Then hand off to `/commit`. Unlike `/drift-handoff`, this skill changes tracked
files, so there is a real diff — and `/commit` splits it logically, which is
why this skill does not commit per brief. If the run stopped early, say plainly
which edits are applied and uncommitted before handing over. A run that wrote
nothing has nothing to hand over: report the clean tree and stop, rather than
invoking `/commit` against an empty diff.

Do **not** start the work an escalated decision implies, and do not begin the
next source's briefs. Both are separate, deliberate invocations.

## 6. Constraints

- **Briefs come from disk.** Never from the transcript, a summary, or memory.
- **The brief set is the scope.** No unbriefed edits, no adjacent fixes, no
  re-opened reasoning.
- **Kind decides.** Decision briefs are escalated, never executed.
- **Stale splits two ways, and neither is improvising.** A missing quoted
  line means the fix already landed (stamp `already-applied`) or the target
  moved (stop the run). Never substitute a line that looks close enough.
- **Constraints and Out-of-scope sections are binding**, not advisory.
- **First failure stops the run.** Leave the tree as it is and report.
- **Stamp what ran**, including deferrals and deviations.
- **Warm runs announce themselves**, cap at three briefs, and refuse briefs
  targeting the drift skills themselves.
