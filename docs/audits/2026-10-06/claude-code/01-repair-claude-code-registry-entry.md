# Handoff: repair the claude-code registry entry

- **Audit run**: 2026-10-06
- **Source**: `claude-code`
- **Window**: floor `2026-08-30` (base `f1af9b1f`, 2026-08-28) → head
  `fbe20e00` (2026-10-06)
- **Covers recommended actions**: 1
- **Kind**: registry repair in the drift-audit skill's own machinery;
  dated figures corrected in place, no change to how a run fetches
- **Target**: `.claude/skills/drift-audit/references/sources/claude-code.md`

## The problem

The `claude-code` registry entry tells the next run what this source
costs, and three of its expectations are out of date. Its bullet rate is
a third of what this window produced. Its size figure is 590 KB against
945 KB at head. It does not warn that the new region alone can outgrow
both the skill's per-source budget and the Read tool's per-call cap. And
it does not say the changelog is ever edited in place, which this window
did once.

## Evidence

From the 2026-10-06 run's on-disk two-ref diff, recorded in
`00-audit-report.md` § "Audit window":

| Measure | This window | The entry today |
| --- | --- | --- |
| Days, base to head | 39 (2026-08-28 → 2026-10-06) | 35 and 89 |
| Commits on `CHANGELOG.md` | 38 | ~29 and 85 |
| Version sections added | 34 | 77 over the 89 days |
| Top-level bullets added | 2,336 | ~550 and 1,713 |
| Bullets per day | ~60 | ~19 |
| Bullets the `filter` kept | ~46 | 418 of 1,713 over the 89 days |
| File at head | 945,458 bytes, 414 version sections | ~590 KB, 380+ |
| New region | 2,438 lines, 357,781 bytes | not stated |

- The new region alone is 2.4× the ~150 KB per-source budget that
  `SKILL.md` § 4a step 4 sets.
- The Read tool refused 620-line slices of the region at 29–34k tokens
  against its 25,000-token cap; 420-line slices passed, six in all.
- The diff had a second hunk: one 2.1.252 bullet was reworded in place,
  from "over 50K characters" to "over 10,000 characters … a
  2,000-character preview". `sources.md` § "Shape contracts" records the
  2026-08-29 run confirming a strict prepend, which held for that window
  and not for this one.

## What to change

All three in `.claude/skills/drift-audit/references/sources/claude-code.md`,
in the list that opens "Two measured facts drive the fields above":

1. **Volume.** The bullet opening "**Volume, per window length.**"
   carries:
   > That is roughly **0.95 commits/day and ~19 bullets/day** — scale by
   > the window rather than reading the 35-day figures as the source's
   > steady state.

   Add the 2026-10-06 sample and correct the rate in place: about one
   commit a day still holds, but bullets per day tripled, so the bullet
   rate moves from window to window and is no constant to scale by.
2. **Size.** The bullet opening "**Size.**" carries:
   > ~590 KB, 380+ version sections, and it only grows.

   Correct it to the head's figures, dated, and say what they cost a
   run: on a five-week window the new region alone outgrows the ~150 KB
   budget, and must be read in slices of about 420 lines to pass the
   Read tool's 25,000-token cap.
3. **Shape.** Add one sentence where it reads naturally: the file is a
   prepend almost always, but a bullet is now and then reworded in
   place, so a run reads the diff's removed lines too.

## Constraint on the fix

Correct in place; never append a second figure below the stale one
(`coding-markdown.md` § "Prose discipline"). Keep every rule sentence
word for word, "Do not filter on the leading verb alone" above all:
`docs/handoffs/execute/drift-registry-evidence.md`, deferred, is the
pass that may later move this entry's measurements out, and it names
that sentence as a rule to keep. Change nothing in `SKILL.md`: how the
skill should treat a region larger than its budget is not decided here.

## Verification

1. `grep -n -E "19 bullets/day|~590 KB|380\+" .claude/skills/drift-audit/references/sources/claude-code.md`
   — no hit outside a dated clause naming an earlier window.
2. `grep -n "2026-10-06" .claude/skills/drift-audit/references/sources/claude-code.md`
   — the new sample and size figures carry the date.
3. `grep -n "leading verb alone" .claude/skills/drift-audit/references/sources/claude-code.md`
   — still present.
4. `wc -c .claude/skills/drift-audit/references/sources/claude-code.md`
   — under 20 KB, the `drift-registry-evidence.md` reopen trigger; it
   was 4,269 bytes on 2026-10-06.
5. `pre-commit run --all-files`.

## Provenance

Measured by the 2026-10-06 `claude-code` run itself. Both refs were
downloaded to the session scratchpad and compared with `diff`, so the
byte, line and section counts are exact; the bullet count is
`grep -c '^- '` over the added region, and the ~46 kept bullets are the
audit's own tally of its filter. Self-referential: the entry is the
audit's input, so the next `claude-code` run is what checks it.

## Execution log

- **Executed**: 2026-10-07 — applied with deferrals
- **Session**: fresh (no audit or handoff run in this session; the whole
  pass, in its own worktree)
- **Files changed**:
  `.claude/skills/drift-audit/references/sources/claude-code.md`
- **Verification**: Step 1 — **passed**: no hit for `19 bullets/day`,
  `~590 KB` or `380+`. Step 2 — **passed**: `2026-10-06` on the new
  sample (line 43) and on the size figures (lines 7, 53 and 61). Step 3
  — **passed**: `leading verb alone` at line 50. Step 4 — **passed**:
  4,832 bytes, under the 20 KB trigger. Step 5 (`pre-commit run
  --all-files`) runs once at the end of the run. `lint-frontmatter.py`
  does not apply: the file is a `references/` page, not a `SKILL.md` or
  a rule.
- **Deferred**: the behavioural check, as Provenance says: the next
  `claude-code` audit is what reads the corrected entry, and this run
  cannot re-run an audit against it.
- **Deviations**: line 7's `sections` field carried the same undated
  `~590 KB`, outside the three bullets **What to change** lists, so
  step 1 could not pass with it unedited. Put to the user, who chose to
  correct it too: it reads `945 KB (2026-10-06)`. Two notes. The 35-day
  sample's own rate is ~16 bullets a day (550 over 35), so the bullet
  gives ~16 and ~19 for the first two windows rather than one ~19. The
  region's cost follows "two-ref diff on long ones" rather than the
  figures, so "This is why SKILL.md § 4a…" still points at the file's
  size and not at a region larger than the budget, which the brief
  leaves undecided.
- **Needs**: the next claude-code drift audit — reading the corrected
  entry is the behavioural check; and the Size bullet's "~1.2 MB" for
  two full files, which predates the 945 KB head and was unbriefed here.
