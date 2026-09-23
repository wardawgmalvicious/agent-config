# Handoff: `.alter table` semantics the Kusto docs get wrong, and four serialization gaps

- **Written**: 2026-09-22, consolidating the Fabric halves of two inbox
  notes from the same client estate —
  `2026-09-22-kusto-alter-table-semantics-and-branch-consumers.md`
  learnings 1–4, and the residue of
  `2026-09-15-kusto-streaming-and-warehouse-git-serialization.md`, seven
  of whose nine learnings had already landed.
- **Source notes deleted** 2026-09-22, with the user's explicit approval,
  once this brief carried their content — so this file and `git log` are
  now the only record of them.
- **Kind**: payload edits to `skills/fabric/fabric-eventhouse/SKILL.md`,
  `skills/fabric/fabric-eventstream/SKILL.md`,
  `skills/fabric/fabric-warehouse/references/platform-features.md` and
  `claude/rules/fabric-git-serialization.md`. Plus one **memory-hygiene
  action** that is not in this repo at all.
- **Status**: **Open, nothing landed.** Item 1 is fully measured with
  controls and **contradicts Microsoft Learn**, which makes it the most
  valuable thing here. Items 2 and 4 are documented-but-missing. Item 3
  carries an explicitly unverified exemption that must not land clean.
- **Run in**: this repo. **No Fabric tenant is needed** — every
  measurement is already taken; what is left is writing it down.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## Scrubbing, before anything else

Both source notes came from a client estate and were written raw for a
private inbox. **This repo is public.** The ERP table and column names
the measurements ran against are that client's table inventory — product
schema rather than identities, but still theirs — and the notes
themselves say to generalize them to `T`, `Col1`, `Col2` when landing.
The measurements do not depend on the names.

**Nothing in this brief quotes one, and nothing that lands should
either.** An earlier draft of this section did, naming three of them
while instructing the reader not to. The identity denylist caught it
before the commit, which is exactly the case that guard exists for: a
passage about scrubbing is where a real name most easily reads as
subject matter rather than as a leak.

The `zz_FolderProbe` scratch table below is safe: it was created by the
probe and dropped afterwards.

## Evidence status, per item

| Item | Status |
| --- | --- |
| 1 — a bare `.alter table` preserves docstring and folder | **Fully measured**, two environments, before/after controls, three tables |
| 2 — `.alter table` is the only column-reorder command | **Documented**, reorder half independently reproduced by item 1's dumps |
| 3 — the live-ingestion mitigation a MultiJSON estate lacks | Warning **documented**; the MultiJSON exemption is **UNVERIFIED reasoning** |
| 4 — `cslschema` is the prescribed pre-alter capture | **Documented**, fetched 2026-09-22; **not independently run** |
| 5 — notebook markdown-cell encoding | **A** proven by a three-commit trail; **B** by a commit survey ≥5 commits over a week |
| 6 — Eventstream destination `422` | **Observed**, relayed from a project's auto-memory; mechanism not established |
| 7 — `xmla.json` as the format-1.0 tell | **Observed** Sept 2026; the format mechanism is inferred, not doc-confirmed |

---

## 1. A bare `.alter table` preserves the table docstring *and* folder — Microsoft Learn says it overwrites both

**This is the item worth the brief.** A validator emitting `.alter table`
to reorder bronze columns restated `docstring` and `folder` in every
generated statement, on the documented premise that omitting them erases
them — and that the next portal commit would then serialize the table
without them, deleting the prose from the git-tracked `.kql` too. **That
premise was never measured, and it is wrong.**

Learn's `.alter table` page says the command "Sets a new column schema,
`docstring`, and folder to an existing table, **overwriting the
existing** column schema, `docstring`, and folder", with no carve-out for
the `with (...)` clause being omitted, and its "How the command affects
the data" section is **entirely silent** on `docstring` and `folder`.

**Measured 2026-09-22** against a Fabric Eventhouse, with
`.show database schema as json` dumps immediately before and after as the
control. Column order flipped in every run, so each statement
demonstrably executed; docstrings and folder were byte-identical
afterwards. A scratch table carried the folder case, because no real
table in the estate had a folder set at all:

```kusto
.create table zz_FolderProbe (ColA:string, ColB:string)
.alter table zz_FolderProbe folder "ProbeFolder"
.alter table zz_FolderProbe docstring "Scratch: safe to drop."
-- then, bare, no with(...) clause — the actual test:
.alter table zz_FolderProbe (ColB:string, ColA:string)
```

