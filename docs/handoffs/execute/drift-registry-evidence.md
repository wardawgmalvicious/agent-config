---
status: deferred
priority: 3
needs: [user]
blocked-by: []
reopen-when: an entry file under drift-audit's references/sources/ passes 20 KB, or a run misses a rule buried in an entry's dated history
written: 2026-10-06
---

# Handoff: move the registry's dated history out of its entries

- **Written**: 2026-10-06, for the pass that the registry's split into
  one file per source, landed the same day, left out of scope. The user
  asked that day for it to wait in a brief of its own.
- **Kind**: a decision of the user's, on what moves and where it goes,
  then an edit to the entry files. It starts after the split lands.

## What it is

Each `drift-audit` registry entry mixes two kinds of text: what a run
follows (fields, fetch steps, filters, traps) and how that was
established (dated measurements, known-answer runs, run prices, worked
cases). A run reads both, every time. This pass moves the second kind
out, so an entry holds its contract and points at its evidence. That is
the arrangement the two `CLAUDE.md` files already have with
`docs/evidence/`: read it before changing a rule, not before following
one.

## Why it waits

Measured 2026-10-06 at `de236cc`: `skills-for-fabric` is 14,857 bytes
and `powerbi` 10,114, the two largest entries; the other four come to
14,080 together. Once the split lands, a run reads only its own entry,
so this pass saves part of those two sources' 10–15 KB per run. That is
less than the split saves the same runs, and the sort takes judgment
sentence by sentence. Entries do grow: by their subjects, 10 of the 18
commits on the file through 2026-09-24 amend an existing entry. The
trigger catches growth past 20 KB, a third over the largest entry today,
or the failure the mixing risks.

## The trap: much of the history is also a rule

At `de236cc`:

- `powerbi`'s "What step 4 catches" is a dated table of four forks, and
  it ends "Never accept an empty commit list from a fork that has not
  already passed step 4."
- `skills-for-fabric`'s "Registered 2026-09-10" paragraph is provenance,
  and it carries "Don't register an aggregator or a community catalog
  here."
- `skills-for-fabric`'s worked counterpart cases carry "A retired
  upstream name can still have a live local counterpart".
- `claude-code`'s "Two measured facts drive the fields above" is the
  evidence for its filter, and it carries "Do not filter on the leading
  verb alone".

So the sort is per sentence, not per paragraph: a rule stays in its
entry, and only the measurement behind it moves.

## Where it goes

Proposed: `docs/evidence/drift-audit-sources.md`, one `##` heading per
source id, each entry file pointing at its heading, as the two
`CLAUDE.md` files point at theirs. The other option is to delete the
history and rely on `git log` and the `docs/audits/` ledger. The choice
is the user's, made when this reopens.

## Verification, when it runs

- Before editing, list every rule sentence in each entry; after, each is
  still in its entry word for word, or the user agreed to its removal.
- `pre-commit run --all-files`.
- A known-answer run of each source touched, if the user wants one: the
  registry records the windows (`powerbi`, floor 2026-08-01;
  `skills-for-fabric`, under "Assert the stable half instead"). Each is
  a full run on the skill's pinned model.

## Re-measure before acting

```bash
wc -c .claude/skills/drift-audit/references/sources/*.md   # skills-for-fabric: 14,857 bytes on 2026-10-06, as a section
```
