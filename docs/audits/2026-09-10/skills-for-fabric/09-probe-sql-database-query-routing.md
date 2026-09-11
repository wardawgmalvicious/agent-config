# Handoff: probe whether "query my Fabric SQL database" reaches fabric-database

- **Audit run**: 2026-09-10
- **Source**: `skills-for-fabric`
- **Window**: floor `2026-08-06` (diff base `912e06e0`) → head `65902bae`
  (2026-09-04)
- **Covers recommended actions**: 9 (second half)
- **Kind**: **measurement** of trigger behaviour. A description edit
  follows only if the probe shows misrouting.
- **Target** (only if misrouted): the `description` in
  `skills/fabric/fabric-database/SKILL.md`

## The problem

Upstream found that its SQL database skill lost plain query requests to
its Warehouse skill, because it never claimed querying. Our
`fabric-database` description has the same shape: it leads with being a
different engine from Warehouse and lists what works, but never says it
handles querying a SQL database item. Whether that misroutes here has
not been measured.

## Evidence

Upstream, `CHANGELOG.md` `[0.3.14]` (`99de3299`), Fixed, verbatim:

> **`sqldb-cli`** -- "run a query against my Fabric SQL database" reached
> the Warehouse skill instead. `sqldb-cli` presented itself as a
> design-and-troubleshoot skill and never claimed plain querying, so the
> Warehouse skill won on the word "query". It now leads with querying a
> SQL database item, so the request reaches the right engine.

This repo, `SKILL.md` line 3 of each:

- `fabric-database`:

  > Use when working with Fabric SQL Database — the Azure SQL Database
  > hosted inside a Fabric workspace. Key point: this is a DIFFERENT
  > engine from Fabric Warehouse and does NOT share its restrictions. ...

- `fabric-warehouse`:

  > Use for T-SQL against Fabric Warehouse (NOT Fabric SQL Database —
  > see fabric-database). ...

## Why the probe design matters

Both skills are `paths:`-scoped — `fabric-database` on
`**/*.SQLDatabase/**/*.sql`, `fabric-warehouse` on
`**/*.Warehouse/**/*.sql` — so neither is in the startup listing until a
matching file is `Read` (root `CLAUDE.md`, "How the pieces trigger"). A
cold plain-English request cannot reach either by description, and
upstream's failure needs both listed at once. Probe three contexts:

1. **Cold**, no Fabric file read — expect neither skill; note what the
   model does instead.
2. After `Read`ing a `*.SQLDatabase/**/*.sql` file — expect
   `fabric-database`.
3. After `Read`ing files matching **both** globs, as in a repo holding
   both item types — the upstream failure case. Does "run a query
   against my Fabric SQL database" pick `fabric-database`?

Use `test-skill` for the mechanics. Activation is keyed to the `Read`
tool, not to the file, so pin `--allowedTools Read`. The session
transcript is the only witness to activation.

## Decision after probing

Misrouting in context 3 → front-load querying a SQL database item in
the `fabric-database` description, which is about 460 characters
(measured roughly 2026-09-10), well under the 1,024 cap. Correct routing
→ no change; record the result and its date.

## Verification

1. Probe results summarized with date and session IDs.
2. If the description changed:
   `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-database/SKILL.md`,
   then re-run context 3.
3. `pre-commit run --all-files`

## Sequencing note

Split from brief 08; see the note there.

## Provenance

First `/drift-audit --sources skills-for-fabric` run, 2026-09-10, from
bucket (c). The three-context probe design is not from the audit: it
follows from both skills being `paths:`-scoped, a property of this repo
that a cold reader needs before designing the probe.
