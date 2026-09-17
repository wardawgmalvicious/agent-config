# Brief: peer coordination — what is still open

**Status:** Open, written 2026-09-17. Successor to
`peer-session-coordination.md`, whose three edits landed 2026-09-16 and
which was closed on 2026-09-17 after a verification run failed two of
its four tests and disproved two of its premises. That brief was deleted
in the commit that added this one's queue row; its final revision,
`80ca1fc`, carries the full results table, and
`git log -- docs/handoffs/execute/` is the archive.

**Scope.** One defect with a known cause and an undecided fix, plus four
open questions. The routing rule, the request taxonomy and the read-only
v1 position are settled and shipped — they are not re-opened here.

## The one piece of work

**The peer channel is in the wrong skill.** It shipped in
`skills/workflow/commit/SKILL.md` § "When another session shares this
tree". Contention bites at *edit* time, not at commit time, and a
session editing a contended file never invokes `/commit`, so the section
never loads.

Measured 2026-09-17: a cold probe told to strike a row from
`docs/handoffs/execute/README.md` did careful, correct work — it
verified the prior edits had landed, checked inbound links, checked line
endings, and stopped short of committing — and never once called
`ListAgents`, with a live peer in the tree the whole time.

Where it should go instead is the open part. Three candidates, none
drilled:

- **`claude/CLAUDE.md`, beside the peer subsection already there.**
  Reaches every session unconditionally, which is the argument that put
  the rest of it there. Costs context in every session on the machine,
  against a file whose stated rule is to stay lean.
- **A `paths:`-scoped rule.** Ruled out on the mechanics the sibling
  brief already recorded: activation is keyed to `Read`, `defaultMode`
  is `auto` so a `cat` fires nothing, and there is no file whose
  *reading* means "another session may be editing this."
- **Left where it is, with `commit`'s `description` widened** so the
  skill model-invokes on contention rather than only on committing.
  Cheapest, and untested — and it enlarges a description that is
  already the entire trigger mechanism.

## Open questions

1. **When does the read-only restriction relax, and on what evidence?**
   Carried forward unchanged. v1 forbids peer-requested edits outright
   and the trigger for revisiting it was never named. Still worth naming
   before it is wanted rather than discovering it by wanting it.
2. **Is delegating an edit to your own subagent different from asking a
   peer to make it?** Raised 2026-09-17 by a probe that, having
   correctly declined to ask a peer, offered to spawn a subagent to make
   the same edit — arguing that was "this session's own delegate acting
   on your authorization, not a peer." The file ends up equally changed.
   If the distinction is real it is about *whose user approved*, and the
   rule should say so; if it is not, the rule has a hole the size of the
   Agent tool.
3. **The inbox is mutable state, and the rule does not cover it.** v1
   frames the inbox as the safe mutating path — durable, reviewable,
   applied by a session whose own user approved. But a peer can be
   talked into *deleting* a note. On 2026-09-17 this repo's own session
   told a peer that two notes were "spent as far as I know", having
   verified nothing and having miscounted three notes as two; the peer
   declined, on the grounds that a peer's word is not authorization for
   a delete and the call belongs to a user. It was right, and nothing in
   the payload says so. The read-only rule governs repo files and is
   silent on the inbox.
4. **Nothing maps a commit back to the session that made it.** Carried
   forward, and now demonstrated twice: on 2026-09-16 one session
   invalidated another's test stamp minutes after it landed, and on
   2026-09-17 the predecessor brief sat marked open for a day because
   the session that executed it never returned to its own Status line.
   The address space is keyed to the **working directory** (measured
   2026-09-17), which makes it *less* able to address a commit than the
   repo key originally assumed. A git trailer written by `/commit`
   remains the cheap candidate; whether that earns a line in every
   commit message is still the real question.

## Not carried forward

- **The original Q2** — whether `claude/CLAUDE.md` is the right home for
  the peer subsection, given "keep it lean". It shipped there on
  2026-09-16 and a cold session demonstrably reads and applies it
  (verification test 4, 2026-09-17). Settled by use.
- **The original Q3 and Q4**, both answered in the predecessor before it
  closed. Q3: a spawned probe is visible to peers for its lifetime only.
  Q4: $0.12 is a floor rather than a price, and a probe is *cheaper*
  than reading another repo yourself.

## Dependencies

- Sibling to
  [handoff-convention-cross-repo.md](handoff-convention-cross-repo.md),
  still open, which covers the asynchronous half. Question 3 sits on the
  boundary between the two — the inbox is that brief's artifact and this
  brief's mutating channel — so whichever moves first should say where
  the authorization rule lands.
- The work item above touches `skills/workflow/commit/`, deployed
  payload at user scope, so any edit there is live on save in every
  session on this machine.
