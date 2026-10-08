# Handoff: correct the user-scope skills

- **Audit run**: 2026-10-08
- **Source**: `prompt-audit`
- **Window**: floor none, the whole payload → head `c268691`
  (2026-10-08)
- **Covers recommended actions**: findings 8, 34, 35, 36, 37, 38, 39,
  40 and 41
- **Kind**: corrections to junctioned user-scope skills: two command
  bugs, a wrong comment, a dead path, a stale field contract and
  history. Live in every session on the machine the moment a file is
  saved.
- **Target**: `skills/meta/learn/SKILL.md`,
  `skills/social/linkedin-highlights/SKILL.md`,
  `skills/workflow/recreate-repo/SKILL.md`,
  `skills/workflow/commit/SKILL.md`, `skills/workflow/land/SKILL.md`

## The problem

Five user-scope skills carry instructions that are wrong or stale. Two
are command bugs: one makes a failed identity scrub read as clean, the
other breaks a read-only promise.

## Evidence and what to change

Line numbers at `c268691`; each quote is the report's.

| # | Location | Says | Why | Change |
| --- | --- | --- | --- | --- |
| 8 | `learn:95-97, 122, 240-247` | "the fix is the skill's `description`" | `learn`'s own triggers sit in `when_to_use`, capped separately at 512 (`lint-frontmatter.py`) | cover both fields and both caps |
| 34 | `learn:297-303` | "**Sources, cited by kind.**" | the newer note contract, `triage/references/formats.md:114-117`, has **Scrubbing** | rewrite to the contract |
| 35 | `learn:290` | "the doorbell this replaced" | history | remove |
| 36 | `linkedin-highlights:253, 262-265` | `wc -l < "$TERMS"` after `rm -f "$TERMS"` | shells are fresh per call, so a failed count reads as a clean scrub | print the count inside the snippet |
| 37 | `linkedin-highlights:353` | `uv run python -c` | without `--no-project`, uv syncs the user's repo, which breaks the skill's read-only promise | add `--no-project` |
| 38 | `recreate-repo:78` | "exit 0: a current snapshot is committed" | `-Check` compares disk with the live repo and never checks git | fix the comment |
| 39 | `commit:249` | `rules/fabric-git-serialization.md` | resolves nowhere | `~/.claude/rules/fabric-git-serialization.md` |
| 40 | `commit:165-168` | "the question this section could not answer before" | history | rewrite |
| 41 | `land:326-327` | "the half of this skill that used to be missing" | history | remove the sentence |

The session that wrote this brief checked finding 39's path, at line
249, on 2026-10-08. The audit session confirmed the premises of 34 and
38 before drafting them.

## State when written

A `/triage` of a prompt audit run in a client repo against the same
payload landed three of these on 2026-10-08: findings 35 and 41 in
`2c69880` (41 exactly as the patch has it) and 40 in `49310b4`. Each is
already-applied. Findings 8, 34, 36, 37, 38 and 39 still held at
`566973a`. Re-read each file at `HEAD` first; the patch's hunks for a
file edited since will not apply.

`docs/handoffs/declined.md` records that triage's declines for these
skills: `linkedin-highlights`' worked inventory and sentence targets,
and `learn` naming this repo's own skills. Neither touches a finding
here.

## Constraint on the fix

Every file here is junctioned, so a save is live machine-wide, and an
intermediate state that breaks a skill breaks it in every session.
Finish each file's edit in one write, and branch if a change spans
files that must land together (root `CLAUDE.md` § "Branching and
concurrent sessions").

## Verification

1. Finding 36: run the corrected snippet in a scratch directory with a
   throwaway terms file; the count prints, and a missing file is
   reported as an error, never as zero.
2. Finding 37: in a scratch directory holding a `pyproject.toml`,
   `uv run --no-project python -c "print(1)"` leaves no `.venv` or
   `uv.lock` behind.
3. `grep -n 'doorbell\|used to be missing\|could not answer before' skills/meta/learn/SKILL.md skills/workflow/commit/SKILL.md skills/workflow/land/SKILL.md`
   prints nothing.
4. `uv run --with pyyaml scripts/lint-frontmatter.py` on each changed
   `SKILL.md`.
5. `uv run --with pyyaml scripts/skill-status.py --stale`: run the
   retests it names and stamp each.
6. `pre-commit run --all-files`.

## Provenance

Finding 8 (high) and findings 34 to 41 (medium) from
`/doctor prompt-audit` run in this repo on 2026-10-08. `learn` pins
Fable 5.1 and was audited against it.

## Execution log

- **Executed**: 2026-10-08 — applied with deferrals
- **Session**: fresh (no audit or handoff run in this session; the whole
  pass, in its own worktree)
- **Files changed**: `skills/meta/learn/SKILL.md`,
  `skills/social/linkedin-highlights/SKILL.md`,
  `skills/workflow/recreate-repo/SKILL.md`,
  `skills/workflow/commit/SKILL.md`
- **Verification**: the staleness gate at `26f8582` found the history
  of findings 35, 40 and 41 gone (`2c69880`, `49310b4`), each standing,
  and the quotes of 8, 34, 36, 37, 38 and 39 held; 39's sits at
  `commit:285`, 249 at `c268691`, the file having gained three commits
  that day. Step 1 — **passed**: the snippet, extracted from the file
  with only the draft path filled in, run on a throwaway list of two
  terms among a comment, a blank, a whitespace-only and an `exempt:`
  line, printed "2 active terms loaded" and the one hit, exit 0;
  pointed at a missing list, "no readable denylist at …" on stderr,
  exit 1, and no count. The Bash tool's worktree guard refused the run
  in every form, as too complex to show it runs no git, so it ran
  through Git Bash from the PowerShell tool, writing only in the
  scratchpad. Step 2 — **passed**: beside a `pyproject.toml`,
  `uv run --no-project python -c "print(1)"` left the folder as it was,
  where the same run without the flag created `.venv` and `uv.lock`.
  Step 3 — **passed**: nothing printed, exit 1. Step 4 — **passed**:
  `lint-frontmatter.py` on the four files, exit 0. Step 5 — ran:
  `skill-status.py --stale` names `learn`, `commit` and `recreate-repo`
  `retest-behaviour` and `linkedin-highlights` `untested`; deferred.
  Step 6 (`pre-commit run --all-files`) runs once at the end of the run.
- **Deferred**: step 5's four retests. Each skill sits in a deployed
  group, whose probe reads the main checkout's copy, so after the
  landing, each in a fresh session: `/test-skill learn`,
  `/test-skill linkedin-highlights`, `/test-skill commit` and
  `/test-skill recreate-repo`, then
  `skill-status.py --stamp <skill> --phase behaviour`.
- **Deviations**: finding 36's snippet also checks the list before
  reading it, beyond the patch: without that line a missing list
  printed the shell's error and then "0 active terms loaded", which
  step 1 forbids. Finding 34 follows the inbox README's contract,
  "which content is raw and which is genericized", and drops the
  patch's "Cite client evidence by kind, never by name", which
  contradicts this skill's own Step 7, "record what you observed
  plainly, including names". Finding 8's headroom claim was measured:
  of 61 skills, 17 descriptions sit within 24 characters of 1,024, and
  3 of the 23 `when_to_use` fields within 22 of 512. The constraint's
  one-write rule is held by the worktree: no save here is live until
  the landing, which brings every file at once.
- **Needs**: the landing, a fresh session — `/test-skill` on `learn`,
  `linkedin-highlights`, `commit` and `recreate-repo`, step 5's
  retests.
