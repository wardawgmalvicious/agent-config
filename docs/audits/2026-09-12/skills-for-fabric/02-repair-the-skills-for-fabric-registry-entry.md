# Handoff: repair the skills-for-fabric registry entry

- **Audit run**: 2026-09-12
- **Source**: `skills-for-fabric`
- **Window**: floor `2026-08-20` (diff base `a5e82199`) → head `358d4d87`
  (2026-09-10T14:37Z)
- **Covers recommended actions**: 2
- **Kind**: content repair to one registry entry — two stale counterpart
  facts, one unrun assertion now run, and two mechanism notes. Edits
  only; no behaviour change to the pipeline and no new fetch strategy.
  Project-scope skill, live in sessions in this repo only.
- **Target**: `.claude/skills/drift-audit/references/sources.md`, the
  `skills-for-fabric` entry — lines 589, 600, 617, 650–654, 667–676,
  and the bundle paragraph near 692

## Context

The entry was repaired once already, on 2026-09-11, from the
2026-09-10 brief 06. Four of its facts have gone stale since, all from
work this repo did in the two days after: two upstream skills named as
having no local counterpart now have one, the sentence counting them is
wrong, and the known-answer assertion the entry records as unrun has
now been run. A fifth item is new — `v0.3.16` adds an install route the
entry's own prose says was not evaluated.

None of this is a defect in the pipeline. It is an entry describing a
world two days out of date, in the one file `/drift-audit` reads at the
start of every run.

## Evidence

**Both remaining brief 07 candidates were authored on 2026-09-12.**
From `git log --diff-filter=A` on each `SKILL.md`:

| Upstream | Local skill | First commit | Date |
| --- | --- | --- | --- |
| `dataflows-cli` | `fabric-dataflow` | `9153d3d` | 2026-09-12 |
| `deployment-pipelines-authoring-cli` | `fabric-deployment-pipelines` | `529fce7` | 2026-09-12 |

The other two accepted candidates were already recorded:
`onelake-catalog-govern-cli` → `fabric-catalog-governance` (line 619)
and `activator-cli` → `fabric-activator` (line 620), both authored
2026-09-12 as well.

**The counterpart table is half-right on one of them.** Line 617 reads:

```text
| `deployment-pipelines-authoring-cli` | `fabric-cicd` (partial) |
```

That row exists and is not wrong; it is incomplete. `dataflows-cli` has
**no row at all** — confirmed by reading the table at lines 604–621.

**The count sentence is now zero.** Lines 650–654 read, in part:

> Two of the four accepted candidates remain unauthored —
> `dataflows-cli` and `deployment-pipelines-authoring-cli`, the latter
> already holding a partial counterpart row above.

**The known-answer assertion ran.** Line 672 ends:

> The exact known-answer floor, 2026-08-20, has not been run.

It was run on 2026-09-12, and it passed in the stable form lines
678–692 specify — the subtraction, not a named skill. Result, for the
record:

| Assertion | Outcome |
| --- | --- |
| Vendored pair empty and tree-SHA proven, bounded at `65902bae` | passes — `[]` on both paths since `2026-08-20T13:22:57Z`; tree SHAs `d160d140`, `b9fe475b`, `9b609076`, `4f847fca` identical at `b8d541c` and `65902bae` |
| Clause-1 subtraction | passes — the sole in-window lexical hit, `onelake-catalog-govern-cli`, was subtracted by the table and reported under No-op; zero new-skill candidates, as expected |
| No false positive on a retired name | passes — `databricks-migration` (4 base mentions) stayed in (d), as did the six retired names `0.3.14` cites, each with 2–5 base mentions |

The clause-1 subtraction was checked by counting each of the 13 names
from the 2026-09-10 report in the base file at `a5e82199`: 12 carry 1–8
mentions there, so only `onelake-catalog-govern-cli` (0 mentions) is
in-window for this floor.

**The base fetch need not enter context.** Step 3 at line 589 says to
fetch the whole file at the base ref. The 2026-09-12 run did that with
`curl` to the scratchpad over anonymous HTTPS —
`https://raw.githubusercontent.com/microsoft/skills-for-fabric/<sha>/CHANGELOG.md`
— and then ran `grep -c` per name against the local copy. 44,935 bytes
on disk, and the file never reached the conversation. `get_file_contents`
would have put all of it there.

**`v0.3.16` adds a fourth install route.** From the `CHANGELOG.md`
patch at `f1802196`, verbatim:

> Added a root `apm.yml` plus a generated `skills/<name>/apm.yml` for
> every skill, so a user can install a single skill with
> `apm install microsoft/skills-for-fabric --skill <name>` instead of a
> whole plugin bundle.

The bundle paragraph near line 692 currently names three options —
vendoring, authoring, installing a bundle — and says the bundle "was
not evaluated here".

## D-1 — two counterpart facts are stale

**Symptom.** `dataflows-cli` has no row; `deployment-pipelines-authoring-cli`
names only `fabric-cicd (partial)`. Both now have a dedicated local
skill.

**Fix.** Add a row for `dataflows-cli` → `fabric-dataflow`. Join
`fabric-deployment-pipelines` to the existing line 617 row rather than
adding a second row with the same key — the same shape brief 06's D-4
used for `semantic-model-authoring`, and deviation 2 of its execution
log records why.

