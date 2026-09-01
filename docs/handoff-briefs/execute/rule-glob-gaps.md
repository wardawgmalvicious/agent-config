# Handoff: should `coding-kql` reach the JSON files that hold queries?

- **Written**: 2026-08-31, from the trigger-fixture work (`9d49302`).
  Trimmed 2026-08-31 to the one open question — see below.
- **Kind**: decision, not a bug fix. Do not execute it unattended.
- **Status**: open. The three glob *bugs* this brief originally carried
  have landed; what is left is the judgement call they were filed
  alongside.
- **Run in**: a fresh session (frontmatter is a trigger surface), and in
  the same sitting as
  [item-type-skill-kqlqueryset.md](item-type-skill-kqlqueryset.md) —
  they are one decision in two files.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## What already landed

Bugs 1, 1b and 3 are fixed; git history is the archive. In short:

- **Bug 1** — `coding-sparksql.md` globbed `**/notebooks/**/*.sql`, a
  directory shape Fabric never emits, so a Spark SQL notebook silently
  got **T-SQL** conventions from `coding-tsql.md`'s bare `**/*.sql`.
  Fixed by adding `**/*.Notebook/notebook-content.sql` and
  `**/*.SparkJobDefinition/**/*.sql`.
- **Bug 1b** — the `coding-tsql` / `fabric-database` overlap on
  `*.SQLDatabase/**/*.sql` turned out **not** to be a contradiction:
  Fabric SQL Database *is* Azure SQL, which `coding-tsql.md` already
  claims. Only the two Warehouse-preview sections needed fencing.
  Recorded as a scope carve-out in the rule, not a glob change.
- **Bug 3** — `fabric-git-serialization.md` was missing
  `**/*.GraphModel/**`. Added, plus `**/*.UserDataFunction/**` and
  `**/*.ApacheAirflowJob/**` from a partial diff against the live
  item-type set (see *Still unchecked* below).

One finding came out of fixing bug 1 that was **not** in the original
brief and is worth carrying forward: Fabric emits `notebook-content.sql`
for **two** dialects, and no glob can tell them apart, because the
discriminator is inside the file.

| `kernel_info.name` | Cell `language` | Dialect | Rule that wins |
| --- | --- | --- | --- |
| `synapse_pyspark` | `sparksql` | Spark SQL | `coding-sparksql` |
| `sqldatawarehouse` | `sql` | T-SQL on a Warehouse | `coding-tsql` |

Confirmed against `edkreuk/FMD_FRAMEWORK` @ `ebe97d4` and
`LanreAdetola/wwi_fabric_dw` @ `493bea1`. Both rules co-load on that file
by design now, each carrying a precedence section naming the other. **If
you are tempted to "fix" that overlap by narrowing a glob, don't** — the
overlap is the correct behaviour and the resolution is prose.

## The open question — `coding-kql` never fires on an actual KQL query

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
Verified against ACME, which has all four shapes, and reproducible against
the fixtures with the probe below.

**The catch**: adding those three JSON files to the glob loads KQL prose
conventions for a file that is mostly JSON envelope. That may be right —
the KQL inside is what a human edits — but it is a judgement call, not a
typo fix like bug 1 was. Consider whether `fabric-realtime-dashboard` and
a future KQLQueryset skill are the better home for query-authoring
guidance, in which case the rule stays as-is and this becomes a note
rather than a fix. See
[item-type-skill-kqlqueryset.md](item-type-skill-kqlqueryset.md).

Whichever way it goes, **record the reasoning**. A "no" that leaves no
trace gets re-opened by whoever next notices the empty column.

## Still unchecked

The item-type diff on `fabric-git-serialization.md` was **partial**. Three
names were confirmed against real exports and added; the rest of the list
was not re-verified, and there is still no mechanism keeping it current.
`Dataflow` was the one existing entry actively questioned, and it is
**correct** — 246 public exports use `<name>.Dataflow`; `DataflowGen2` is
a portal name that never reaches Git. Worth a full pass sometime, cheap
with a `filename:.platform` code search per candidate name.

## Reproducing

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
for f in ["RealTime/X.KQLQueryset/RealTimeQueryset.json",
          "RealTime/X.KQLDatabase/EmbeddedRealTimeQueryset.json",
          "RealTime/X.KQLDashboard/RealTimeDashboard.json"]:
    print(f, "->", sorted(n for n, p in R.items()
                          if wg.globmatch(f, p, flags=F)))
```

## Validation, if you do change the glob

- Lint the rule:
  `uv run --with pyyaml scripts/lint-frontmatter.py claude/rules/coding-kql.md`
- Re-run the probe above and the static check in both
  `tests/skills/*-triggers/README.md`.
- **The fixtures already exist** — `RealTimeQueryset.json`,
  `EmbeddedRealTimeQueryset.json` and `RealTimeDashboard.json` are all in
  `tests/skills/fabric-triggers/fixtures/` — so update the rules table in
  `expected_activations.md` rather than adding files.
- `pre-commit run --all-files`, `git status` clean, finish with `/commit`.

## Why the linter did not catch the original three

`scripts/lint-frontmatter.py` rejects the mistakes that *silently narrow* a
pattern — a backslash separator, a leading `/`, a bare `*.ext` with no `/`.
All three globs were well-formed. They were wrong about the **world**, not
about glob syntax, and no linter can check that.

The check that would have caught them is the one that found them: match the
globs against a real repo's file list. That is now cheap — the fixture trees
and the snippet above — and is worth running whenever a `paths:` glob is
added or edited, in `rules/` as much as in `skills/`.