```text
BEFORE  order=['ColA','ColB']  Folder='ProbeFolder'  DocString set
AFTER   order=['ColB','ColA']  Folder='ProbeFolder'  DocString unchanged
```

**Three claims, settled three different ways — keep them apart**, because
collapsing them is what produced the wrong premise in the first place:

- **Table `docstring` survives.** Measured with a control on two
  environments and a third, scratch table. This is the part that
  contradicts the docs.
- **Column docstrings survive** — measured, but *expected* once the
  parameter table is read. `.alter table`'s supported properties are only
  the table's `docstring` and `folder`; **there is no syntax for column
  docstrings in the command at all** (they are set by
  `.alter table column-docstrings`). So the docs' phrase can only ever
  have meant the table's. Worth stating explicitly, because the summary
  sentence reads as though it covers them.
- **`folder` survives too** — settled only on the scratch table, which is
  all that was possible.

The docs *do* use explicit erasure language where they mean it:
`.alter table column-docstrings` says columns not explicitly set "will
have this property **removed**." Its absence on `.alter table`'s
properties is consistent with what was measured.

**The pattern is the stronger argument for the skill carrying this at
all.** This estate has now caught the Kusto docs wrong about docstring
handling **twice, in opposite directions** — the origin repo carries a
measured 2026-09-17 finding that `.create-merge table` with a
`with (docstring = …)` clause **does** set the docstring on an existing
table, where the docs read the other way. The docs understate what
`.create-merge` does to a docstring and overstate what `.alter table`
does to one. **Docstring and folder semantics on this platform are
documented unreliably and should be measured, not read.** Say that in the
skill alongside the specific facts.

**How to write the remedy.** Restating `docstring` and `folder`
defensively still costs nothing and guards the documented reading — which
is the one that loses prose if the platform ever matches its own docs.
But write it as **belt-and-braces, not a required workaround**, which is
the opposite of how the origin validator had it.

**Scope the claim**: Fabric Eventhouse, 2026-09-22, not tested on Azure
Data Explorer, and platform behaviour can change.

**Destination.** `fabric-eventhouse/SKILL.md` → `## Schema Evolution`
(line 43). One or two lines. Nothing is left hedged.

---

## 2. `.alter table` is the only column-reorder command, and `## Schema Evolution` omits it entirely

`## Schema Evolution` currently lists `.create-merge table`,
`.alter-merge table`, `.rename column`, `.drop column`, `.drop table` —
every one additive, single-column, or whole-table. **None can reorder**,
and the section does not say so, so the absence reads as *"column order
is not adjustable"* rather than *"the command for it is missing here."*

`.alter table T (col1:type, col2:type, …)` restates the full column list
and is documented as doing exactly this — Learn's bullet 2 is "Reorders
table columns", and its data section ends "The table will have the same
columns, in the same order, as specified."

**The warning belongs beside it**, from the same page, because it is what
makes the command dangerous rather than merely blunt:

> Existing columns that aren't specified in the command will be dropped.
> This could lead to unexpected data loss.

That is the reason to name it as a deliberate **full-restatement** form
rather than a casual one.

**One edit covers items 1 and 2.** Name `.alter table` as the
full-restatement form, say it reorders and drops-by-omission, and say
what it does *not* disturb.

---

## 3. Learn prescribes a live-ingestion mitigation a MultiJSON estate does not have

Learn's `.alter table` page warns:

> Data ingestion that disregards the order of columns and occurs in
> parallel with `.alter table` risks ingesting data into the wrong
> columns. To prevent this, make sure that ingestion uses a mapping
> object or stop ingestion while running the `.alter table` command.

The alters above ran against environments with streaming ingestion
enabled and no pause, posting `streamFormat=MultiJSON` with **no
ingestion mapping** — every bronze column is `string`, so mappings were
never created. Neither documented mitigation was in place. Nothing went
wrong, and nothing in the skill said anything should have.

**The likely reconciliation, and it is reasoning.** The warning scopes
itself to ingestion "that disregards the order of columns", which
describes positional formats (CSV/TSV) rather than name-keyed JSON. The
payload already records at
`fabric-eventhouse/references/ingestion.md:67` that MultiJSON auto-maps
"by name, not position; column order is not contractual" — which if
correct puts a MultiJSON sender outside the warning's scope and makes the
missing mapping object harmless.

