# Handoff: does `.DataPipeline` need a skill?

- **Written**: 2026-08-31, from the trigger-fixture work (`9d49302`).
- **Kind**: coverage decision, then possibly `/author-skill`.
- **Status**: open. **Recommendation: yes, author it.** Strongest of the
  three item-type gaps the fixtures surfaced.
- **Run in**: a fresh session. Start with `/author-skill` if the decision
  below holds after you check the overlap in step 1.
- **Queue**: [README.md](README.md) has the execution order and what
  blocks what. This brief does not carry its own position.

## The gap

`tests/skills/fabric-triggers/fixtures/SamplePL.DataPipeline/` activates
**no skill**. In ACME, DataPipeline is one of the largest surfaces by volume:

| File | Bytes | What loads today |
| --- | --- | --- |
| `ACME_PL_Operation.DataPipeline/pipeline-content.json` | 117,027 | `coding-expressions`, `fabric-git-serialization` |
| `ACME_PL_Orchestration.DataPipeline/pipeline-content.json` | 9,853 | same |
| `ACME_PL_Orchestration.DataPipeline/.schedules` | — | **nothing** |
| `*.DataPipeline/.platform` | — | `fabric-git-serialization` |

127 KB of orchestration with no skill behind it.

## Step 1 — check the overlap before writing anything

Three things already touch this surface. The skill is only worth writing if
it covers what they do not.

**`claude/rules/coding-expressions.md`** globs
`**/*.DataPipeline/pipeline-content.json` — the exact same file. It covers
the **Workflow Definition Language**: function casing, null safety with
`coalesce()`, variable-vs-parameter-vs-activity-output, long-expression
decomposition, activity dependency conditions, the ForEach variable race.
That is expression *authoring*, and it is good. It says nothing about
activity types, connection references, or deployment.

**Consequence to weigh**: a skill on the same glob **co-loads with the
rule**, on every pipeline file. Budget the pair, not the skill alone —
`coding-expressions.md` is ~1,900 tokens on its own. This is the same
co-activation arithmetic as C1 in
[skill-context-cost.md](skill-context-cost.md), and it is the main argument
*against* the skill.

**`fabric-cicd`** and **`fabric-gotchas`** are unconditional and may
already carry pipeline deployment content. **Grep both before drafting** —
if pipeline parameterisation is already in `fabric-cicd`, the right move is
a `paths:` glob on that skill (Workstream E's lever) rather than a new one.

## Step 2 — the content that is genuinely uncovered

Candidates, in rough confidence order. Drill each against Microsoft Learn
before it goes in the brief; this list is a starting point, not research.

- **`.schedules`** — a Git-synced schedule file with its own JSON schema
  (`.../fabric/gitIntegration/schedules/1.0.0/schema.json`), carrying
  `jobType`, cron/weekly config, `localTimeZoneId`, and an `enabled` flag.
  **Nothing in the payload globs it.** Non-obvious that schedules are in Git
  at all, and the `enabled: false` / timezone interaction is exactly the
  kind of thing that burns a deployment.
- **Fabric-specific activity types** — `TridentNotebook` (with `notebookId`
  + `workspaceId`, both of which are environment-specific GUIDs),
  Copy, Lookup, ForEach, Office365Outlook, Web/WebHook.
- **`state: "Inactive"` / `onInactiveMarkAs`** — present in the ACME
  pipeline. Deactivating an activity rather than deleting it is a real
  practice with a real trap: an inactive activity still participates in
  dependency edges.
- **Connection references and parameterisation across environments** —
  how a pipeline's GUIDs get rebound per workspace. This is where the
  `fabric-cicd` overlap is most likely.
- **Concurrency, retry, timeout defaults**, and where they bite.

## Step 3 — the glob

`**/*.DataPipeline/**` matches `.platform`, `.schedules` and
`pipeline-content.json` — three files per pipeline, all relevant. No
narrowing needed. Verify with the static check in
`tests/skills/fabric-triggers/README.md` before committing.

## Validation

- Add `.schedules` to `SamplePL.DataPipeline/` in the fixture tree **in the
  same commit** as the skill, and update `expected_activations.md` — the
  row currently reads *(none)* and that is the assertion being changed.
- Body cap: aim under ~3,100 chars-per-token-equivalent (see
  [skill-context-cost.md](skill-context-cost.md) on why ~2,900 was probably
  too tight). Long detail goes in `references/`, not `SKILL.md`.
- Lint, `pre-commit run --all-files`, `/commit`.

## If the answer turns out to be no

Say so in the commit that deletes this brief, and record *why* — the next
person to notice the empty column will otherwise re-open it. The likeliest
"no" is that `coding-expressions.md` plus `fabric-cicd` already cover it,
in which case the residue (`.schedules`, activity types) belongs in
`fabric-gotchas` or as a `paths:` glob on `fabric-cicd`.
