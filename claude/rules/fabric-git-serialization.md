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
