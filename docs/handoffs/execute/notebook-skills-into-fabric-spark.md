---
status: open
priority: 2
needs: []
blocked-by: [fabric-deploy-skill.md]
written: 2026-10-09
---

# Handoff: fold four notebook skills into fabric-spark, always listed

- **Written**: 2026-10-09, on the user's decision in
  [platform-skill-portfolio.md](platform-skill-portfolio.md): one
  notebook skill, keeping the name `fabric-spark`, always listed.
  Measured at `9535085`.
- **Kind**: a restructure, done by hand, then `/test-skill fabric-spark`.
  Four skills become references of `fabric-spark` as they stand, and its
  `paths:` goes. No platform fact is added, so nothing is drilled and
  `/author-skill` does not apply.
- **After the pilot**: [fabric-deploy-skill.md](fabric-deploy-skill.md)
  tests the router shape first, and this is its second wave's notebook
  item, widened by the user.

## Why

- **Three skills share one glob.** `fabric-spark`,
  `fabric-spark-monitoring` and `fabric-error-handling` all carry
  `**/*.Notebook/**`, so every notebook Read lists all three: 888, 646
  and 591 characters, 2,125 in all. That happened in 6 client
  sessions, 2026-09-24 to 2026-10-08, and none of the three was invoked.
- **Two are always listed.** `fabric-mlv` (1,024 characters) and
  `fabric-ai-functions` (1,016) sit in every session's listing.
  `fabric-ai-functions` was never invoked in its lifetime, and no client
  notebook calls AI Functions (2026-10-08). `fabric-mlv`'s six lifetime
  uses fall at its authoring and test stamps (a client repo's
  `/skill-doctor`, 2026-10-08).
- **One entry of at most 500 characters replaces both costs**: 1,540
  fewer at startup, and nothing more on a notebook Read. Always listed,
  it also answers a request made in words, "add a materialized lake
  view", before any notebook is read, which a glob cannot.

## Shape

### Files

| Today | After |
| --- | --- |
| `fabric-spark-monitoring/SKILL.md` | `fabric-spark/references/spark-monitoring.md` |
| `fabric-spark-monitoring/references/REFERENCE.md`, the log and `resourceUsage` APIs | `fabric-spark/references/spark-monitoring-apis.md` |
| `fabric-error-handling/SKILL.md` | `fabric-spark/references/error-handling.md` |
| `fabric-error-handling/references/REFERENCE.md`, a Learn link bundle | appended to `error-handling.md`, then removed |
| `fabric-mlv/SKILL.md` | `fabric-spark/references/mlv.md` |
| `fabric-mlv/references/REFERENCE.md`, a Learn link bundle | appended to `mlv.md`, then removed |
| `fabric-ai-functions/SKILL.md` | `fabric-spark/references/ai-functions.md` |
| `fabric-ai-functions/references/REFERENCE.md`, its config tables | `fabric-spark/references/ai-functions-tables.md` |

Move each with `git mv`, so `git log --follow` keeps its history. Strip
each moved file's frontmatter and re-point its relative links:
`spark-monitoring-apis.md` cites `../SKILL.md`, which becomes
`spark-monitoring.md`. `fabric-spark`'s own `references/REFERENCE.md`
stays.

### The router

`fabric-spark`'s body stays and gains one table near its top, the job
to the reference:

| The job | Read first |
| --- | --- |
| a Spark job queued, slow or failed; Livy sessions; the History Server | `references/spark-monitoring.md` |
| error handling in a notebook's code | `references/error-handling.md` |
| a materialized lake view | `references/mlv.md` |
| AI Functions on a DataFrame | `references/ai-functions.md` |

Its "See also" lines for `fabric-error-handling` and
`fabric-spark-monitoring` become those links; the rest stay.

### Frontmatter

- `paths:` goes, so the skill is always listed: the user's choice.
- The entry, `description` plus any `when_to_use`, at most 500
  characters, trigger vocabulary and no facts: notebook, PySpark, Spark
  SQL, lakehouse, Livy, Spark History Server, slow or queued job,
  materialized lake view, MLV, AI Functions, error handling. Upstream
  skills-for-fabric 0.3.14 cut its descriptions by about 40% "with no
  loss of routing accuracy", as `fabric-deploy-skill.md` cites.