**Knock-on.** Leave `fabric-cicd (partial)` in place on that row. The
new skill covers service-side stage-to-stage ALM; `fabric-cicd` still
holds the `fab deploy` / `fabric-cicd` library side, so both are real
places to look.

## D-2 — the unauthored count is wrong

**Symptom.** Lines 650–654 say two of four candidates remain
unauthored. All four are authored.

**Fix.** Replace the sentence with the settled outcome: all four
2026-09-11 candidates were authored on 2026-09-12, so clause 1 will not
surface any of them again. Do not restate "four" as a standing count —
the next accepted candidate makes it five, and this entry has already
rotted once by carrying a number.

**Constraint.** Keep both worked cases that precede it. The
`onelake-catalog-govern-cli` case and the `activator-cli`
consolidation-rename case are the evidence that D-5 of brief 06 was
right to keep the lexical test, and they are why the rows are worth
having in view. This edit removes a count, not an argument.

## D-3 — the known-answer floor has now been run

**Symptom.** Line 672 records the exact floor as unrun, and lines
667–676 describe the 2026-09-10 superset run as the only evidence.

**Fix.** Record the 2026-09-12 run at floor 2026-08-20, with the three
outcomes in the Evidence table above, and keep the bounded-at-`65902bae`
caveat — `v0.3.16` (`f1802196`) touched both vendored paths, so an
unbounded vendored check now returns one commit per path, correctly and
outside the known answer. That caveat is deviation 1 of brief 06's
execution log and still holds.

**Knock-on.** The run also measured the unbounded case and it is worth
a line: all four `powerbi-report-*` tree SHAs moved at `v0.3.16`, but
blob SHAs show `SKILL.md`, `references/` and `assets/` byte-identical to
`b8d541c` — the entire delta is a new generated `apm.yml` per
directory. So the tree-SHA check is a *trigger*, not a verdict; narrow
with blob SHAs before reading a patch. Brief 04 of this run covers the
`apm.yml` decision itself.

## D-4 — two mechanism notes

**Symptom.** The entry's fetch step 3 implies the base file enters
context, and its price line (line 600) is the 2026-09-10 run's.

**Fix.** Two additions, both small:

1. On step 3, note that the base fetch may be a `curl` to the
   scratchpad over anonymous HTTPS with `grep` run against the local
   copy, so the ~44 KB never enters the conversation. This is the same
   exemption the `changelog` shape contract already states for a two-ref
   diff — "only the new region enters context" — applied to the base
   read.
2. Update line 600's price with the 2026-09-12 figures: 31 github-mcp
   calls (7 `list_commits`, 8 directory and file listings, 5 `stats`,
   11 isolated patches), 1 raw HTTPS base fetch, 4 Learn searches, 1
   WebFetch.

**Fix, second item.** Add the APM route to the bundle paragraph near
line 692: `apm install microsoft/skills-for-fabric --skill <name>`
installs one skill, which makes four acquisition routes rather than
three. Say it is unevaluated, as the bundle option already is — no
claim about whether `apm` is installed here or whether a single-skill
install is preferable to vendoring.

## Verification

1. **Re-read the file immediately before editing.** It is shared with
   other registry work and two sessions in this tree share every file.
   Confirm each quoted target is in `HEAD` before changing it:

   ```bash
   git show HEAD:.claude/skills/drift-audit/references/sources.md \
     | grep -n -E 'Two of the four accepted|has not been run|Installing a bundle is a third option'
   ```

   Nothing back for a quote means the line is another session's
   uncommitted work, not yours — leave it and note the deferral in the
   commit message.
2. `grep -n -E 'fabric-dataflow|fabric-deployment-pipelines' .claude/skills/drift-audit/references/sources.md`
   — both counterparts present, `dataflows-cli` on its own row and
   `fabric-deployment-pipelines` joined to the existing one.
3. `grep -n 'Two of the four accepted' .claude/skills/drift-audit/references/sources.md`
   — no hit.
4. `uv run --with pyyaml scripts/lint-frontmatter.py .claude/skills/drift-audit/SKILL.md`
   — body-only edits to a `references/` file, but confirm the skill
   still lints and its `description` still describes what the registry
   covers.
5. `uv run scripts/lint-skill-scopes.py`.
6. `pre-commit run --all-files`.

## Sequencing note

Do not bundle this with brief 01, which edits the same skill's
`SKILL.md`. That brief is gated on a live tenant probe and may change
nothing; this one is a content repair verified by grep. Different
verification, different risk. Whichever runs second re-reads its target
first.

Do not bundle it with brief 03 either. That brief stamps the prior run's
ledger with the same known-answer result recorded here in D-3, but it
writes into `docs/audits/2026-09-10/`, which is a committed dated record
rather than live payload — a wrong edit there rewrites history rather
than guidance.

## Provenance

Every item came out of the 2026-09-12 `/drift-audit` run against this
source at floor 2026-08-20, which was itself the step-4 verification
the 2026-09-10 brief 06 deferred. D-1 and D-2 are bookkeeping the run
tripped over while applying the filter — the counterpart table is what
subtracts a clause-1 hit, so its staleness was load-bearing for the
assertion in D-3. D-4's first item is how the run actually executed the
entry's own step 3. Nothing here was found by review.
