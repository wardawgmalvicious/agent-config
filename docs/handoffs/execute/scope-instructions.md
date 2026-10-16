---
status: open
priority: 3
needs: [user]
blocked-by: []
written: 2026-10-15
---

# Skill handoff brief: scope-instructions

Last verified: 2026-10-15

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.
>
> Guidance: The frontmatter is this brief's whole queue state: `scripts/handoff-status.py` prints the queue from it, and pre-commit's `lint-briefs` fails a commit on a brief without it or with a placeholder left in. Pick `priority` — 1 now, 2 next, 3 later — list in `needs` what a session cannot supply alone (`user` for a decision), name any brief this waits on in `blocked-by`, and state none of it in the body.

## Artifact path

Payload, in the `meta` group: it acts on any repo's agent
configuration and must run in client repos, which is what
`skills/README.md` § "Meta" is for.

- Repo: `skills/meta/scope-instructions/SKILL.md`, its script at
  `skills/meta/scope-instructions/scripts/folder-sessions.py`
- Deployed: `~/.claude/skills/scope-instructions/`, by junction, only
  once `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`
  runs from the main checkout: a new directory has no junction until
  then, and the linker refuses a worktree.

This brief replaces `nested-instruction-files.md`, whose Phase 3 it is
(§ "Where this came from" below). It was written in that brief's
worktree, `.claude/worktrees/nested-instruction-files`, on
`worktree-nested-instruction-files`, so the queue view never paired
this stem with a worktree.

## Scope

In any repo, sorts the agent guidance into the home that loads it when
it is needed. It reads every instruction file there, by Read, in its
own context: a root `CLAUDE.md` or `AGENTS.md`, `CLAUDE.local.md`,
nested files, `.claude/rules/`, and other tools' files. Each section of
a root file, each folder README's must-know lines and each other tool's
file is weighed against the homes in
`claude/rules/agent-instructions-scoping.md`. The test for each is what
event loads that home, and whether the event comes before the mistake.
The repo's own transcripts give per-folder evidence, through a bundled
script. It proposes every move in one table and edits only on approval.
Inline, model-invocable, and unconditional, with no `paths:`: the
request comes in words, before any instruction file is Read, and the
skill's first act is that Read.

## Sources drilled

Drilled 2026-10-15 on CLI 2.1.293, the doc pages as raw markdown from
`code.claude.com/docs/en/<page>.md`:

- **memory**: a subdirectory's `CLAUDE.md` loads "once Claude reads,
  writes, or edits another file in that subdirectory", and "Reading
  includes viewing the file with a Bash command that counts as a read,
  such as `cat` or `head` on a single file". "If an entry is a
  multi-step procedure or only matters for one part of the codebase,
  move it to a skill or a path-scoped rule instead", and "target under
  200 lines per CLAUDE.md file". `/doctor prompt-audit`, from 2.1.283,
  "looks for problems such as instructions written for older models,
  references to files or commands that don't exist, and files that
  contradict each other". The `/doctor` checkup "cuts content Claude
  can derive from the codebase". `CLAUDE_CODE_NEW_INIT=1` makes `/init`
  explore "with a subagent". To test a new nested file, "create it
  from your shell rather than asking Claude to write it, then ask
  Claude to read a file in that subdirectory".
- **large-codebases**: the split table quoted in
  `agent-instructions-scoping.md`'s lineage stands unchanged: a
  per-directory file when "Directory owners maintain their own
  conventions; instructions are versioned with the code", a
  path-scoped rule when "You want all conventions in one place, or the
  same rule applies to many scattered paths".
- **sessions**: transcripts sit at
  `~/.claude/projects/<project>/<session-id>.jsonl`, `<project>` being
  "your working directory path with non-alphanumeric characters
  replaced by `-`", kept 30 days by default (`cleanupPeriodDays`).
  "The entry format is internal to Claude Code and changes between
  versions, so scripts that parse these files directly can break on
  any release."
