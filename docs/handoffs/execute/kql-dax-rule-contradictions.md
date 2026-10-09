---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-08
---

# Handoff: correct where coding-kql and coding-dax contradict their sources

- **Written**: 2026-10-08, from three findings that cold `/code-review`
  runs made against the rules themselves while verifying prompt-audit
  2026-10-08 brief 06 (closed at `7ff8cf2`). Each is re-measured below
  against the source the rule cites or should.
- **Kind**: corrections to user-scope rules, their examples, and the
  code-review cheat sheet that leans on them. No decision is open:
  each source settles its claim.

## coding-kql calls a syntax rule a convention

`claude/rules/coding-kql.md` § "Casing" says lowercase operators are
"the KQL convention; do not uppercase like T-SQL" (lines 23–25 on
2026-10-08), and lists lowercase functions beside them. The KQL
overview says "KQL is case-sensitive for everything – table names,
table column names, operators, functions, and so on" (read
2026-10-08). So `WHERE` or `TOLOWER()` is no style slip but a query
that does not run, which the review of the KQL fixture said unprompted.

Fix: give that reason, and keep the list. Not captured: the parser's
error text for an uppercase operator. Any Kusto query endpoint gives
it, and the rule should quote it if the session can run one.

## coding-kql's Good example compares a string column with a number

Lines 67 and 90 write `| where ResultType != 0` on `SigninLogs`. Azure
Monitor's table reference types `SigninLogs.ResultType` as `string`,
"the 5-6 digit error code … 0 indicates success" (read 2026-10-08).
The filter should be `!= "0"`, which matches the column's type
whatever Kusto does with a string against a long. Not probed: whether
that mismatch errors or converts; `print ResultType = "0" | where
ResultType != 0` on any Kusto endpoint says which, and decides only
how the rule words it.

## coding-dax's examples break its own argument rule

`claude/rules/coding-dax.md` § "Indentation and whitespace" puts
"Function arguments on separate lines for any function with 2+
arguments or any argument that's itself a non-trivial expression"
(lines 76–77), and the rule is anchored on SQLBI, whose
[Rules for DAX code formatting](https://www.sqlbi.com/articles/rules-for-dax-code-formatting/)
say "Always put arguments on a new line if the function call has 2 or
more arguments" and "Write a function inline only if it has a single
argument that is not a function call" (read 2026-10-08). The rule's
own examples keep two-argument calls on one line: `Margin % = DIVIDE (
[Profit], [Revenue] )` under `-- Good` (line 101), and the
`CALCULATE` and `DIVIDE` calls in § "Variables" (lines 60 and 62). The
review of the DAX fixture followed the examples, and said so.

Fix: bring the fenced examples to the rule. The calls written inline in
prose bullets (lines 118–120 and 179) and the `NAMEOF` output table
(lines 192–195) show a single call each and can stay on one line; say
so if they stay.

`claude/rules/coding-tmdl.md` inherited the error: `d68e755` kept
`TOTALYTD ( [Total Sales], 'Date'[Date] )` on one line (line 118),
citing the `DIVIDE ( a, b )` precedent. In TMDL a multi-line measure
expression sits one level deeper than the measure's properties (TMDL
overview), so re-check that fence by deserializing it, with the snippet
in `tmdl-space-indentation.md` § "Reproducing the probe".

## Where it lands

- `claude/rules/coding-kql.md`, `coding-dax.md` and `coding-tmdl.md`.
  Each has a frozen Copilot port, and
  `copilot/instructions/coding-kql.instructions.md` repeats all three
  KQL lines: leave the ports, and re-stamp with
  `uv run --with pyyaml scripts/lint-instructions.py --stamp`
  (`.claude/rules/editing-rules.md`).
- `tests/skills/code-review/expected_findings.md` § `kql_fixture.kql`:
  the uppercase findings become correctness, not "(Style …)" and "KQL
  convention is **lowercase**", and the fixture's line 10,
  `ResultType != 0`, earns the finding the sheet lacks. The fixtures
  stay as committed.
- Deploy from the main checkout with
  `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`, then
  `cmp` each deployed rule against the repo's.
- Verify with a cold slash review of the KQL and DAX fixtures, launched
  from PowerShell: Git Bash rewrites `/code-review` into a path and no
  skill runs (`~/.claude/CLAUDE.md` § "Shell traps").

## Re-measure before acting

```bash
grep -n "KQL convention\|ResultType != 0" claude/rules/coding-kql.md   # 25, 67 and 90 on 2026-10-08
grep -n "separate lines\|DIVIDE ( \[Profit\]" claude/rules/coding-dax.md   # 76 and 101
grep -n "TOTALYTD" claude/rules/coding-tmdl.md   # 118
```
