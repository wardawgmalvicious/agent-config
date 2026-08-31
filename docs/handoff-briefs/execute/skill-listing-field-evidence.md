# Handoff: field evidence for the skill listing budget (live deployed repo)

- **Written**: 2026-08-31, from a `/doctor` + `/context` run inside `C:\Repos\ACME\fabric-acme`
  (the ACME client repo, where all 37 platform skills + 7 workflow skills are
  deployed via `link-claude.ps1 -ClaudeDir`).
- **Kind**: measurement input. **No edits proposed here.** This brief exists to
  fill in step 1 of [skill-optimization-pass.md](skill-optimization-pass.md)
  ("Measure before touching anything") and to settle two of its three open
  questions with evidence.
- **Status**: open brief — fold the numbers into `skill-optimization-pass.md`
  and delete this file, per the README convention. It is deliberately scoped
  so it can be consumed and discarded in one pass.
- **Run in**: read it anywhere; the numbers were taken in the ACME repo and are
  only reproducible there (agent-config itself deploys just the 7 workflow
  skills, so truncation is invisible from inside the home repo).

## Why this exists

`skill-optimization-pass.md` states the listing is over budget and infers that
"long descriptions are probably already being silently shortened in most
sessions." That inference is now **confirmed and quantified** — and one of its
supporting assumptions turns out to be wrong (see "Drop order" below, which
changes which lever in step 5 is reliable).

The home repo cannot show this. Only 7 skills deploy there; the ACME repo
deploys all 44, which is where the budget actually binds.

## Measured facts (2026-08-31)

Environment: Claude Code `2.1.251`, model Opus 5 `[1m]` (1M context window),
cwd `C:\Repos\ACME\fabric-acme`, 44 skills deployed (7 user-scope via
`~/.claude/skills`, 37 project-scope via `.claude/skills`).

- **44 skills, 35,540 description chars** measured from the deployed
  `SKILL.md` frontmatter (description field only). Adding each entry's `name`
  plus delimiters gives **37,769 chars** of listing text if every skill were
  listed — **~13,000 tokens** at the measured 2.7 chars/token rate for this
  content (see "Measurement lesson" below; a chars/4 estimate would say 9,442
  and be wrong by ~46%).
  *(`skill-optimization-pass.md` records 36,830 desc chars from the home repo
  the same day — measure once in the executing session and use one number.)*
- **19 of the 44 skills were absent from the session's skill listing.** Not
  shortened — absent entirely, name and description both.
- Absent set: **16,793 desc chars ≈ 6,150 tokens** never reached the model.
  Present set: 18,747 desc chars = 6,860 tokens (`/context`-measured, user +
  project rows).

### The 19 skills dropped from the listing

All project-scope (`fabric-acme/.claude/skills`), listed with lifetime
`skillUsage` count in parentheses:

```text
fabric-data-agent (0)          pbip-project-structure (2)
fabric-database (0)            pbir-bookmarks (0)
fabric-error-handling (1)      pbir-conditional-formatting (0)
fabric-eventhouse (0)          pbir-filters (3)
fabric-eventstream (4)         pbir-pages (0)
fabric-graph (0)               pbir-themes (0)
fabric-realtime-dashboard (0)  pbir-visual-json (1)
fabric-semantic-model-ai-instructions (0)
fabric-spark (1)               fabric-tmdl (1)
fabric-variable-library (1)    fabric-warehouse (2)
```

**Ruled out as causes** — verified, not assumed:

- None of the 19 sets `disable-model-invocation` or `allowed-tools`.
- All 44 frontmatter blocks parse; every `name` field matches its directory
  name; no missing `description`.
- All 19 `SKILL.md` files are readable through their junctions (sizes were
  measured from them in the same pass), so this is not a broken-link artifact.

That leaves the aggregate listing budget as the only remaining explanation.

### Drop order does NOT follow lifetime invocation count

`skill-optimization-pass.md` records the upstream behaviour as "dropped
starting with the least-invoked skills." **The observed drop set contradicts
that**, at least for whatever counter is visible to us:

| Kept, never used | Dropped, has usage |
| --- | --- |
| `fabric-copy-job` (0) | `fabric-eventstream` (4) |
| `fabric-mirroring` (0) | `pbir-filters` (3) |
| `fabric-security` (0) | `fabric-warehouse` (2) |
| `fabric-rest-api` (0) | `pbip-project-structure` (2) |

Nor does it split by description length (dropped avg 884 chars vs kept-project
avg ~830) or alphabetically.

