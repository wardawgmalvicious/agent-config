# Handoff: skill effectiveness telemetry (new capability candidate)

- **Written**: 2026-08-31, from a `/doctor` session in `C:\Repos\ACME\fabric-acme`.
  User's framing, verbatim in substance: *"It's difficult to see the
  effectiveness of the skills prior to deployment to an actual live repo, so
  maybe being able to gather some stats on the telemetry and effectiveness
  after a session could be useful in improving the skill. Not sure how much is
  captured via /learn."*
- **Kind**: scoping brief for a **new capability** — not yet a skill. The first
  decision (script vs skill vs both) is unmade and is step 1 below.
- **Status**: open brief, and it **stands alone** — unlike the context-cost
  work, it is not consumed by an existing pass.
- **Corrected 2026-08-31**: this brief was written citing a finding that was
  later retracted (see "One motivating example was wrong", below). The core
  case survives; one of the original three blind spots did not.
- **Run in**: a fresh session in `agent-config`. Everything needed is on disk.
- **Queue**: [README.md](README.md) has the execution order and what
  blocks what. This brief does not carry its own position.

## The gap, stated precisely

Skills in this repo are authored brief-first and validated by a fresh-session
smoke test. That validates *mechanics* — does it load, does it lint, does it do
the thing when invoked. It does not validate **triggering**, which is the part
that only fails in the wild:

- A skill whose description never matches real phrasing is indistinguishable,
  from inside the home repo, from a skill that works perfectly.
- A skill that is *withheld* from the listing looks identical to one that was
  listed and simply not needed. (Withholding is normally by design — see the
  correction below — but the observational problem is real either way: from
  inside a session you cannot tell "not offered" from "offered and declined".)
- A skill that fired but did not change the outcome looks identical to one that
  carried the whole session.

All three failure modes are invisible pre-deployment, and none of them raise an
error. That is the case for post-hoc telemetry.

## Does `/learn` already cover this? No — and the distinction is clean

`/learn` routes a *session learning* into persistent guidance: it identifies
which skills and rules were loaded, checks existing coverage, verifies against
docs, proposes an edit at the right heading. It is **qualitative, human-
triggered, and single-instance** — one insight, one edit.

What is proposed here is **quantitative and aggregate**: across N sessions,
which skills fired, which were listed but never chosen, which were not listed
at all. `/learn` answers "what did we learn"; this answers "which skills are
earning their listing budget." No overlap, and they compose well — telemetry
identifies a weak description, `/learn` (or `/author-skill`) fixes it.

## Data that already exists (measured 2026-08-31)

More is captured than the user may realise. Two hooks already write JSONL, and
`scripts/instructions-log` already queries them.

| Source | Volume | Range | What it gives |
| --- | --- | --- | --- |
| `~/.claude/logs/instructions-loaded.log` | **1,613 entries** | 2026-07-08 → 08-31 | `ts, cwd, file_path, load_reason, memory_type, prompt_id, session_id, transcript_path` |
| `~/.claude/logs/skills-invoked.log` | 24 entries | 2026-08-25 → 08-31 | `ts, session_id, cwd, skill, args` |
| `~/.claude.json` → `skillUsage` | 26 skills | lifetime, never resets | per-skill `usageCount`, `lastUsedAt` |
| `~/.claude/projects/**/*.jsonl` | 136 files | — | every tool call, slash invocation, denial, hook run |

`load_reason` distribution across the 1,613 rows — this is the interesting one,
because it is already a *triggering* signal for rules:

```text
session_start     1190      path_glob_match    185
include            146      compact             44
nested_traversal     3
```

`path_glob_match` (185) is the rules layer demonstrably firing on real work.
There is no equivalent field for skills.

**Critical correction to carry in** (established in the sibling brief):
`skills-invoked.log` captures **Skill-tool dispatches only**, never user-typed
`/slash` runs — `/drift-update` has 9 slash invocations and 0 log entries. Any
aggregation built on that log alone will understate usage badly. `skillUsage`
counts both; transcripts distinguish them. Use all three or the numbers lie.

## The four blind spots

1. **Listed but not chosen.** No record exists of skills that were in the
   listing and passed over. This is the single highest-value signal for
   description tuning and the hardest to get — it requires knowing the listing
   contents at each turn, which nothing logs today.
2. **Not listed at all.** Budget truncation is silent. Detectable only by
   diffing skills-on-disk against the session's actual listing. A skill can
   look "unused" for months when it was never offered.
3. **Fired but ineffective.** No outcome linkage. Approximations are possible
   (did the session continue down the skill's path? was it re-invoked? did the
   user correct immediately after?) — all inferential, none clean.
4. **Invoked but never logged.** *(added 2026-09-01)* `skills-invoked.log`
   misses a slash invocation that the harness expands inline instead of
   routing through the `Skill` tool. Measured: a `/commit` run carried
   `attributionSkill=commit` on all 22 of its assistant messages in the
   session transcript and wrote **zero** rows to the log, because the
   `PostToolUse` matcher `Skill` never fired — there was no `Skill` tool call
   to match. A comparable `/commit` earlier the same evening (session
   `ca10585c`) *did* route through the tool — 1 `Skill` tool_use block — and
   *was* logged. So the same user-visible invocation is recorded or not
   depending on an expansion path the hook cannot observe, and
   `skills-invoked.log` counts are a **floor, not a total**.

Blind spot 2 is mechanically solvable today. Blind spot 1 needs a new capture
point. Blind spot 3 may not be worth chasing.

