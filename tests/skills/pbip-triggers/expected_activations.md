# Expected activations

Skill lists measured against the payload at commit `975b87f` and refreshed
2026-09-01, using the static glob check in [README.md](README.md). Refreshed
2026-10-12, when the six `pbir-*` file skills folded into
`pbir-report-workflow`, which has no `paths:`, and the `Tokens` column was
recomputed; and again that day, when `fabric-tmdl-api` and
`fabric-semantic-model-ai-instructions` folded into `fabric-tmdl`.

**The `Tokens` column is a ceiling, not a toll.** A `paths:` match injects
each skill's **listing entry** — a name, plus its description where
`skillOverrides` does not collapse it — and nothing more. The figures below
are *body* size at ~3.5 chars/token: what you would pay if every skill in
the row were then **invoked**. Treat them as relative weights and as the
worst case, never as the cost of opening the file. (Corrected 2026-09-01;
this table previously read as though a match loaded the bodies.)

| Fixture file | Activates | Tokens |
| --- | --- | --- |
| `control/notes.md` | *(none)* | 0 |
| `SampleReport.pbip` | `pbip-project-structure` | 2,948 |
| `SampleReport.Report/.platform` | `pbip-project-structure` | 2,948 |
| `SampleReport.Report/definition.pbir` | `pbip-project-structure` | 2,948 |
| `SampleReport.Report/definition/report.json` | *(none)* | 0 |
| `SampleReport.Report/definition/reportExtensions.json` | *(none)* | 0 |
| `SampleReport.Report/definition/pages/pages.json` | *(none)* | 0 |
| `…/pages/Page1/page.json` | *(none)* | 0 |
| `…/pages/Page1/bookmarks/bookmarks.json` | *(none)* | 0 |
| `…/pages/Page1/bookmarks/Bookmark1.bookmark.json` | *(none)* | 0 |
| **`…/pages/Page1/visuals/Visual1/visual.json`** | *(none)* | **0** |
| `SampleReport.Report/StaticResources/RegisteredResources/theme.json` | *(none)* | 0 |
| `SampleModel.SemanticModel/.platform` | `fabric-tmdl`, `pbip-project-structure` | 6,621 |
| `SampleModel.SemanticModel/definition.pbism` | `fabric-tmdl`, `pbip-project-structure` | 6,621 |
| `SampleModel.SemanticModel/definition/model.tmdl` | `fabric-tmdl` | 3,673 |
| `SampleModel.SemanticModel/definition/cultures/en-US.tmdl` | `fabric-tmdl` | 3,673 |

## Assertions that carry weight

**1. `visual.json` must not activate `pbip-project-structure`.** This is
the A1 regression test (`8ce009c`). Before that fix the same file pulled
four skills and ~11,923 tokens. It pulled three until 2026-10-12 and none
since, assertion 4 below; `pbip-project-structure` on it means the
over-broad `**/*.Report/**` glob is back.

**2. `.Report/.platform` activates `pbip-project-structure`, but a
`.platform` in any *other* item type must not.** A1's second half
narrowed a bare `**/.platform` — a Fabric item marker, not a PBIP one —
to the two PBIP item types. The positive half is the two rows above; the
negative half is proved in
[`../fabric-triggers/`](../fabric-triggers/expected_activations.md),
whose eleven non-PBIP `.platform` files pull no `pbip-project-structure`
between them.

**3. `control/notes.md` activates no *skill*.** If one fires, the
observation method is wrong — check this before believing any other row.
It does pull the `coding-markdown` **rule**, whose glob is `**/*.md`; that
is correct, and § "Rules load here too" below records the rules the other
fixtures load.

**4. No report file activates a skill.** The six `pbir-*` file skills
folded into `pbir-report-workflow` on 2026-10-12 as its references, and
the router has no `paths:`, so every row from `report.json` to
`theme.json` activates nothing. A skill on any of them means a report glob
is back. The router is listed at startup instead, and its body names the
reference to read before each hand edit.

That fold rests on use, not on the co-firing this assertion used to hold.
On 2026-09-01 a merge of the three skills that co-fire on `visual.json`
was declined, as saving at most ~700 listing tokens and only in client
repos. The fold came after client report work ran through the `pbir`
CLI, by Bash, which activates nothing: in a session of 72 `pbir`
commands no report file passed through `Read`, `Write` or `Edit`, so no
glob fired.

**5. No `.SemanticModel` file activates a semantic-model skill but
`fabric-tmdl`.** `fabric-tmdl-api` and
`fabric-semantic-model-ai-instructions` folded into it on 2026-10-12, as
`references/definition-api.md` and `references/ai-instructions.md`,
because neither glob ever fired alone. The API skill had carried
`**/*.SemanticModel/**`, `fabric-tmdl`'s own glob, since Workstream E
took it out of the session listing on 2026-09-01; the AI-instructions
glob, `**/*.SemanticModel/definition/cultures/*.tmdl`, sits inside it.
`fabric-tmdl`'s body names the reference to read before each of the two
jobs. A second semantic-model skill on any of these four rows means one
of them is back as a skill.

## Rules load here too

The rules pass, the static snippet in
[`../fabric-triggers/README.md`](../fabric-triggers/README.md) run over
`claude/rules/*.md`, first ran over these fixtures on 2026-10-13:

| Fixture file | Rules |
| --- | --- |
| every file under `SampleReport.Report/` or `SampleModel.SemanticModel/` | `fabric-git-serialization` |
| `SampleReport.pbip` | *(none)*: it sits outside both item folders |
| `control/notes.md` | `coding-markdown` **only** |
| `…/definition/model.tmdl`, `…/definition/cultures/en-US.tmdl` | + `coding-dax`, `coding-tmdl` |

So a report file that activates no skill, `visual.json` among them,
still loads a rule.

## Known gaps

The Fabric item-type skills are covered by
[`../fabric-triggers/`](../fabric-triggers/), which carries that set's own
gaps. Nothing in the Power BI half is untested.

## Refreshing this table

Token figures drift whenever a skill body changes — the Workstream B
splits moved four of them by thousands. Re-run the static check in
[README.md](README.md) and update the numbers; a changed number is
expected, a changed *skill list* is a regression.
