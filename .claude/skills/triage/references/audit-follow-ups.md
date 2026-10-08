# Sweeping an audit's open follow-ups

What changes when `/triage` takes its learnings from `docs/audits/`
rather than from the inbox. [SKILL.md](../SKILL.md)'s steps all hold;
this file gives the differences, under the step each belongs to.

A follow-up is a brief that `/drift-update` stamped escalated, deferred
or applied with deferrals, and whose log no `**Closed**:` line has
discharged. Its work waits in a log that has no priority, no deferral
and no claim, so nothing in the view ever reads as the next thing to
do: the ten of 2026-09-07 and 2026-09-10 went untouched from
2026-09-27, when their `**Needs**:` lines went in, to 2026-10-07. A
sweep carries what is still worth doing to `docs/handoffs/execute/`,
where a brief has all three, and closes the follow-up in the ledger
with a line saying where its work went. Decided 2026-10-07; the
reasoning is in `docs/handoffs/execute/README.md` § "Audit briefs are
a second queue". A run left with nothing open is then retired whole,
once a later run of its source exists, on the user's yes (step 8;
decided 2026-10-08).

## 1. Take stock

An argument under `docs/audits/` names the source: a date directory
takes every source under it, and `<date>/<source-id>` takes one.

```bash
uv run scripts/handoff-status.py . --no-inbox       # its audit half lists every open follow-up
git worktree list                                   # a <date>-<source-id> worktree: that pass is running
sha256sum docs/audits/<date>/<source-id>/[0-9]*.md  # keep: step 6 compares before each Closed line
```

- **The follow-ups are what the view's audit half lists** under the
  named directories. `audit-status.py` decides which are open, in
  `follow_ups()` beside `OPEN_OUTCOMES`, so take its word over a
  folder's.
- **A brief never run is not one.** The view prints its directory under
  `not executed: /drift-update`: name it in the report and leave it.
- **A pass still running is left whole**: a worktree named
  `<date>-<source-id>` (`/drift-update` step 2), or a peer in
  `ListAgents` at work in the directory.
- **A named run with nothing open is no sweep.** If
  `uv run scripts/audit-status.py --retirable` lists it, the run goes
  straight to step 8's question, which is how `/drift-handoff` hands one
  over; if not, say so and stop.
- **Size the batch** as SKILL.md says. The ten September follow-ups ran
  to 2,202 lines (2026-10-07).

## 2. Read each follow-up whole

- **The body and the log hold different halves.** The log says what is
  open, and its last `**Needs**:` line what that waits on, since a
  repeated key keeps its last value. The body holds the evidence, and
  the constraint the open work still owes, such as "if a property
  cannot be observed, leave it out".
- **The unit is still the learning.** One follow-up can hold two that
  resolve apart, and several can hold one that resolves together, as
  briefs waiting on one export do.
- **Name each by its source and number**, `powerbi/04`, with a learning
  number where one splits: `powerbi/13.2`.

## 3. Re-measure what it waits on, too

**The block is a claim like the rest.** Re-run what the `**Needs**:`
line names: a release (`<tool> --version`, then the property or command
it lacked), a CLI on `PATH` (`command -v <cli>`), the audit it waits for
(`ls -d docs/audits/*/<source-id>`), a brief it depends on (the view).
On 2026-10-07 `pbir` 0.9.29's schema listed matrix and donut properties
that 0.9.7's lacked, which one follow-up named as its way past Desktop,
and the `powerbi` audit another awaited had run on 2026-10-06 and closed
nothing.

- **Re-measure a dependency first.** A follow-up that waits inside
  another's session moves with that one's verdict.
- **A later audit of the same source may own the work now**: a newer
  follow-up that owes the same re-check, or a brief that re-scoped the
  same registry entry. Then the older one is Covered by it.

## 4. Give each one verdict

SKILL.md's table holds, first match wins, Stays second. Every verdict
but Stays closes the follow-up, with one line appended to its log:

| Verdict | Its log gains |
| --- | --- |
| Covered | `- **Closed**: <today> — covered, by /triage: <what did it, with its sha or the newer brief's path>.` |
| Stays | nothing, or a fresh `**Needs**:` line where what it waits on changed |
| Misrouted | `- **Closed**: <today> — sent by /triage to <the repo, or its kind for a client's> inbox: <the note's name>.` |
| Declined | `- **Closed**: <today> — declined at /triage: <a reason the next reader can test>. Would change it: <the evidence or event>.` |
| Folded | `- **Closed**: <today> — carried by /triage to docs/handoffs/execute/<brief>.md: <what it carries, in a line>.` |
| Landed | `- **Closed**: <today> — landed by /triage: <file> § <heading>.` |
| Briefed | the same line as Folded |