Blind spot 4 is already solved by a data source this brief did not know about.
The per-session transcripts at `~/.claude/projects/<project>/<session>.jsonl`
carry `attributionSkill`, `effort` and `message.model` on **every** assistant
message — strictly more than the hook can see, with no new capture point
needed, and they distinguish *which* skill was active per message rather than
counting one row per invocation. Anything built here should read those instead
of `skills-invoked.log`, or read both and treat the gap between them as its own
signal. This also revises the "Data that already exists" section below, which
was measured before the transcripts were known to carry these fields.

## Proposed shape — recommendation, not a decision

**Split it: mechanical aggregation in a script, interpretation in a skill.**

The counting is deterministic and belongs in `scripts/` alongside the existing
`instructions-log` (extend it rather than adding a sibling — it already owns
these log files and its usage block is the discovery surface). Proposed
subcommands:

- `instructions-log coverage` — skills on disk vs skills ever invoked, joined
  across `skillUsage` + the log + transcript slash counts, so the three
  sources' disagreements are visible rather than averaged away.
- `instructions-log listing [--cwd <path>]` — skills deployed vs skills the
  listing can hold, i.e. blind spot 2 as a standing check.
- `instructions-log triggers` — for each skill, Skill-tool dispatches vs slash
  invocations. A high slash-to-auto ratio is the tell for a description that
  is not earning its trigger.

The *judgment* — is this description weak, or is this skill simply rarely
relevant? — is skill-shaped, and it is where a skill adds value over a table.
That skill should be **`disable-model-invocation: true`** and slash-only: it is
a deliberate maintenance pass, never something to auto-trigger, and under the
budget pressure documented in the sibling brief it should not spend listing
chars on natural-language triggers it does not want.

Whether it is a standalone skill or a section inside `/author-skill` (which
already owns skill quality) is genuinely open. Leaning standalone: authoring
and auditing have different cadences.

## Open questions to settle in-session

- **Is blind spot 1 capturable at all?** Nothing exposes per-turn listing
  contents. If it is not, say so in the artifact rather than approximating it —
  an inferred "was offered and declined" number would be worse than none.
- **Does `UserPromptSubmit` see enough to log slash invocations?** That closes
  the `skills-invoked.log` gap at the source and makes every downstream count
  honest. Verify the payload before designing around it.
- **Retention.** `instructions-loaded.log` is 1,613 rows in ~7 weeks and
  unbounded. Rotation is not urgent but should be decided before adding a
  third log.
- **Cross-machine.** Logs are per-machine and gitignored by nature. Does the
  audit assume one machine, or is aggregation expected to travel?
- **What is the actual effectiveness threshold?** "Zero invocations" is not
  disuse if the skill was never listed (blind spot 2) or covers a rare-but-
  critical path. Define the verdict rubric before automating verdicts, or the
  tool will confidently recommend deleting `fabric-eventstream` — a skill with
  4 real uses that simply lost its listing slot.

## Validation

- Run the new subcommands against the existing logs; hand-verify at least one
  skill's numbers against the transcripts (the four-way table in the sibling
  brief is a ready-made fixture — `doctor 2/0/2/0`, `commit 53/14/15/8`).
- Confirm the coverage report flags all 19 currently-dropped skills as
  "deployed but not listed" when run from the ACME repo, and flags none when run
  from `agent-config` (only 7 skills deploy there, well under budget). That
  contrast is the regression test.
- Lint any new skill per root `CLAUDE.md`; `pre-commit run --all-files`.

## One motivating example was wrong

This brief originally cited "a skill silently dropped from the listing
entirely — 19 of 44 in a live repo" as a blind spot telemetry would catch.
**That finding was retracted.** Those 19 skills carry `paths:` frontmatter and
were withheld by design until a matching file entered scope; nothing was
dropped and no budget was exceeded. The retraction was recorded in
`skill-context-cost.md` under "How this brief's premises were corrected";
that brief was retired 2026-09-01 and is recoverable from git history.

What this changes: **truncation is not available as a fixture.** The original
plan was to use measured drop counts as the telemetry's primary test case, and
there are none. The other two blind spots — descriptions that never match real
phrasing, and skills that fire without changing the outcome — are unaffected
and remain the case for building this.

It also sharpens the requirement. Any telemetry built here must distinguish
**withheld** (conditional, no matching file), **listed but not chosen**, and
**chosen** — because conflating the first two is precisely the error that
produced the retracted finding. A counter that cannot tell them apart will
reproduce it.

## Dependencies

None blocking. The measured listing/activation baseline lived in
`skill-context-cost.md`, retired 2026-09-01 — recover it from git history
with
`git log --diff-filter=D -- 'docs/**/skill-context-cost.md'`
rather than re-measuring. Two things from it are load-bearing here, and are
restated so this brief does not depend on that recovery:

- **The `--debug-file` recipe** for reading what the model actually
  received. It survives in `tests/skills/pbip-triggers/README.md`, which
  also carries the limit worth knowing before reaching for it: the debug
  log's skill lines are all emitted before any `Read`, so it can never
  witness a conditional activation. For that, use
  `scripts/test-activation.ps1` and the transcript it asserts against.
- **The `skillUsage`-vs-Skill-tool distinction.**
  `scripts/instructions-log skills` counts Skill-tool calls only;
  `skillUsage` in `~/.claude.json` counts typed `/name` invocations too.
  **Neither counts conditional activation** — a `paths:`-matched skill is
  *loaded*, never invoked, so a zero in either says nothing about whether
  its glob fired. Only the session transcript records that.
