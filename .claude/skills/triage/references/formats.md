# What triage writes besides an edit

Four shapes: a brief made from a learning, the decline ledger, a note
for another repo, and the commit message that replaces the notes.
[SKILL.md](../SKILL.md) says when each is written.

## A brief made from a learning

One file per subject in `docs/handoffs/execute/`, named for the subject,
with no date and no number: the filename is a link target.
`docs/handoffs/CLAUDE.md` holds the frontmatter keys. The body below is
the shape that held for the briefs written from notes on 2026-09-22 and
2026-09-30.

```markdown
---
status: open
priority: 2
needs: []
blocked-by: []
written: <today>
---

# Handoff: <the subject, as a statement>

- **Written**: <today>, from <how many> inbox note(s) of <their dates>
  by <the kind of session, in the kind of repo>. Re-measured against the
  payload at `<HEAD's short sha>`, which <what moved, or changed nothing>.
- **Kind**: <an edit | a decision, the user's | an investigation>, and
  what is or is not drafted.

## <One section per item>

<What is true, first. Then how it was established: the note's
measurement with its date, and this run's re-measure with today's. A
correction to the note is stated as one.>

## Where it lands

<The file and heading, and what that file's own rules will owe.>

## Not checked

<What this run did not re-run, and what would.>

## Scrubbing

<Only where a source was raw: what is cited by kind.>

## Re-measure before acting

<The commands a later session runs first, with today's answers.>
```

- **`priority`** is a draft for the user: `1` for a defect live on this
  machine now, `3` for what costs nothing to leave, `2` otherwise.
- **`needs`** is `[]` only where a session can act alone. `user` marks
  every decision, and every kind "What may land" says a note can never
  move; `tenant`, `desktop` or a short phrase marks the rest.
- **`status: deferred`** takes a `reopen-when` naming the trigger, which
  `lint-briefs` requires.
- **No plain value opens with a backtick, a quote or another YAML
  indicator**, and none holds a colon then a space, or a space then a
  `#`: `lint-briefs` fails each.
- **Group by destination, not by note.** Items that resolve together
  share a file; items that resolve apart do not.
- **Keep evidence status per item**: measured here, measured by the
  note's session, inferred, or never tested. A note that marks its own
  inferences has done the useful part, and a brief that flattens them
  loses it.
- **A brief made from audit follow-ups** says so in its **Written**
  line: from how many, each linked at its `completed/` path. It needs
  no Scrubbing section, since the ledger is public already, and copies
  none of a follow-up's evidence
  ([audit-follow-ups.md](audit-follow-ups.md) § 4).

## The decline ledger

`docs/handoffs/declined.md`, one file, created at the first decline with
this header. `/triage` reads it before any verdict and is its only
writer. `scripts/handoff-status.py` reads it as a ledger, not a brief.

```markdown
# Declined

Learnings that reached this repo's inbox and were refused. `/triage`
reads this before it gives a verdict, and is its only writer. Entries
are dated and never corrected in place: a learning that comes back with
new evidence gets a verdict, or a new entry.
```

Each decline appends one entry at the end:

```markdown
## <yyyy-mm-dd> — <the learning, in a line>

- **From**: a note of <its date>, by <the kind of session, in the kind
  of repo>.
- **Why not**: <a reason the next reader can test>.
- **Would change it**: <the evidence or the event>.
```

The heading is what step 3's grep finds, so write the learning with the
token a later note would use for it.

## A note for another repo

`~/handoff-inbox/README.md` is the contract; read it before writing one.
A whole note that is misrouted moves as it is. A single learning out of
a note is written fresh as `<yyyy-mm-dd>-<topic>.md` in the other repo's
directory, opening with the three lines that README asks for:

```markdown
- **Origin** — <the repo or workspace it came from, cited by kind>, by
  way of this repo's inbox on <today>.
- **For** — <what should act on it there>.
- **Scrubbing** — <which content is raw and which is genericized>.
```

The inbox is private, so between two of its directories a measurement
is copied exactly and nothing needs genericizing. Say which parts are
raw: the session that lands it may be writing into a public repo.

## The commit message that replaces the notes

The briefs, folds and ledger entries go in one `docs(handoffs):` commit,
and its body is the record of what was deleted. It says, in prose:

- how many notes there were and since when, and the commit they were
  re-measured against;
- what each became, grouped by destination, with the commits that hold
  what landed;
- each correction to a note, stated as a correction;
- what was already landed, with its commits;
- that the user approved the deletion, or did not.

`3bf1fb5`, `c7a900e` and `3a62ed8` are the precedents. Each Landed edit
is its own commit, under its destination's scope, and says in a line
that it came from an inbox note and what kind of session wrote it.
