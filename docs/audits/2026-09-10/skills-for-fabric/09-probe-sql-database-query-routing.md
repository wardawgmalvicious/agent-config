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

## Execution log

- **Executed**: 2026-09-11 — escalated
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in the session)
- **Files changed**: none
- **Verification**: none run. This is a measurement brief whose probe
  needs cold sessions, so it is a separate task and not part of a
  `/drift-update` run.
- **Decision**: **queue the three-context probe** as a follow-up, run
  with `test-skill` mechanics. The `fabric-database` description changes
  only if context 3 misroutes.
- **Deferred**: the probe and every verification step.
- **Deviations**: none.
- **Probe run**: 2026-09-15 — three cold `claude -p` sessions on
  `claude-opus-5`, each in its own directory outside any repo, with
  `--strict-mcp-config` and only `Read` and `Skill` permitted, so neither
  the Learn MCP server nor the web tools could supply an answer the
  skills were meant to carry. Sessions `e6f3b326` (cold), `7384d1f6`
  (SQLDatabase only), `439c58c7` (both item types). Fixtures were copied
  from `tests/skills/fabric-triggers/fixtures/` and read, never edited.
- **Result — routing is correct; no description change.** Context 3 is
  the one that matters and it reproduced the upstream failure condition
  exactly: its second `commands_changed` record carries `fabric-database`,
  `fabric-warehouse` **and** `fabric-warehouse-monitoring` at once, so the
  Warehouse skills were genuinely on offer and lost on the merits. The
  session invoked `Skill fabric-database` and never `fabric-warehouse`,
  then answered with that skill's own claims — the `database.windows.net`
  audience, the nvarchar/datetime/money/MERGE/triggers list, OneLake Delta
  replication — and said in as many words "do not carry Warehouse
  restrictions across". Context 2 routed the same way on one read.
- **The premise this brief argued from is now measured, not inferred.**
  Every `init` record put `cmds` at 69, carrying the eleven unconditional
  `fabric-*` skills and neither conditional one, which is what a `paths:`
  glob is supposed to do.
- **Cold behaviour, recorded because the brief asked for it.** Context 1
  reached `fabric-auth` and `fabric-gotchas` — the nearest unconditional
  skills — and still opened by separating SQL Database from Warehouse and
  SQL analytics endpoint on their T-SQL surfaces. The cold path degrades
  to a correct general answer rather than to a confident wrong one, so
  there is no cold-entry gap to close either.
- **No behaviour stamp was written, deliberately.** This measured which
  of two payload skills wins a contested request, for which the base
  model is not a control — it has neither skill. Attributing the answer's
  content to `fabric-database` would need a `--safe-mode` arm that was not
  run, so `fabric-database` stays `untested-behaviour` in
  `skill-status.py` and this is not evidence against that verdict.
  Activation was already stamped 2026-09-12 and its glob has not moved;
  the static check passed 70/70 on 2026-09-15, so no cold activation
  session was spent.
- **Closed**: 2026-09-15 — the probe ran, context 3 did not misroute, and
  the description edit it gated is therefore not wanted. Nothing is left
  deferred.
