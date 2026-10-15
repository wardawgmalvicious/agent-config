---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-15
---

# Handoff: a single-file Bash read loads rules and nested files

- **Written**: 2026-10-15, by the session that landed
  `scoped-rule-imports-and-trigger-sorting.md`, which met this in the
  memory page and the changelog while checking its own claim.
- **Kind**: probes first, in `scripts/test-instruction-loading.py` and
  three scratch runs, then corrections in the homes below, a ledger
  entry, and a `/test-skill test-skill` routing retest if its
  description changes. Nothing is drafted.

## What changed

**Since 2.1.293 a Bash command that views one file loads that file's
`paths:` rules and nested `CLAUDE.md`, as a Read does.** The changelog's
2.1.293 entry, verbatim:

> Fixed path-scoped rules and nested CLAUDE.md files not loading when
> Claude views a file with a single-file cat, head, tail, sed -n or grep
> command in the Bash tool instead of the Read tool

The tools reference, § "Edit tool behavior", read 2026-10-15, gives the
set: `cat`, `nl`, `bat`, `batcat`, `head`, `tail`, `sed -n 'X,Yp'`,
`grep`, `egrep`, `fgrep` and `rg`, "each run on one file with no pipes
or redirects. A search that prints no matches doesn't count as a read,
nor does any command outside this list." Such a view "also loads any
subdirectory `CLAUDE.md` and path-scoped rules", and the memory page's
§ "Path-specific rules" says the same of rules. Neither says whether a
skill's `paths:` follows, and neither draws a line between project and
user rules.

