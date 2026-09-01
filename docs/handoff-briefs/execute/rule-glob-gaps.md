# Handoff: three rule `paths:` globs that never match what they target

- **Written**: 2026-08-31, from the trigger-fixture work (`9d49302`).
- **Kind**: bug fix. Three independent glob errors in `claude/rules/`.
- **Status**: open, nothing edited. Found by measurement, not reported by
  anyone — a wrong `paths:` glob has no error path, so all three have been
  silently wrong for as long as they have existed.
- **Run in**: a fresh session (frontmatter is a trigger surface).
- **Priority**: bug 1 first. It is the only one that loads *actively wrong*
  guidance rather than merely loading nothing.
- **Queue**: [README.md](README.md) has the execution order and what
  blocks what. This brief does not carry its own position.

## How these were found

Extending the static glob check in `tests/skills/*-triggers/README.md` to
`claude/rules/*.md` as well as `skills/`, then probing it with real path
shapes from `C:\Repos\ACME\fabric-acme`. Reproduce with:

```bash
# uv run --with pyyaml --with wcmatch python thisfile.py
import pathlib, yaml
from wcmatch import glob as wg
F = wg.GLOBSTAR | wg.DOTGLOB
R = {}
for p in sorted(pathlib.Path('claude/rules').glob('*.md')):
    d = yaml.safe_load(p.read_text(encoding='utf-8').split('---', 2)[1])
    if d and d.get('paths'):
        R[p.stem] = d['paths']
for f in ["Integration/X.Notebook/notebook-content.sql",
          "RealTime/X.KQLQueryset/RealTimeQueryset.json",
          "Analytics/X.GraphModel/graphmodel.json"]:
    print(f, "->", sorted(n for n, p in R.items()
                          if wg.globmatch(f, p, flags=F)))
```

## Bug 1 — `coding-sparksql.md` never fires on a Fabric notebook

**This one loads the wrong dialect's conventions, so fix it first.**

```yaml
paths:
  - "**/notebooks/**/*.sql"      # lowercase, plural
  - "**/lakehouse/**/*.sql"      # lowercase
  - "**/spark/**/*.sql"
```

Fabric Git serialization emits `<Name>.Notebook/notebook-content.sql` — a
**singular, capitalised item-folder suffix**, not a `notebooks/` directory.
No Fabric repo has a directory named `notebooks`, `lakehouse` or `spark`,
so none of the three globs has ever matched a Fabric file.

What matches instead: `coding-tsql.md`, whose glob is a bare `**/*.sql`.

```text
Integration/000_Archive/ACME_NB_MLV.Notebook/notebook-content.sql
  -> ['coding-tsql', 'fabric-git-serialization']
```

So a Spark SQL notebook gets **T-SQL conventions** — a different dialect
with different identifier quoting, different null semantics, different
temporal syntax. This is worse than no rule.

ACME has exactly **one** such file today, which is why it has gone
unnoticed; the exposure grows with every `%%sql` notebook saved as SQL.

**Suggested fix** — add the item-folder shapes, keep the existing globs
(they may match non-Fabric repos):

```yaml
  - "**/*.Notebook/notebook-content.sql"
  - "**/*.SparkJobDefinition/**/*.sql"
```

Then decide what to do about the overlap: `coding-tsql.md`'s `**/*.sql`
still matches, so both rules co-load and contradict each other on the same
file. Narrowing `coding-tsql.md` is the cleaner fix but has the wider blast
radius — it is the rule most likely to be relied on in non-Fabric repos.
**Measure before narrowing it**, and check the same overlap against
`fabric-warehouse` and `fabric-database` (see bug 1b).

### Bug 1b — the same overlap, already live on SQL Database

