# Handoff: fold claude-code evidence into two handoff briefs

- **Audit run**: 2026-10-06
- **Source**: `claude-code`
- **Window**: floor `2026-08-30` (base `f1af9b1f`, 2026-08-28) → head
  `fbe20e00` (2026-10-06)
- **Covers recommended actions**: 14 and 15
- **Kind**: dated evidence added to two open handoff briefs; no
  frontmatter, status or plan changes
- **Target**: `docs/handoffs/execute/payload-claude-md-double-load.md`,
  `docs/handoffs/execute/drift-fetch-subagent.md`

## The problem

Two handoff briefs rest on measurements this window bears on.
`payload-claude-md-double-load.md` measured double loads of
`claude/CLAUDE.md` on 2.1.268–2.1.281, and three later fixes touch the
same loader. `drift-fetch-subagent.md` waits for a single-source run
that strains Phase 1 and asks for an inline run's context cost; the
2026-10-06 run is such a run, and its cost is recorded in neither
brief.

## D-1 — three loader fixes postdate the double-load measurements

**Symptom.** `payload-claude-md-double-load.md` § "How big it was":
> Before the exclude, 32 sessions Read under `claude/`, on every CLI
> version from 2.1.268 to 2.1.281

**Cause.** In this window's changelog:

- 2.1.281: "Fixed CLAUDE.md and rules files from an `--add-dir`
  directory inside the working directory being sent to the model twice
  in headless and SDK sessions"
- 2.1.286: "Fixed subagents spawned with worktree isolation loading the
  project CLAUDE.md and its imports a second time from the worktree copy
  on their first file read"
- 2.1.287: "Fixed a folder's CLAUDE.md being attached a second time
  after resuming a session or after a compaction"

**Fix.** Append a dated paragraph (2026-10-06) at the end of § "How big
it was", naming the three fixes and saying the brief's measurements
predate them. Draw no conclusion: none of the three names a nested file
loaded twice in one uninterrupted session, the brief's case, though
2.1.287 bears on its two loads after `/compact`.

## D-2 — the 2026-10-06 run's Phase 1 cost

**Symptom.** `drift-fetch-subagent.md` defers until "a single-source
`/drift-audit` run compacts mid-Phase-1 or reports files left
undiffed", and its § "Notes" asks to "Capture the inline run's context
cost against the delegated run's on the same window."
**Cause.** The 2026-10-06 `claude-code` run, one source, inline:

- 38 commits, taken by the on-disk two-ref diff; both refs, 587,814 and
  945,458 bytes, stayed on disk.
- The added region, 2,438 lines and 357,781 bytes, entered context
  whole: 2.4× the ~150 KB per-source budget.
- It took six Read slices: 620-line slices were refused at 29–34k
  tokens against the Read tool's 25,000-token cap, and 420-line slices
  passed.
- No compaction, and no file left undiffed, so the reopen trigger as
  written did not fire.

**Fix.** Append those figures as a dated paragraph (2026-10-06) in
§ "Notes", beside the success criterion they answer, and say the
trigger did not fire. Leave `status: deferred` and `reopen-when` as
they are: changing them is the user's call.

## Sequencing note

Brief 07 D-3 also edits `drift-fetch-subagent.md`, in § "Frontmatter"
and § "Confidence". Re-read the file before editing it.

## Verification

1. `grep -n "2026-10-06" docs/handoffs/execute/payload-claude-md-double-load.md docs/handoffs/execute/drift-fetch-subagent.md`
   — a hit in each.
2. `git diff docs/handoffs/execute/payload-claude-md-double-load.md docs/handoffs/execute/drift-fetch-subagent.md`
   — additions only, none inside a frontmatter block.
3. `uv run scripts/handoff-status.py . --no-inbox` — both briefs listed
   as before.
4. `pre-commit run --all-files`.

## Provenance

The fixes are from the 2026-10-06 `claude-code` run's changelog diff.
The Phase 1 figures are that run's own: the byte and line counts are in
`00-audit-report.md` § "Audit window", and the slice sizes are from the
Read tool's refusals in the same session.

## Execution log

- **Executed**: 2026-10-07 — applied
- **Session**: fresh (no audit or handoff run in this session; the whole
  pass, in its own worktree)
- **Files changed**: `docs/handoffs/execute/payload-claude-md-double-load.md`,
  `docs/handoffs/execute/drift-fetch-subagent.md`
- **Verification**: D-1's quote sat at lines 42–43, and D-2's success
  criterion in § "Notes", which the file was re-read for after brief
  07's fold into § "Frontmatter". Step 1 — **passed**: `2026-10-06`
  once in the double-load brief and twice in the drift-fetch one, the
  second being brief 07's. Step 2 — **passed**: additions only, at line
  58 of the first and lines 174 and 417 of the second, none in a
  frontmatter block. Step 3 — **passed**: both listed as before, open
  with `needs user` and deferred with their `reopen-when`. Step 4
  (`pre-commit run --all-files`) runs once at the end of the run.
- **Deviations**: one wording, put right against the brief's own figures.
  **Fix** says the measurements predate the three fixes, but they ran
  on 2.1.268 to 2.1.281, so D-1's paragraph says they predate 2.1.286
  and 2.1.287 and reach 2.1.281 only at their end. It draws no
  conclusion, as the brief asks.