**Why this matters for step 5**: if the drop order cannot be predicted from
usage, then `skillOverrides: name-only` on "never-invoked" skills is not a
targeted fix — you cannot steer *which* skills survive by usage. The levers
that reliably work are the ones that shrink the total: trim descriptions, raise
`skillListingBudgetFraction`, or remove competing consumers. Worth re-deriving
the real ranking rule from upstream before relying on any usage-based
targeting.

### The most-relevant skills are the ones being lost

In a Fabric eventstream/warehouse/variable-library repo, the dropped set
includes `fabric-eventstream`, `fabric-warehouse`, `fabric-variable-library`,
`fabric-tmdl`, `fabric-spark`, `fabric-eventhouse`, and
`fabric-realtime-dashboard` — precisely the skills this repo exists to use, and
several with demonstrated invocation history. Auto-triggering for them is
currently impossible; only an explicit `/name` reaches them.

## Open question settled: what the invocation log counts

`skill-optimization-pass.md` asks: *"Does the invocation log capture user-typed
`/slash` runs, or only Skill-tool calls?"*

**Answer: Skill-tool calls only. `skillUsage` in `~/.claude.json` counts both.**

Two independent confirmations, from a 50-transcript scan (2026-08-28 → 08-31,
5 projects) cross-referenced against `~/.claude/logs/skills-invoked.log`
(24 entries, 2026-08-25 → 08-31):

| Skill | `skillUsage` (lifetime) | `skills-invoked.log` | Slash typed (transcripts) | Skill-tool (transcripts) |
| --- | --- | --- | --- | --- |
| `doctor` | 2 | **0** | 2 | 0 |
| `init` | 14 | **0** | 2 | 0 |
| `drift-update` | 9 | **0** | 9 | 0 |
| `commit` | 53 | 14 | 15 | 8 |

`/doctor`, `/init` and `/drift-update` have non-zero `skillUsage` and **zero**
log entries, having only ever been typed as slash commands. So:

- The `PostToolUse`/`Skill` hook is blind to slash invocations — the frequency
  table in `skill-optimization-pass.md` ("commit 14, learn 5, pbir-filters 2,
  drift-audit 2, powerbi-report-design 1") is a **Skill-tool-only** table and
  understates real use. Read it as "how often the model chose the skill on its
  own", which is arguably the more useful signal for trigger tuning — but it is
  not total usage.
- `skillUsage` counters are the total-usage source. Note they are lifetime and
  never reset.

To capture slash invocations too, the hook would need a `UserPromptSubmit`
event parsing `/<name>`, since no `Skill` tool call occurs on that path.

## Open question settled: the budget is tokens, exactly 1% of the window

`/context` in the same session, same repo:

```text
Skills            10k        1.0%          (of 1m context window)
Memory files      14.8k      1.5%
Messages         136.6k     13.7%
Free space       816.7k     81.7%
```

**The listing is saturated at exactly 1.0% — 10,000 tokens of a 1M window.**
Characters are ruled out (the loaded set alone is 18,747 chars). The budget
fraction behaves precisely as documented.

### Full accounting — every token in the 10k, by source

| Source | Skills listed | Tokens (from `/context`) |
| --- | --- | --- |
| Project (`fabric-acme/.claude/skills`) | 18 of 37 | **5,100** |
| Built-in (bundled in the CLI, not removable) | 16 | ~2,460 |
| User (`~/.claude/skills`) | 7 of 7 | 1,760 |
| Plugin (4 enabled plugins) | 11 | ~720 |
| **Total** | **52 of 71** | **~10,040** |

The 19 dropped project skills account for the missing ~6,150 tokens. The
arithmetic closes: all 44 repo skills want ~13,000 tokens; built-ins and
plugins consume ~3,180 of the 10,000 cap; the ~6,820 remaining fits exactly the
25 that loaded.

### Measurement lesson for the linter (step 2)

`scripts/lint-frontmatter.py` gates on **characters** (`DESCRIPTION_MAX = 1536`);
the budget spends **tokens**. Measured against `/context`, these descriptions
tokenize at **~2.7 chars/token** — denser than ordinary prose (~4), because they
are packed with backticked identifiers, hyphenated skill names and API symbols.

Consequence: a description at the full 1,536-char cap is **~560 tokens**. Forty-
four of those would be ~24.6k tokens — **2.5× the entire listing budget**. The
per-skill cap and the aggregate budget are not just independent limits (as the
pass already notes); they are denominated in different units, and the char cap
is the looser of the two by a wide margin. A chars/4 estimate understates real
cost by ~46% for this content — do not size the trim with it.

### Which lever, now that the numbers are exact

| Lever | Effect | Cost |
| --- | --- | --- |
| **Raise `skillListingBudgetFraction` 1% → 1.5%** | 10k → 15k; **all 44 fit immediately**, no rewriting | 5k tokens on a 1M window = 0.5% of context. Session measured here sat at 18% used, 816.7k free. |
| Disable 4 unused plugins | frees ~720 tokens → ~2–3 more skills | none — zero lifetime uses |
| Halve every description | ~296 → ~155 tokens avg, fits all 44 in the current 1% | 44 rewrites, each risking trigger quality |

**Recommendation: raise the fraction first, then trim descriptions as a
separate, unhurried pass.** The raise is one settings key and fixes the outage
now; the trim is still worth doing (it helps on smaller-context models, where
1% is far less than 10k) but it should not be the emergency fix. Note the raise
needs `link-claude.ps1 -Force` to deploy, and verify the setting key against
current upstream docs before relying on it.

## Cheap lever not currently in step 5: four unused plugins

Four plugins are enabled at user scope with **zero lifetime uses** each
(`pluginUsage` counts of 0; their identical `lastUsedAt` values are
install-time seeds, not usage; no transcript hits in the scan window):

`/context`-measured cost, which is **higher than the listing alone** — three of
them also ship subagents, and those sit in the Custom agents category, outside
the skills budget but still resident every session:

| Plugin | Skills listing | Custom agents | Total tokens |
| --- | --- | --- | --- |
| `plugin-dev` (8 skills, 3 agents) | ~530 | 1,243 | **~1,773** |
| `skill-creator` | ~120 | — | ~120 |
| `claude-md-management` | ~50 | — | ~50 |
| `claude-code-setup` | ~20 | — | ~20 |
| **Total** | **~720** | **1,243** | **~1,963** |

For scale: `plugin-dev`'s three subagents (`agent-creator` 406,
`skill-reviewer` 408, `plugin-validator` 429) cost **more than ten times** the
repo's own `security-reviewer` agent (117), and all three have never been used.