**A compound read still loads nothing, and auto mode batches reads.** In
the `/init` trial of 2026-10-15 on 2.1.293
([scope-instructions.md](scope-instructions.md) § "The fixture:
decision 1's trial, 2026-10-15"), the improver session `a465d5cf` read
every file in three Bash calls: a `find` piped to `head` then
`cat Makefile 2>/dev/null`, a `for` loop over `cat "$f"`, and one
`tail -n +1` across many files. Its transcript holds no `nested_memory`
record. None of the three is a single-file view, so the trial agrees
with the changelog.

Nothing here was probed.

## What the payload says, at `0105b27`

| Home | Says |
| --- | --- |
| root `CLAUDE.md` § "Validating a change" | "Activation keys on Read, Write and Edit, not `cat` or `Grep`" |
| `.claude/rules/activation-testing.md`, first bullet | "a `cat` through Bash, or a `Grep`, loads no skill and no rule" |
| `.claude/rules/editing-rules.md`, first bullet | Read, Written or Edited, "never for a `cat`, `sed` or heredoc edit" |
| `claude/rules/agent-instructions-scoping.md`, the `paths:` row | "only Grep or `cat` touch it" |
| the same, § "How Claude Code loads them" | "Grep, Glob and Bash load nothing" |
| `claude/rules/README.md` § "How they trigger" | Read, Write or Edit only |
| `.claude/skills/test-skill/SKILL.md`, `description` | "activation is keyed to the `Read` tool so a Bash `cat` activates nothing" |
| the same, its failure table | "Bash `cat` and `Grep` touch the same bytes and activate nothing" |
| `scripts/test-activation.ps1`, trap 3 | "Bash `cat` and Grep touch the same bytes and activate nothing" |
| `tests/skills/fabric-triggers/README.md` and `tests/skills/pbip-triggers/README.md` | "`cat` through Bash ... activates **nothing**" |
| `scripts/test-instruction-loading.py`, p8 | "Write, Grep, Glob and Bash load no nested CLAUDE.md" |

Root `CLAUDE.md`'s "`sed` or heredoc never" in § "Editing conventions",
and `editing-rules.md`'s "heredoc edit", hold as they stand: a `sed -i`
or a redirect is outside the set. Each still reads as if no Bash
command loads anything, so weigh a clause there. The skill homes hang
on the skill arm below: if a Bash view leaves a `paths:` skill's listing
hold in place, their trap stands for skills and only the rule half
moves. Ledger entries under `docs/evidence/` and `docs/audits/` stay as
they stand. Re-derive the list rather than trust it; it misses
`claude/rules/README.md`, which says nothing of Bash:

```bash
grep -rn -E 'Glob and Bash|Grep or `cat`|not `cat`|Bash `cat`|`cat` through Bash|cat`, `sed`' --include='*.md' --include='*.ps1' --include='*.py' . | grep -v -E '^\./docs/(audits|evidence)/'
```

## The probes

Rules and nested files go in `scripts/test-instruction-loading.py`, so
they re-run after an upgrade. Its `Step` builds only `cat '<target>'`
for Bash, so each arm needs its command spelled out, and a plain rule
kind beside `r@`, whose import would load at launch in every arm. One
session per arm, since a load is a per-session delta:

| Arm | Bash command | The docs expect |
| --- | --- | --- |
| cat | `cat a.probe` | the rule |
| head | `head -n 1 a.probe` | the rule |
| sed -n | `sed -n '1,1p' a.probe` | the rule |
| grep, a match | `grep plain a.probe` | the rule |
| grep, no match | `grep zzz a.probe` | nothing |
| a pipe | `cat a.probe \| head -n 1` | nothing |
| two files | `cat a.probe b.probe` | nothing |
| an edit | `sed -i 's/plain/flat/' a.probe` | nothing |
| nested | `cat sub/x.txt` | `sub/CLAUDE.md` |

p8 gets its expectation brought up to date: its Write should now load
`w/CLAUDE.md` at step 1, by 2.1.288, and its Bash `cat` `b/CLAUDE.md`
at step 4. It ran INVALID twice on 2026-10-15 for the protocol, not the
loader: in `8fd712fa` haiku printed `done 1` as a text-only message
after the Write, which ends a `-p` turn. Give each step its own
`--resume` process, as `segments()` already gives a `/compact`, or keep
"done N" out of a message of its own.

p6 and p7 come here too, from `scope-instructions.md` on 2026-10-15,
since they are this script's: both ran that day on 2.1.293, twice. p7
FAILED: a main-checkout Read in `.claude/worktrees/w1/` loaded no
`CLAUDE.md` there, the nearest changelog entry being 2.1.286's on
worktree subagents. The memory page points files under
`.claude/worktrees/` at the worktrees page, which says only that a
subagent in such a worktree "doesn't load the `CLAUDE.md` file or
`.claude/rules/` directory at the worktree's root as it reads files
there" (read 2026-10-15); a main session's Read goes unstated, so p7's
new expectation is the observed one. p6 was INVALID, judging no loader:
its subagent now ends with a `SubagentHandback` call, which the protocol
check has to allow.

Three arms the script cannot judge, run once as scratch probes the way
the 2026-10-06 entry in the ledger's § "Validating a change" ran its
arms E and F:

- **A skill**: a conditional skill on `**/*.probe`, `--tools Bash,Skill`,
  one `cat`. A listing delta naming it means a Bash view ends a
  `paths:` skill's hold too.
- **A user rule**: `cat` of a `.md` file, then a `nested_memory` record
  whose path is `~/.claude/rules/coding-markdown.md`, which globs
  `**/*.md`.
- **PowerShell**: `Get-Content` of `a.probe` through the PowerShell
  tool, outside the documented set, which this machine's sessions use
  as often as Bash.

## Edits, once the probes answer

- Each home in the table, corrected in place and dated with the version:
  a single-file view loads what a Read would, while a compound or
  multi-file Bash read, a pipe, a redirect, an edit, `Grep` and `Glob`
  load nothing, and the skill and PowerShell cases say what their arms
  found.
- `activation-testing.md`'s pin stays: auto mode batches reads as the
  trial's improver did, so an unpinned probe still goes dark at random,
  now by its command's shape rather than its tool.
- Root `CLAUDE.md` is capped by `scripts/lint-claude-md.py`, so its edit
  replaces words rather than adding a line.
- The evidence: one entry at the end of
  `docs/evidence/root-claude-md.md` § "Validating a change", the heading
  that holds the 2026-09-01 measurement the claim began as, with the arm
  table and session ids.
- `scope-instructions.md` § "Re-measure before acting" names p6, p7
  and p8 as this brief's; once they pass, that clause goes.

## Verification

- Each new probe, p6 and p7 included, passes twice in fresh sessions,
  then the whole set; anything else failing means the loader moved
  again.
- `uv run --with pyyaml scripts/lint-frontmatter.py` on each rule and
  skill touched, and `uv run scripts/lint-claude-md.py`.
- If test-skill's `description` changes, `uv run --with pyyaml
  scripts/skill-status.py --stale` lists it, and `/test-skill
  test-skill` retests its routing.
- After the merge, `./scripts/link-claude.ps1 -SkillGroups
  workflow,social,meta` from the main checkout, never bare, then `cmp`
  the deployed `agent-instructions-scoping.md` and `README.md` under
  `~/.claude/rules/` against the repo's.
- `pre-commit run --all-files`.

## Not checked

- A file outside the working directory, or in a folder added by
  `--add-dir`, whose `paths:` rules never load by
  `agent-instructions-scoping.md` (2026-10-15, 2.1.300).
- Whether the InstructionsLoaded hook fires for a load by a Bash view.
- A subagent's Bash view.

## Re-measure before acting

- `claude --version`: 2.1.293 on 2026-10-15, the release that shipped
  the fix.
- The changelog's 2.1.293 entry and the tools reference's paragraph,
  quoted above.
- The grep above, against the table.
