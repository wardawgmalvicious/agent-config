# Brief: a cross-repo handoff convention

**Status:** Open, written 2026-09-16. Nothing drafted. **All four
questions are answered**: Q1 and Q2 the same day — see
[Decisions](#decisions--2026-09-16), which also records four findings
that reframed Q1 and retracts one of this brief's own arguments — and
Q3 and Q4 by the estate repo's own index, also written 2026-09-16 and
recorded here 2026-09-18 — see
[Q3 and Q4](#q3-and-q4--answered-by-the-estate-repos-index). What
remains is execution: Q1's three edits, none of which exists yet.

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

Measured 2026-09-16 across the three repos.

| Repo | Visibility | Briefs | Index | A brief is about |
| --- | --- | --- | --- | --- |
| this one | public | 6 open in `execute/`, plus `docs/audits/` | yes — `execute/README.md` | payload: skills, rules, hooks |
| `machine-config` | private | 1, in `execute/` | yes — `docs/handoffs/README.md`, added 2026-09-16 | machine setup: shells, PATH, installed tooling |
| client estate repo | internal | 3, in `execute/` | yes — `execute/README.md`, added 2026-09-16 | estate work |

**The brief shape is already converging without coordination.** All
three of the client repo's briefs carry a `**Status:**` line; two cite a
measured or verified claim; the `machine-config` brief was written to
the same shape from this repo. Nobody standardized that.

**The index was missing everywhere but here**, and that is the part this
repo learned the hard way — that ordering must live in exactly one file,
that positions churn so filenames must not carry them, and that a spent
brief left in a queue invites re-execution. Both other repos closed that
gap the same day — `machine-config` and then the estate repo, which was
the last without one (the table above records it corrected 2026-09-18).

So the deliverable is **not a shared brief template.** A template would
have to span skill authoring, shell configuration and estate work, and
would collapse into either uselessly generic headings or this repo's own
concerns imposed on two repos that do not share them. The deliverable is
a short contract plus a per-repo index.

## Proposed: a minimal common core

Nine invariants — eight as written 2026-09-16, and a ninth added
2026-09-18 when Q4 was answered. Everything else stays per-repo.

1. **One index per repo, and it is the only place order lives.** A
   brief carries its dependencies; it never carries its position.
2. **Stable filenames, subject-named, no dates and no positions.** The
   filename is the link target. Dates go inside.
3. **Self-contained and readable cold.** A brief that only makes sense
   to the session that wrote it has failed.
4. **A status line**: state, the date written, and what it waits on.
   Already emergent in all three repos.
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
9. **The index says whether it is the backlog.** Either it is the only
   one, or it is scoped to agent-executable work beside a named tracker.
   Per-repo, declared in the stub beside direction and visibility.

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

A directory should say which of these it accepts. Today none does.

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

The convention is working when, in a fresh session in any of the three
repos, the agent can answer "what handoff work is open here, and in what
order" from one file, without reading every brief. Test it cold in each
repo — including the estate repo, whose subject matter is furthest from
this one and is the real test of whether the core generalized or just
described this repo in general-sounding words.

Two corrections to that criterion. It is **one file plus one command**:
the in-repo index answers what is open *here*, and
`ls ~/handoff-inbox/<repo>/` answers what has been routed here and not
yet triaged. And all three legs became testable on 2026-09-16, when
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
  `machine-config/docs/handoffs/execute/gh-account-path-shim.md` and is
  indexed by a stub written to this brief's Q1 shape, with that repo's
  `CLAUDE.md` pointing at it. Verified here against the three commits
  (`d5476c9`, `d53310a`, `beb9e67`) and the files themselves, rather
  than taken on report.
- No dependency on the shim brief's *outcome* — this is about the
  convention, and stands whether that change is made or declined.
