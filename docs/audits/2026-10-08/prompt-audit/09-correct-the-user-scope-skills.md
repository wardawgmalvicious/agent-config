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
