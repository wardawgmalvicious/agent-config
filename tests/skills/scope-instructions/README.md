# `scope-instructions` — behaviour cases

`scope-instructions` is unconditional, so it has no activation contract.
These cases test its body and its trigger text on `orders-sync`, a
scratch repo [make_fixture.py](make_fixture.py) builds, against a
`--safe-mode` baseline, an ablation and the built-in
`/doctor prompt-audit`. The generator rebuilds the trial fixture of the
skill's brief, whose own generator was lost; its docstring lists the six
known answers, K1 to K6.

## The fixture

Build a fresh copy per arm, **outside this repo and outside any path
that names it**: on 2026-10-14 a baseline holding file tools found this
checkout from a scratchpad path and read a skill off disk (`test-skill`'s
`references/reading-a-failure.md`). A copy no session has run in holds
no transcripts, so `folder-sessions.py` exits 1 there, and the skill
should say it sorted on content alone.

```bash
uv run --no-project tests/skills/scope-instructions/make_fixture.py <dest>/orders-sync
```

Three flaws the generator did not intend, each a fair finding for an
arm: nothing loads `.env`, though root says `make run` reads it;
`make lint` fails on `ANN001` in `tests/test_sync.py`; and `Order` lacks
the contract's `placed_at` and `status`. Every arm on the payload side
also loads the user-scope `coding-tsql.md` on the fixture's PostgreSQL
files, and two named its PascalCase and `dbo.` advice as a conflict.

## The cases

| Arm | Sent as | Flags beyond the common set |
| --- | --- | --- |
| payload | the main query | none |
| baseline | the main query | `--safe-mode` |
| ablation | the main query | `--disallowedTools 'Skill(scope-instructions)'` |
| doctor | `/doctor prompt-audit` | `--effort medium` and the ablation's deny |
| slash | `/scope-instructions` | `--model haiku` |
| routing | each query below | `--tools Skill --max-turns 1 --max-budget-usd 0.5`, no `--effort` |

The main query, verbatim:

```text
Our CLAUDE.md keeps growing. Split it up so a session loads only what it needs.
```

The routing queries are the brief's: seven that should call
`scope-instructions` and four that belong to a neighbour.

| Query | Expected |
| --- | --- |
| Where should the SQL conventions in our CLAUDE.md live? | `scope-instructions` |
| Does the contracts folder need its own CLAUDE.md? | `scope-instructions` |
| Our CLAUDE.md is 300 lines; split it so a session loads only what it needs. | `scope-instructions` |
| Move the testing instructions out of CLAUDE.md into .claude/rules. | `scope-instructions` |
| Audit this repo's instruction files across Claude Code and Copilot. | `scope-instructions` |
| Nobody ever seems to read contracts/README.md; why, and what should we do about it? | `scope-instructions` |
| Should we switch our CLAUDE.md to AGENTS.md? | `scope-instructions` |
| learn! a nested CLAUDE.md didn't load when I grepped the folder | `learn` |
| Create a CLAUDE.md for this new repo | `init` |
| Find the session where we split the CLAUDE.md | `find-session` |
| Fix the typo on line 40 of CLAUDE.md | no skill |

## Running them

Drop every `CLAUDE*` variable of the launching session, as
`scripts/test-instruction-loading.py` does, then set
`CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS=1` and
`CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`. The common set:

```powershell
claude -p '<prompt>' --output-format stream-json --verbose --model opus --effort max --tools Skill,Read,Glob,Grep,Bash,Edit,Write --strict-mcp-config --settings <file> --max-budget-usd 8 -n 'probe: <arm>'
```

The settings file holds
`{"crossSessionInbound":"refuse","permissions":{"deny":["Read(~/.claude/**)","Read(~/handoff-inbox/**)"]}}`.
Launch the slash and doctor arms from PowerShell, since Git Bash
rewrites a leading `/`. The deny stops Read, Glob and Grep, not Bash:
the doctor arm listed `~/.claude` through Bash, so audit each arm's Bash
calls before trusting it. The arms edit their copies, so a copy serves
one arm once.

## Result, 2026-10-15

