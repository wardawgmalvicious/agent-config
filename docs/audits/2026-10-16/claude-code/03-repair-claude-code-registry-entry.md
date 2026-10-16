# Handoff: repair the claude-code registry entry

- **Audit run**: 2026-10-16
- **Source**: `claude-code`
- **Window**: floor `fbe20e00` (2026-10-06, the 2026-10-06 run's head) →
  head `c017428c` (2026-10-16)
- **Covers recommended actions**: 4
- **Kind**: registry repair in the drift-audit skill's own machinery; one
  stale figure corrected in place, one measured sample and one Read
  option added, no change to how a run fetches
- **Target**: `.claude/skills/drift-audit/references/sources/claude-code.md`,
  the list opening "Two measured facts drive the fields above"
  (lines 38–66)

## The problem

The `claude-code` entry tells the next run what this source costs, and
one of its figures is stale. Its Size bullet says two full copies of the
changelog would pull "~1.2 MB" into context. That is undated, and false:
this window's two refs total 1,991,789 bytes. The 2026-10-06 run's
brief 01 left that figure for this audit to settle, and brief 07 closes
it naming this brief.

Two additions ride along. The slice rule gives one way past the Read
tool's per-call cap, and since 2.1.296 Read has a second, `allow_large`.
And the Volume bullet holds three samples where this run measured a
fourth.

## Evidence

Measured in the run's blobless clone of `anthropics/claude-code`, base
`fbe20e00e2851fc01506f54f98a8f0b875af3847` (2026-10-06T18:59:09Z) →
head `c017428c8c27e604840435048d5bce6a9a22c040` (2026-10-16T20:52:45Z):

| Measure | This window |
| --- | --- |
| Days, base to head | 10 |
| Landings on `CHANGELOG.md` | 8, each a "chore: Update CHANGELOG.md and feed.xml" squash |
| Version sections added | 8, 2.1.293 to 2.1.302; 2.1.297 and 2.1.298 have none |
| Top-level bullets added | 672, ~67 a day; 2.1.299 alone 190 |
| Bullets the filter kept | the report's No-op: "~640 of 672 bullets filtered out" |
| File, base → head | 945,458 → 1,046,331 bytes; 414 → 422 version sections |
| Both refs together | 1,991,789 bytes |
| Diff | one hunk, `@@ -1,5 +1,701 @@`, 0 removed lines: a strict prepend |
| Added region | 696 lines, 100,873 bytes |

Bullets are `grep -c '^- '` over the added region; sections are
`grep -c '^## '` over each ref. The region fit the ~150 KB per-source
budget of `SKILL.md` § 4a step 4, and two Read slices of 350 lines took
it, neither refused.

**`allow_large`.** Changelog 2.1.296, verbatim:

> - Added an `allow_large` option to the Read tool so Claude can read a
>   text file past the usual size limits in one call when it needs the
>   whole file and the context has room

It was in the audit session's Read tool schema, on CLI 2.1.301: "Set to
true to read a text file, or a line range of one, that is over the
usual size limits, up to what still fits in your context."

**The entry today**, verbatim:

- `:41–47`, the Volume bullet:
  > Three measured samples, not one operating
  > range: ~29 commits and ~550 bullets across 35 days; 85 commits, 77
  > version sections and 1713 bullets across 89 days; and 38 commits, 34
  > version sections and 2336 bullets across the 39 days to 2026-10-06.
  > Commits hold near one a day in all three, but bullets ran ~16 and ~19
  > a day in the first two and ~60 in the third, so the bullet rate moves
  > from window to window and is **no constant to scale by**.
- `:55–58`, the Size bullet:
  > This source is why SKILL.md § 4a keeps two refs on disk once
  > they outgrow the budget: letting two full
  > files into context to diff them would pull ~1.2 MB to learn what a small
  > append-at-top region already says.
- `:60–63`, the same bullet:
  > On a
  > five-week window the new region alone outgrows the ~150 KB per-source
  > budget — 358 KB in the 39 days to 2026-10-06 — and must be read in
  > slices of about 420 lines to pass the Read tool's 25,000-token cap.

## What to change

All in the list opening "Two measured facts drive the fields above".

1. **Volume, `:41–47`.** Add the 2026-10-16 sample: 8 commits, 8
   version sections and 672 bullets across the 10 days to 2026-10-16.
   "Three measured samples" becomes four, "near one a day in all three"
   covers all four (0.8 a day here), and the bullet rates gain this
   window's ~67 a day.
2. **Size, `:57`.** Replace "~1.2 MB" with the measured figure, dated:
   1,991,789 bytes for the 2026-10-06 and 2026-10-16 refs together.
3. **Slices, `:60–63`.** Beside the slice rule, name Read's
   `allow_large` (2.1.296) as the other way past the per-call cap.

## Constraint on the fix

- Correct in place; append no second figure below the stale one
  (`coding-markdown.md` § "Prose discipline"). Keep every rule sentence
  word for word, "Do not filter on the leading verb alone" above all:
  `docs/handoffs/execute/drift-registry-evidence.md`, deferred, names it
  as a rule to keep.
- Leave the dated sizes: "945 KB (2026-10-06)" at `:7` and "945 KB and
  414 version sections on 2026-10-06" at `:54` were true when measured,
  and say when.
- `allow_large` lifts the per-call cap, not the ~150 KB budget, which
  governs what enters context whatever one call can read. Let the
  wording keep the two apart.
- Change nothing in `SKILL.md`. Whether § 4a should mention
  `allow_large` is not decided here.

## Verification

1. `grep -n '1\.2 MB' .claude/skills/drift-audit/references/sources/claude-code.md`
   — no hit.
2. `grep -n '2026-10-16' .claude/skills/drift-audit/references/sources/claude-code.md`
   — the new sample and the two-ref figure carry the date.
3. `grep -n 'allow_large' .claude/skills/drift-audit/references/sources/claude-code.md`
   — present.
4. `grep -n 'leading verb alone' .claude/skills/drift-audit/references/sources/claude-code.md`
   — still present.
5. `wc -c .claude/skills/drift-audit/references/sources/claude-code.md`
   — under 20 KB, the `drift-registry-evidence.md` reopen trigger; it
   was 4,883 bytes on 2026-10-16.
6. `pre-commit run --all-files`.

## Provenance

Recommended action 4 of the 2026-10-16 `/drift-audit claude-code` run,
and the failed half of the re-check it owed the 2026-10-06 run's brief
01. Every figure is exact: both refs sat in a clone on disk, and the
counts are `grep -c` and `wc`. Self-referential: the entry is the
audit's input, so the next `claude-code` drift audit is what reads the
correction.
