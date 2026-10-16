---
name: scope-instructions
# model: inherit  # any model: value hangs a skill on VS Code's Claude target (editing-skills.md)
effort: max
disable-model-invocation: false
argument-hint: "[file-or-folder]"
allowed-tools: Read Grep Glob Bash(git rev-parse *) Bash(git ls-files *) Bash(git shortlog *) Bash(git log *) Bash(uv run --no-project ${CLAUDE_SKILL_DIR}/scripts/folder-sessions.py *)
description: "Sorts a repo's agent instructions into the homes that load them when they are needed. Weighs each section of a root CLAUDE.md or AGENTS.md, each folder README's must-know lines and each file another coding tool reads against root, a paths: rule, a nested CLAUDE.md or AGENTS.md, a skill, a hook, a README or nowhere, by the event that loads each home and whether that event comes before the mistake. Reads every instruction file itself, in its own context, so the scoping rule loads where the proposal is written. Measures the repo's own session transcripts per folder with a bundled script: who worked there, whether they opened its README first, which nested files and rules loaded, how often they compacted. Finds an AGENTS.md a CLAUDE.md silences and a fact two tools' files hold apart. Proposes every move in one table and edits only on approval. Where /init and /doctor refresh and trim a root file, this moves what does not belong there."
when_to_use: "Use when asked where a piece of guidance should live, whether a repo or folder needs a nested CLAUDE.md or AGENTS.md, to split, slim or reorganize a CLAUDE.md, to move instructions into .claude/rules/, to audit instruction files across Claude, Copilot and other tools, or why a folder's README or an AGENTS.md is never read. A learning about how Claude Code loads these files is /learn's, into its user-scope rule."
---

# Scope instructions: where each piece of guidance lives

The question about a repo's agent guidance is rarely what to write and
usually where. Each home loads on its own trigger and misses in silence:
the guidance is on disk, correct, and never read. The built-ins answer
the other questions. In a trial on 2026-10-15, `CLAUDE_CODE_NEW_INIT=1`
`/init` and the `claude-md-improver` skill each cut derivable lines,
surfaced a README's rule and caught a stale command, and in three runs
neither moved a section out of a root `CLAUDE.md` into a nested file or
a `paths:` rule. This skill asks what they skip, of every section:
**what event loads its home, and does that event come before the mistake
it guards against?**

The homes and how each fails live in one place, the user-scope rule
`agent-instructions-scoping.md`, which this skill applies and does not
restate. It **proposes**; files change only on approval, and committing
is `/commit`'s.

## 0. Whose guidance

```bash
git rev-parse --show-toplevel
```

- **This repo's project-scope files only**: `CLAUDE.md`, `AGENTS.md` and
  `CLAUDE.local.md` at any depth, `.claude/CLAUDE.md`, `.claude/rules/`,
  and other tools' files. A `CLAUDE.local.md` is one person's: propose
  for it, never move another person's lines out of it.
- **User scope is not this skill's.** A section that belongs in every
  repo on the machine, in `~/.claude/`, is a `/learn` learning: name it
  in the proposal and leave it.
- **The repo's own conventions about its instruction files outrank the
  table**: a cap on root's length, a lint, a ban on nested files. Look
  for them in root and `CONTRIBUTING.md` first.
- **An argument narrows the run** to that file, or to that folder and
  the files whose guidance is about it.

## 1. Read every instruction file, here, with Read

Glob for the set, then Read each file with the Read tool, in this
context:

- `CLAUDE.md`, `CLAUDE.local.md` and `AGENTS.md` at any depth, and
  `.claude/CLAUDE.md`
- `.claude/rules/**/*.md`
- `.github/copilot-instructions.md` and
  `.github/instructions/**/*.instructions.md`
- `GEMINI.md`, `.cursor/rules/`, `.windsurfrules`, `.clinerules`
- each folder's `README.md`, since a must-know line can hide in one

**Never through a subagent, and never in a compound Bash command.** Both
are how the trial's built-ins lost the rule. A subagent's Read loads a
nested file or rule into the subagent only, so `/init`, which hands its
exploring to one, wrote its proposal in a context that held none. A
loop, a pipe or a `cat` of several files loads nothing, which is how the
improver read. A single-file `cat` or `head` loads as a Read does since
2.1.293, but Read is the route that loads on every version.

**Then check the rule is in context.** The first Read of a `CLAUDE.md`,
`AGENTS.md` or rule loads `agent-instructions-scoping.md` by its glob:
its table headed "Guidance is…" should now be in context. If it is not,
Read `~/.claude/rules/agent-instructions-scoping.md` directly, or `cat`
that one file if Read refuses a path outside the working directory. A
project-scope copy of the same name supersedes it; then that one is the
table.

