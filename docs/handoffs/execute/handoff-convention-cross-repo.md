# Brief: a cross-repo handoff convention

**Status:** Open, written 2026-09-16. Nothing drafted. **Q1 and Q2 were
answered the same day** — see [Decisions](#decisions--2026-09-16), which
also records four findings that reframed Q1 and retracts one of this
brief's own arguments. Q3 and Q4 remain open and neither blocks
drafting: under the chosen form both are per-repo policy that the
directory declares for itself.

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
| `machine-config` | private | 1, written 2026-09-16 | no | machine setup: shells, PATH, installed tooling |
| client estate repo | internal | 3 | no | estate work |

**The brief shape is already converging without coordination.** All
three of the client repo's briefs carry a `**Status:**` line; two cite a
measured or verified claim; the `machine-config` brief was written to
the same shape from this repo. Nobody standardized that.

**What is missing everywhere but here is the index**, and that is the
part this repo learned the hard way — that ordering must live in exactly
one file, that positions churn so filenames must not carry them, and
that a spent brief left in a queue invites re-execution.

So the deliverable is **not a shared brief template.** A template would
have to span skill authoring, shell configuration and estate work, and
would collapse into either uselessly generic headings or this repo's own
concerns imposed on two repos that do not share them. The deliverable is
a short contract plus a per-repo index.

## Proposed: a minimal common core

Eight invariants. Everything else stays per-repo.

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
8. **Delete when spent, or record the decision in place.** The queue
   rule, not the ledger rule — with the ledger exception kept, see the
   open questions.

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
- No shared tooling. This repo's `audit-status.py` and
  `skill-status.py` derive indexes from metadata; that is worth copying
  only if a repo's brief count justifies it, and one brief does not.
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

- the eight invariants go in `skills/meta/learn/references/`, read on
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
`link-claude.ps1 -SkillGroups workflow,social,meta -Force` runs. The
per-repo *index* pointer is the mirror of it at project scope, and is
the user's to make in each repo.

## Open questions

Q3 and Q4 below are still open. Neither blocks drafting — under the form
chosen above, both are per-repo policy that each directory's stub
declares for itself, so the contract only has to say *that* a directory
declares them, not which way.

1. **Answered 2026-09-16 — extend `/learn`.** See
   [Decisions](#decisions--2026-09-16). The argument this question
   originally made against the rule form is retracted there; the rule
   form is ruled out on activation mechanics instead.
2. **Answered 2026-09-16 — the inbox widens**, routed by destination.
   See Decisions.
3. **Does delete-when-spent suit a client repo?** Estate work plausibly
   wants the ledger rule instead — an audit trail of what was done and
   when. If so the split is per-repo rather than universal, and
   invariant 8 needs rewording.
4. **Does a client repo's index collide with a real tracker?** This
   repo has no Jira or Azure DevOps and its queue is the only backlog.
   A client repo usually does have one, and an index that drifts into
   project management duplicates it badly. The index may need to be
   explicitly scoped to *agent-executable* work only.

## Verification

The convention is working when, in a fresh session in any of the three
repos, the agent can answer "what handoff work is open here, and in what
order" from one file, without reading every brief. Test it cold in each
repo — including the estate repo, whose subject matter is furthest from
this one and is the real test of whether the core generalized or just
described this repo in general-sounding words.

## Dependencies

- `machine-config/docs/handoffs/gh-account-path-shim.md` is the first
  instance and is currently unindexed. Whatever lands should index it.
- No dependency on the shim brief's *outcome* — this is about the
  convention, and stands whether that change is made or declined.
