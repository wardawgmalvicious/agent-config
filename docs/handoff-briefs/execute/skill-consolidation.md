# Handoff: reduce skill activation cost (glob hygiene, body slimming, merges)

- **Written**: 2026-08-31, from the measurements in
  [skill-listing-field-evidence.md](skill-listing-field-evidence.md).
- **Kind**: policy + content pass. The three workstreams below are ordered by
  risk, cheapest and safest first. **Workstream C changes skill names** and
  must not start before A and B land.
- **Status**: open brief.
- **Run in**: a fresh session. This brief plus the field-evidence brief are the
  whole context; nothing else from the authoring session is needed.

## Why

Two different costs were conflated in earlier work. Separating them:

| Cost | Paid by | Size | Fixed by |
| --- | --- | --- | --- |
| **Listing** | the 25 **unconditional** skills, every session | ~7,437 tokens | trimming `description` — tracked in [skill-optimization-pass.md](skill-optimization-pass.md), *not here* |
| **Activation** | the 19 **conditional** skills, when a `paths:` glob matches | ~64,116 tokens of bodies total; **~11,922 from touching one `visual.json`** | this brief |

Conditional skills cost **zero** listing tokens until they fire, so none of
this is about the skill listing. It is about what lands in context the moment a
file is opened. Measured in `C:\Repos\ACME\fabric-acme` (295 tracked files).

The user's framing was consolidation. The measurements say consolidation is the
*third*-best lever and the only one carrying rename risk — two cheaper fixes
come first.

## Measured facts (2026-08-31, ACME)

Worst observed single file — one report visual, 4 skills, **~11,922 tokens**:

```text
Analytics/ACME_RP_Operation.Report/definition/pages/DailySnapshot/visuals/barCustomersToday/visual.json
  -> pbip-project-structure, pbir-conditional-formatting, pbir-filters, pbir-visual-json
```

Top co-activation pairs (files where both fire):

| Files | Pair | Bodies |
| --- | --- | --- |
| 82 | `pbip-project-structure` + `pbir-filters` | ~6,137 tok |
| 73 | `pbir-filters` + `pbir-visual-json` | ~6,390 tok |
| 73 | `pbir-conditional-formatting` + `pbir-visual-json` | ~5,785 tok |
| 73 | `pbip-project-structure` + `pbir-visual-json` | ~5,926 tok |
| 36 | `fabric-error-handling` + `fabric-spark` | ~4,418 tok |
| 23 | `fabric-tmdl` + `pbip-project-structure` | ~5,596 tok |

All 19 conditional skills, by body size (the part that loads on activation):

| Skill | Body | refs | ACME matches |
| --- | --- | --- | --- |
| `fabric-warehouse` | ~7,214 tok | 1f / 8.7 KB | 45 |
| `fabric-data-agent` | ~7,128 tok | 1f / 4.2 KB | 0 |
| `fabric-eventstream` | ~6,383 tok | **0f / 0 KB** | 24 |
| `fabric-eventhouse` | ~4,788 tok | 1f / 10.8 KB | 10 |
| `fabric-semantic-model-ai-instructions` | ~3,701 tok | 1f / 3.7 KB | 0 |
| `pbir-filters` | ~3,301 tok | 1f / 4.1 KB | 82 |
| `pbir-visual-json` | ~3,089 tok | 1f / 5.5 KB | 73 |
| `fabric-spark` | ~3,028 tok | 1f / 6.8 KB | 36 |
| `pbir-pages` | ~2,991 tok | 1f / 4.6 KB | 9 |
| `pbir-themes` | ~2,913 tok | 1f / 4.5 KB | 3 |
| `pbip-project-structure` | ~2,837 tok | 1f / 6.9 KB | **148** |
| `fabric-tmdl` | ~2,759 tok | 1f / 22.4 KB | 23 |
| `pbir-conditional-formatting` | ~2,696 tok | 1f / 4.0 KB | 73 |
| `fabric-variable-library` | ~2,693 tok | 1f / 6.4 KB | 7 |
| `fabric-graph` | ~2,662 tok | 1f / 16.6 KB | 0 |
| `pbir-bookmarks` | ~2,097 tok | 1f / 3.6 KB | 0 |
| `fabric-realtime-dashboard` | ~1,839 tok | 1f / 3.2 KB | 2 |
| `fabric-error-handling` | ~1,390 tok | 1f / 6.3 KB | 36 |
| `fabric-database` | ~608 tok | 1f / 7.7 KB | 0 |

Body tokens estimated at ~3.5 chars/token (prose+code, looser than the ~2.7 of
description text). Treat as relative weights, not billing figures.

## Workstream A — glob hygiene (do first; no renames, no rewrites)

Narrowing an over-broad `paths:` glob removes a whole body from activations it
never should have joined. Zero content risk: the skill is unchanged.

**A1. `pbip-project-structure` — the single biggest win.**
Current globs match 148 of 295 files:

```yaml
paths:
  - "**/*.pbip"
  - "**/*.pbir"
  - "**/*.pbism"
  - "**/.platform"
  - "**/*.Report/**"        # <- matches every file in every report
  - "**/*.SemanticModel/**" # <- matches every file in every semantic model
```

The last two turn an orientation skill ("how a PBIP project is laid out") into
a passenger on nearly every Power BI file touch. The first four already match
the files that *are* the project structure. **Proposal: drop the last two.**
Re-measure the match count afterwards; expect ~40 rather than 148.

Judgment call for the user: dropping them means the skill no longer fires when
someone opens a report file deep inside a project without touching a
`.platform` / `.pbip` manifest. Whether project-structure orientation is
wanted in that case is the actual question.

