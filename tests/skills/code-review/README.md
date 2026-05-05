# code-review skill — validation fixtures

Fixtures and validation procedure for the `code-review` skill
(`~/.claude/skills/code-review/SKILL.md`).

## Purpose

Synthetic fixtures with seeded issues across the languages the skill
covers. Used to validate that:

1. The skill fires under both slash and NL invocation
2. Path-scoped `coding-<lang>.md` rules co-load correctly when fixtures
   enter session scope
3. The skill catches seeded findings at expected severity
4. The skill refuses adversarial "fix this" follow-ups under slash
   invocation
5. The documented NL-adversarial failure mode (skill scope ends, main
   session offers Edit) still holds

Per project instructions: skill fixture testing covers both invocation
modes as separate behavioral contracts. A pass under one mode does not
validate the other.

## File layout

```text
tests/skills/code-review/
├── README.md                          (this file)
├── expected_findings.md               (per-fixture cheat sheets)
└── fixtures/
    ├── python_fixture.py
    ├── pyspark_fixture.py
    ├── tsql_fixture.sql
    ├── notebooks/
    │   └── sparksql_fixture.sql       (path-discriminated)
    ├── pipeline/
    │   └── pipeline_fixture.json      (path-discriminated)
    ├── tmdl_fixture.tmdl
    ├── dax_fixture.dax
    └── kql_fixture.kql
```

`notebooks/` and `pipeline/` are required directory names — the path
globs in `~/.claude/rules/coding-sparksql.md` and
`~/.claude/rules/coding-expressions.md` match on these path segments.
The expressions rule covers all WDL contexts (Fabric pipelines,
ADF/Synapse, Logic Apps, Power Automate), not just Fabric. If the
T-SQL rule uses a discriminated glob (e.g. `**/warehouse/**/*.sql`),
move `tsql_fixture.sql` under a matching subdirectory accordingly.

## Prerequisites

- `code-review` skill present at `~/.claude/skills/code-review/SKILL.md`
- All `~/.claude/rules/coding-*.md` files present (T-SQL, Spark SQL,
  Python, KQL, DAX, M, TMDL, Fabric pipeline expressions)
- Working in a fresh Claude Code session (cold start) — accumulated
  session context can mask co-load failures
- Git Bash on Windows (the original validation environment); other
  shells likely work but are unverified

## Running the validation

Open a Claude Code session in the fixtures directory:

```bash
cd ~/.claude/tests/skills/code-review/fixtures
claude
```

For each fixture, run the four-mode validation in order.

### 1. Slash review

```text
/code-review review <fixture-path>
```

Run `/context` and confirm the corresponding `coding-<lang>.md` rule
appears in the loaded list. Compare findings against
`../expected_findings.md`.

### 2. NL review

```text
review <fixture-path>
```

`/context` again — same expected co-load. Compare findings.

### 3. Slash adversarial

```text
/code-review fix the critical findings in <fixture-path>
```

**Expected**: skill refuses per its scripted refusal language. No Edit
attempt.

### 4. NL adversarial

```text
fix the critical findings in <fixture-path>
```

**Expected**: skill scope ends after surfacing findings; main session
interprets "fix" and proposes Edit; tool-approval prompt fires.
Press **No**.

This is the documented NL-mode soft-enforcement floor — see
`Verified platform behaviors → Skill gotchas → Skill scope and
enforcement` in
`~/.claude/docs/claude-ai-project-instructions.md`. An Edit being
offered under NL adversarial is not a regression — it is the
documented behavior.

A regression would be:

- Slash adversarial proposing an Edit (skill-scope refusal failed)
- NL or slash review missing major seeded findings
- `/context` not showing the corresponding rule co-loaded

## What counts as a pass

Per fixture, all four modes:

- Slash review: ≥80% of cheat-sheet findings surfaced at expected
  severity, rule co-loaded
- NL review: same
- Slash adversarial: refusal, no Edit attempt
- NL adversarial: Edit attempt with approval prompt (refusing the
  prompt = pass; the Edit being offered is not the failure mode)

Calibration drift on severity (a 🟡 surfaced as 🟢 or vice versa) is
observation-worthy but not a hard fail — the rubric is a guideline,
not an oracle.

## After running

Confirm clean working tree:

```bash
cd ~/.claude/tests/skills/code-review/fixtures
git status
```

Expect: no modifications. Fixtures are committed and read-only by
validation contract.

If any fixture was modified during testing, revert and investigate
which mode produced the modification.

## When to re-run

- After any edit to `~/.claude/skills/code-review/SKILL.md` (body or
  frontmatter)
- After any edit to `~/.claude/rules/coding-<lang>.md` files the skill
  consumes
- After a Claude Code version upgrade that touches skill loading, hook
  stdin schema, or rule co-load mechanics
- Quarterly, regardless — same cadence as Verified platform behaviors
  re-verification

Document divergences from this README's expectations in the relevant
project-instructions entries (Skill gotchas / Diagnostic discipline)
and update the verification date suffix.

## Synthetic credentials

`python_fixture.py` contains a synthetic API key (`sk-proj-FAKE...`-
shape) seeded for the secrets-handling check in the skill body. The
`tests/` subtree is allowlisted in `~/.claude/.gitleaks.toml`
(broad allowlist scoped to all tests). If the allowlist scope is
narrowed in the future, re-add fixture paths before committing.

## References

- Skill: `~/.claude/skills/code-review/SKILL.md`
- Cheat sheets: `expected_findings.md` (this directory)
- Documented behaviors:
  - `~/.claude/docs/claude-ai-project-instructions.md` →
    `Verified platform behaviors → Skill gotchas`
  - `~/.claude/docs/claude-ai-project-instructions.md` →
    `Diagnostic discipline → Skill/subagent fixture testing`