**Nobody has run a concurrent-ingest-during-alter test.** Land this as a
sentence pairing two facts the payload already holds separately — the
warning exists, and name-keyed MultiJSON is the **likely** exemption —
stated as likely, never as proven. **Do not let it land as a clean
"MultiJSON is safe."** A CSV or positional sender in the same estate
would be squarely inside the warning.

**Destination.** Appended to the item-2 bullet, or a `## Gotchas` row
(line 228) keyed on *"columns land in the wrong column after an alter"*.
Cross-reference `references/ingestion.md`.

---

## 4. `.show table T cslschema` is the docs' prescribed pre-alter capture and is missing from `## Schema Discovery`

Capturing the current schema before an alter meant parsing
`.show database schema as json`, whose payload is **double-encoded** —
the schema arrives as a JSON string inside `Rows[0][0]` and needs
unwrapping before it is usable.

`## Schema Discovery` (line 32) lists `.show table T schema as json` but
not `cslschema`, which Learn names twice, in a Tip on both `.alter table`
and `.alter-merge table`:

> Use `.show table [tableName] cslschema` to get the existing table
> schema before you alter it.

`cslschema` returns the column list already in the exact
`name:type, name:type` form an `.alter`/`.create` takes, so it
round-trips by copy-paste.

**Distinguish the two forms' purposes in the same line.** Having both
listed without comment invites picking the wrong one: `schema as json` is
for programmatic diffing, `cslschema` for hand-editing a single table's
DDL. One line inside the existing `kql` block.

---

## 5. Fabric notebook markdown-cell encoding, and two distinct portal behaviours

From the older note, and **both halves must land together** — see below.

**The encoding.** In the flat git format (`notebook-content.py`), a
`# MARKDOWN ****` cell stores each line as `# ` plus the markdown source.
So `#` alone is a **blank line**, `# ## text` is an H2 (how these cells
normally title themselves), and `# # text` is an **H1**.

**Behaviour A — content damage, recurs forever.** Every git → portal
sync absorbs a bare `#` into the following line, turning a paragraph break
into an H1 that renders larger than the cell's own `##` title.
**Reverting in git always loses**, proven by a three-commit trail: the
portal applied it, a revert merged, and the portal re-applied it
identically seven minutes later. Remedy: use a bold lead-in and keep one
paragraph, or split the cell in two.

**Behaviour B — separator whitespace, converges.** The portal also writes
a *second* blank line between a markdown cell's last content line and the
next cell marker. It stops at two — surveyed across ≥5 workspace→git
commits spanning a week, never 3 — and it renders as nothing. Likely
mechanism, stated as theory: the editor appends a trailing newline and
`"# " + ""` rstrips to a genuinely blank line.

**Why both halves must be written down together.** Without B, the next
person reads any portal touch on a notebook as evidence that the A fix
failed, and reverts something that is inert.

**The trap.** A bare `#` in a *code* cell is an ordinary Python comment
and is never touched. The two are indistinguishable to `grep` — classify
by the enclosing `# CELL` / `# MARKDOWN` marker. Counting both and
reading the total as proof the markdown convention survives round-trips
is a mistake actually made in the originating session.

**Destination.** `claude/rules/fabric-git-serialization.md`. Its `paths:`
already covers `**/*.Notebook/**`, and `### git → portal is not uniformly
a no-op` (line 104) is the existing section this belongs under.

**Do not conflate** with the existing `fabric-gotchas` row for notebook
`400 exceptionCulprit:1` (cell `source` as a bare string rather than an
array). That is the REST/ipynb definition format; this is the flat git
serialization. Different formats, different failure.

---

## 6. Eventstream destination `422` after a schema reset

Creating or updating any schema-routed Eventstream destination has
answered `422` since 2026-09-10. Already-running destinations keep
working, and `ESComponentUpdateFailure` on a Running node is **not
fatal**. Confirmed 2026-09-22: `fabric-eventstream` has **zero** hits for
either `422` or `ESComponentUpdateFailure`.

**Destination.** `fabric-eventstream/SKILL.md` → `## Destinations`
(line 51) or `## Gotchas` (line 165).

**Do not mistake the existing row for coverage.** `fabric-gotchas`
carries a `CloudEventPropertyMissingException` row for schema-associated
Eventstream custom endpoints — that is the **producing** path; this is
the **destination create/update** path. Complementary, not duplicate.

**This one is the weakest evidence here** and should land hedged: a
dated observation of a platform state, with no mechanism established and
no re-check since 2026-09-10. Write the date prominently; a `422` that
has since been fixed upstream would leave this actively misleading.

## 6b. The memory-hygiene action, which is not in this repo