For each file, note its length and when it loads: root and every
ancestor at launch, a nested file at the session's first Read, Write or
Edit in its folder, a rule with `paths:` on a match and one without at
launch, an `@path` import at launch with its parent.

**Find the silent files.** Claude Code reads an `AGENTS.md` only when no
`CLAUDE.md`, `.claude/CLAUDE.md` or `CLAUDE.local.md` sits in the working
directory or above it, so a root `CLAUDE.md` silences every `AGENTS.md`
in the repo, nested ones included. One that `claudeMdExcludes` skips does
not count. A silent file's unique lines are guidance no Claude session
has read.

## 2. Who reads them

- `git shortlog -sne HEAD` for who commits. One author means the user
  alone: design for their tools, not for teammates.
- **The tools come from the files found in step 1**, and from any
  `chat.*` keys in `.vscode/settings.json`. The rule's harness table says
  what VS Code's targets and GitHub.com's Copilot agent read. For Cursor,
  Windsurf, Cline and Gemini CLI this skill says nothing of when their
  files load: keep them, and flag a fact they hold apart.
- Ask the user only about readers who never commit.

## 3. Measure the sessions

```bash
uv run --no-project ${CLAUDE_SKILL_DIR}/scripts/folder-sessions.py
```

Run it from the repo, or from one of its worktrees. Per folder it prints
how many past sessions Read, Wrote or Edited there and how many edited;
whether each opened the folder's README **first**, **later** or
**never**, and how many of the first were named in a prompt; which
nested files and rules **loaded** on calls there; and how many of those
sessions compacted. `--folder <path>` narrows it, `--depth`, `--min` and
`--limit` shape it, `--json` is for parsing.

- **A README is the agent's choice to open; a nested file or a rule is
  not.** Many `never` beside many sessions is the evidence that the
  folder's must-know lines belong in a rule or a nested file.
- **`loaded` shows what already reaches the folder's work**, so a move
  there may be into a home that exists.
- **`compacted` counts sessions that lost them for a while**: after
  `/compact`, root returns at once while nested files and `paths:` rules
  return only at the next matching Read, Write or Edit.
- **The last lines give the reach**: the oldest transcript, which
  `cleanupPeriodDays` bounds (30 days by default), the versions seen, and
  the loads it could pin to no folder, by what they followed.
- **Misses are an upper bound.** Only Read, Write and Edit count as work
  in a folder, so a README viewed by `cat` reads as never opened, and an
  edit made through Bash is not seen. A folder with under five sessions
  is an anecdote; say so.
- **Exit 1**, no session ran here: sort on content alone and say so.
  **Exit 2**, the transcript format moved: report it, and do not grep the
  transcripts by hand as a stand-in.

## 4. Sort each section

Every `##` section of a root file gets one home, and so does each part
of any other file the rule's sizes flag: root past about 200 lines, a
nested file past about 60. Ask in order, and stop at the first yes:

1. **Does a live command or a sync trigger the mistake?** No file touch
   comes before it, so no rule or nested file can: it stays in root. In
   a client Fabric repo's hand trim, 4 of 15 silent-failure gotchas
   stayed for exactly this reason (2026-09-29).
2. **Is it about one directory's work?** A nested file there, or a
   `paths:` rule on that folder: a nested file where the folder's owners
   keep their own conventions with the code, a rule where all
   conventions are kept in one place (the large-codebases docs' split).
   On Windows, prefer the `paths:` rule either way: a nested file misses
   every Read, Write or Edit whose drive letter is cased unlike the
   launch directory's, and a rule loads on both (the drive-letter bullet
   of `agent-instructions-scoping.md`).
   A section that also governs files outside the folder is split, each
   line going where the files it governs are touched.
3. **Is it about one kind of file, wherever it sits?** A `paths:` rule
   globbed on that kind, `**/*.sql` and not `*.sql`, which matches the
   repo root only.
4. **Is it a procedure someone asks for in words?** A skill.
5. **Must it hold before the agent acts?** A hook or a
   `permissions.deny` rule.
6. **Is it long reference for people?** A README, its must-know lines
   going by this same list.
7. **Can it be derived from the code?** Nowhere: what a formatter
   config, a linter or the layout already says. `/doctor`'s checkup cuts
   the same.
8. **Otherwise**, root.

In the same pass:

- **The other direction.** A README's must-know lines and a silent
  file's unique lines move to where a session will load them. A silent
  root `AGENTS.md` becomes the import form, `@AGENTS.md` at the top of
  the `CLAUDE.md`, never a copy, which leaves two homes to drift.
