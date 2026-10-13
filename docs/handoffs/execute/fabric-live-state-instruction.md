---
status: open
priority: 2
needs: [user]
blocked-by: []
written: 2026-10-13
---

# Handoff: whether every session is told to read Fabric's live state by REST before asking the user to look

- **Written**: 2026-10-13, from one inbox note of 2026-10-13 by a
  session in a client Fabric estate repo, whose own agent instructions
  had made this their first rule. Re-measured against the payload at
  `cf7a595`, which changed nothing the note names.
- **Kind**: a decision, the user's, then an edit. A candidate sentence
  is drafted below; the room it needs in `claude/CLAUDE.md` is not.

## The pattern

A session that needs a Fabric workspace's state reads it itself, with
read-only REST calls, rather than asking the user to look in the portal
or to commit from it so the session can read the result:

| Question | Read-only call |
| --- | --- |
| Is the workspace at its branch's head, and what is uncommitted? | Get Status, `GET …/git/status` (long-running) |
| What does a live item hold? | `POST …/items/{id}/getDefinition` (long-running), against the committed files |
| Is a schedule on, what controls it, when does it next read its variable? | List Item Schedules |
| Did it run? | List Item Job Instances |
| Is the workspace connected to Git at all? | Get Connection |

The user is left with what only the portal does: in the estate, setting
an Activator rule, or selecting **Update** on a running one. A write,
an update from Git among them, follows each repo's own rule for which
environment a session may change. The estate updates its first stage
unasked after a push, its second only on the user's word, and reaches
its last two only through deployment pipelines; another repo may have
no first stage at all. So only the read half can be global. The write
half stays with each repo, and fabric-tools carries a template for it
(its own inbox note of 2026-10-13).

## Why, and what it costs

Measured by the note's session in the estate:

- About ten round trips on 2026-10-12 and 2026-10-13 went this way,
  where each had meant the user selecting **Update all** and reporting
  what the workspace showed; the user judged that it needed little
  direction from them.
- One List Item Schedules read answered what the portal's Schedules
  pane could not: whether a binding had been read yet, and when it
  would be.
- A read is a snapshot. One schedule read `enabledEvalState: null` at
  18:22 UTC and `Normal` at 18:42, and the session had already recorded
  the first as an open question; the reads are in
  [schedule-controller-serialization.md](schedule-controller-serialization.md).

How to make the calls is in `fabric-rest-api` already: a `202` to poll,
which `az rest` hides, and `git/status` types outside Learn's enum (both
re-read here, 2026-10-13). So is pinning the tenant before any `az`
call, in `claude/CLAUDE.md`.

## The homes

| Home | Loads | Cost | Misses |
| --- | --- | --- | --- |
| `claude/CLAUDE.md`, beside line 3's Power BI / Fabric sentence | every session, before any Read | 357 characters for the candidate below, five wrapped lines' worth, in a file at its 200-line cap | nothing |
| A section of `claude/rules/fabric-git-serialization.md` | a Read of a Fabric item folder or a `.platform` file | no `CLAUDE.md` room | a session that asks about live state and opens no item file |
| `fabric-rest-api`'s `description` (580 of 1,024 characters) or `when_to_use` (430 of 512) | the listing, in every session | an activation retest | says how to make the calls, not to make them unasked |
| Each repo's own instructions, as now | that repo | nothing global | every repo has to adopt it; one has |

Line 3 of `claude/CLAUDE.md` is already one unwrapped line of 432
characters, so appending there would keep the line count, but
`.claude/rules/editing-claude-md.md` meets the cap by moving lines out,
never by lengthening one. That room is what
[claude-md-path-traps.md](claude-md-path-traps.md) waits on too, about
four lines, so the two would land with one move.

The note recommends `claude/CLAUDE.md` for the read half: the user's
daily work is Fabric across several repos, the read half is safe in all
of them, and it is the only home that loads before any file is open.
The user, on 2026-10-13, thought it would make sense at a global level
but was not sure yet.

A candidate, in the file's style:

> **Read a Fabric workspace's state yourself before asking the user to
> check it:** sync state, an item's definition, a schedule and a run are
> read-only REST calls (`fabric-rest-api`), so the user keeps only what
> the portal alone can do. A write, an update from Git included, follows
> the repo's own rule for which environment a session may change
> (2026-10-13).

## Where it lands

On a yes for `claude/CLAUDE.md`: the sentence; its evidence under the
same heading in `docs/evidence/user-claude-md.md`, the round trips and
the two reads above; the lines moved out to make room; and the deploy,
`./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`. On
a yes for the rule: a section there, and the deploy without `-Force`,
`./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`. On a no:
an entry in `docs/handoffs/declined.md` saying what would change it.

## Not checked

How often a session asks the user to look in the portal outside the
estate: no transcript was searched.

## Scrubbing

The estate's environment names, its pull request, its script's path and
its rule's wording stay out; its stages are named by their order.

## Re-measure before acting

- `uv run scripts/lint-claude-md.py`: 200 of 200 lines on 2026-10-13.
- `awk 'NR==3 {print length}' claude/CLAUDE.md`: 432 on 2026-10-13.
- `grep -rln -i "live state" claude/CLAUDE.md claude/rules/`: only
  `fabric-git-serialization.md`, on other subjects, on 2026-10-13.
