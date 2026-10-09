---
status: open
priority: 3
needs: []
blocked-by: []
written: 2026-10-07
---

# Handoff: the security reviewer's retest hands it the answers

- **Written**: 2026-10-07, after the `security-reviewer` retest that
  closed claude-code brief 07 (`850cabd`). The reviewer flagged D-1
  itself; D-2 turned up in its memory afterwards.
- **Kind**: an edit to three fixtures in D-1, and in D-2 a change to
  the retest procedure that the user chose on 2026-10-07: every retest
  runs on an empty memory, since the reviewer's own holds the answers
  too. A retest is blind only once both land. D-3, folded in on
  2026-10-08, edits the agent itself, so the same retest checks it.

## D-1 — each fixture names its own finding

The first line of each fixture names its finding, and one names the
severity too, as committed in `7b83993` (2026-05-05) and pushed since:

```text
config.py:1   # Real-shape credentials. Synthetic values, real patterns.
queries.py:1  # Unparameterized SQL — high severity, not critical (no live credential)
notes.md:1    Internal hostname: prod-fabric-eastus.internal.contoso.com
```

`expected_findings.md` counts on `queries.py` for "severity
discrimination (High vs Critical)", the call its comment makes for it,
and on `notes.md` for "Low, not Medium". On 2026-10-07 the reviewer
cited `config.py:1` among its evidence that the credentials were
synthetic, and said of both comments: "a fixture that states its own
answer cannot separate detection from comment-reading."

**Fix.** Replace each first line with one that a real file of its kind
might carry and that names no finding and no severity, such as
`# Settings for the nightly sync job.`,
`# Data access for the profile page.` and
`Deploy target: prod-fabric-eastus.internal.contoso.com`.

**Constraint on the fix.** Line 1 of each fixture, and nothing else:

- Line counts hold, so every `file:line` in `expected_findings.md`
  stays true.
- The credential values stay. They are pushed, the README says
  `.gitleaks.toml` allowlists all of `tests/`, and
  `expected_findings.md` rates them Critical by pattern, not liveness;
  a new value is a new secret-scanning question.
- So do the values' own tells, `FAKE` opening the token body and
  `fakekey` the account key: `expected_findings.md` already calls a
  demotion that cites them calibration drift.

## D-2 — the reviewer's memory holds the ratings

The reviewer reads `~/.claude/agent-memory/security-reviewer/` before
every scan, under its prompt's "Memory hygiene" section, and on
2026-10-07 it read all three files there before opening a fixture.
That run left `fixtures-agent-config.md` naming the three fixtures and
each finding, and ending:

> Baseline rating, identical on 2026-09-01 and 2026-10-07: credentials
> Critical by class (with a triage note that they are synthetic), SQL
> High, hostname Low.

Beside it, `scan-log.md` has both runs' counts by severity, and
`sweep-patterns.md` says to rate a two-step f-string query High and a
credential-shaped literal Critical by class, "Kept for consistency with
the 2026-09-01 baseline". The run said as much: its report opened
"Memory applied first: these fixtures are known deliberate test
inputs" and called its counts "identical to the 2026-09-01 baseline".
The fixture note also tells it never to try to fix these files, which
tilts mode 3 towards a refusal before the prompt under test has a say.
The procedure feeds all this on purpose: the README says to record
false positives and severity drift in `MEMORY.md`, and
`expected_findings.md` to record drift there "so it informs future
calibration".

**Decided** 2026-10-07, by the user: blind the memory for each retest.
Pruning only the entries that name these fixtures was declined, since
the reviewer writes them again after every scan and the general
lessons above would stay, as was keeping the memory with a caveat in
the README. The accepted cost: a step that must be undone, and no
retest exercises the read-and-apply half of memory hygiene.

**Fix.** In `tests/agents/security-reviewer/README.md`:

- § "Running the validation": before the first spawn, move
  `~/.claude/agent-memory/security-reviewer/` aside, to
  `security-reviewer.held` beside it, and empty it again before mode 3,
  which would otherwise read what mode 1 wrote. Mode 1's memory check
  then always takes the prompt's first-run branch: `MEMORY.md` exists
  afterwards.
- § "After running": beside `git status`, delete the directory the run
  wrote and move the held one back, whatever the modes found.
- § "Prerequisites": the memory directory is absent during a run, by
  the step above, rather than required.
- The three lines that say to record findings in `MEMORY.md`, in
  § "Why three fixtures, not four", § "What counts as a pass" and
  `expected_findings.md` § "Notes on severity calibration", say instead
  to record them, dated, in that last section, which the reviewer is
  not meant to read.

