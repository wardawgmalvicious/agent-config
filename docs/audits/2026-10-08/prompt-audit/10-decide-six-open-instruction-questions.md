# Handoff: decide six open instruction questions

- **Audit run**: 2026-10-08
- **Source**: `prompt-audit`
- **Window**: floor none, the whole payload → head `c268691`
  (2026-10-08)
- **Covers recommended actions**: decisions 1, 3, 4, 5, 6 and 7
- **Kind**: decision. Six questions the audit put to the user with no
  patch; worked by asking, never by editing ahead of an answer.
- **Target**: `skills/workflow/prune-branches/SKILL.md`,
  `skills/workflow/commit/SKILL.md`, `claude/CLAUDE.md`,
  `.claude/skills/test-skill/SKILL.md`,
  `.claude/skills/drift-update/SKILL.md`,
  `.claude/skills/author-skill/SKILL.md`,
  `.claude/skills/drift-audit/SKILL.md`

## The problem

Six items where the audit could see a conflict or a dated line but not
which side is right. Each needs the user's call before any edit, and
each answer then goes through its file's own route. Decisions 2 and 8
are in briefs 05 and 06.

Line numbers below are at `c268691`, and the quotes are the report's.

## Decision 1 — `prune-branches` switches with no live-session check

**Symptom.** At `prune-branches:249-251` the rescue runs `git switch`
with no check for a live session, which `land:487-489`,
`commit:33-35` and root `CLAUDE.md` § "Branching and concurrent
sessions" all forbid while a peer is live. Medium confidence.
**Suggested by the audit.** "Before either switch, run `ListAgents` and
read every row; with anyone else live, cut the rescue in a linked
worktree (`git worktree add -b <branch> <path> main`) instead."
**Settled.** `547eff8`, from a `/triage` of a client repo's prompt
audit on 2026-10-08 and approved by the user by name, makes the rescue
check for peers before it switches, pointing at `land` step 1, and ask
before rebasing. It took no worktree route. Unless the user wants that
route too, record this decision as already-applied.

## Decision 3 — two different branch triggers

**Symptom.** `commit:25-35` branches only when the repo lands by pull
request; `claude/CLAUDE.md` § "Branch naming" (136-139) branches when
the work is more than one commit or an intermediate state would break
while deployed. Both lines date from the same day, so history cannot
say which is current.
**Context.** Root `CLAUDE.md` § "Branching and concurrent sessions"
overrides the global trigger for this repo, and says to edit the two
together.
**Options.** The global trigger wins and `commit` cites it; `commit`'s
wins and the global line narrows; or both stay, each saying where it
applies.

## Decision 4 — `/test-skill` never closes an audit brief

**Symptom.** `test-skill:447-454` with `drift-update:342-352`:
`/test-skill` writes no `**Closed**:` line, so an audit brief whose
skill it confirmed stays open in the queue (`audit-status.py:272`).
Medium confidence.
**Fix the audit names.** `/test-skill` calls `audit-status.py` and
writes the line. Not patched, because the ledger policy changed that
day in `bde833c`.

## Decision 5 — the "do not hallucinate" line

**Symptom.** `claude/CLAUDE.md:3`: "…asking for clarification rather
than fabricating specifics". The audit reads it as an instruction
written for older models; it is the file's oldest line, older than the
platform-skill prune. Low confidence.
**Options.** Keep it, rewrite it to say what to do instead, or drop it.

## Decision 6 — "userPreferences has the summary"

**Symptom.** `claude/CLAUDE.md:199` points at a userPreferences
summary, but no userPreferences block reached the audit's session. Low
confidence.
**Open question.** Does any session this file serves receive one?
Keep the pointer where one does; otherwise drop it or name where the
summary lives.

## Decision 7 — `effort: max` on the Fable pins

**Symptom.** `author-skill:7` and `drift-audit:8` pin `effort: max`
on Fable 5.1. The audit cites the migration guide as suggesting Fable
start at `high`, while `.claude/rules/editing-skills.md` § "Invocation
and spend fields" puts `max` on every behavioural skill but `commit`.
Low confidence.
**Knock-on.** Lowering the pins changes that rule too.

## Verification

1. Each decision's answer, with its date, in the log.
2. Every edit an answer authorizes lands through its file's own route:
   a skill's lint and retest, `claude/CLAUDE.md`'s ledger entry and
   deploy with `-Force`.
3. `pre-commit run --all-files`.

## Provenance

Decisions 1, 3 and 4 (medium) and 5, 6 and 7 (low) from
`/doctor prompt-audit` run in this repo on 2026-10-08. The audit
proposed no patch for any of them.

## Execution log

- **Executed**: 2026-10-08 — escalated
- **Session**: fresh (no audit or handoff run in this session; the whole
  pass, in its own worktree)
- **Files changed**: none
- **Verification**: each decision's evidence re-read at `26f8582`
  before it was asked: `prune-branches:248` runs `ListAgents` before
  the rescue (`547eff8`); `commit:24-34` against `claude/CLAUDE.md:136-139`;
  `test-skill` step 10 appending a confirmation and no **Closed** line;
  `claude/CLAUDE.md:3` and `:199`; `effort: max` at `author-skill:7`
  and `drift-audit:8`. No ledger or `declined.md` entry had settled 3
  to 7. Step 1 — **done**: the answers below, all given 2026-10-08.
  Step 2 is the tasks under **Needs**. Step 3
  (`pre-commit run --all-files`) runs once at the end of the run.
  - **Decision 1** — no worktree route. Already applied by `547eff8`,
    which checks for peers before the rescue's switch and asks before
    rebasing.
  - **Decision 3** — the global trigger wins: `commit` step 4 takes
    `claude/CLAUDE.md` § "Branch naming"'s trigger and cites it. Root
    `CLAUDE.md`'s override for this repo stands.
  - **Decision 4** — yes: `/test-skill` step 10 appends **Closed** when
    its confirmation discharges an audit brief's last open item, and
    regenerates that directory's index.
  - **Decision 5** — rewrite `claude/CLAUDE.md:3`'s second sentence as
    what to do when a relevant skill is not loaded.
  - **Decision 6** — no session served receives a userPreferences
    block: replace "userPreferences has the summary" at `:199` with a
    pointer to the list that exists, `~/.claude/rules/README.md`
    § "What's here".
  - **Decision 7** — not decided: read the migration guide's effort
    advice for Fable first. Lowering the pins changes
    `editing-skills.md`'s effort bullet with them.
- **Deferred**: the work each answer implies, none of it started here.
- **Deviations**: none
- **Needs**: a session of its own, user — decision 3's edit to
  `commit` step 4 and decision 4's to `test-skill` step 10, each linted
  and retested; decisions 5 and 6's edits to `claude/CLAUDE.md`, with
  their `docs/evidence/user-claude-md.md` entries and a `-Force`
  deploy; decision 7's read of the guide, then the user's call.
