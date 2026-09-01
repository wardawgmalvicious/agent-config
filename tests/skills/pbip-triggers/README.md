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
Worse, **there is no observability for conditional skill
activation on this machine**, so "it didn't seem to fire" was not a
usable signal:

| Log | Records | Sees `paths:` activation? |
| --- | --- | --- |
| `~/.claude/logs/instructions-loaded.log` | `CLAUDE.md`, `AGENTS.md`, `.claude/rules/coding-*.md` | **No** — its 188 `path_glob_match` entries are all *rules* |
| `~/.claude/logs/skills-invoked.log` | Skill-*tool* calls | **No** — a path-triggered skill is loaded, never invoked |
| `skillUsage` in `~/.claude.json` | slash + Skill-tool invocations | **No** — same reason |

All three count *invocation*. Conditional skills are *loaded*. A zero in
any of them says nothing about whether a glob matched. Verify by
observing what is in context, never by reading a counter.

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

Ten of the repo's 23 conditional skills are covered here. The other thirteen
are keyed to Fabric item types (`.Eventstream`, `.Warehouse`,
`.Notebook`, …) and live in [`../fabric-triggers/`](../fabric-triggers/).
Together the two sets cover all 23.

## Running the test

**Cold session required.** `paths:` is frontmatter, and in-place
frontmatter hot-reload is the one case not verified on this machine — a
warm session may be reporting the pre-edit globs.

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
actually loads on a match. For that, in a fresh session, read one fixture
file and then ask which skills are available.

Read the listing carefully: it normally shows **unconditional skills
only**. A conditional skill appearing is the positive signal; its absence
in a session where nothing matched is correct, not a failure.

For a machine-readable capture:

```bash
claude -p "Read <fixture path> and reply ok" --model opus[1m] \
  --debug-file /tmp/trig.log
grep -iE "conditional|unique skills|via attachment|<skill-name>" /tmp/trig.log
```

Grep for the **skill name**, not only `via attachment`. The
`Sending N skills via attachment (initial)` line is emitted *before* the
Read runs, so it cannot show a file-triggered activation and reading it
as a negative result is a mistake.

Always run `control/notes.md` as well. It matches nothing, so if a
conditional skill shows up there, the observation method is broken rather
than the globs.

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
`visuals/Visual1/visual.json` pulls ~9,086 tokens of skill bodies into
the session — that is the fixture working as designed, and it is the
repo's worst single-file activation. Don't leave it open while doing
unrelated work.