Both facts in item 5 and item 6 were found sitting in a **client
project's auto-memory** as domain knowledge — Fabric product facts, not
facts about the user. `/learn`'s own rule is that domain knowledge never
goes to memory. Promoting them here is what makes them reachable from
every repo instead of one project's sessions.

**Delete those two memory files once this content lands** — that is the
action, and it is in a project memory directory outside this checkout, so
the session that lands the content has to go and do it. One of them also
carries a line now stale (that the fact "belongs in the repo's gotcha
table, not added there yet", which a later commit superseded); fix or
drop it either way.

---

## 7. `xmla.json` is the real format-1.0 tell, and the documented one is wrong

The last unlanded fragment of the older note's learning 6. Everything
else from it landed in
`fabric-warehouse/references/platform-features.md` — `Microsoft.Build.Sql`
version ping-pong, the sanctioned SDK hand-edit, `.sharedqueries`, the
all-zero `<ProjectGuid/>`. **`xmla.json` did not**, confirmed by zero
hits across the whole payload 2026-09-22.

**The gap is a doc-vs-reality one, which is why it matters.** The docs
say to read `.platform`'s `config.version` to tell which definition
format an item is on. **That value reads `2.0` for every item type** —
notebooks, pipelines, eventstreams, all of them — so it says nothing
about the warehouse. The real format-1.0 tells are:

- the presence of `xmla.json`
- the **absence** of a `.sharedqueries` folder
- the **absence** of a warehouse-level `.gitignore`

`config.version` is already documented in `platform-features.md`, so
check what that text currently claims before adding: if it landed as "read
`config.version`" the entry is not merely incomplete, it is wrong, and
this is a correction rather than an addition.

**Also unlanded from the same learning**, and lower value: format 2.0
drops `xmla.json` and re-extracts every object definition — let the
portal do it rather than hand-rolling.

## 8. Lower confidence — include only if it survives a drill

Deployment pipelines offer **no data-source rules and no autobinding for
real-time dashboards**, so promotion overwrites the target's binding and
Test/Prod get re-pointed by hand after every deploy of a dashboard.
Semantic models *do* have parameter rules; RTDB does not.
`fabric-realtime-dashboard/SKILL.md:39` documents `databaseArtifactId`
but not this consequence.

**Observed, not doc-confirmed.** Nearest existing text is
`fabric-deployment-pipelines/SKILL.md:325` — deleting an item deletes its
*deployment rules*, which is a different fact. Drill it or drop it; do
not land it on one observation.

---

## Deployment

Everything under `skills/fabric/` is **pruned from user scope on this
machine** — the standing `-SkillGroups workflow,social,meta` invocation
does not deploy it — so **none of these edits changes any session's
payload at any point.** That is the point rather than an omission, and it
is why this brief needs no branch under
[CLAUDE.md](../../../CLAUDE.md) § "Branching and concurrent sessions".

`claude/rules/fabric-git-serialization.md` is the exception: it deploys
by **copy** and is live after

```powershell
./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force
```

Never bare — see [CLAUDE.md](../../../CLAUDE.md) § Commands.

## Verification

- `uv run --with pyyaml scripts/lint-frontmatter.py` on each edited
  `SKILL.md` and on the rule.
- `uv run --with pyyaml scripts/skill-status.py --stale` — item 1's edit
  is a body change to `fabric-eventhouse`, so its stamp is invalidated.
- **No `paths:` glob changes**, so no activation run. If one is added,
  `./scripts/test-activation.ps1 -Set fabric -StaticOnly` first, per
  [README.md](README.md) § "Before touching any `paths:` glob".
- `pre-commit run --all-files` clean, which also runs
  `lint-skill-overrides.py` — no new skill, so coverage is unchanged.
- **Re-read the Learn pages before quoting them.** Every documented claim
  here was fetched 2026-09-22 and the whole point of item 1 is that the
  docs and the platform disagree; a quoted sentence that has since been
  corrected upstream would invert the finding.

## Dependencies

- Blocks nothing and is blocked by nothing. Shares no file with any other
  open brief.
- [fabric-event-schema-set.md](fabric-event-schema-set.md) is the other
  open Fabric brief. Different item type, no overlap — but it is also a
  brief whose evidence is one tenant on one date, so the same
  re-measure-before-acting rule in [README.md](README.md) applies to
  both.
- Item 6b's action is outside this repo and outside git. It will not be
  caught by any check here, so it has to be done deliberately in the
  landing session or it will not happen.
