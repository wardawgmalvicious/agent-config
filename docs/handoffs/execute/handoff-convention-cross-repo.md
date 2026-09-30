---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-09-16
---

# Brief: a cross-repo handoff convention

**Status:** Nothing drafted. **All four
questions are answered**: Q1 and Q2 the same day — see
[Decisions](#decisions--2026-09-16), which also records four findings
that reframed Q1 and retracts one of this brief's own arguments — and
Q3 and Q4 by the estate repo's own index, also written 2026-09-16 and
recorded here 2026-09-18 — see
[Q3 and Q4](#q3-and-q4--answered-by-the-estate-repos-index). What
remains is execution: Q1's first two edits, neither yet drafted,
re-planned 2026-09-27 when this repo's queue moved into each brief's
frontmatter — see [Re-plan](#re-plan--2026-09-27). The third, one note
per repo, went out 2026-09-29 ahead of them, when the user moved every
repo they work in to frontmatter — see
[Decision](#decision--2026-09-29).

**Scope.** Generalize the handoff discipline this repo already runs to
the other repos on this machine, which have started growing their own
handoff directories independently. Findings and a proposal only — this
brief does not itself change any convention.

## Why now

Three repos on this machine now hold handoff briefs, and only this one
has an index. The immediate trigger was a `/learn` run on 2026-09-15
that produced a brief for a *different* repo: the fix it describes
belongs to `machine-config`, not to the payload, so
`docs/handoffs/gh-account-path-shim.md` was written there and became the
first file in a directory that had been created empty. A brief alone in
an unindexed directory is the exact failure
[execute/README.md](README.md) exists to prevent.

The second trigger is volume. A client estate repo is accumulating its
own handoffs on unrelated subject matter — estate work, not payload —
and is likely to be the second-highest-churn repo here after this one.
Whatever shape is chosen has to survive tasks that look nothing like
authoring a skill.

## What already exists

Measured 2026-09-16 across three repos, re-measured 2026-09-27, when a
fourth had briefs, and again 2026-09-29, when this one had fallen from
14 briefs to 11 and the second client repo had risen from 2 to 3.

| Repo | Visibility | Briefs | Index | A brief is about |
| --- | --- | --- | --- | --- |
| this one | public | 11 in `execute/`, each with frontmatter, plus open follow-ups in `docs/audits/` | none since 2026-09-27: `handoff-status.py` generates the view | payload: skills, rules, hooks |
| `machine-config` | private | 2, in `docs/handoffs/` | yes — `docs/handoffs/README.md`, added 2026-09-16 | machine setup: shells, PATH, installed tooling |
| client estate repo | internal | 6, in `execute/` | yes — `execute/README.md`, added 2026-09-16 | estate work |
| a second client repo | private | 3, in `execute/` | yes — `execute/README.md`, added with its first brief 2026-09-27 | its deferred infrastructure and CI work |

Two more repos the user works in, `fabric-tools` and
`personal-scripts`, held no briefs and no handoff directory on
2026-09-29.

**The brief shape is already converging without coordination.** All
three of the client repo's briefs carry a `**Status:**` line; two cite a
measured or verified claim; the `machine-config` brief was written to
the same shape from this repo. Nobody standardized that.

**The index was missing everywhere but here**, and that is the part this
repo learned the hard way — that a brief's state must live in exactly
one place, that positions churn so filenames must not carry them, and
that a spent brief left in a queue invites re-execution. Both other repos
closed that gap the same day — `machine-config` and then the estate repo,
which was the last without one (the table above records it corrected
2026-09-18) — and the second client repo opened with an index.

That one place was one index in every repo until 2026-09-27, when this
repo moved each brief's state into its own frontmatter and let
`handoff-status.py` generate the view, because the index was the file
two sessions in one tree dropped each other's rows from.
[README.md](README.md#no-file-lists-the-queue) has why. The other three
kept their indexes until 2026-09-29, when the user moved every repo to
frontmatter; the sweep reads either form while each makes the move.

So the deliverable is **not a shared brief template.** A template would
have to span skill authoring, shell configuration and estate work, and
would collapse into either uselessly generic headings or this repo's own
concerns imposed on two repos that do not share them. The deliverable is
a short contract plus a per-repo stub, which held an index until
2026-09-29.

## Proposed: a minimal common core

Nine invariants — eight as written 2026-09-16, and a ninth added
2026-09-18 when Q4 was answered; 1, 4 and 9 were corrected 2026-09-27
for per-brief state, and 1 and 4 again 2026-09-29, for frontmatter in
every repo. Everything else stays per-repo.

1. **A brief's state lives in exactly one place**: its own frontmatter,
   from which a tool generates the view. A brief carries its
   dependencies, never its position. This said "one index" until
   2026-09-27, and allowed either form until 2026-09-29;
   `handoff-status.py` still reads an index, for a repo partway through
   the move.
2. **Stable filenames, subject-named, no dates and no positions.** The
   filename is the link target. Dates go inside.
3. **Self-contained and readable cold.** A brief that only makes sense
   to the session that wrote it has failed.
4. **State, the date written, and what it waits on**, as frontmatter
   keys, which the body does not restate. A status line emerged in every
   repo with an index; its state word and date are what move into the
   keys.
5. **A scrubbing declaration** — see below. New; nothing has this.
6. **Measured and Not checked as separate headed lists.** The
   undrilled set is what bounds the work, and it is the first thing
   lost. This repo's `skill-handoff.md` template already does it; it is
   the most portable idea in there.
7. **Verification steps**, concrete enough to run without the author.
8. **Delete when spent, promoting durable measurement first.** The
   queue rule, not the ledger rule, in every repo — but a measurement
   that outlives the decision moves, dated, into the document that owns
   it before the brief goes. A **no** is recorded in the deleting
   commit; a **deferral** is the one outcome that leaves a file. See
   [Q3](#q3-and-q4--answered-by-the-estate-repos-index).
9. **The directory says whether it is the backlog.** Either its briefs
   are the only one, or they are scoped to agent-executable work beside a
   named tracker. Per-repo, declared in the stub beside direction and
   visibility.

## The two genuinely new rules

Both are consequences of briefs crossing repo boundaries, which is
why this repo never needed them.

**Scrubbing is decided by the destination's visibility, not the
origin's.** A brief written in an internal estate repo may name estate
objects freely there; the same content routed into this repo, which is
public, must be cited by kind. `machine-config` is private and still
takes placeholders, because an organization's account names stay out of
files whatever the repo's visibility. So each brief states plainly which
of its content is raw and which is genericized — a note that *looks*
scrubbed but is not is the failure mode, and the landing session is the
one that pays for it.

**Direction has to be explicit.** Three cases exist and read
differently:

- **Local** — written and executed in the same repo. Most briefs.
- **Outbound** — written here, lands elsewhere. Needs a section naming
  what changes in the origin repo once it lands. The `machine-config`
  brief calls this `## Downstream`.
- **Inbound** — written elsewhere, lands here. `~/handoff-inbox/` is
  the machine-level inbound path for payload work, with two writers and
  one reader.

A directory should say which of these it accepts. None did on
2026-09-16; every indexed repo's stub did by 2026-09-29.

## What this does not propose

- No shared template, for the reason above.
- No tooling copied into other repos. This repo's `audit-status.py` and
  `skill-status.py` derive indexes from metadata; that is worth copying
  only if a repo's brief count justifies it, and one brief does not.
  **One tool reads them all instead, added 2026-09-18** at the user's
  call: `scripts/handoff-status.py` sweeps every repo's index and inbox
  directory from here and writes nothing, after the Q3/Q4 answers sat
  unread in the estate repo for two days. It changes no repo's
  convention, which is why it does not contradict the bullet above.
- No change to `docs/audits/`. The queue-versus-ledger split here is
  already correct and documented.

## Decisions — 2026-09-16

Answered the day the brief was written, after checking four things the
brief itself had not.

**Four findings, in the order they moved the decision.**

1. **This brief's own argument against the rule form was wrong, and is
   retracted.** Q1 said a path-scoped rule "is guidance for a human
   convention, which is not what rules have been used for." Three of the
   eighteen rules are exactly that: `claude-config-scoping.md`,
   `git-identity-scoping.md` and `vscode-scoping.md` each open with
   *what belongs where*, and none is a language convention.
2. **A harder blocker rules it out anyway, and this is the one worth
   keeping.** `permissions.defaultMode` is `auto` at user scope, and
   activation is keyed to the `Read` tool — auto mode prefers `cat`, so
   a `paths:` rule is live but dormant through a whole session that
   never `Read`s. And the trigger here is **writing** a brief, not
   reading one: the case that produced this brief was a session writing
   the first file into an empty `machine-config/docs/handoffs/`, where
   nothing matching existed to read. A glob is structurally blind to it.
3. **A fourth artifact already in production went uncounted.**
   `~/.copilot/instructions/cross-repo-handoffs.instructions.md` already
   encodes both of the two genuinely new rules above — inbound routing
   to the inbox, and the scrubbing split ("record what you observed
   plainly… a later session in the target repository decides what
   survives into anything published"). It is hand-written, at user
   scope, in no repo, versioned by nothing, and Copilot-only. So Q1 was
   never "invent a form" — it is "where does that content live so it is
   versioned and both harnesses see it."
4. **The skill form has a measurable cost.**
   `uv run --with pyyaml scripts/skill-overlap.py overlap --skill learn`
   puts `author-skill + learn` at 32.88, the top pair across 56 skills.
   A `/handoff` skill that writes a brief and updates an index lands
   between those two and pushes that cluster higher.

**Q1 — extend `/learn`, rather than any of the three forms proposed.**
The trigger analysis favours the skill *mechanism*: a description is
matched against intent, not against a file read, which is why `/learn`
works where a rule would not. But `/learn` is already that skill, and
already writes a dated cross-repo note. So the deliverable is three
edits rather than a new artifact:

- the invariants go in `skills/meta/learn/references/`, read on
  invocation, at no listing cost;
- the Copilot instruction is ported into `copilot/instructions/`, so it
  stops being an unversioned hand-written file and gains the Claude side
  it never had;
- each repo's handoff directory gets a **stub** `README.md` carrying
  direction, visibility and the index table — nothing else. The "drifts
  three ways" objection was against duplicated *prose*; there is none to
  duplicate once the contract lives in one place and the stub links it.

**Q2 — the inbox widens, routed by a directory per destination.** A note
lives under the repo it is addressed to; a session in that repo lists
that one directory. That closes the gap which produced the direct
cross-repo write on 2026-09-16.

A destination *field* in a flat inbox was recorded here first and
**reversed the same day**, on the failure mode rather than on taste: a
field that is missing or misspelled looks identical to every other note
and is invisible to every filter — which is how three notes sat unread
from 2026-09-15. A note loose in the inbox root is visibly un-routed,
and routing by path costs no reads to filter.

**Done 2026-09-16.** `~/handoff-inbox/agent-config/` holds all three
notes — each declared its own target in a `**For:**` line, so none
needed triage — and `~/handoff-inbox/README.md` carries the layout, the
three opening lines a note owes, and the scrubbing rule.

**The reader pointer landed the same day**, via `/learn`: nothing on the
machine had told a session to *read* the inbox — the only file that
mentioned it was
`~/.copilot/instructions/cross-repo-handoffs.instructions.md`, which is
Copilot-only and describes writing to it, never reading, and
`claude/CLAUDE.md` did not mention it at all. The check belongs at
**user scope** — the inbox is machine environment, and a per-repo line
would have to be repeated in every repo including ones that do not
exist yet — so it is now a paragraph in `claude/CLAUDE.md` § "Agent
config source", a copy that is live only after
`link-claude.ps1 -SkillGroups workflow,social,meta -Force` runs — done
and verified against the deployed file the same day. The per-repo
*index* pointer is the mirror of it at project scope; `machine-config`
made its own in `beb9e67`, and each remaining repo owns the rest.

**Q1's stub has a worked instance, written by another session.**
`machine-config` indexed its handoff directory on 2026-09-16 to exactly
this shape — direction (inbound and local), visibility (private, and
explicitly *not* a licence to skip scrubbing), a one-row index, and the
lifecycle rules **linked here rather than restated**, so there is no
second copy to drift. That answers Q1's "drifts three ways" objection in
practice rather than in argument, and it was built before the invariants
reference below exists, which is the harder test.

It settles the **template** question the same way. `templates/` and
`example/` were created there and removed unfilled: a template derived
from one brief freezes a guess about which headings recur, and a
fabricated example would carry invented measurement dates in a document
culture whose rules turn on a claim having actually been checked. The
committed brief is the reference shape instead. Revisit at three or four
briefs, when the common headings can be observed rather than guessed.

## Q3 and Q4 — answered by the estate repo's index

Both were framed as hypotheses about a client repo. The client repo
settled them for itself on 2026-09-16, about an hour after this brief
was committed, when it indexed its three briefs under `execute/` with a
stub written to Q1's shape. Nobody here read that index until
2026-09-18, which is why the questions stayed open for two days after
they had been answered. Its content is cited by kind below, since this
repo is public.

**Q3 — delete-when-spent suits it; the ledger was never missing.** The
hypothesis was that estate work would want an audit trail and so the
ledger rule. The estate index keeps the queue rule instead, and adds
**one carve-out**: some briefs are queue rows, worthless once executed,
while others carry profiling that outlives the decision. Before a brief
is deleted, any durable measurement is promoted, dated, into the
document that already owns it — in that repo, a dated gotchas table in
its agent instructions, or its architecture doc. The audit trail the
hypothesis wanted already exists in two places: git history for the
brief, and that table for the findings. So the split is **not**
per-repo, and invariant 8 is rewritten to carry the promotion step
everywhere. This repo already does the same thing without saying so —
a finding lands in the skill, rule or `CLAUDE.md` that owns it, and
then the brief goes.

**Q4 — no collision today, and the index declares what happens if one
appears.** Measured 2026-09-18: the repo has GitHub issues enabled and
has never used them — `gh issue list --state all` is empty and the open
count is 0, matching the index's own 2026-09-16 reading. It uses PRs,
which are review rather than tracking. Its index says so under a
heading of its own ("This index is the backlog") and states the
condition in advance: if a tracker appears, scope the file to
agent-executable work and let the tracker own the rest. That is the
right shape for every repo, so it becomes invariant 9 and a third field
in the stub, beside direction and visibility.

**One follow-on for the Q1 draft.** The estate index carries a "Brief
shape" section in prose, with a note to cut it to a link once the
invariants land in `learn`'s `references/`. That is the one duplicated
copy of the contract so far, and it is flagged by its own author. Cut
it when the reference exists — it is that repo's edit, so it goes as a
note to `~/handoff-inbox/<estate-repo>/`, not as a direct write.

## Re-plan — 2026-09-27

This repo's queue moved into each brief's frontmatter on 2026-09-27, and
`handoff-status.py` now generates the view, audit follow-ups included.
That superseded invariant 1 as written, the core's first line, so the
three Q1 edits are re-planned here, with none yet drafted to undo.
Invariants 1, 4 and 9 above are corrected in place.

**The other repos moved without any of the three.** Measured the same
day: `machine-config`'s stub carries direction and visibility but no
backlog declaration, and still points at this repo's `execute/README.md`
for the queue rules, which now describe the frontmatter form, not its
index. The estate repo's stub and the second client repo's, written with
its first brief, carry all three fields, and each opens "This is the
only place the execution order lives": invariant 1 in its index form,
still true there. Each also restates the brief shape in prose, the
second client repo's under "Conventions", so the flagged duplicate is
now two.

1. **The invariants reference** goes in `skills/meta/learn/references/`,
   as decided, now carrying invariant 1 as corrected 2026-09-29 and the
   frontmatter keys. `handoff-status.py` is what validates the keys, and
   `docs/handoffs/CLAUDE.md` here keeps its own table, which has to load
   before a brief here is touched. So a key change edits the script, that
   table and the reference together, and since 2026-09-29 is also a note
   to every repo holding a copy of the table (see
   [Decision](#decision--2026-09-29)). `lint-briefs` rejects a key the
   script does not know, which surfaces a documented key it lacks once a
   brief uses one; nothing catches the reverse, or a stale reference.
2. **The Copilot instruction port** is unchanged: nothing in it touches
   the queue.
3. **The per-repo stubs** are written, by their own repos. The one note
   per repo planned here for after edit 1 went out 2026-09-29, ahead of
   it and widened to the move itself; see
   [Decision](#decision--2026-09-29). It carries `machine-config`'s
   backlog declaration, and re-aims that repo's queue-rules pointer at
   this repo's `docs/handoffs/`, since the reference does not exist yet.
   The brief-shape cut does not go out with it; the Decision says why.

## Decision — 2026-09-29

**Every repo the user works in moves to per-brief frontmatter**, not
only one whose sessions collide on its index, because it is "better for
potential parallel work as it comes", in the user's words. That
reverses what this brief recorded on 2026-09-27 under "What this does
not propose": a repo with an index would keep it, and frontmatter would
be offered to a repo only once its sessions collided. The two
reference-only client repos are excluded by the user's call.

**One note per repo went to `~/handoff-inbox/<repo>/` the same day**,
each named `2026-09-29-handoff-state-per-brief.md`:

| Repo | Briefs | The note asks for |
| --- | --- | --- |
| client estate repo | 6, indexed | frontmatter on each, the queue table cut, the root pointer re-aimed |
| second client repo | 3, indexed | the same |
| `machine-config` | 2, indexed, dated names | the same, the briefs renamed to their subjects, and the missing backlog declaration |
| `fabric-tools`, `personal-scripts` | none | one root `CLAUDE.md` line now; the directory and its stub come with the first brief |

Each note carries the key table and a draft of every brief's values,
leaving the priorities to the user. **The root pointer is the edit that
matters in each repo**, for finding 2's reason in
[Decisions](#decisions--2026-09-16): writing a brief is a Write, which
loads no nested file, so only a root instruction file reaches the
session writing a repo's first brief.

**No tooling is copied**, so "No tooling copied into other repos" above
still holds. A repo prints its view by running this repo's script by
path, with `uv run --no-project`. That took 0.55 s, measured
2026-09-29 from inside a repo with its own `pyproject.toml`, which plain
`uv run` would have synced first. A clone without this repo, whether a
teammate's or CI's, reads the same state with one `grep` over the keys.

**The estate repo names no personal repo in its files**, a rule its own
session reported that day as the user's. The rule is not yet in that
repo's committed files. Under it, the estate repo's view command stays
out of its committed files, where the grep does the job. The rule also
voids the cut-to-a-link planned for its brief-shape prose, since a link
there would name this repo. So that prose stays as its own copy, and
the flagged duplicate becomes a copy kept on purpose. Whether the second
client repo follows the same rule is the user's call. Until then, its
note offers the path-free form too.

**This brief does not wait on the notes.** Each lands in its own repo,
on its own session's time, and the sweep lists each note until that
repo deletes it. This brief lands with edits 1 and 2. The Verification
below is the cold check on the notes, once they have landed.

## Open questions

None remain. All four are answered below, each pointing at where its
answer is recorded.

1. **Answered 2026-09-16 — extend `/learn`.** See
   [Decisions](#decisions--2026-09-16). The argument this question
   originally made against the rule form is retracted there; the rule
   form is ruled out on activation mechanics instead.
2. **Answered 2026-09-16 — the inbox widens**, routed by destination.
   See Decisions.
3. **Answered 2026-09-16 by the estate repo, recorded 2026-09-18 —
   yes, with measurement promoted first.** Asked whether a client repo
   wants the ledger rule instead. It does not, and the split is not
   per-repo. See
   [Q3 and Q4](#q3-and-q4--answered-by-the-estate-repos-index).
4. **Answered the same way — no collision; the index declares its
   relation to any tracker.** Asked whether a client repo's index
   duplicates a real tracker. That repo has none, and its index names
   the condition under which it would narrow to agent-executable work.
   Now invariant 9.

## Verification

The convention is working when, in a fresh session in any repo the
user works in, the agent can answer "what handoff work is open here,
and what can run at once" from `handoff-status.py`, or the one `grep`
where a repo names no personal repo, without reading every brief. Test
it cold in each repo, once its 2026-09-29 note has landed. That includes
the estate repo, whose subject matter is furthest from this one and is
the real test of whether the core generalized or just described this
repo in general-sounding words.

Two corrections to that criterion. It is **two commands**: the view
answers what is open *here*, which was one in-repo index until
2026-09-29, and `ls ~/handoff-inbox/<repo>/` answers what has been
routed here and not yet triaged. And all three legs became testable on
2026-09-16, when
`machine-config` and the estate repo each indexed their directories. No
cold test has run in either yet.

The **cross-repo** form of the question — what is open anywhere — is
answered by `uv run scripts/handoff-status.py`. Its first run, on
2026-09-18, read all three indexes, 13 indexed briefs and 5 inbox
notes, with no unindexed brief and no dangling row. It also showed
`machine-config` indexing with a bulleted list rather than a table and
naming its briefs by date, against invariant 2; the sweep reports that
and does not fail on it, since a repo's own convention wins.

## Dependencies

- **Settled 2026-09-16.** The first instance moved to
  `machine-config/docs/handoffs/execute/gh-account-path-shim.md` and was
  indexed by a stub written to this brief's Q1 shape, with that repo's
  `CLAUDE.md` pointing at it. Verified here against the three commits
  (`d5476c9`, `d53310a`, `beb9e67`) and the files themselves, rather
  than taken on report. **The shim brief is spent**: its change landed
  and `machine-config` deleted it the same day in `3959ee5`, so that
  path no longer exists. `git show 3959ee5^:docs/handoffs/execute/gh-account-path-shim.md`
  there recovers it. The stub outlived it and indexes that repo's
  current briefs.
- No dependency on the shim brief's *outcome* — this is about the
  convention, and stands whether that change is made or declined.
- **Blocked by `queue-state-per-brief.md` until it landed, 2026-09-27**,
  since that brief's last step was this re-plan.