- **One fact, one home across tools.** Where Copilot's file and the
  `CLAUDE.md` disagree, say on a line length the formatter config
  settles, the config wins and the duplicates go; shared long form
  sits in one doc that each tool's file points at, by code span in
  Copilot's (the rule's import-form conditions).
- **Stale lines.** Check each command, make target, script and path a
  section names against the repo (`Makefile`, `package.json`, the disk)
  and flag what is missing. A full pass for staleness, contradiction and
  prompting written for older models is `/doctor prompt-audit`'s, from
  2.1.283: name it rather than redo it.
- **A nested file's name** follows the rule's table: `CLAUDE.md` under a
  root `CLAUDE.md`, `AGENTS.md` under a bare root `AGENTS.md`, and under
  the import form a `CLAUDE.md` importing a sibling `AGENTS.md` where
  other tools need it.

## 5. Where a new file never goes

- **Inside a Fabric item folder** (`<name>.<ItemType>/`): untested
  against Git sync. A markdown file at a workspace's sync root coexists.
- **Under `.claude/`**, except `.claude/rules/`: `.claude/CLAUDE.md` is
  the project file's second home, loaded at launch beside a root one.
- **In a folder copied elsewhere**, such as a skill's or a template's:
  the file travels with every copy.
- **At or above test fixtures or samples**: an instruction file there is
  live, and loads on a Read like any other.
- **Never a bare `AGENTS.md` in place of a root `CLAUDE.md`**: the rule
  lists five things it loses, each silently.
- **No `claudeMdExcludes` or `instructionFiles` change unasked.**
  `instructionFiles` is read only from user, managed and `--settings`
  files, so a repo cannot set it for its readers. A committed exclude
  travels into every worktree, and `**/.claude/worktrees/**` strips a
  worktree session's own root `CLAUDE.md` (probed 2026-09-27, held on
  2.1.293 on 2026-10-15).

## 6. Propose

One table, a row for every section, moved or kept:

| Section | Now | Proposed home | Loads when | Evidence |
| --- | --- | --- | --- | --- |

Under it: each new file's full text, root's line count before and
after, the silent files and what becomes of them, the stale lines
flagged, and what goes to `/learn` or `/doctor prompt-audit`. Then stop.
The user approves rows, not the table: some may go and some stay.

## 7. Apply what was approved

- **Exactly the approved rows.** A section moves; it is not copied. Its
  old text leaves in the same edit, or two homes start to drift.
- **Prove a new nested file or rule loads, in a session that did not
  write it.** This session wrote it, so it is in context already and
  never arrives as a nested load here. The docs' own test is a fresh
  session reading a file in that folder. Offer a cold probe, which costs
  cents, and run it only on a yes. It drops this session's `CLAUDE*`
  variables first, as this machine's loader probes do, so that it starts
  as a session of its own rather than a child of this one. On Windows,
  name the file by its absolute path, its drive letter in upper case.
  Git Bash starts the probe on an upper-case drive, `C:\` and not
  `c:\` (2026-10-15), and a nested file loads only on a path whose
  drive letter is cased as the launch directory's (the rule), so a
  `c:\` path copied from a VS Code session misses a file that is in
  place.

  ```bash
  ( for v in $(compgen -e | grep -E '^(CLAUDE|MCP_CONNECTION_NONBLOCKING)'); do unset "$v"; done
    claude -p "Read <a file in that folder>, then reply done" -n "probe: scope-instructions" --model haiku --tools Read --strict-mcp-config )
  uv run --no-project ${CLAUDE_SKILL_DIR}/scripts/folder-sessions.py --probes --folder <that folder> --min 1
  ```

  The new file listed under `loaded` is the proof. Its absence, with the
  file in place and the path so spelled, means a glob or a name is
  wrong.
- **Hand off to `/commit`.** The repo's own checks run there.

## Constraints

- **Proposes first.** Nothing changes before the user approves a row.
- **Reads in its own context, with Read**, never through a subagent or
  a compound Bash command.
- **Edits no user-scope file**; those learnings are `/learn`'s.
- **Removes no guidance without its new home in the same change.**
- **The repo's conventions win** over the table.
- **A client's evidence stays in that repo.** Folder names and session
  counts belong in that repo's files, never in another repo's.
- **Not this skill**: a first `CLAUDE.md` for a repo with none is
  `/init`'s; trimming a well-placed file of derivable lines is
  `/doctor`'s; staleness and contradiction are `/doctor prompt-audit`'s;
  how the loader behaves is `/learn`'s.