- `disable-model-invocation: false`, `# model: inherit` and `effort`
  commented, as today.

## The rename trap

Nothing errors when a skill name goes stale. Change each of these in
the commit that folds:

- `.claude/settings.json` `skillOverrides`: the four entries go;
  `fabric-spark`'s stays. `lint-skill-overrides` fails until then.
- `tests/skills/fabric-triggers/expected_activations.md`: the table
  asserts conditional skills only, so `fabric-spark`,
  `fabric-spark-monitoring` and `fabric-error-handling` leave the
  Notebook rows. Recompute the `Tokens` cells as that file's README
  says, then run `./scripts/test-activation.ps1 -Set fabric -StaticOnly`.
- `tests/skills/.tested.json`: drop the stamps of
  `fabric-spark-monitoring`, `fabric-error-handling` and `fabric-mlv`;
  the frontmatter edit makes `fabric-spark`'s stale.
- `skills/README.md`: four bullets fold into `fabric-spark`'s.
- Other skills' mentions, counted 2026-10-09: outside the five, only
  `fabric-gotchas` names any of them, `fabric-mlv` and
  `fabric-ai-functions`; re-point it to `fabric-spark`. Mentions among
  the five become reference links. A name backticked in a description
  fails `scripts/skill-overlap.py routing`.
- The drift registry's counterpart rows for `fabric-mlv`, in two files
  under `.claude/skills/drift-audit/references/sources/`.
- `.claude/skills/author-skill/SKILL.md:95` uses
  `fabric-spark-monitoring` as an example of a name sharing a
  substring: name another pair.
- Open briefs naming the four: re-point them. `docs/audits/` stays as
  written.

```bash
grep -rnE 'fabric-spark-monitoring|fabric-error-handling|fabric-mlv|fabric-ai-functions' --exclude-dir=audits --exclude-dir=.git .
```

**Client repos**: relink each with exactly the groups it holds, as
`fabric-deploy-skill.md` says; the relink prunes the four dangling
junctions. The main client repo's `"off"` for `fabric-ai-functions`
then names nothing, which is harmless and that repo's to tidy.

## Verify

1. The static check passes, and
   `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-spark/SKILL.md`
   is clean.
2. `/test-skill fabric-spark`, behaviour, against a `--safe-mode`
   baseline:

   | Case | Prompt, in short | Passes when |
   | --- | --- | --- |
   | MLV by words | add a materialized lake view over a silver table, no file read | `fabric-spark` is invoked and reads `references/mlv.md` |
   | AI Functions | classify support tickets in a notebook with AI Functions | reads `ai-functions.md`; the import fits pandas or PySpark |
   | Slow job | a notebook's Spark job queued for ten minutes: why? | reads `spark-monitoring.md`; Livy session timings |
   | Error handling | after a notebook Read, add error handling to its per-table loop | reads `error-handling.md`; the Tier 2 results shape |
   | Plain Spark | an abfss path for a lakehouse table | answers from the body alone |

3. **Listing**: the new entry against the 2,040 always-listed and 2,125
   activated characters above.
4. `pre-commit run --all-files`.

## Re-measure before acting

- The pilot's result, in `fabric-deploy-skill.md`. If its router routed
  worse than the pair it replaced, stop and put this brief back to the
  user, who decided it before that result.
- `uv run --with pyyaml python scripts/skill-telemetry.py coverage`
  rows for the five skills, and the grep above.
- Whether `/triage` has applied the client prompt audit's hunks to any
  of the five, as `platform-skill-portfolio.md` says it may; re-read
  them before moving.

## Not checked

Whether the always-listed router is invoked when notebook work happens:
`skill-telemetry.py triggers` after a few weeks of client sessions.

## Scrubbing

Client repos are named by kind, and no workspace, item or tenant is
named.