- **This machine's transcripts**, the last 60 of this repo's, on
  2.1.293. The script keys on these records. A load is an `attachment`
  of type `nested_memory`, with `path` and an inner `content` whose
  `type` reads `User` for a user rule and whose `globs` name a rule's
  `paths:`. A nested `AGENTS.md` is `hook_additional_context` opening
  `Contents of <path>\AGENTS.md:` (probes C0 and 4, 2026-09-25), its
  content a list of strings and its `toolUseID` the call's id plus
  `-context` (probe p4, 2026-10-15).
  Compactions are `system` records of subtype `compact_boundary`, and
  launch loads are an `instructions` attachment with `files`. A
  subagent writes `<session>/subagents/agent-<id>.jsonl`, each record
  `isSidechain: true`. Every record carries `cwd` and `version`. A
  worktree session gets a project directory of its own, and the drive
  letter's case varies between them (`c--…` and `C--…`); a session that
  enters a worktree by `EnterWorktree` moves its transcript there too.
  A load links back through `parentUuid` to the last tool result before
  it, up to five hops in 62 of 69 loads sampled. After parallel calls
  that is the batch's last, often not the call that loaded it: of 1,115
  rule loads here on 2026-10-15, 369 chained to a file their globs
  match. A rule's record drops a trailing `/**` from its globs, keeping
  `claude/hooks/**` as `claude/hooks`. A prompt's @-mention is a `file`
  attachment with `filename`, and a nested file it brings follows no
  tool call. The launch `instructions` record listed root's files only,
  one `Project` entry each in 79 sessions.
- **The changelog**, 2.1.283 to 2.1.300: `/doctor prompt-audit`
  (2.1.283); a worktree-isolated subagent no longer loads the project
  file twice (2.1.286); a folder's `CLAUDE.md` no longer attaches a
  second time after a resume or a compaction (2.1.287); Write and Edit
  load rules and nested files (2.1.288); a subdirectory's `AGENTS.md`
  attaches on an @-mention (2.1.290); "a transcript line when a nested
  one isn't loaded" (2.1.292); a single-file Bash view loads both
  (2.1.293).
- **This repo's prompt audit of 2026-10-08**,
  `docs/audits/2026-10-08/prompt-audit/00-audit-report.md`: it groups
  findings as dated prompt text, stale facts and conflicting files,
  tool descriptions and request code, and proposes no move, over a
  repo holding a nested file and nine rules.
- **GitHub's repository-instructions page**, through WebFetch, so not
  raw bytes: "the nearest `AGENTS.md` file in the directory tree will
  take precedence", or "a single `CLAUDE.md` or `GEMINI.md` file stored
  in the root", and path-specific `.instructions.md` files "are only
  supported for Copilot cloud agent and Copilot code review" on
  GitHub.com. The rule's claim of 2026-09-25 holds.
- `skills/workflow/find-session/scripts/find-session.py`, the
  transcript reader the script follows: `CLAUDE_CONFIG_DIR`, probe
  sessions left out, exit 2 when transcripts exist and nothing parses.
- Carried from `nested-instruction-files.md`, at `92f8afc`: probes 1–8,
  C0, k0–k2 and h1 on 2.1.282, now `scripts/test-instruction-loading.py`
  and the rule; the two folder measurements (§ "Notes"); the trial.

Not drilled:

- **VS Code's custom-instructions page**, not re-read: the skill takes
  the harness table in `agent-instructions-scoping.md` (2026-09-30,
  Local added 2026-10-13) as it stands, and states no VS Code claim of
  its own.
- **Cursor, Windsurf, Cline, Gemini CLI and Codex**: how each loads
  `.cursor/rules/`, `.windsurfrules`, `.clinerules` or `GEMINI.md` was
  not read. The skill lists those files as another tool's and says
  nothing of when they load.
- **`/doctor prompt-audit` and `/doctor`'s checkup on the fixture**:
  not run. By their docs neither places guidance, and the 2026-10-08
  audit moved nothing; the pilot runs prompt-audit as a third arm
  (§ "Notes").
- **2.1.292's not-loaded line**: its record kind did not appear in the
  sample, so the script does not read it.
- **The Agent SDK's session API**: `find-session` measured
  `get_session_messages()` returning only the chain since the last
  compaction (2026-10-06); not re-measured, and the script reads the
  JSONL for the same reason.
