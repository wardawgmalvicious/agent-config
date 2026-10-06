# Handoff: add this run's evidence to the fetch-strategy decision

- **Audit run**: 2026-10-06
- **Source**: `vscode-agent`
- **Window**: floor `2026-09-01` (diff base `28f76f5f`, 2026-08-28) →
  head `c642b585` (2026-10-01)
- **Covers recommended actions**: 5
- **Kind**: an **edit** adding evidence to another audit run's open
  decision brief, before the user decides it. No skill text changes
  here: `SKILL.md` changes when that decision is made.
- **Target**: `docs/audits/2026-10-06/fabric/18-decide-table-source-fetch-strategy.md`

## The problem

Brief 18 of the 2026-10-06 `fabric` run puts to the user how
`/drift-audit` should fetch a large source: how far § 4a's on-disk
two-ref exemption reaches, when to walk the in-window versions, and
whether Bash belongs in the read-only skill. Its evidence comes from a
`table` source. The `vscode-agent` run the same day hit the same budget
on a `prose` source with a directory `path`. It also found two faults
in how § 4a and § 7 enumerate in-window commits, which brief 18 does
not mention.

## Evidence

**E-1. A directory source over budget, and the method that kept it out
of context.** 19 listed in-window commits is more than 5, so § 4a
step 3 sends the run to `get_file_contents` at both refs. All four
registered files changed blob SHA:

| File | Bytes at base `28f76f5f` | Bytes at head `c642b585` |
| --- | --- | --- |
| `custom-instructions.md` | 25,395 | 23,527 |
| `agent-skills.md` | 19,598 | 21,731 |
| `custom-agents.md` | 22,879 | 23,652 |
| `hooks.md` | 24,962 | 17,571 |

That is 179,315 bytes at both refs, against the 150 KB per-source
budget. The run cloned instead, into the session scratchpad, and
diffed on disk:

```bash
git clone --quiet --filter=blob:none --no-checkout --single-branch --branch main \
  --shallow-since=2026-08-26 https://github.com/microsoft/vscode-docs.git <scratchpad>/repo
git -C <scratchpad>/repo diff 28f76f5f c642b585 -- docs/agent-customization/<file>
git -C <scratchpad>/repo log --first-parent --numstat 28f76f5f..c642b585 -- docs/agent-customization/
```

Blobs arrive lazily, only for the diffs asked for, so no file entered
context. `--shallow-since` has to fall before the diff base's date.

**E-2. A `since:` listing misses a commit merged in the window but
dated before it.** `list_commits` with `path:
docs/agent-customization/` and `since: 2026-09-01T00:00:00Z` returned
19 SHAs. `git log 28f76f5f..c642b585 -- docs/agent-customization/`
returned 20. The extra one, `0ff80a1` ("Update documentation for agent
customization and source control sections", 2026-08-28,
`language-models.md` +3/-3), reached `main` in the window through
`99bbccc` (the PR #10243 merge, 2026-09-03). The two-ref diff includes
its change. The commit enumeration does not, and neither would the
per-commit-patch route § 4a takes at 5 commits or fewer.

**E-3. The path filter lists branch commits, not what landed.** Of the
19 listed SHAs, 7 are squash merges on `main`'s first-parent line, 9
are branch commits, and 3 are "Merge branch 'main' into …" commits
(`70664392`, `4316a2c4`, `78460cbe`). The 10 PR merges that landed the
branch commits are not listed: `1606fea`, `c9d4cd2`, `ff30176`,
`b5fb0d9`, `e951b76`, `b30d3f3`, `b2a3aa4`, `99bbccc`, `7177031` and
`0959679`. A per-commit patch of a "Merge branch 'main' into …" commit
diffs against the branch, so it shows main's changes arriving rather
than the branch's own. `git log --first-parent <base>..<head> --
<path>` lists the 17 commits as they reached `main`.

The registry already records both faults for one source. Its
`skills-for-fabric` entry, § "Fetch — one `CHANGELOG.md` patch per
commit, isolated by file pagination", notes that "a path-filtered
`list_commits` shows the **branch commit, not the merge**" and that "a
date floor can miss a release whose branch commit predates the floor
but whose merge follows it"
(`.claude/skills/drift-audit/references/sources.md`). E-2 and E-3 show
the same faults on a second repo.

**E-4. Another Bash precedent.** The clone, diffs and listings of E-1
ran in Bash, writing only to the session scratchpad. That is one more
case for brief 18's decision 3.

## What to change

1. In brief 18, before § "Decisions to put to the user", add a section
   `## Evidence from the vscode-agent run, 2026-10-06` carrying E-1 to
   E-4, and a pointer to
   `docs/audits/2026-10-06/vscode-agent/00-audit-report.md`.
2. Tie each item to the decision it informs: E-1 to decision 1 (a
   `prose` directory source exceeds the budget too), E-4 to decision 3.
   E-2 and E-3 bear on how § 4a and § 7 enumerate in-window commits,
   which brief 18 does not ask yet: say so in one line under its
   decisions, and add no decision.

## Constraint on the fix

- **Brief 18 is another session's run**, committed in `c982a59`. Add
  evidence only. Keep its metadata block, so its generated index row
  stays right, and change none of its decisions or verification.
- **If brief 18 already carries an execution log**, it has been
  decided. Do not edit it: put this evidence to the user as a
  follow-up to that decision.
- **An audit directory is written once and stamped in place**
  (`docs/audits/README.md`). An evidence section added to an
  unexecuted brief stays within that. A rewrite does not.

## Verification

1. `grep -n 'Evidence from the vscode-agent run' docs/audits/2026-10-06/fabric/18-decide-table-source-fetch-strategy.md`
   prints one line.
2. `git diff --stat` lists only brief 18, plus this brief's execution
   log.
3. `pre-commit run --all-files`. Its `lint-audit-index` hook fails if
   the fabric directory's index no longer matches its briefs.

## Sequencing note

Keep this apart from brief 04. That one decides what one source is for
and is verified by its own re-run. This one feeds a decision about how
every source is fetched.

## Provenance

Surfaced by the 2026-10-06 `vscode-agent` run, which departed from
§ 4a on purpose and said so in its audit-window block. E-2 and E-3 came
from comparing the API's path-filtered listing with `git log` in the
clone.
