# Handoff: strip history and contradictions from the user-scope rules

- **Audit run**: 2026-10-08
- **Source**: `prompt-audit`
- **Window**: floor none, the whole payload → head `c268691`
  (2026-10-08)
- **Covers recommended actions**: findings 7, 22, 23, 27, 28 and 32
- **Kind**: wording in user-scope rules: a contradiction with the
  global `CLAUDE.md`, a possible one inside a README, an unlabeled
  example and three passages that read as history. No behavior changes.
- **Target**: `claude/rules/git-identity-scoping.md`,
  `claude/rules/README.md`, `claude/rules/fabric-git-serialization.md`,
  `claude/rules/coding-bash.md`, `claude/rules/coding-ci-workflows.md`

## The problem

Six passages in the user-scope rules either disagree with a newer file
or describe how things used to be, so a reader cannot tell what holds
now.

## Evidence and what to change

Line numbers at `c268691`; each quote is the report's.

| # | Location | Says | Why | Change |
| --- | --- | --- | --- | --- |
| 7 | `git-identity-scoping.md:111-118` | "a `-NoProfile` `pwsh` acts as the keyring's active account" | the newer `claude/CLAUDE.md` § "Git identity is folder-scoped" says three wrappers cover both tool shells | rewrite; keep the `gh api user` confirm step |
| 22 | `claude/rules/README.md:165-166` | "never on Grep or a subagent's Read" | the report: lines 22-23 and `agent-instructions-scoping.md` say a subagent's Read loads the file into that subagent | rewrite, if the conflict holds |
| 23 | `fabric-git-serialization.md:165-166` | `Engineering/** -text`, with no label | one estate's folder names shown as the answer | label them an example |
| 27 | `coding-bash.md:210-214` | "until machine-config fixed it … (`c9a2ed4`)" | reads as solved | rewrite to the symptom |
| 28 | `coding-bash.md:311-314` | "the probe this example once carried" | history | rewrite |
| 32 | `coding-ci-workflows.md:66-69` | "in evaluate mode now" | false from 2026-11-02 | anchor it to the date |

## Constraint on the fix

Finding 22 may not be a conflict. Lines 165-166 describe when a nested
`CLAUDE.md` loads into the session, and lines 22-23 when a rule loads
into a subagent, so "never on a subagent's Read" can be true of the
session and still read as false of the subagent. Read
`agent-instructions-scoping.md` first. The fix may be one clarifying
clause, or nothing.

## State when written

A `/triage` of a prompt audit run in a client repo against the same
payload landed five of the six on 2026-10-08, in its own words: finding
7 in `b5d6269`, 23, 27 and 28 in `8510852`, and 32 in `d60be04`. Each
is already-applied, and that wording stands unless it is wrong. Only
finding 22 still held at `566973a`, so this brief is mostly a
confirmation pass.

`docs/handoffs/declined.md` has two of that triage's standing calls
that bear on this file set: removals that take a claim's only date or
failure description are declined, and so are the "since" dates in
`claude/rules/README.md`. Finding 22 is neither; it is about whether
two passages agree.

## Verification

1. `git-identity-scoping.md`'s passage agrees with `claude/CLAUDE.md`
   § "Git identity is folder-scoped" on which shells the wrappers
   cover.
2. `grep -n 'evaluate mode now\|once carried\|until machine-config' claude/rules/*.md`
   prints nothing.
3. `uv run --with pyyaml scripts/lint-frontmatter.py` on each changed
   rule.
4. `uv run --with pyyaml scripts/lint-instructions.py --stamp`, if
   `coding-ci-workflows.md` changed: it has a frozen Copilot port.
5. `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`.
6. `pre-commit run --all-files`.

## Provenance

Finding 7 (high) and findings 22, 23, 27, 28 and 32 (medium) from
`/doctor prompt-audit` run in this repo on 2026-10-08. The session that
wrote this brief read finding 22's two passages the same day, which is
where the constraint above comes from.

## Execution log

- **Executed**: 2026-10-08 — applied with deferrals
- **Session**: fresh (no audit or handoff run in this session; the whole
  pass, in its own worktree)
- **Files changed**: `claude/rules/README.md`
- **Verification**: the staleness gate at `26f8582` found the triage's
  text for five findings, each old quote gone: 7 at
  `git-identity-scoping.md:111-118` (`b5d6269`); 23 as
  `<workspace-folder>/** -text` at `fabric-git-serialization.md:169`,
  and 27 and 28 in `coding-bash.md` (`8510852`); 32's "in evaluate mode
  before then" at `coding-ci-workflows.md:68` (`d60be04`). None is
  wrong, so each stands. Finding 22's quote held at `README.md:165-166`,
  wrapped across the two lines. Step 1 — **passed**: the passage names
  the same three wrappers, and the same three cases the keyring
  answers, as `claude/CLAUDE.md:109-113`, and keeps the
  `gh api user -q .login` step. Step 2 — **passed**: nothing printed,
  exit 1. Step 3 — **passed**: `lint-frontmatter.py` on `README.md`,
  exit 0. Step 4 — not needed: `coding-ci-workflows.md` did not change
  in this run. Step 6 (`pre-commit run --all-files`) runs once at the
  end of the run.
- **Deferred**: step 5: `link-claude.ps1` refuses a worktree, so from
  the main checkout after the landing,
  `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta` deploys
  the README.
- **Deviations**: finding 22 took the one clarifying clause the
  constraint allows: `agent-instructions-scoping.md:49-50` says "a
  subagent's Read loads it into the subagent only", and the README now
  says so, where "never on Grep or a subagent's Read" was true of the
  session and read as false of the subagent. The clause leaves one
  short line rather than rewrapping the entry below it.
- **Needs**: the landing — `link-claude.ps1` deploys the `README.md`
  edit.
- **Closed**: 2026-10-08 — the deploy it waited on ran:
  `link-claude.ps1 -SkillGroups workflow,social,meta` on `main` at
  `66ada3c`, after the landing, and the deployed `README.md` matches
  the repo's (`cmp`).
