---
paths:
  - "**/.platform"
  - "**/*.SemanticModel/**"
  - "**/*.Report/**"
  - "**/*.Notebook/**"
  - "**/*.DataPipeline/**"
  - "**/*.Dataflow/**"
  - "**/*.Warehouse/**"
  - "**/*.Lakehouse/**"
  - "**/*.Eventstream/**"
  - "**/*.Eventhouse/**"
  - "**/*.KQLDatabase/**"
  - "**/*.KQLQueryset/**"
  - "**/*.KQLDashboard/**"
  - "**/*.Reflex/**"
  - "**/*.Activator/**"
  - "**/*.VariableLibrary/**"
  - "**/*.SparkJobDefinition/**"
  - "**/*.Environment/**"
  - "**/*.MirroredDatabase/**"
  - "**/*.CopyJob/**"
  - "**/*.GraphQLApi/**"
  - "**/*.GraphModel/**"
  - "**/*.SQLDatabase/**"
  - "**/*.MountedDataFactory/**"
  - "**/*.DataAgent/**"
  - "**/*.UserDataFunction/**"
  - "**/*.ApacheAirflowJob/**"
  - "**/*.OperationsAgent/**"
  - "**/*.Ontology/**"
---

# Fabric Git-synced repos: portal serialization

Applies when editing item-definition files inside `*.{ItemType}`
folders of a Fabric Git-synced repo (any folder containing a
`.platform` file).

If a project-scope `.claude/rules/fabric-git-serialization.md` exists,
that file supersedes this one.

Fabric re-serializes an item's definition files whenever the item is
committed from the portal, and its canonical form for JSON and SQL
parts (`pipeline-content.json`, `variables.json`, eventstream/report
JSON, Warehouse `.sql` scripts) **has no final newline** — a trailing
newline added locally is stripped on the next portal round-trip,
producing a whitespace-only diff. TMDL, `notebook-content.*`, and
`.kql` parts *do* end with a newline.

When editing these files:

- **Preserve the file's existing EOF exactly** — never append a final
  newline to a file that lacks one, never remove one that's there.
- New JSON / SQL item parts: end at the last character, no final
  newline. New TMDL / notebook / KQL parts: end with one.
- Don't "clean up" portal-written formatting in Warehouse scripts —
  trailing spaces after commas in table DDL and the
  `-- Auto Generated (Do not modify) <hash>` header on views are
  reapplied by the portal on every sync. That header is **not** a
  content hash: the portal reapplies the same value after the view's
  schema name, comments, and column list have all changed. Carry it
  forward verbatim across edits and moves; never recompute or drop it.
  A brand-new view has no way to know its hash in advance — omit the
  header and accept one round-trip.

## A portal commit serializes live state — absence is a deletion

Above is how bytes round-trip; this is what content survives at all. A
portal commit is not an authored change but a serialization of *that
workspace's* live state, so anything in the folder the live item does
not contain is drift to be removed. Three ways that bites, all observed
Sept 2026, all silent:

- **Hand-authored files in an item folder are deleted** — 13 `.sql`
  scripts (~3,300 lines) left a trunk in one commit because the live
  warehouse held no matching shared queries. Keep such scripts outside
  anything Fabric syncs.
- **Deleting an item deletes its definition** — 35 files (~2,000 lines)
  in one commit. Recreating it commits back only `.platform`,
  `.gitignore` and `.sqlproj`, and the live item comes back empty too,
  so neither side warns you.
- **A branch-out or sandbox workspace commits *its* reality onto your
  branch** — `shortcuts.metadata.json` 19 shortcuts → 1 and
  `DatabaseSchema.kql` 19 tables → 1, because that sandbox genuinely
  held one table.

Recover a deleted definition with
`git checkout <commit-before-the-delete> -- <item path>`, but **keep the
new `.platform`**: a recreated item has a different `logicalId`, and
restoring the old one re-points the folder at an item that no longer
exists. Sequence a deliberate delete-and-recreate as note the commit →
delete → recreate → sync → restore definitions → rewire the item GUID
wherever it is referenced.

**Before merging a branch carrying portal commits**, diff the
environment-bound files — shortcut manifests, database schema, item
bindings — against the **target environment's live state**, not just
against the target branch. Repo CI is unlikely to catch it: a shortcut
naming a table the target lacks fails the *entire* Lakehouse git update
(`InvalidShortcutPayloadBatchErrors`, "Target path doesn't exist"),
while a live table with no shortcut is at most a warning.

### git → portal is not uniformly a no-op

"Portal → git only" is the wrong mental model, and which way it runs
decides whether a class of work can be branched. A KQL database's
`DatabaseSchema.kql` *"is executed when syncing to your Fabric
Workspace"* — but only as create-or-merge / create-or-alter / alter,
with **no drop and no rename**, so additions apply and subtractions
cannot be expressed at all. Use git sync for additive schema change and
do drops and renames live. And because sync *executes* `.create-merge`,
a branch still carrying those lines for renamed-away tables
**recreates them as empty tables** on the next sync — after a live
rename that file is a hazard until it is updated. Per-object detail:
the `fabric-eventhouse` skill. (Docs:
`fabric/real-time-intelligence/git-eventhouse-kql-database`.)

## Line endings: every Fabric repo needs a `.gitattributes`

Fabric writes some lines CRLF and some LF **inside the same file** —
the `GO` / `ALTER TABLE` constraint block in Warehouse table DDL and
the auto-generated view header are CRLF, the surrounding body is LF.
With Git for Windows' default `core.autocrlf = true` and no
`.gitattributes`, a local commit strips those CRs, the next portal
sync puts them back, and the history fills with recurring
"Auto formatted" commits. No amount of careful local authoring fixes
this — it is a translation layer underneath the edit, not an
authoring mistake.

Check early in any Fabric repo: `git config core.autocrlf` and whether
`.gitattributes` exists. If translation is on and unpinned, add one
scoped to the workspace folders holding item definitions:

```gitattributes
Engineering/** -text
RealTime/**    -text
Analytics/**   -text
```

`-text` (no translation at all), **not** `text eol=lf` — forcing LF
strips the portal's CRLF lines and restarts the ping-pong from the
other side. This does not retroactively fix already-committed blobs;
expect one more normalization commit before it settles.

Practical consequence while editing: exact-match string edits against
these files can fail on the CRLF lines even when the text looks
identical. Match a smaller span that avoids the line break, or operate
on bytes.