`SampleSQL.SQLDatabase/dbo/Tables/Customer.sql` loads `fabric-database`
**and** `coding-tsql`. The skill's whole thesis is *"do NOT apply Warehouse
T-SQL restrictions to Fabric SQL Database"*; the rule announces itself as
covering "SQL Server, Azure SQL, Fabric Warehouse, Synapse SQL pools".
Whether they actually contradict on a specific claim is unverified — read
both and check before assuming. Recorded here because it is the same
overlap and should be settled in one pass.

## Bug 2 — `coding-kql.md` never fires on an actual KQL query

```yaml
paths:
  - "**/*.kql"
  - "**/*.csl"
```

Every Fabric RTI **query** surface stores KQL as a string inside JSON:

| File | Item type | Gets `coding-kql`? |
| --- | --- | --- |
| `DatabaseSchema.kql` | KQLDatabase | **yes** |
| `EmbeddedRealTimeQueryset.json` | KQLDatabase | no |
| `RealTimeQueryset.json` | KQLQueryset | no |
| `RealTimeDashboard.json` | KQLDashboard | no |

So the KQL conventions reach schema DDL and **not one written query**.
Verified against ACME, which has all four shapes.

**The catch**: adding those three JSON files to the glob loads KQL prose
conventions for a file that is mostly JSON envelope. That may be right —
the KQL inside is what a human edits — but it is a judgement call, not a
typo fix like bug 1. Consider whether `fabric-realtime-dashboard` and a
future KQLQueryset skill are the better home for query-authoring guidance,
in which case the rule stays as-is and this becomes a note rather than a
fix. See [item-type-skill-kqlqueryset.md](item-type-skill-kqlqueryset.md).

## Bug 3 — `fabric-git-serialization.md` is missing `GraphModel`

Its 24-entry item-type list includes `**/*.GraphQLApi/**` but not
`**/*.GraphModel/**`. Those are two different Fabric items, and
`fabric-graph` targets the latter.

Effect is small: `.platform` inside the folder still matches via the bare
`**/.platform`, so only the item's own definition files miss the rule.

```text
Analytics/X.GraphModel/graphmodel.json  ->  []      (no rule at all)
Analytics/X.GraphModel/.platform        ->  ['fabric-git-serialization']
```

**Fix**: add `**/*.GraphModel/**`. While in there, diff the list against the
current Fabric item-type set — it was written at a point in time and there
is no mechanism keeping it current. `MountedDataFactory` and `Activator`
are in it; `Dataflow` is present but `DataflowGen2` naming should be
confirmed.

**Caveat**: `.GraphModel` is itself unverified — no instance exists in ACME,
and the name comes from `fabric-graph`'s own claim. If that claim is wrong
this "fix" propagates the error into a second file. Settle the shape first
via [fixture-shape-capture.md](fixture-shape-capture.md).

## Validation

- Lint each touched rule:
  `uv run --with pyyaml scripts/lint-frontmatter.py claude/rules/<name>.md`
- Re-run the probe above; every line must resolve to the intended rule.
- Re-run the static check in both `tests/skills/*-triggers/README.md`.
- **Add a fixture for anything you fix.** Bug 1 needs
  `SampleNB.Notebook/notebook-content.sql` in `tests/skills/fabric-triggers/`;
  bug 2 already has `RealTimeQueryset.json` and
  `EmbeddedRealTimeQueryset.json` sitting there with an empty skills column.
  A fix with no fixture is how these three got in.
- `pre-commit run --all-files`, `git status` clean, finish with `/commit`.

## Why the linter did not catch these

`scripts/lint-frontmatter.py` rejects the mistakes that *silently narrow* a
pattern — a backslash separator, a leading `/`, a bare `*.ext` with no `/`.
All three globs here are well-formed. They are wrong about the **world**,
not about glob syntax, and no linter can check that.

The check that would have caught them is the one that found them: match the
globs against a real repo's file list. That is now cheap — the fixture trees
and the snippet above — and is worth running whenever a `paths:` glob is
added or edited, in `rules/` as much as in `skills/`.