- **Bash views as reads**: a one-file `cat` loads a nested file or rule
  as a Read does (probed 2026-10-15, `docs/evidence/root-claude-md.md`
  § "Validating a change"). The script counts Read, Write and Edit, so a
  README viewed by `cat` reads as never opened: it overcounts misses, the
  direction that favours a move, and its output says so. Sized on this
  repo on 2026-10-15, counting any Bash or PowerShell command that names
  the README: 10 of the 73 sessions marked never under
  `docs/handoffs/execute/`, 8 of 84 under `skills/`, 8 of 39 under
  `claude/rules/`, 5 of 47 under `docs/audits/`, fewer elsewhere, so the
  script still counts no shell view.
- **Per-directory skills and a skill's own `paths:`**: a skill is a
  home in the table; where one sits, and whether a Bash view ends a
  `paths:` skill's hold, is not judged.

## Frontmatter

```yaml
---
name: scope-instructions
# model: inherit  # always commented under skills/: a pin hangs on VS Code's Claude target (editing-skills.md)
effort: max  # a behavioural skill, unpinned (editing-skills.md § "Invocation and spend fields")
disable-model-invocation: false  # it must fire on a request in words, in any repo
argument-hint: "[file-or-folder]"  # optional: sort one file or one folder's guidance; default, the whole repo
allowed-tools: Read Grep Glob Bash(git rev-parse *) Bash(git ls-files *) Bash(git shortlog *) Bash(git log *) Bash(uv run --no-project ${CLAUDE_SKILL_DIR}/scripts/folder-sessions.py *)  # pre-approves the reads and the script for the invoking turn; the cold probe stays unapproved, run on a yes
description: "Sorts a repo's agent instructions into the homes that load them when they are needed. Weighs each section of a root CLAUDE.md or AGENTS.md, each folder README's must-know lines and each file another coding tool reads against root, a paths: rule, a nested CLAUDE.md or AGENTS.md, a skill, a hook, a README or nowhere, by the event that loads each home and whether that event comes before the mistake. Reads every instruction file itself, in its own context, so the scoping rule loads where the proposal is written. Measures the repo's own session transcripts per folder with a bundled script: who worked there, whether they opened its README first, which nested files and rules loaded, how often they compacted. Finds an AGENTS.md a CLAUDE.md silences and a fact two tools' files hold apart. Proposes every move in one table and edits only on approval. Where /init and /doctor refresh and trim a root file, this moves what does not belong there."
when_to_use: "Use when asked where a piece of guidance should live, whether a repo or folder needs a nested CLAUDE.md or AGENTS.md, to split, slim or reorganize a CLAUDE.md, to move instructions into .claude/rules/, to audit instruction files across Claude, Copilot and other tools, or why a folder's README or an AGENTS.md is never read. A learning about how Claude Code loads these files is /learn's, into its user-scope rule."
---
```

No `paths:`, `context` or `hooks`: a `paths:` glob would hide it until
an instruction file is Read, which is the step it exists to force, and
a fork would put that Read in a subagent, the trial's failure.

## Description char count

- `description`: 944 / 1,024
- `when_to_use`: 414 / 512

Unconditional and in the default deploy, so its 1,358 characters sit
in every session's listing on the machine, `learn`'s neighbour there.
The draft's last sentence no longer says `/doctor` never moves a
section: the trial measured `/init` and the improver, not `/doctor`.

## Body structure outline

0. **Which repo, whose guidance.** `git rev-parse --show-toplevel`. The
   skill edits this repo's project-scope files only. A section that
   belongs at user scope, `~/.claude`, is `/learn`'s, named and not
   written. The repo's own conventions about its instruction files
   (a cap, a lint, a ban) outrank the skill's table.
