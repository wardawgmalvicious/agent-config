---
paths:
  - "**/*.DataPipeline/pipeline-content.json"
  - "**/pipeline/*.json"
---

# Fabric Pipeline Expression Coding Conventions

Applies to expressions in Fabric data pipelines (`pipeline-content.json`).

The rules below apply to any Workflow Definition Language (WDL)
context — same language family, same function library, same idioms:

- Fabric pipeline expressions (auto-loads via `paths:` above)
- ADF / Synapse pipeline expressions (manually reference; no auto-load)
- Logic Apps / Power Automate expressions (manually reference)

**Out of scope**: Power Fx (Power Apps canvas formulas, Dataverse
formula columns) — different language, different file.

If a project-scope `.claude/rules/coding-expressions.md` exists, that
file supersedes this one.

## Naming

- **Pipeline parameters**: `PascalCase` — `SourceSchema`,
  `LoadStartDate`.
- **Pipeline variables**: `PascalCase` — `RowsLoaded`, `BatchId`.
- **Activity names**: `PascalCase`, action-oriented —
  `CopyCustomerToBronze`, `LookupBatchMetadata`. Spaces are technically
  allowed but break expression references; never use them.
- **Power Automate action names**: `PascalCase`. Same reason.
- **Trigger names**: `PascalCase` — `OnSchedule`, `OnHttpRequest`.

## Function casing

Built-in functions are **camelCase** by language definition:
`concat()`, `formatDateTime()`, `coalesce()`, `if()`, `length()`,
`split()`, `equals()`. Don't fight it.

```
// Good
@concat(pipeline().parameters.SourceSchema, '.', item().TableName)

// Bad (won't resolve)
@Concat(pipeline().parameters.SourceSchema, '.', item().TableName)
```

## Variable vs parameter vs activity output

- **Parameter**: input to the pipeline, set at trigger time. Immutable
  during the run. Use for environment-specific values
  (`TargetWorkspaceId`, `LoadDate`).
- **Variable**: mutable during the run, scoped to the pipeline. Use
  for accumulating state (row counts, error flags).
- **Activity output**: read directly via `activity('Name').output...`.
  Don't copy to a variable just to reference it later — adds
  indirection without value, unless you need to mutate it.

## Inline vs Set Variable

- Inline expressions where the value is used once and the expression is
  short.
- Extract to a `Set Variable` activity when:
  - The same expression repeats across activities (DRY).
  - The expression is long enough to obscure the activity it's inside.
  - You need to inspect the value in run history (variables show up;
    inline expressions don't).

## Null safety

WDL is unforgiving on nulls — referencing a property of a null object
fails the activity. Defend explicitly:

```
// Good
@coalesce(activity('LookupConfig').output.firstRow.BatchSize, 1000)

// Better when null path is possible at multiple levels
@if(
    empty(activity('LookupConfig').output.firstRow),
    1000,
    activity('LookupConfig').output.firstRow.BatchSize
)

// Bad (fails when firstRow is null)
@activity('LookupConfig').output.firstRow.BatchSize
```

## Type conversion

- Explicit, always: `string()`, `int()`, `bool()`, `float()`.
- `formatDateTime()` for date strings — never string-concatenate date
  parts.

```
// Good
@formatDateTime(utcNow(), 'yyyy-MM-dd')

// Bad
@concat(string(year(utcNow())), '-', string(month(utcNow())), '-', string(day(utcNow())))
```

## String building

- `concat()` for two-three pieces.
- `replace()` chains for token replacement.
- For anything more complex, build the string in a variable across
  multiple `Set Variable` activities so each step is inspectable.

## Long expressions

WDL has no native multi-line expression syntax. Two strategies:

1. Decompose into multiple `Set Variable` activities, each named
   for its purpose. Final variable holds the result.
2. Keep inline but format with deliberate whitespace inside the
   expression editor (it tolerates newlines):

```
@concat(
    pipeline().parameters.TargetSchema,
    '.',
    item().TableName,
    '_',
    formatDateTime(utcNow(), 'yyyyMMdd')
)
```

## Activity dependencies

Use the right edge condition:

- **Success**: default; downstream runs only on success.
- **Failure**: downstream runs only on failure (logging, alerts).
- **Completion**: runs regardless (cleanup, final logging).
- **Skipped**: runs when upstream was skipped (rare; usually
  diagnostic).

Don't paper over real failures with `Completion` to make the pipeline
"green" — that hides bugs.

## Documentation

- **Activity description field**: short purpose statement on every
  non-trivial activity. Two seconds to write, saves hours later.
- **Pipeline annotations** (Fabric / ADF): tags and annotations for
  searchability — environment, owner, criticality.
- **Power Automate**: comments on each action via the action's
  description.

## Anti-patterns

- Spaces in activity names — breaks `activity('Name with spaces')`
  references silently in some contexts.
- Hard-coding values that should be parameters (workspace IDs,
  connection strings, schemas).
- Deeply nested `if()` expressions — switch to a Switch activity or
  decompose into variables.
- Reading from a variable that was written earlier in the same
  ForEach iteration — variables are pipeline-scoped, not iteration-scoped;
  parallel iterations race. Use `Set Variable` only outside parallel
  ForEach, or set ForEach to sequential.
