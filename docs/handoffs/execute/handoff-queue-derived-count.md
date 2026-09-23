# Handoff: the queue's count line is the contended string

- **Written**: 2026-09-22, from the user's question about guiding
  concurrent sessions that change repo state — after they narrowed the
  problem themselves: two sessions never work the same item, and the one
  time it happened it was operator error. What recurs is two sessions
  doing **different** work both writing back to one index.
- **Kind**: one prose deletion in [README.md](README.md), or one script
  change in
  [`scripts/handoff-status.py`](../../../scripts/handoff-status.py).
  **No payload edit** — neither file deploys anywhere, so nothing here is
  live in another session on save.
- **Status**: **Open.** The choice between the two forms is argued below
  and recommended; nothing is drafted, and the recommendation is the
  user's to overturn.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## The collision is narrower than the rules assume

Two sessions striking two *different* rows do not collide at the tool
level. `Edit` is exact string replacement and two rows are two different
anchors, so neither write disturbs the other and neither needs the other
to have finished.

What actually collides is two things, and they are different problems
with different remedies:

1. **A whole-file rewrite** — `Write`, or `cat > file <<'EOF'`. This
   drops the other session's rows outright. It is what root
   `CLAUDE.md`'s *"re-read it immediately first"* protects against, and
   that rule stays necessary. It is a tool choice, not a property of the
   file.
2. **The count line.** Both sessions must touch it whichever row they
   came for. It is the one string two sessions doing otherwise disjoint
   work are **guaranteed** to fight over.

Only the second is structural. That is the whole finding: the recurring
concurrent-session collision in this repo is one sentence long.

## The repo already bans this shape of sentence

This is the stronger argument, and it has nothing to do with
concurrency. Root `CLAUDE.md` refuses restated totals in four separate
places, each with the drift that earned the rule:

> Don't restate that count — it read 41 and went stale the day the 42nd
> skill landed.

> **Don't restate the count here** — it read "eight" while the real
> figure was ten, having missed `prune-branches` and
> `linkedin-highlights` when each was authored.

> **don't restate a total anywhere else**, including here. This count was
> duplicated into six files, checked by nothing, and by 2026-09-02 had
> drifted three ways at once.

> Don't write a "still untested" list anywhere; the README carried one
> for four months and every skill on it had been edited since.

[README.md](README.md) opens with exactly such a total — *"Eleven items
remain on the queue: seven open and four deferred"* — and **nothing
checks it.** Measured 2026-09-22: `grep -rn "items remain\|remain on the
queue" scripts/ .pre-commit-config.yaml` returns nothing.

So two independent arguments land on the same remedy, and only one of
them is about concurrent sessions. The count line would be worth
removing if this repo had exactly one session, ever.

## It is already derivable, and the machinery is already written

[`scripts/handoff-status.py`](../../../scripts/handoff-status.py) has
every input needed to compute that sentence:

- `read_rows()` parses every table row and list item in a `README.md`
  under `docs/handoffs/`.
- It extracts each row's state from *"the row's first `**bold**` span,
  which is where every index here puts it; failing that, the heading the
  row sits under"* — so `**Open, written 2026-09-22**` and
  `**Deferred 2026-09-10**` are already read and already classified.
- Its own docstring states the design: *"Everything is DERIVED, as in
  audit-status.py -- no state is kept here."*
- `--check` already gates pre-commit on an unindexed brief, a dangling
  row, and an unrouted inbox note. It has never gated the count.

## The two forms, and why the smaller one wins

**Option 1 — generate it.** Give `handoff-status.py` a `--write` mode
that rewrites the sentence in place, plus a `--check` arm that fails on a
stale count, matching
[`scripts/audit-status.py`](../../../scripts/audit-status.py), which
does exactly this (`target.write_text(wanted, ...)`) for each
`docs/audits/<date>/<source>/README.md`.

**Option 2 — delete the sentence** and let `handoff-status.py` be where
the count lives. **Recommended.**

The argument against Option 1 is not cost, it is coherence.
`audit-status.py` generates a **whole** index out of brief metadata and
execution logs — that file has no author and `docs/audits/README.md`
says so: *"a generated `README.md` index"*, *"Never edited by hand"*. The
handoffs queue is the opposite: every row is hand-authored judgment,
several hundred words of it, that no script could produce. Generating
only the first sentence would leave one file that is part generated and
part authored with no marker saying which — worse than either, and a
standing invitation to hand-edit the generated half.

Option 2 also keeps a property root `CLAUDE.md` advertises in its command
listing: *"Reads, never writes."* That is worth more than a number a
reader can get from one command.

## What to keep

The paragraph is two sentences and only the first is a tally. Keep the
second — it makes a claim no count makes:

```text
Every deferral names the trigger that would re-open it; none has fired.
```

Proposed replacement for the opening paragraph:

```text
Every deferral names the trigger that would re-open it; none has fired.
Run `uv run scripts/handoff-status.py` for what is open and how long it
has sat.
```

Leave the dated `Re-measured 2026-09-11:` line further down alone. It is
a measurement with a date on it, not a restated total, and it is the kind
of thing the lifecycle section exists to carry.

## Verification

- `uv run scripts/handoff-status.py --check` still exits 0.
- `bash tests/scripts/handoff-status/test-findings.sh` still passes —
  the negative cases, since a gate firing on nothing looks identical to a
  gate that passes.
- `pre-commit run --all-files` clean.

Note the honest limit: **after the sentence is gone there is nothing to
verify**, which is the point rather than a gap in this section. What
replaces verification is that the number now has exactly one source.

## Scope — this repo's index only

`handoff-status.py` reads every `README.md` under `docs/handoffs/` in
every repo it sweeps, and the other indexes it finds may carry their own
totals. Whether "no restated totals" becomes a cross-repo index
invariant belongs to
[handoff-convention-cross-repo.md](handoff-convention-cross-repo.md),
which owns the nine-point core and the per-repo stub README — not here.
Do not widen this brief to touch another repo's index.

## Dependencies

- Sibling to
  [worktree-isolation-scope.md](worktree-isolation-scope.md), which
  covers the half of the concurrency problem a worktree **does** fix —
  the shared git index — and states plainly that it does not fix this
  one. A worktree makes this case worse: two worktrees are two branches,
  two divergent versions of this file, and a merge in a repo that has
  never had a merge commit.
- [handoff-convention-cross-repo.md](handoff-convention-cross-repo.md)
  owns any cross-repo generalization, per Scope above.
- Blocks nothing. Nothing blocks it.

## Sequencing note, which is also the demonstration

Landing this brief's own queue row required adding two rows and editing
the count line by hand — the exact operation the brief is about, done
twice in one session already during the 2026-09-22 commit split, where
stepping the count through `Ten` and `Eleven` was the fiddliest part of
the split. Strike the sentence in the same commit that strikes this
brief's row, so the file never sits in a state where the count is present
and wrong.
