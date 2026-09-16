# Brief: a cross-repo handoff convention

**Status:** Open, written 2026-09-16. Nothing drafted. Four open
questions below must be answered before anything is written, and one of
them decides the artifact's form.

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

## Open questions — answer before drafting

1. **What form does the convention take?** A `README.md` in each repo's
   handoff directory duplicates prose three ways and will drift, which
   is the argument that killed this repo's second instruction file. A
   path-scoped rule (`claude/rules/`) auto-loads when a brief is opened
   in any repo and lives in one place — but it is guidance for a human
   convention, which is not what rules have been used for. A `/handoff`
   skill would be reachable everywhere, like `/learn`, and could write
   the brief *and* update the index — but skills are verbs, and this may
   not be one. **This is the question that decides everything else**,
   and it is a genuine three-way call.
2. **Does the inbox stay payload-only?** It is documented as such, with
   two writers and one reader. A learning routed from the estate repo to
   `machine-config` currently has nowhere to land, which is what
   produced a direct cross-repo write on 2026-09-16. Widening it means a
   second reader and a routing decision per note.
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