Disabling all four (`enabledPlugins` → `false` in `claude/settings.json`, then
`link-claude.ps1 -Force`) returns **~720 tokens of listing budget** — roughly
two to three dropped skills' worth — plus **~1.2k tokens of agent context**
that is not competing for the same budget but is pure waste. No loss of
anything in use. Independent of, and complementary to, the description trim;
worth adding as a step-5 option.

## Unrelated finding worth a look: the PreToolUse hook fails on every run

`~/.claude/hooks/security-reviewer-memory-scope.sh` (user-scope, matcher
`Edit|Write`) recorded **4 runs in the scan window, all 4
`hook_non_blocking_error`, zero successes**. Median 322ms, so speed is fine
(well under the 2s bar for a per-tool-call hook) — this is a correctness
problem: it fires on every Edit/Write and errors out silently.

Static reading did not identify the cause. The main-session path should short
out at the `agent_type` guard and `exit 0`; `set -euo pipefail` plus the
`timeout 5 jq` wrapper is the most likely place a non-zero status leaks, but
that is a hypothesis, not a diagnosis. The hook is read-only (it only reads
stdin and exits with a status; the block path writes to stderr), so it is safe
to reproduce directly:

```bash
echo '{"tool_name":"Edit","tool_input":{"file_path":"C:/tmp/x.md"}}' \
  | bash ~/.claude/hooks/security-reviewer-memory-scope.sh; echo "exit: $?"
```

Fail-open means nothing is currently unsafe — the scope guard simply is not
enforcing, which matters if `security-reviewer` is ever pointed at a repo.

## What was NOT done

Nothing was changed. The user (solo developer, no team to coordinate with)
declined all edits in the originating session on the grounds that ACME is not
the skills' home repo — the skills are junctions from `agent-config` and are
not committed on the ACME side. Also deliberately left alone:

- `permissions.defaultMode: "auto"` in `claude/settings.json` — proposed and
  declined for now; auto mode is active per-session anyway.
- The ACME repo's own `CLAUDE.md` trim (~1.3k est. tokens available between
  derivable content and a lazy-loading migration) — that is ACME-side work and
  does not belong in this repo's queue.

## Reproducing these numbers

From a session inside a repo with the full skill set deployed:

- `/context` → Skills row (post-budget size actually received).
- `/doctor` → listing cost and biggest contributors.
- Skills absent from the listing: compare the session's skill listing against
  `ls .claude/skills` + `ls ~/.claude/skills`. The absence is silent; nothing
  warns at normal verbosity, which is the core hazard here.
