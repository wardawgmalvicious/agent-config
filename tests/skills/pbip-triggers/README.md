# PBIP / PBIR trigger fixtures

A minimal but structurally real PBIP project, used to test **`paths:`
activation** — which conditional skills load when a given file enters
session scope.

## Why this exists

Every other fixture set here tests what a skill *does once invoked*. This
one tests whether it fires at all, which is a different contract and the
one that fails silently.

Before this fixture, the Power BI half of the payload — the `pbip-` and
`pbir-` skills — could only be trigger-tested against a real client repo.
And **no log on this machine sees a `paths:` activation**, so "it didn't
seem to fire" is not a usable signal:

| Source | Records | Sees `paths:` activation? |
| --- | --- | --- |
| `~/.claude/logs/instructions-loaded.log` | `CLAUDE.md`, `AGENTS.md`, `.claude/rules/coding-*.md` | **No** — its 188 `path_glob_match` entries are all *rules* |
| `~/.claude/logs/skills-invoked.log` | Skill-*tool* calls | **No** — a path-triggered skill is loaded, never invoked |
| `skillUsage` in `~/.claude.json` | slash + Skill-tool invocations | **No** — same reason |
| `claude --debug-file` output | startup skill discovery | **No** — its `N conditional skills stored` and `Sending N skills via attachment (initial)` lines are both written before any Read |
| **the session transcript `.jsonl`** | every attachment | **Yes** — see below |

The first four count *invocation* or *startup*. Conditional skills are
*loaded*, mid-session. A zero in any of them says nothing about whether a
glob matched.

### The transcript does record it

Corrected 2026-09-01 on 2.1.252; this file previously said nothing
recorded activation. A match appends one JSON line to
`~/.claude/projects/<project>/<session-id>.jsonl` with `type` of
`attachment`, whose `attachment` object carries:

- `type` — `skill_listing`
- `isInitial` — **`false`** (this is the whole assertion)
- `names` — e.g. `["pbir-conditional-formatting", "pbir-filters", "pbir-visual-json"]`
- `content` — the listing lines, e.g. `"- pbir-filters"`

The `isInitial: true` record is the startup listing and is present in
every session regardless of what was read, so filter it out.

