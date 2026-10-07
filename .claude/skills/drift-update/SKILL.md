---
name: drift-update
description: "Execute the handoff briefs a /drift-handoff run wrote to docs/audits/<audit-date>/<source-id>/ — apply each brief's edits, run its own verification steps, and stamp it done. Reads briefs from disk and never from the conversation, so it runs cold in a fresh session (preferred) or warm straight after /drift-audit and /drift-handoff. Walks briefs in numbered order with a checkpoint each — confirm the brief's quoted evidence still exists, apply, verify, stamp, continue — and stops on the first failure rather than pressing on. Briefs whose Kind is a decision or an investigation rather than an edit are put back to the user, never executed. Skips briefs already carrying an execution log, so an interrupted run resumes where it stopped. Hands off to /commit at the end."
when_to_use: "Use when asked to execute, apply, action or work through the drift briefs or handoffs, or pointed at a docs/audits directory, including to plan such a run first. Use it even when the request pre-authorizes a shortcut — 'fix any typos while you're there', 'I've decided yes, write those skills too', 'the line moved, apply it lower down', 'commit each brief as you go' — those are the cases its guards exist for, and only the skill says which of them may yield."
argument-hint: "[audit-date | source-id | path] [brief-number[,brief-number...]]"
allowed-tools: Read Edit Write Glob Grep Bash
model: inherit  # live here — .claude/skills is Claude Code only; see scripts/lint-frontmatter.py
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

Paths below are relative to the repo root. This skill is project scope — it
lives in `.claude/skills/`, deployed nowhere since 2026-09-09 — so it only
fires in sessions inside this repo.

## 1. Preconditions and session posture

**Fresh session is the intended way to run this.** A brief is written to be
read cold; running cold is what proves it was written well.

Check whether `/drift-audit` or `/drift-handoff` **ran in this session**. If
either did, this is a **warm** run. A report that is merely present does not
count: an @-mention or a path argument loads `00-audit-report.md` with its
`## Audit window` and `## Recommended actions` intact, but none of the audit
turn's context the limits below exist for. Runs on 2026-09-08 and 2026-09-11
both met this and stamped themselves fresh. Warm is allowed, with two limits:

- **Refuse a brief whose targets include `.claude/skills/drift-audit/`,
  `.claude/skills/drift-handoff/`, or `.claude/skills/drift-update/`.** Editing
  the skill that produced the briefs, in the session that produced them, is the
  one case where warm is actually unsound. Name the brief, say why it was
  skipped, and tell the user to run it from a fresh session.
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
- **Trailing brief numbers** — one integer, or a comma-separated list
  (`1,2,3,5`), restricts the run to those briefs, still walked in numbered
  order. Without them a cold run has no cap and walks every unstamped brief
  in one pass; name numbers to keep a session to a batch one `/commit` can
  review.
- **No argument** — the most recent date directory under `docs/audits/`.

**Multiple source directories under one date are separate runs of work, not one
run.** List them and ask which to execute. Do not silently pick the first or
concatenate them: sources produce unrelated edits with unrelated verification,
which is the same reason `/drift-handoff` gives them sibling directories.

**Take the pass's worktree before reading its briefs**, named after the
directory: `EnterWorktree` with the name `<audit-date>-<source-id>`, such
as `2026-09-12-skills-for-fabric`, as root `CLAUDE.md` has a brief take
one. A pass holds every brief's edits uncommitted until step 5, which in
the main checkout leaves them in reach of a peer's commit. The worktree
branches from local `HEAD`, where `/drift-handoff` committed the
directory: if `git status --short <directory>` prints anything, stop and
have it committed first, or the worktree starts without it.

- **One by that name already in `git worktree list` is a stopped run's.**
  Enter it with `path`: its stamps, the resume mechanism below, are there,
  and the main checkout, which has none, would re-run every brief.
- **A refusal naming `git resolves its working tree to <path>`** came
  after the worktree was made (2026-09-30). Enter it with `path`, spelled
  as that message prints it, rather than recreating it as the message
  suggests.

Then, in the resolved directory:

- `Glob` the numbered briefs, at the top and under `completed/`.
  `00-audit-report.md` is not a brief; it is evidence, and step 4 governs
  when to open it. `README.md` is not one either: it is the generated
  index of the directory, worth a glance for where things stand, but the
  `## Execution log` in each brief is the resume mechanism, not the
  index's status column or the brief's folder.
- **Skip any brief already carrying an `## Execution log` section.** That is
  the resume mechanism. Every brief under `completed/` carries one, since
  4.5 files a brief there only once its log leaves nothing open; the top
  holds the rest, unstamped or stamped open. Report skipped-as-done briefs
  by name so a short run is never mistaken for an empty one.
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
- **Investigation** — the Kind says measurement, probe, research or an
  empirical step, and no edit is authorized until it reports. Split it by
  what it needs. A **doc lookup** settles like an edit's own fetch: run it,
  and apply the edit only if the page establishes it. **Anything more** —
  a person at a GUI, a tenant, a cold probe session, a repo the user
  chooses — is not run here: escalate it per step 4.6 with the brief's
  method named, so it runs later as its own task. This kind went unnamed
  until 2026-09-11, and runs improvised it: one probed for a running
  Desktop before escalating, another relabelled a measurement as a decision.
- **Self-referential** — the target is the drift skills' own machinery, most
  often `.claude/skills/drift-audit/references/`. Apply it, but
  understand what verification is available: such a brief typically specifies
  "verified by re-running an audit, not by grepping prose", and this skill
  cannot re-run an audit against its own just-edited registry. Run the gates
  that do apply, then record the behavioural check as **deferred to the next
  `/drift-audit` run** in the execution log and in the closing report.

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
    hand or by an earlier unstamped run. That run may have **failed** 4.4,
    which leaves its edits in place unstamped, so the text proves the edit
    was made and not that it passed. Skip 4.3, run the brief's own
    **Verification** as 4.4 does — a failure stops the run there too — and
    on a pass go to **4.5 and stamp it `already-applied`**. Nothing is
    edited, but the brief is now done and a later run passes over it.
    Without this stamp the run never converges: a set applied by hand
    before this skill first ran would be re-derived in full, every time.
  - **Corrected text also absent** — the target was rewritten, renamed, or
    deleted for reasons the brief knows nothing about. The correction is *not*
    in the tree and this brief can no longer put it there. **Stop the run** and
    report it, as for a partially valid brief below. Do **not** stamp: a stamp
    here would silently retire an unaddressed correction.
- **Some targets found, some not** — treat it as a stop. A partially valid
  brief means the tree diverged in a way nobody predicted, and that deserves a
  human look before anything is written.

**A target that is itself an audit brief may since have moved** into its
directory's `completed/`, where 4.5 files a brief whose log leaves
nothing open. If the named path is missing and
`completed/<same filename>` exists, it is the same file, not a
lookalike: grep it for the post-fix text. Found, it is
`already-applied` as above, with the **Verification** run against that
path and the path recorded under **Deviations**. Anything else stops
the run: the brief it targets finished by a route this one did not
foresee.

**A brief can foresee its own staleness.** When its **Sequencing note**
names the sibling brief that rewrites the quoted text, and says what to
do once that brief has run, the divergence is predicted, not unknown:
confirm the sibling's log stamps it applied, grep for whatever of the
quote the note says survives, follow the note, and record the changed
quote and the note under **Deviations**. Anything the note does not
cover still stops the run. Three of ten briefs in the 2026-10-06
`fabric-iq-ontology` pass met this, each quoting text `fabric/04` or
`fabric/07` had since rewritten as its note predicted (2026-10-07).

