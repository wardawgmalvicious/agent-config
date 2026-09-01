# Handoff: does `.KQLQueryset` need a skill?

- **Written**: 2026-08-31, from the trigger-fixture work (`9d49302`).
- **Kind**: coverage decision.
- **Status**: open. **Recommendation: no new skill. Fix the rule glob
  instead** — see [rule-glob-gaps.md](rule-glob-gaps.md) bug 2. This brief
  exists to record the reasoning so the empty column is not re-opened.
- **Run in**: whichever session takes `rule-glob-gaps.md`. These two are
  one decision.

## The gap

`tests/skills/fabric-triggers/fixtures/SampleQS.KQLQueryset/` activates no
skill. But the interesting finding is not the missing skill — it is that
the *rule* is missing too.

A KQLQueryset is two files: `.platform` and `RealTimeQueryset.json`. The
JSON is an envelope — `dataSources`, `tabs` — and everything of value is
KQL text inside a `content` string.

In ACME:

```text
38,887  RealTime/ACME_QS_Operation_MV.KQLQueryset/RealTimeQueryset.json
 9,724  …/ACME_KDB_Operation.KQLDatabase/EmbeddedRealTimeQueryset.json
 2,174  …/ACME_KDB_Logging.KQLDatabase/EmbeddedRealTimeQueryset.json
```

**The 38 KB file is the largest single query surface in the repo, and
`coding-kql.md` does not fire on it.** That rule globs `**/*.kql` and
`**/*.csl` only, so it reaches `DatabaseSchema.kql` — schema DDL — and not
one written query, in any item type.

## Why a skill is the wrong instrument here

Apply the test from Workstream E in
[skill-context-cost.md](skill-context-cost.md): *does the content change
what the agent does, or only what it knows?*

There is no KQLQueryset **procedure**. You do not deploy one in a
particular order, there are no refusal conditions, and the item has no
lifecycle worth documenting. What is needed on this file is **KQL
authoring conventions** — and those already exist, fully written, in
`claude/rules/coding-kql.md`. The only thing wrong is that the glob does
not reach the file.

Writing a skill would duplicate a rule that already says the right thing.

## The actual work

In `claude/rules/coding-kql.md`, add the three JSON surfaces:

```yaml
  - "**/*.KQLQueryset/RealTimeQueryset.json"
  - "**/*.KQLDatabase/EmbeddedRealTimeQueryset.json"
  - "**/*.KQLDashboard/RealTimeDashboard.json"
```

**Weigh this before doing it.** Unlike bug 1 in
[rule-glob-gaps.md](rule-glob-gaps.md), this is a judgement call, not a
typo:

- **For**: the KQL inside is what a human edits, and the conventions are
  already written and correct.
- **Against**: the rule loads on a file that is mostly JSON envelope, and
  `RealTimeDashboard.json` *also* activates `fabric-realtime-dashboard`
  (1,839 tok), so that file would carry rule + skill. Check that pair does
  not say contradictory things about query style.

Prefer the narrow item-specific globs above over a broad
`**/*RealTime*.json` — the payload has had two bugs from over-broad globs
already (A1, and bug 1 in the rule brief).

## Reconsider only if

A KQLQueryset skill earns its place only if a genuine *procedure* appears —
for example, if queryset-to-dashboard promotion, or cross-database
`dataSources` rebinding across environments, turns out to have ordered
steps and traps. ACME's `dataSources` blocks do carry per-environment
`clusterUri` and `databaseItemId` GUIDs, which is a rebinding surface worth
a look; if it has real deployment gotchas, that content belongs in
`fabric-cicd` or `fabric-eventhouse` before it justifies a new skill.

## Validation

- Re-run the probe in [rule-glob-gaps.md](rule-glob-gaps.md); the three
  files must resolve to `coding-kql`.
- Update the `SampleQS.KQLQueryset` rows in
  `tests/skills/fabric-triggers/expected_activations.md`. Note that table
  currently lists **skills only** — if you add a rules column, do it for
  both trigger fixture sets so they stay comparable.
- `uv run --with pyyaml scripts/lint-frontmatter.py claude/rules/coding-kql.md`
- `pre-commit run --all-files`, `/commit`.