Two things follow. This is a machine-readable assertion — a cold
`claude -p` probe plus a grep of the resulting transcript tests a row of
the table below without a human reading context. (Pin the probe's tools;
"Read <fixture> and reply ok" is *not* enough — see
[Real path](#real-path--does-the-harness-agree).) And what a match injects is the skill's **listing entry, not its
body**: `content` above is three lines of names. Bodies load on
invocation only, so the token figures in `expected_activations.md` are
*body* weights for the case where the skill is then invoked — they are
not the cost of the match.

Self-report is not a substitute. Asking the print session which skills it
could see returned different answers across otherwise identical runs, and
once omitted an unconditional skill that was certainly present. Read the
transcript.

## File layout

```text
tests/skills/pbip-triggers/
├── README.md                    (this file)
├── expected_activations.md      (the assertion table)
└── fixtures/
    ├── SampleReport.pbip
    ├── SampleReport.Report/
    │   ├── .platform
    │   ├── definition.pbir
    │   ├── StaticResources/RegisteredResources/theme.json
    │   └── definition/
    │       ├── report.json
    │       ├── reportExtensions.json
    │       └── pages/
    │           ├── pages.json
    │           └── Page1/
    │               ├── page.json
    │               ├── bookmarks/{bookmarks.json,Bookmark1.bookmark.json}
    │               └── visuals/Visual1/visual.json
    ├── SampleModel.SemanticModel/
    │   ├── .platform
    │   ├── definition.pbism
    │   └── definition/
    │       ├── model.tmdl
    │       └── cultures/en-US.tmdl
    └── control/notes.md         (matches nothing — negative control)
```

Ten of the repo's 27 conditional skills are covered here. The other seventeen
are keyed to Fabric item types (`.Eventstream`, `.Warehouse`,
`.Notebook`, …) and live in [`../fabric-triggers/`](../fabric-triggers/).
Together the two sets cover all 27.

## Running the test

**Cold session required.** `paths:` is frontmatter, and in-place
frontmatter hot-reload is the one case not verified on this machine — a
warm session may be reporting the pre-edit globs.

### Scripted — both halves in one command

```powershell
./scripts/test-activation.ps1 -Set pbip          # static, then the real path
./scripts/test-activation.ps1 -Set pbip -StaticOnly   # globs only, no session
```

`scripts/test-activation.ps1` deploys the platform skills to a throwaway
probe directory outside this repo, opens one cold `claude -p` session
there, has it `Read` every fixture, asserts the transcript against
`scripts/activation-expect.py`, and tears the probe down in a `finally`
block. One session per fixture set, not one per file — see
[the delta note](#activation-is-a-per-session-delta).

It handles all three traps below on your behalf; the rest of this section
is what it is doing and why, kept because a run that fails still has to be
read by a human. Two guards are worth knowing about because they turn the
silent failures into loud ones:

- **Both skill groups deploy for either set.** The pbip fixtures activate
  `fabric-tmdl*` on their `.SemanticModel` files, and the fabric set's
  headline negative assertion — `pbip-project-structure` must *not* fire
  on `SampleNB.Notebook/.platform` — is vacuous unless that skill is
  actually present to fail.
- **The startup listing is checked before any fixture is read.** If the
  unconditional `fabric-*`/`pbi*` skills are missing from it, the deploy
  failed and every row would report "nothing loaded" — trap 1, told apart
  from a broken glob.

### Fast path — static, no session needed

Confirms the globs still resolve as documented. Catches a broken glob
without spending a session:

```bash
# uv run --with pyyaml --with wcmatch python thisfile.py
import pathlib, yaml
from wcmatch import glob as wg
F = wg.GLOBSTAR | wg.DOTGLOB
skills = {}
for p in sorted(pathlib.Path('skills').glob('*/*/SKILL.md')):
    d = yaml.safe_load(p.read_text(encoding='utf-8').split('---', 2)[1])
    if d.get('paths'):
        skills[d['name']] = d['paths']
base = pathlib.Path('tests/skills/pbip-triggers/fixtures')
for f in sorted(base.rglob('*')):
    if f.is_file():
        hits = [n for n, pats in skills.items()
                if wg.globmatch(f.as_posix(), pats, flags=F)]
        print(f"{f.relative_to(base).as_posix():<70} {sorted(hits)}")
```

Compare against [expected_activations.md](expected_activations.md).

### Real path — does the harness agree?

The static check tests the globs. It does **not** test that Claude Code
actually loads on a match.

**The probe must use the `Read` tool.** Activation is keyed to file
access through `Read`, not to the file itself — `cat` through Bash, and
`Grep`, both touch the same file and activate **nothing**. This is the
trap, and it has no error path: a Bash-read probe reports exactly the
output a broken glob does. Measured 2026-09-01 on 2.1.252; see
[the auto-mode note](#why-a-probe-silently-reads-with-bash) below for why
it happens by default on this machine.

So pin the tools rather than trusting the model to pick `Read`:

```bash
claude -p "Use the Read tool to read <fixture path> then reply with just: ok" \
  --model opus[1m] --output-format json \
  --allowedTools Read --disallowedTools Bash PowerShell Glob Grep Agent
# --output-format json prints session_id; the transcript is
# ~/.claude/projects/<project-slug>/<session-id>.jsonl
grep -o '"type":"skill_listing"[^}]*' <session-id>.jsonl
```

Every activation is one JSON line whose `attachment.type` is
`skill_listing` and whose **`isInitial` is `false`**; its `names` array is
the assertion. Discard the `isInitial: true` record — that is the startup
listing, present in every session whatever you read. Reading it as a
result is the same mistake as grepping
`Sending N skills via attachment (initial)` in a `--debug-file` log, which
is emitted before any Read and so can never show an activation.

**The converse trap does not bite here, and it is the `--allowedTools`
line that stops it.** An `isInitial: false` record is emitted by a *hot
reload* too — edit a `SKILL.md`, or re-run `link-claude.ps1`, and the
affected skills are re-announced exactly as a glob match would be (438
such deltas across this machine's transcripts, measured 2026-09-03). The
probe pins `--allowedTools Read`, so it cannot write a skill or redeploy,
which is why every delta it produces is a real activation. Keep that
restriction even if a future probe needs another tool — the moment the
session can edit `skills/`, the assertion stops meaning what it says.

**Assert the tool call too, not just the attachment.** Parse the
transcript for the `tool_use` block and fail the probe if it is not a
`Read` — otherwise a run that silently reached for `cat` is scored as a
glob failure.

#### Activation is a per-session delta

An attachment names only what was **not already active** — for rules as
well as skills. Measured 2026-09-01 on 2.1.252, three ways in one session:
reading `bookmarks.json` then `Bookmark1.bookmark.json` (identical
expectations) emitted an attachment for the first and **nothing** for the
second; `report.json` after it emitted `pbir-filters` but *not* the
`fabric-git-serialization` rule already loaded; and `page.json`, which
matches both `pbir-filters` and `pbir-pages`, emitted only `pbir-pages`.
The static check is the control — all of those files do match, so the
silences are deduplication and not a failure to fire.

Two consequences. **One session can cover a whole fixture set**, which is
what makes this test cheap enough to run at all — ~2 sessions for both
sets rather than ~70. And **per-file assertions are not independent**:
what a file emits depends on what was read before it, so an expectation
has to be computed against the read order, which is what
`activation-expect.py` does. `expected_activations.md` stays a plain
per-file table; nothing about it needs to become order-aware.

**Attachments are flushed in batches, not after every read.** A run of
several reads can be followed by a single flush covering all of them, so
an activation can only be attributed to the *group* of files read since
the previous flush. The script reports how many groups a run produced;
prompting the model to print a line after each read narrows them but does
not reliably reach one file per group. It costs assertion sharpness, not
correctness — a group's expectation is the union over its files.

Do **not** ask the session which skills it can see. Self-report is
unreliable: measured 2026-09-01, it varied across identical runs and once
omitted an unconditional skill that was certainly present.

Always run `control/notes.md` as well. It matches nothing, so if a
conditional skill shows up there, the observation method is broken rather
than the globs.

#### Why a probe silently reads with Bash

This repo's own `claude/settings.json` sets `permissions.defaultMode` to
`auto`, user scope, so **every session on this machine starts in auto
mode** — and auto mode instructs the model to read files with `cat`
through Bash wherever Bash can do the job. Nothing is wrong when it does;
the file is read and the answer is correct. Only the activation is
missing.

It is not deterministic, which is what makes it expensive to diagnose:
across the 2026-09-01 runs the model picked `Read` sometimes and `cat`
others from near-identical prompts. Eight probes in one directory all
chose `cat` and were read as a property of the directory
(see `activation-cleanroom-null.md`, retired).

`--disallowedTools Bash` fixes it twice over: the model cannot reach for
`cat`, and auto mode switches itself off when Bash is unavailable
(confirmed — the `auto_mode` attachment is absent from those transcripts).

#### Where the probe may run

**Anywhere.** A scratch directory activates exactly as the repo does,
with the same payload. Ruled out by measurement on 2026-09-01, each as
its own probe: being outside a git repo, being under
`AppData/Local/Temp`, having no `.claude/settings.json`, the 8.3 short
path, and the fixture's depth below the project root (`fixtures/…`
matched identically to `tests/skills/pbip-triggers/fixtures/…`). Project
scope activates; skills reached through this repo's junctions activate.

**Rules follow the same rule.** A `paths:` rule loads on a `Read` and not
on a `cat`, arriving as a `nested_memory` attachment naming the rule file.
Assert it from the transcript, not from
`~/.claude/logs/instructions-loaded.log` — the `InstructionsLoaded` hook
missed two of four confirmed loads in short `-p` sessions, so its silence
proves nothing.

## What this fixture is asserting

The load-bearing case is the **A1 regression** (`7eb6d9e`):

> `visual.json`, deep inside a `.Report/` folder, must activate exactly
> three skills — and **`pbip-project-structure` must not be one of them.**

`pbip-project-structure` used to carry `**/*.Report/**` and
`**/*.SemanticModel/**`, matching 148 of 295 files in a client repo and
riding along on nearly every Power BI file touch. If it reappears on
`visual.json`, that regression is back.

## Cost note

These files are inert until opened. Reading
`visuals/Visual1/visual.json` activates three skills at once — the most in
either fixture set, and the fixture working as designed. Activation itself
is cheap: three listing entries. What makes this the repo's worst single
file is the **ceiling** behind it, ~9,086 tokens of bodies if all three are
then invoked. Don't leave it open while doing unrelated work.