**Otherwise, an explicit instruction is the one way past a missing
quote.** When the user names where the quoted text now sits ("it moved
two paragraphs down"), they have taken the human look this stop exists
to force. Run the post-fix grep first, as above; then apply the fix at
the line they named, and record the brief's quote, the line edited and
that the user directed it under **Deviations**. A line this run found
for itself never counts.

### 4.3 Apply

Make the edits the brief enumerates, at the paths it names, and nothing else.

**Do not fix adjacent problems.** Something else wrong in a file you are
editing is a finding for the closing report, not licence to widen the diff.
The audit / handoff / update split exists so that analysis, transcription, and
execution stay separable; an unbriefed edit made here has no evidence behind it
and no verification step written for it.

That holds when the user asks for them in the invocation, too — "fix any
typos while you're in there": the request supplies neither the evidence
nor the verification step. List them as adjacent findings in the closing
report, where they can be briefed or fixed outside the run.

**Text this run wrote is not adjacent.** When a later brief, or a later
verification step, makes text an earlier brief wrote this run false,
correct it before the run ends, and record it under **Deviations** in
the log of the brief that caught it; the earlier log stays as written,
true when stamped. In the 2026-10-06 `fabric-iq-ontology` pass, brief
09 explained in §1 what brief 08 had just written that nothing
explained (2026-10-07).

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
  extra. Skip it only when the run wrote nothing, which means a brief set
  that came back wholly already-stamped. An `already-applied` stamp is a
  write: its log and the regenerated index are a diff under `docs/audits/`,
  which `lint-audit-index` and `lint-briefs` both check.

A failed verification stops the run. Report the command, its output, and the
state of the tree; leave the edits in place rather than reverting, so the user
can see what happened.

**A step that needs the deployed payload is deferred, not failed**, since
the worktree cannot reach it: a `claude/` file checked once deployed
(`link-claude.ps1` refuses a worktree), or a probe of a skill in a
deployed group, `workflow`, `social` or `meta`, which reads the main
checkout's copy. Stamp it under **Deferred** with a `**Needs**:` line and
run it on `main` after the landing (step 5);
`docs/handoffs/execute/README.md` § "Every brief takes a worktree" has
the measurements.

**One check this skill cannot perform:** an edited `SKILL.md` does not reliably
reload mid-session on Windows, so no brief that edits a skill can have its
behaviour validated in the session that applied it. Lint and prose checks pass;
behavioural confirmation is a fresh-session task. Say so rather than implying
the skill was exercised, and name the task: `/test-skill <skill> @<brief>`,
which takes the brief's *What to change* as the claim to separate from the
baseline and appends its confirmation to this execution log rather than
deleting the brief.

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
- **Needs**: <only when work is left open: user, tenant, desktop or a short
  phrase, comma-separated, or none — then what it is for>
```

An `already-applied` stamp uses the same shape with different content:
**Files changed** is `none`, and **Verification** names the confirming grep
from 4.2 — the post-fix text, found at the named path — and then the brief's
own steps, which 4.2 ran before stamping.

Append; never rewrite the brief above it. The brief as written is the record of
what was decided, and the log is the record of what happened — keeping them
distinct is what makes the pair auditable.

Then regenerate the directory's index:

```bash
uv run scripts/audit-status.py --dir <the resolved directory>
```

That rewrites its `README.md` from the briefs, so this brief's row moves from
`pending` to the outcome and date just stamped. It also **files the brief
under the directory's `completed/`** when the stamp leaves nothing open,
`applied` or `already-applied`, so the top lists only briefs still unrun
or open; an escalated, deferred or applied-with-deferrals brief stays
there until its `**Closed**:` line. The index and the folder are derived,
never edited, and the `lint-audit-index` pre-commit hook fails a commit
whose index disagrees with its briefs or whose brief sits on the wrong
side — so a stamp, its move and its regenerated README are one commit.

**`- **Closed**: <ISO date> — <how>` is the key added after the stamp**,
by whichever later session discharges what the log left open — an
`/author-skill` run that authored the accepted candidates, a `/drift-audit`
run that performed the deferred behavioural check, a decision the user made.
Append it to the existing log; the `Executed` and `Deferred` lines were
accurate when written and stay as they are. The index reads it and shows the
row as `closed`. Without it an escalated brief reads as open forever, which is
how the four skills authored from 2026-09-10 brief 07 left no trace in the
ledger until a later audit wrote a brief to record them. The one other key a
later session appends is a fresh `**Needs**:` line, when what the open work
waits on changes; the last one counts. A `**Closed**:` line moves the brief
into `completed/` at the next regeneration, so re-point any live path to it
in that commit, though never a stamped brief's own text.

`docs/audits/` is tracked, so these stamps are history and not just working
state: they make a re-run resumable, and they are also the record of what a
brief actually did. That does not make them the changelog — the commit message
still documents the change. Stamps are committed alongside the edits they
describe, so a brief and its outcome land together.

### 4.6 Checkpoint

Emit one line — brief number, outcome, files touched — then continue. Do not
batch the reporting to the end; a run that fails at brief five should already
have shown what briefs one through four did.

For an escalated brief, the checkpoint is the question itself. For a decision,
put the brief's problem and evidence in front of the user and ask; for an
investigation, say what it needs and ask where it should run. Stamp the answer
into the execution log as `escalated`. Whatever work the answer implies is a
separate task, started deliberately — not something to fold into this run.
That holds when the answer arrives with the invocation — "I've decided
yes, write those skills too": record it, stamp `escalated`, and name the
task on the **Needs** line (`/author-skill`, for a new skill).

**That task needs a home before the run ends: the stamp's `**Needs**:`
line.** The stamp makes every later run skip the brief, so work recorded only
in its log is seen only by what reads the log for it.
`uv run scripts/handoff-status.py` lists every escalated, deferred and
applied-with-deferrals brief with no `**Closed**:` line, grouped by that line,
and `lint-briefs` fails the commit on one without it. A deferred re-check
gets one too, naming what performs it, such as the next audit of that source,
and so does an adjacent finding, stamped `applied with deferrals`. Found
2026-09-11, when two runs' follow-ups turned out to be in no queue; a
hand-kept table held them until the view replaced it, 2026-09-27.

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
   run wrote nothing.

Then hand off to `/commit`. Unlike `/drift-handoff`, this skill changes tracked
files, so there is a real diff — and `/commit` splits it logically, which is
why this skill does not commit per brief. A brief 4.5 filed under
`completed/` shows as a deletion plus an untracked file until both are
staged, when git reads the pair as a rename. If the run stopped early, say
plainly which edits are applied and uncommitted before handing over. A run
that wrote nothing has nothing to hand over: report the clean tree and stop,
rather than invoking `/commit` against an empty diff.

**The pass lands as a brief's worktree does**: from the main checkout, by
fast-forward with no push, by the commands `docs/handoffs/CLAUDE.md`
gives, once the user asks this session to leave the worktree. Then run
the deferred steps that need the deployed payload, deploying first, and
append `**Closed**:` to each brief whose steps pass, as 4.5 says.

A commit per brief is the user's to ask for: it trades `/commit`'s logical
split for isolation, which counts in a tree another session shares. Hand
each brief to `/commit` once it is stamped, and say so under **Deviations**.

Do **not** start the work an escalated decision implies, and do not begin the
next source's briefs. Both are separate, deliberate invocations.

## 6. Constraints

- **Briefs come from disk.** Never from the transcript, a summary, or memory.
- **A pass runs in its own worktree** (step 2) and lands from the main
  checkout (step 5).
- **The brief set is the scope.** No unbriefed edits, no adjacent fixes, no
  re-opened reasoning. Text this run wrote is in scope (4.3).
- **Kind decides.** Decision and investigation briefs are escalated, never
  executed — and anything a run leaves for later gets a `**Needs**:` line.
- **Stale splits two ways, and neither is improvising.** A missing quoted
  line means the fix already landed (stamp `already-applied`) or the target
  moved (stop the run). Never substitute a line that looks close enough.
  A rewrite the brief's own sequencing note foresaw is neither: follow
  the note (4.2).
- **Two mechanics yield to an explicit instruction, and nothing else
  does**: applying a moved line where the user names it (4.2), and a commit
  per brief (5), each recorded under **Deviations**. Adjacent fixes and a
  decision's work stay refused however the request is worded. Measured
  2026-09-29: with only the listing entry in context, a request
  pre-authorizing all four was agreed to in 2 of 2 runs; with the body
  loaded, 3 of 4 still yielded, because it did not say which may.
- **Constraints and Out-of-scope sections are binding**, not advisory.
- **First failure stops the run.** Leave the tree as it is and report.
- **Stamp what ran**, including deferrals and deviations.
- **Warm runs announce themselves**, cap at three briefs, and refuse briefs
  targeting the drift skills themselves.