- **Stays is a re-check that the next audit of its source performs,
  while no audit of that source has run since.** The audit pipeline
  owns that one, and carrying it would only move the wait. Once such an
  audit has run without doing it, the follow-up falls through to the
  rows below.
- **A decline goes in the Closed line**, never in `declined.md`, whose
  entries are inbox learnings: `2026-09-07/powerbi/07` closed as
  declined is the precedent.
- **Folded and Briefed copy nothing.** The brief links the follow-up at
  its `completed/` path, where step 6 files it, and carries only the
  open work and this run's re-measure: the ledger keeps the evidence.
  A brief that already cites the follow-up is the likeliest fold.
- **`completed/` then means nothing is left in the ledger**, not that
  the work is done. The Closed line says where the work went, and when
  that brief lands and is deleted, the line stays as written, until
  the run itself is retired.
- **A decision still open is the user's.** It is Briefed with
  `needs: [user]`, unless the user answers it at the table, which makes
  the row theirs.
- **"What may land" holds unchanged**, rule 5 included: a follow-up is a
  past session's plan, and moves no permission, setting, hook, MCP
  config or deploy script.

## 5. The table

Each row names its follow-up, and the Closed line it would gain or why
it stays. No note is deleted, so the questions are whether to apply the
table and commit it, and whether to retire each run the commit would
leave retirable: every brief finished, and a later run of its source on
disk.

## 6. Carry out what was approved

After the edits, folds and briefs that SKILL.md orders:

1. **Re-hash each follow-up** and compare with step 1. One that moved
   was edited after this run read it: read it again and re-judge it.
2. **Append its line at the end of its log** with `Edit`, after its
   last key. Every line above stays as written: a stamp is never
   corrected in place.
3. **Regenerate each directory's index**, which files every closed
   brief under `completed/`:

   ```bash
   uv run scripts/audit-status.py --dir docs/audits/<date>/<source-id>
   ```

4. **Re-point every live link to a moved brief**, in the same commit.
   Outside `docs/audits/`, every hit is live; inside it, only the index
   changes, regenerated, and a stamped brief's text stays as written.

   ```bash
   grep -rn "<date>/<source-id>/<NN>-" --include='*.md' . | grep -v '^\./docs/audits/'
   ```

Then `handoff-status.py . --check --no-inbox` and
`pre-commit run --all-files`, once each, as SKILL.md says:
`lint-audit-index` fails a commit whose index disagrees with its
briefs, or whose brief sits on the wrong side.

## 7. Commit

**A Closed line lands in the commit that does what it says**: beside
the brief or fold it names, as `docs(handoffs):`, or beside the edit it
records, under that edit's scope. Never before: a line naming a brief
not yet committed points at nothing. The regenerated index and the
re-points ride with it. The message says what each follow-up became,
and the Closed lines say it again in the ledger.

## 8. Retire what a later run supersedes

SKILL.md's step 8 deletes notes. Here a follow-up ends at its Closed
line, and `audit-status.py` alone moves it, but a whole run is retired
once it is spent: every brief finished, and a later run of its source
on disk. `uv run scripts/audit-status.py --retirable` lists each such
run, and `handoff-status.py` prints the same list. The newest run of a
source is never listed, finished or not: the next audit of that source
starts from it, as the 2026-10-06 `powerbi` run took its floor from the
2026-09-07 directory. Decided by the user on 2026-10-08, ending the rule
that kept finished runs whole; git history is a retired run's archive.

On the user's yes, and only once the commit that closed the run has
landed, for each run:

1. **Note the commit that last holds it**: `HEAD`, right after that
   closing commit.
2. **Re-point every live link into it** to that commit, in the form
   `git show <sha>:<path>`, since a path into a deleted directory finds
   nothing. Inside `docs/audits/`, leave reports and stamped briefs as
   written.

   ```bash
   git grep -n "<date>/<source-id>/" -- . ':!docs/audits/'
   ```

3. **Delete it**: `git rm -r -q docs/audits/<date>/<source-id>`.
4. **Commit through `/commit`** as `docs(audits): retire …`, the
   re-points with the delete, the message naming the commit that last
   holds the run.

To read a retired run later, find the commit that deleted it, then show
any file as it stood just before:

```bash
git log --diff-filter=D --format=%h -1 -- docs/audits/<date>/<source-id>
git show <that-sha>^:docs/audits/<date>/<source-id>/00-audit-report.md
```

## 9. Report

Per follow-up: its verdict, its Closed line or why it stays, and the
commit that holds it. A directory left with open follow-ups says how
many, and why each stays. Each run retired names the commit that last
holds it.