1. **Inventory by Read, in this context.** Glob for `CLAUDE.md`,
   `CLAUDE.local.md`, `.claude/CLAUDE.md` and `AGENTS.md` at any depth,
   `.claude/rules/**/*.md`, `.github/copilot-instructions.md`,
   `.github/instructions/**/*.instructions.md`, `GEMINI.md`,
   `.cursor/rules/`, `.windsurfrules`, `.clinerules`, and each folder's
   `README.md`. Read each one with the Read tool, never in a subagent,
   whose loads stay in it (probe 6, and the trial's `/init`), and never
   in a compound Bash command, which loads nothing (the trial's
   improver). The first Read of a `CLAUDE.md` or `AGENTS.md` loads
   `agent-instructions-scoping.md` by its glob; check it is in context,
   and Read `~/.claude/rules/agent-instructions-scoping.md` if not.
   Note what the either/or silences: an `AGENTS.md` beside or below a
   `CLAUDE.md` (K4).
2. **Who reads them.** `git shortlog -sne HEAD` for the authors, and
   the tool files found in 1 for the tools. Ask the user only about
   readers who never commit.
3. **Measure the sessions.** Run `folder-sessions.py` from the repo
   root. Per folder: sessions that Read, Wrote or Edited there,
   subagent-only ones apart; whether each opened the folder's README
   before any other file there, after, or never, and whether the
   user's prompt named it first; which nested files and rules loaded
   on calls there; how many of those sessions compacted. It prints its
   reach (oldest transcript, the versions seen) and exits 2 when
   transcripts exist and no tool call parses. Few transcripts: say so,
   and sort on content alone.
4. **Sort.** Every `##` section of a root file, and of any file past
   the rule's sizes, gets one home from the rule's table, by the load
   event and its timing: about one directory (K1), about one file kind
   across folders (K2), a procedure, a must-hold, long reference,
   derivable (K5), or root. A gotcha that a live command or a sync
   triggers stays in root, since no file touch precedes it (the client
   trim of 2026-09-29). The reverse direction too: a README's must-know
   lines (K3), a silenced file's unique lines (K4), one fact two tools'
   files hold apart, kept in one home (K5's 88 against 100). Flag a
   command or path the repo lacks (K6); a full staleness pass is
   `/doctor prompt-audit`'s. A nested file's name follows the rule's
   naming table.
5. **Where a file never goes.** Inside a Fabric item folder, untested;
   under `.claude/`; in a folder copied elsewhere; at or above test
   fixtures, which load like any file. Never a bare `AGENTS.md` in
   place of a root `CLAUDE.md`. No `claudeMdExcludes` or
   `instructionFiles` change unasked: a committed exclude travels into
   every worktree (probe 7).
6. **Propose.** One table: section, current home, proposed home, the
   event that loads it, the evidence from 3. Root's line count before
   and after. Nothing is edited yet.
7. **Edit on approval.** Apply exactly the approved rows. A new nested
   file or rule is in this context already, since this session wrote
   it, so its load is proved only by a cold session: offer
   `claude -p` with `--tools Read` reading a file in its folder, its
   transcript checked for the `nested_memory` record. Commit is
   `/commit`'s.
8. **Constraints**: proposes before editing; reads in its own context;
   no user-scope edits; client evidence stays in that repo; the repo's
   conventions win.

## Changes from source proposal

The source is `nested-instruction-files.md` § "Phase 3", its five
proposals for `/author-skill` to keep or cut, at `92f8afc`.

- **`learn`'s Step 3 row exists**, added with decision 2: row 120 sends
  a loader learning to the rule and leaves "A repo's own placement
  decision" to that repo. So `learn` is no neighbour to extend: its
  Step 0 hands back exactly the question this skill answers. A pointer
  from that row to this skill is a `/learn` edit after landing, since
  `/author-skill` edits no other skill.
- **The cheapest rival is declined**, by the trial: the rule reached
  the deciding context in one route of three, and there it changed
  nothing. The sentence would reach only that route.
- **Proposal 1, transcript evidence: kept**, the user's call on
  2026-10-15, as `scripts/folder-sessions.py`. Counting Read, Write and
  Edit only, as the 2026-09-27 measurement did.
- **Proposal 2, the cross-tool inventory: kept, narrowed.** Other tools'
  files are listed and their loading is not judged, beyond what the
  rule states for VS Code and GitHub.com.
- **Proposal 3, placement by the table: kept**, with the trigger test
  the client repo's trim of 2026-09-29 found: a gotcha a command or a
  sync triggers stays in root.
- **Proposal 4, platform checks: kept** as step 5.
- **Proposal 5, propose then edit: kept.**
- **Added: Read in the main context**, the trial's finding, as step 1.
- **Added: `/doctor prompt-audit`**, absent from the source, named as
  the pass for staleness and contradiction; the skill flags only what
  its own reading finds.
- **Added: the cold check of a new file** in step 7, since the writing
  session never loads its own file.

## Tag

personal

## Portability caveats

N/A — personal scope. Under Copilot, `effort` and `when_to_use` warn
and are ignored, and `${CLAUDE_SKILL_DIR}` is Claude Code's.

## Cross-reference dependencies

- `claude/rules/agent-instructions-scoping.md` — (a) already converted.
  The tables the sort applies; the skill reads them there and copies
  none.
- `learn` — (a). Takes a section that belongs at user scope; its row 120
  gains a pointer here after landing, through `/learn`.
- `commit` — (a). The hand-off after step 7.
- `find-session` — (a). The script's pattern, not invoked.
- `scripts/test-instruction-loading.py` — (a). The loader probes the
  skill's claims rest on; a FAIL there can void a step.
- `/init`, `/doctor`, `/doctor prompt-audit` — (c) built-ins, named as
  the neighbours that refresh and trim.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief; brief-specific observations belong in Notes below.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

### Where this came from

The user asked on 2026-09-24 for a fresh look at when a repo should get
a nested `CLAUDE.md` or `AGENTS.md`, and possibly a skill making those
determinations in any repo, "something similar to what init does but
deeper"; on 2026-09-25, for a root cut over to `AGENTS.md` where that
makes it tool-agnostic and loses nothing. `nested-instruction-files.md`
answered five decisions, all landed: the strategy is a user-scope rule,
`agent-instructions-scoping.md` (2026-09-27); `instructionFiles` stays
at its default; the import form went to the client Fabric repo, not
here; this repo got `docs/handoffs/CLAUDE.md`. Decision 1, a skill at
all, waited on a trial of the built-ins, which ran 2026-10-15 and left
the gap below; the user reopened it the same day. Its full log, probes
with session ids included, is
`git show 92f8afc:docs/handoffs/execute/nested-instruction-files.md`.

### Trigger queries and the fresh-session test

Should fire, in a repo with a root `CLAUDE.md`:

1. "Where should the SQL conventions in our CLAUDE.md live?"
2. "Does the contracts folder need its own CLAUDE.md?"
3. "Our CLAUDE.md is 300 lines; split it so a session loads only what
   it needs."
4. "Move the testing instructions out of CLAUDE.md into .claude/rules."
5. "Audit this repo's instruction files across Claude Code and
   Copilot."
6. "Nobody ever seems to read contracts/README.md; why, and what should
   we do about it?"
7. "Should we switch our CLAUDE.md to AGENTS.md?"

Should not fire, each owned by a neighbour:

- "learn! a nested CLAUDE.md didn't load when I grepped the folder":
  `/learn`, a loader learning.
- "Create a CLAUDE.md for this new repo": `/init`.
- "Find the session where we split the CLAUDE.md": `find-session`.
- "Fix the typo on line 40 of CLAUDE.md": no skill.

The behavioural test, after the landing and the deploy, since `meta`
is a deployed group: the skill against a `--safe-mode` baseline on the
fixture below, built outside any path that names this repo. **K1 and K2
do not discriminate.** Run 2026-10-15, every Opus 5.5 arm asked to
split for loading moved the `contracts/` section to a nested file or a
rule on `contracts/**` and the SQL section to a `paths:` rule on
`**/*.sql`, the baseline and a `Skill`-denied ablation included. What
separated was the body's, in a main session holding the
`nested_memory` record for `agent-instructions-scoping.md`: a proposal
with no edit, the lines the formatter enforces cut rather than moved,
and the README's and the silent file's rules put into the plan rather
than left as gaps (`tests/skills/scope-instructions/README.md`). Give
each arm a fresh copy of the fixture: one no session has run in holds
no transcripts, so `folder-sessions.py` exits 1 there and the skill
should say it sorted on content alone.

### The fixture: decision 1's trial, 2026-10-15

**Both built-ins left the placement half undone.** In three runs none
moved a section out of a root `CLAUDE.md`, into a nested file or a
`paths:` rule, even once with `agent-instructions-scoping.md` in the
context that wrote the proposal; each did the rest well. Run on
2.1.293, Opus 5.5 at `--effort medium`, `--strict-mcp-config`, under
this machine's user scope, for $3.72 in all, one run per arm.

The fixture was a scratch repo, `orders-sync`, built to six known
answers. A 75-line root `CLAUDE.md` held a `contracts/` section (K1, a
nested file's), a section on every `.sql` file across two folders (K2,
a `paths:` rule's), style rules `pyproject.toml` already enforces and a
layout list (K5, nowhere), and `make db-migrate`, a target the
`Makefile` lacks (K6, a control). `contracts/README.md` held the only
breaking-change rule (K3); a root `AGENTS.md`, silent beside the
`CLAUDE.md`, the only "never log customer email" rule (K4); and
`.github/copilot-instructions.md` said 88-character lines against
`pyproject.toml`'s 100 (K5). Its generator is gone;
`tests/skills/scope-instructions/make_fixture.py` rebuilds the fixture
from this paragraph.

| Known answer | `CLAUDE_CODE_NEW_INIT=1` `/init` | `claude-md-improver`, as run | `claude-md-improver`, Bash denied |
| --- | --- | --- | --- |
| K1 `contracts/` rules to a nested file | no | weighed, declined: some govern code outside the folder | no |
| K2 SQL rules to a `paths:` rule | no | no | no |
| K3 the README's rule surfaced | yes | yes | yes |
| K4 `AGENTS.md` silenced, its rule recovered | yes, copied, so two files hold it | yes, `@AGENTS.md` | yes, `@AGENTS.md` placed to spare MD041 |
| K5 derivable rules cut, Copilot drift flagged | yes | yes | yes |
| K6 the stale command | yes | yes | yes |

- No run proposed a `.claude/rules/` file, and the improver's procedure
  never asks where a section belongs: its rubric scores commands,
  architecture, gotchas, conciseness, currency and actionability, and
  its `SKILL.md` says "Propose targeted additions only". Its discovery
  `find` names `.claude.local.md`, which Claude Code never reads, and
  not `CLAUDE.local.md`, `AGENTS.md` or `.claude/rules/`.
- The rule reached the deciding context in one run of three. The
  improver read every file through Bash, compound commands that load
  nothing. `/init` handed every Read to an Explore subagent, whose
  loads stayed there, and the main session that wrote the proposal held
  no `nested_memory` record. Denied Bash, the improver Read in its main
  context, got the rule beside three coding rules, and still proposed
  root-only edits.
- Under `claude -p`, `/init` asks its questions in text: three turns to
  a diff. Git Bash rewrote the bare `/init` argument to
  `C:/Program Files/Git/init`; `MSYS2_ARG_CONV_EXCL='*'` keeps it.

**No built-in found K1 or K2, but the base model does once asked to
split for loading**, so a draft passes on what separates it from the
baseline (above), with K1 to K6 found. `/doctor prompt-audit`, the third
arm, found K4 and K6 and moved nothing (2026-10-15). The fixture's
instruction files load as nested files in any session here that Reads
them, so the generator writes them outside this repo, never under
`tests/`.

### The worked measurements

The script's output should reproduce these shapes. Neither can be
re-derived: both reached back `cleanupPeriodDays`, 15 then, and those
transcripts are gone.

A client Fabric repo, 2026-09-24, 53 transcripts:

| Folder holds | README | Sessions working there | Opened it | Before any other file there |
| --- | --- | --- | --- | --- |
| Per-object contract files | 305 lines | 7 | 6 | 3 |
| Column docstrings | 68 lines | 1 | 0 | 0 |
| Eventhouse definitions | 86 lines | 1 | 1 | 1 |

This repo, 2026-09-27, 300 main-session transcripts from 2026-09-11,
Edit and Write counted as edits; its ledger entry is
`docs/evidence/root-claude-md.md` § "Editing conventions":

| Directory | Sessions editing there | Read its README first | Of those, the user named it | Read it only after | Never read it |
| --- | --- | --- | --- | --- | --- |
| `docs/handoffs/execute/` | 24 | 11 | 4 | 2 | 11 |
| `docs/audits/` | 6 | 0 | 0 | 1 | 5 |
| `scripts/` | 15 | 1 | 0 | 2 | 12 |

`docs/audits/` and `scripts/` wanted nothing: skills carry the audit
conventions, and what governs editing a script is in path rules. A run
here that proposes a nested file in either without new evidence has
overreached.

The script's own reading here, as fixed on 2026-10-15: the queue README
opened first in 19 of 100 sessions under `execute/`, later in 8, never
in 73, against 11, 2 and 11 of 24 on 2026-09-27.

### The pilot

On the client Fabric repo, then here. Re-measured 2026-10-15 and moved
since 2026-09-29: its Copilot-format instruction files were retired on
2026-10-02, leaving a 274-line root `AGENTS.md` behind a three-line
`CLAUDE.md` of `@AGENTS.md` (its Claude-only bullets gone), three
`paths:` rules and no nested file. Root's section on the contract
folder is down to pointers, while that folder's README grew from 305
to 586 lines; the README of the column-docstring folder and of the
Eventhouse folder sit under no rule. So the 2026-09-24 proposal, move
root's contract section into the rule covering it and fold each
README's must-know lines into that rule, is half done by hand. A draft
should find what is left of it, and handle the trigger test and the
rules there that point at other files. The user runs it there, by
`/scope-instructions` in a session of their own (their call,
2026-10-15), so it is real use: its verdict comes back here scrubbed,
and `skill-status.py --stamp scope-instructions --phase real-use`
records it. The repo's name stays out of this repo.

It ran there on 2026-10-15 and held, stamped at `7a02e6c`:
`tests/skills/scope-instructions/README.md` § "Real use, 2026-10-15"
has the verdict. The run here, which this section's first line plans,
has not been made.

### Owed before this brief lands

- **Not p6 or p7** of `scripts/test-instruction-loading.py`: both pass
  since 2026-10-15, p7 expecting what it found, that a main-checkout
  Read in `.claude/worktrees/` loads no `CLAUDE.md` there. That leaves
  the exclude Phase 2 declined preventing nothing, so the decline stands.
- **The three body gaps the pilot found**, listed in the tests README,
  landing under one Phase B retest with the drive-letter edits to steps
  4 and 7, made 2026-10-16 (the user's call of 2026-10-15).

`tests/scripts/folder-sessions/`, the script's negative cases, written
2026-10-15: the seven this list named, which the script `f03128b`
shipped passes, and five that writing them found, which it fails. A
rule loaded beside a parallel Bash call pins by its globs, a recorded
glob covers what lies under it, a rule file named `agents.md` is still
a rule, a nested `AGENTS.md` pins from its hook's list of strings, and
a load after a later prompt follows no call, not the turn before's.

### Scrubbing

This repo is public. The client repo, its folder names, its source
systems and its session ids stay out of every commit and out of the
skill's text (`author-skill` § 4); "a client Fabric repo" is the
citation.

### Re-measure before acting

- `claude --version`: 2.1.293 on 2026-10-15; 2.1.300 is out, and its
  changelog past 2.1.293 touches no instruction loading.
- `uv run scripts/test-instruction-loading.py`: all 28 passed on
  2026-10-15, before `0ab1dee` added d1 to d5; those five, p6 and p8
  passed that day, the rest not rerun since.
- `bash tests/scripts/folder-sessions/test-folder-sessions.sh`: 28 of
  28 on 2026-10-15, where the script `f03128b` shipped fails 7.
- The memory, large-codebases and sessions pages, read 2026-10-15.
- The client repo's root and rules, re-measured 2026-10-15 (§ "The
  pilot").

## Confidence

- Structure: H. It answers the gap the trial measured, with the step
  that closes each of its three routes.
- Field specs: H. Counted, and matched to `editing-skills.md`.
- Body content: M. The sort is judgment; the trial shows the built-ins
  miss K1 and K2, not that this procedure finds them.
- The script: M. It reads a format the docs call internal, so it is
  built to fail loudly, not to last.