**A2. Audit the other 18 the same way.** `fabric-tmdl` already had this exact
bug fixed in `a31c150` (`**/definition/**` matched 84 report JSON files). Use
the harness in "Verifying" below; look for any glob whose match count is far
above the number of items of that type in the repo.

## Workstream B — body slimming (do second; no renames)

`SKILL.md` **body** loads in full on activation. Files under `references/` load
only when the model chooses to read one. So moving detail from body to
`references/` cuts activation cost directly, with no merging and no rename.

Highest-value targets, all single-skill activations where no merge is even
relevant:

- **`fabric-eventstream`** — ~6,383-token body and **no `references/`
  directory at all**. Fires on 24 ACME files. Best single target in the repo.
- **`fabric-warehouse`** — ~7,214-token body, largest overall, fires on 45
  files.
- **`fabric-data-agent`** — ~7,128 tokens. Fires on 0 ACME files but will fire
  in any repo with a `.DataAgent` item.
- **`fabric-eventhouse`** — ~4,788 tokens.

Those four alone are ~25,500 tokens of body. Compare the whole listing budget:
10,000.

Keep in the body: triggers, the decision rules, the gotchas that must be known
*before* acting. Move to `references/`: syntax tables, exhaustive property
lists, long worked examples, API payload shapes. `fabric-tmdl` is the existing
model to copy — 22.4 KB of references against a ~2,759-token body.

Set a target body size and hold to it. **Suggested: ~1,500 tokens** (~5,250
chars); nine of the 19 already sit under it.

## Workstream C — merges (do last; renames skills)

Only justified where globs are identical or near-identical, so the skills can
never fire independently anyway.

**C1. `fabric-spark` + `fabric-error-handling`** — **identical** globs
(`**/*.Notebook/**`), 36 ACME files each, always co-fire, ~4,418 tokens
combined. There is no scenario where one is wanted and not the other. Strongest
merge case in the repo.

**C2. The `pbir-*` visual cluster** — `pbir-visual-json` (73 files),
`pbir-conditional-formatting` (73), `pbir-filters` (82). Overlapping but not
identical: `pbir-filters` also covers `report.json` and `page.json`. ~9,085
tokens combined. Merging all three into one visual-authoring skill with three
`references/` files is the obvious shape, but it is also the most opinionated
change in this brief — confirm with the user before doing it.

**C3. Leave alone.** `fabric-tmdl` + `fabric-semantic-model-ai-instructions`
co-appear in the pair table only via `pbip-project-structure`; they have
disjoint globs (`*.tmdl` vs `definition/cultures/*.tmdl`) and 0 co-activations
in ACME. Not a merge candidate.

### The rename trap — read before any merge

A merge changes skill *names*, and three places hardcode them. None of them
error when a name goes stale; they just silently stop doing anything.

1. **`.claude/settings.json` in this repo** lists all 37 platform skill names
   under `skillOverrides`. A key naming a skill that no longer exists is
   ignored silently.
2. **`~/.claude/skills/` holds one junction per skill name.** Re-run
   `./scripts/link-claude.ps1` after any rename; a removed skill's junction is
   pruned only for names resolving inside this repo's `skills/`.
3. **Client repos deployed with `-ClaudeDir`** (ACME has 37 project skills in
   `.claude/skills`). Each needs its own relink after a rename.

Also: merged-away names lose their `skillUsage` history in `~/.claude.json`,
and any `/name` muscle memory breaks. Note the retired names in the commit
message so the history stays traceable.

## Verifying

Re-run this after every glob change. It is how A1, A2 and the `fabric-tmdl`
fix were all measured:

```bash
cd <client-repo> && git ls-files > /tmp/files.txt
```

```python
# uv run --with pyyaml --with wcmatch python thisfile.py
import pathlib, yaml
from wcmatch import glob as wg
F = wg.GLOBSTAR | wg.DOTGLOB
files = [l.strip() for l in open('/tmp/files.txt', encoding='utf-8') if l.strip()]
for p in sorted(pathlib.Path('skills').glob('*/*/SKILL.md')):
    d = yaml.safe_load(p.read_text(encoding='utf-8').split('---', 2)[1])
    if not d.get('paths'):
        continue
    hits = [f for f in files if wg.globmatch(f, d['paths'], flags=F)]
    print(f"{len(hits):4d}  {d['name']}")
```

A match count far above the number of items of that type is the bug signature.

Then, per root `CLAUDE.md`:

- Lint every touched skill:
  `uv run --with pyyaml scripts/lint-frontmatter.py skills/<group>/<name>/SKILL.md`
- `pre-commit run --all-files`
- `./scripts/link-claude.ps1` after any rename; confirm `~/.claude/skills`
  holds one junction per current skill name and no stale ones.
- Fresh-session check: open a file that should trigger the changed skill and
  confirm it activates. `paths:` is frontmatter, so **restart before trusting
  a changed trigger** — hot-reload of an in-place frontmatter edit is the one
  case not verified on this machine.
- `tests/` untouched; `git status` clean; finish with `/commit`.

## Constraints

- Fixtures under `tests/` are never modified.
- Skill bodies are the payload — do not delete content to hit a size target.
  Move it to `references/` or leave it alone.
- A wrong glob has no error path; it just never fires. Every glob edit gets
  re-measured, never assumed.
- Workstreams A and B are independent of each other and of C. A and B are
  safe to land incrementally, one skill per commit if preferred.
- Description trimming belongs to
  [skill-optimization-pass.md](skill-optimization-pass.md), not here. Do not
  justify a description edit with activation-cost evidence — different budget.