One run per arm, on 2.1.293, against the body `f03128b` left: Opus 5.5
at `max` unless the table says otherwise, $8.49 for 18 arms. Witnesses:
the payload arm's `Skill` call and, in its main session, the
`nested_memory` record of `agent-instructions-scoping.md`; the slash
arm's command expansion with no `Skill` call; the baseline's `init`, 55
commands to the payload's 69, `scope-instructions` and `learn` absent;
the ablation's "Skill execution blocked by permission rules", with no
body text in its transcript.

| Known answer | Payload | Baseline | Ablation | Doctor, `medium` | Slash, Haiku |
| --- | --- | --- | --- | --- | --- |
| K1, contracts out of root | nested `contracts/CLAUDE.md` | rule on `contracts/**` and `models.py` | rule on `contracts/**/*` | no | nested file |
| K2, SQL to `**/*.sql` | yes | yes | yes | no | kept in root: a rule loads after the Write that creates a file |
| K3, the README's rule | imported into the nested file | left as a gap | offered as a follow-up | README not read | copied into the nested file |
| K4, the silent `AGENTS.md` | moved to `src/CLAUDE.md`, import form offered | left as a gap | offered: `@AGENTS.md` | `@AGENTS.md` | `@AGENTS.md` |
| K5, derivable lines | Code style cut, ruff tested; Layout kept | moved to a rule | moved to a rule | no | both cut |
| K5, Copilot's 88 | flagged | not seen | flagged | file out of scope | flagged |
| K6, `make db-migrate` | flagged | fixed | flagged | flagged | flagged |
| Changed the fixture | no | yes | yes | no | no |
| Cost | $2.39 | $1.48 | $2.06 | $1.09 | $0.22 |

**K1 and K2 did not separate.** The brief named them the discriminating
claim, since no built-in made either move in the trial, but every Opus
arm here made both once asked to split for loading, the baseline
included. What separated was the body's: it proposed and stopped where
both other Opus arms edited (2 of 2 against 0 of 2), cut what the
formatter enforces rather than moving it to a rule, and put the README's
and the silent file's rules into the plan rather than leaving them as
gaps. Copilot's drift is not the body's: the ablation flagged it too.
Each arm kept the production `make run` warning in root as a gotcha a
command triggers. `/doctor prompt-audit` found K4 and K6 and moved
nothing.

Routing went 11 of 11 for $1.21: each should-fire query called
`scope-instructions` as its first act, questions 6 and 7 included, and
the four others called `learn`, `init`, `find-session` and nothing.

## Real use, 2026-10-15

The pilot the brief named, on a client Fabric repo, run by the user in
a session of their own on the body `7a02e6c` left. Its root was a
275-line `AGENTS.md` behind a three-line `CLAUDE.md` of `@AGENTS.md`,
beside three `paths:` rules and no nested file, with 50 sessions on
disk since 2026-09-30.

**It held.** It stopped at a 15-row table, a row for every root
section, with root's line count, the silent files (none), stale lines
by line number and the hand-offs under it, and asked which rows to
apply. The trigger test did the sorting. Every root section stayed,
since a live command, a sync or a file not yet written sets each off,
and the moves ran the other way: three paragraphs of a source system's
rule went to root, since a live command trips each before any file the
rule matches is opened. Root would grow from 275 lines to 285, its trim
handed on. Of the 2026-09-24 proposal the brief describes, which
predates the trigger test, it kept the contract folder's README a
README, the rule on that folder having loaded in 7 of 8 sessions there,
and sent part of that rule back to root. The rule's drive-letter
bullet, from `32c021e`, reached its context, and it cited it in
proposing no nested file.

Three gaps in the body's text, folded in after this run:

- It corrected one of its own auto-memories, a stale claim about where
  guidance goes, before the user had approved a row.
- Step 6 named only `/doctor prompt-audit` as a hand-off, so it filed
  root's trim there after calling the trim `/doctor`'s.
- One row rested on a load count, which step 3's `loaded` bullet
  allows, though a home that loads says nothing of whether it holds the
  README's must-know lines.

Not folded in: one move went to a wrapper script's own header, a home
the rule's table lacks, chosen on the repo's own convention, which is a
`/learn` candidate for the rule; and step 4's first question sends every
gotcha a command triggers to root, where a hook on the command would
fire first but spawn on every call.

Collecting the verdict: a cross-session message asking that session
which question decided each row, and where it improvised, was flagged
by the API's safeguards as `[reasoning_extraction]`, which ended its
turn. The user pasted its output instead and forked it; the follow-up
questions asked only for its files' content.
