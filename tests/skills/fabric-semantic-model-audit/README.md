# `fabric-semantic-model-audit` — behaviour fixture

A **planning** semantic model, here to test the planning-model carve-out
added to `SKILL.md` §3 on 2026-09-03. Assertions are in
[expected_findings.md](expected_findings.md).

## Why this is not in `pbip-triggers/`

It looks like it belongs there — that set already holds a
`SampleModel.SemanticModel` — but the two directories test different
contracts, and this one would break that.

- `pbip-triggers/` and `fabric-triggers/` assert **`paths:` glob
  activation**: which skills enter context when a file is Read.
  `fabric-semantic-model-audit` is **unconditional** — it carries no
  `paths:` glob — so it has no activation contract to assert.
- `scripts/activation-expect.py` builds its file set with
  `base.rglob("*")` over `<set>/fixtures`, so **every file added there
  needs a row in that set's `expected_activations.md`** or the static
  check fails. Dropping ~20 model files into `pbip-triggers/fixtures/`
  would turn a passing 16/16 into a failing run, and not one of those
  rows would be about the carve-out.

This is a **behaviour** fixture, so it follows
[`../code-review/`](../code-review/README.md): `fixtures/` plus an
`expected_findings.md` stating what must be caught *and* what must not.

## Provenance

Microsoft's companion sample for the planning semantic-modeling guidance,
published in
[`microsoft/fabric-samples`](https://github.com/microsoft/fabric-samples/blob/main/docs-samples/iq/plan/semantic-modeling-sample.pbix)
as `docs-samples/iq/plan/semantic-modeling-sample.pbix`. Downloaded and
saved to PBIP from Power BI Desktop on 2026-09-03. It is Microsoft's own
reference implementation of the ten planning cases, which is the point —
the carve-out is checked against how Microsoft says a planning model is
built, not against a model written to make the skill pass.

**Only the semantic model's `definition/` is kept**, plus `.platform` and
`definition.pbism`. Dropped: the `.Report` folder (irrelevant to a model
audit, and it would pull `pbir-*` skills into an unrelated test), `.pbi/`
(`cache.abf` alone is 5.7 MB and is gitignored anyway), `TMDLScripts/`,
`diagramLayout.json`, and the `.pbip` entry point. 108 KB of text remains.

**The M partition source paths were scrubbed.** As published, eleven
tables embed the local OneDrive path of the person who built the sample,
including their name and employer. It is irrelevant to every check the
audit runs — tier D reads relationships and columns, not partition
sources — so each was rewritten to `C:\PlanningSample\<file>.csv`. Nothing
else in the model was altered.

## Running it

`fabric-semantic-model-audit` is pruned from `~/.claude/skills` by the
workflow-only deploy, **and it is unconditional**, so it cannot be reached by
path either — it is simply absent from the payload. It has to be deployed
before this fixture can be used at all.

[`scripts/test-semantic-model-audit.ps1`](../../../scripts/test-semantic-model-audit.ps1)
does all of it:

```powershell
./scripts/test-semantic-model-audit.ps1              # all three runs
./scripts/test-semantic-model-audit.ps1 -Mode nocarveout
```

It produces the runs; it does not grade them. Compare each written result
against `expected_findings.md` yourself — that judgement is deliberately not
automated, and the script's one heuristic says so at the point it prints.

What it does, and why each part is the way it is:

- **Deploys project-scoped, never into user scope.** The obvious form —
  `-SkillGroups workflow,fabric -Force` — pushes 29 skills into
  `~/.claude/skills`, visible to *every session on this machine* until a
  restoring run happens; a forgotten restore is exactly the 2026-08-31
  failure. None of it is necessary: **project scope only adds names user
  scope lacks**, and this skill is precisely such a name. `-SkillGroups`
  does not prune user scope when `-ClaudeDir` is given, so there is nothing
  to restore. The script captures the user-scope skill list before and
  compares after regardless, and a difference is a hard failure. It held at
  9 across every run on 2026-09-03.
- **Keeps the prompt neutral.** Naming planning, snowflakes or the carve-out
  hands the model the answer, so the prompt is a script constant rather than
  something a caller can pass.
- **Asserts the skill was actually invoked**, from the session transcript.
  A run where the skill never loaded audits the model off general knowledge,
  never fires check 1, and so "passes" criterion 2 for entirely the wrong
  reason. The baseline asserts the inverse.
- **Strips both carve-out references** in `-Mode nocarveout`, and fails if
  any survive. Removing §3's bullet while leaving §9's mention of it makes
  the build self-contradictory — see the methodology note in
  `expected_findings.md`.
- **Tears down each junction individually.** `Remove-Item -Recurse` across a
  reparse point has historically deleted the *target's* contents, which here
  is this repo's `skills/`.

Confirm the fixtures are unmodified with `git status` when finished. A run
that edits its own inputs invalidates every later comparison.