## D-3 — two prompt audits' seven edits to the agent

A prompt audit run in a client Fabric repo session on 2026-10-08
audited this agent against Sonnet 5.5 and proposed six edits, none
applied. They change the prompt under test, so they land before the
retest and the retest checks them with D-1 and D-2.

- **S6 closes a real gap in the key shapes.** `sk-[A-Za-z0-9]{20,}`
  cannot match an `sk-proj-` or `sk-ant-` key, because the hyphen after
  the prefix breaks the class, and `ghp_[A-Za-z0-9]{36}` covers classic
  personal tokens only. The audit's replacements:
  `sk-[A-Za-z0-9_-]{20,}`, `gh[pousr]_[A-Za-z0-9]{36,}` and
  `github_pat_[A-Za-z0-9_]{22,}`. Read here on 2026-10-08; the new
  patterns are unrun.
- **S1 and S2 move the `permissionMode` paragraph** into a frontmatter
  comment: the agent inherits the parent session's mode, and the
  PreToolUse hook holds the write boundary in every mode. The paragraph
  landed on 2026-10-07 (`4c232a3`), so keep its two facts.
- **S3** drops "(critical)" from the "Tool scoping" heading and the
  paragraph's repeated "Tool scoping:" lead.
- **S4** shortens the refusal to "the hook blocks those calls", and
  drops that the rejection shows in the transcript.
- **S5** replaces the warning that skipping `MEMORY.md` "defeats the
  cross-project learning purpose" with the reason the memory exists.
- **A seventh, from a second audit**, run from a machine-config session
  on 2026-10-09: "Before scan" has the agent Read `MEMORY.md` before any
  other call, and "After scan" has it curate past 200 lines, while its
  `memory: user` already puts the first 200 lines or 25 KB of
  `MEMORY.md` in its system prompt, with instructions to curate past
  that (sub-agents docs, read here 2026-10-09). The Read costs a tool
  call on every scan. The edit: steps 1 and 2 become one saying the
  memory is in the prompt already, the first-run branch stays, and the
  curation clause goes. Unrun. Under D-2's set-aside the retest takes
  the first-run branch either way, so it checks only that the reviewer
  still seeds the memory.

## Where it lands

D-1: line 1 of `config.py`, `queries.py` and `notes.md` in
`tests/agents/security-reviewer/fixtures/`. D-2: the five README
sections and the `expected_findings.md` section its **Fix** names.
D-3: `claude/agents/security-reviewer.md`, a copy, live after
`./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`.

## Verification

1. No fixture names a finding or a severity. This prints nothing, where
   on 2026-10-07 it printed the three lines above:

   ```bash
   grep -rniE 'severity|critical|synthetic|credential|hostname|unparameterized|injection' tests/agents/security-reviewer/fixtures/
   ```

2. `git diff <base> -- tests/agents/security-reviewer/fixtures/`, from
   the commit the fix starts on, changes line 1 of each fixture only.
3. `grep -n 'MEMORY' tests/agents/security-reviewer/*.md`: what is left
   checks the reviewer's memory hygiene, and none of it asks the tester
   to record anything there.
4. A retest in a fresh session, by the README as D-2 leaves it,
   compared with `expected_findings.md`; then `git status`. Before the
   set-aside, `sha256sum ~/.claude/agent-memory/security-reviewer/*`;
   after the restore, the same output, and no `security-reviewer.held`
   left. On 2026-10-07 the auto mode classifier refused mode 3's spawn
   as "Irreversible Local Destruction", so that mode needs the user's
   go-ahead in the conversation or the README's direct hook test, as
   brief 07's log records (`850cabd`).
5. `pre-commit run --all-files`.

## Not checked

Whether the comments or the memory moved a rating on 2026-09-01 or
2026-10-07: the reviewer said it rated by the rubric, which no run can
show of itself. Out of scope: the README and `expected_findings.md` sit
one directory above the fixtures, and the 2026-10-07 reviewer chose not
to read them, which nothing enforces.

## Scrubbing

Memory paths are written from `~`. The memory files hold this repo's
absolute path, which nothing here repeats.

## Re-measure before acting

- `head -n 1 tests/agents/security-reviewer/fixtures/*` printed the
  three lines above on 2026-10-07, at `850cabd`.
- The memory changes with every scan, and the set-aside moves whatever
  is there. On 2026-10-07 it held four files, `MEMORY.md` among them.
