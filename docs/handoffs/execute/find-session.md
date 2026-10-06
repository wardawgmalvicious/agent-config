---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-06
---

# Skill handoff brief: find-session

Last verified: 2026-10-06

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.
>
> Guidance: The frontmatter is this brief's whole queue state: `scripts/handoff-status.py` prints the queue from it, and pre-commit's `lint-briefs` fails a commit on a brief without it or with a placeholder left in. Pick `priority` — 1 now, 2 next, 3 later — list in `needs` what a session cannot supply alone (`user` for a decision), name any brief this waits on in `blocked-by`, and state none of it in the body.

## Artifact path

- Repo: `skills/workflow/find-session/SKILL.md`, and the script it runs
  at `skills/workflow/find-session/scripts/find-session.py`, moved there
  by `git mv` from `scripts/find-session.py` (`904b857`).
- Deployed: `~/.claude/skills/find-session/`, a junction made by
  `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta` from the
  main checkout once this brief's worktree lands. A directory that did
  not exist at the last run has no junction, so until then the skill is
  in no listing, `/find-session` answers `Unknown command`, and the path
  the skill runs the script by does not exist.
- Group: `workflow`, confirmed by the user on 2026-10-06. It acts on the
  user's sessions in any repo, as `land` acts on their branches, and its
  subject is not the agent configuration, so not `meta`. Copilot is moot:
  that payload is retiring and `copy-copilot.ps1` is no longer run
  (`editing-skills.md`).

## Scope

One thin skill: when to search, how, how to narrow, how to report. It
runs the bundled script, which reads every transcript under
`~/.claude/projects/` and prints the sessions holding every given term,
each with the passage that matched best and the `claude --resume`
command that reopens it, then a summary line naming the oldest
transcript on disk, which is how far back a search can reach. It only
reads: it names, resumes and deletes nothing. Inline, model-invocable,
unconditional (no `paths:`: the ask arrives in words, not with a file),
`effort: max` as on every behavioural skill but `commit`, and not forked,
since a search is one command and its report.

## Sources drilled

Drilled on 2026-10-06, Claude Code 2.1.291, unless dated otherwise:

- `scripts/find-session.py` at `904b857`, whole: a hit is every term as
  a case-insensitive substring of the session's name, Claude Code's
  title, a typed prompt or a compaction summary, and `--replies` adds
  Claude's text; `isMeta` records, `<system-reminder>` text and
  `<local-command-` output are skipped; a typed slash command is spelled
  `/name args`; hits rank by where every term met, then newest first by
  last record stamp; `--json` carries raw UTC stamps; `CLAUDE_CONFIG_DIR`
  moves the store; exit 1 is no match or no transcripts, exit 2 is
  transcripts read with not one prompt in them, and argparse exits 2 on a
  bad flag too.
- `tests/scripts/find-session/test-find-session.sh` at `904b857`: 17
  cases over a fake store reached through `CLAUDE_CONFIG_DIR`, all 17
  passing from this brief's worktree before the move.
- The commits behind the work: `2a12f4a` (the `name-session` hook, and
  that `ListAgents`, `claude agents` and the `/resume` picker show a
  session's name), `e699dc8` (the probe sweep and its two marks),
  `904b857` (the script, and its `get_session_messages()` measurement),
  and `71ca469` (the queue brief this replaces).
- A live run from the main checkout before entering the worktree:
  `rename group sessions` listed `contributing-md` first, 12 of 208
  sessions matched, so the queue brief's re-measure held.
- The precedent for a script inside a skill: `commit`'s `stage-part.py`
  (`9981cd5`) and `land`'s `never-prompted.sh` (`19cf9ee`), both born in
  their skills, both run by deployed path
  (`~/.claude/skills/<skill>/scripts/`), both with a suite at
  `tests/scripts/<script>/` pointed at
  `$repo/skills/workflow/<skill>/scripts/`, and neither listed in
  `scripts/README.md`.
- `uv run --help`, uv 0.11.21: `--no-project` is "Avoid discovering the
  project or workspace". `commit`'s `references/index-staging.md` gives
  the consequence it guards: a repo's own Python project synced first.
- Git Bash argv, read back by `python3.13 -c 'import sys;
  print(sys.argv[1:])'`: `'/rename'` and `/test-skill` arrive as
  `C:/Program Files/Git/rename` and `C:/Program Files/Git/test-skill`,
  quoted or not, and `MSYS2_ARG_CONV_EXCL=/rename` keeps the first.
  PowerShell 7.6 passes `/rename` intact and expands `~/.claude/...` for
  a native program, to `C:\Users\<username>/.claude/...`.
- code.claude.com/docs/en/skills: the frontmatter table (`description`
  and `when_to_use` share the 1,536-character listing cap;
  `allowed-tools` approves for the invoking turn and "The grant clears
  when you send your next message"; `effort` levels), and the
  substitution table, where `${CLAUDE_SKILL_DIR}` is "The directory
  containing the skill's `SKILL.md` file", for "bash injection commands
  to reference scripts or files bundled with the skill".
- code.claude.com/docs/en/cli-reference, `--resume`: "When you pass a
  session ID, Claude Code searches the current project directory and its
  git worktrees, then every other project on this machine. Before
  v2.1.223, the ID search covered only the current project directory and
  its git worktrees." It takes a transcript's absolute path in place of
  an ID, and `--desktop --resume <id>` opens a session in Claude Desktop
  from v2.1.285.
- code.claude.com/docs/en/claude-directory § "Cleaned up
  automatically": a transcript, and its `subagents/` with it, is deleted
  "once they're older than `cleanupPeriodDays`"; "The default is 30 days
  and the minimum is 1"; managed settings override the user's value;
  Claude Desktop and Cowork transcripts are kept at any age unless
  `desktopSessionCleanupPeriodDays` is set. data-usage: transcripts sit
  "under `~/.claude/projects/` for 30 days by default".
- The store at 12:21 local: 210 transcripts, the oldest last written
  2026-09-29 09:27 and 73 of them that day; median 623 KB, 90th
  percentile 4.7 MB, largest 36.6 MB. `cleanupPeriodDays` is 15 in
  `claude/settings.json`, since `f55d942` (2026-09-04), and in
  `~/.claude/settings.json`.
- **The reach is 7 days, not 15**, read against
  `~/.claude/logs/instructions-loaded.log`, which logs session ids from
  2026-07-08: every session it saw last active from 2026-09-14 to
  2026-09-27 has no transcript, 228 of them from 2026-09-22 on, inside
  the 15 days. No managed settings file, no `Policies\ClaudeCode`
  registry key, no `remote-settings.json`, and no `cleanupPeriod` key in
  `~/.claude.json` or any VS Code `settings.json`. The probe sweep's one
  run, at 12:09 local, removed 88 sessions, each logged with a
  temp-folder working directory. machine-config's one transcript
  reference is a read-only keep-awake check.
- The Claude Code CHANGELOG. 2.1.287: "Added an `n:<text>` filter to the
  agents view that matches session names and tasks"; 2.1.288: the `n:`
  filter "(and Ctrl+F search)" opens the best name match on Enter.
  Nothing from 2.1.280 to 2.1.291 adds a search over past sessions.

Not drilled:

- **The cause of the 7-day reach.** Every source above was ruled out and
  none found it. So the skill states no reach of its own: the script
  reports the one on disk, and the setting is named only as the cap.
- **`${CLAUDE_SKILL_DIR}`**: documented, not adopted. Its form on
  Windows and through a junction was not measured, and `commit` and
  `land` already run their scripts by deployed path, which this follows.
- **Whether VS Code opens a session by its id**, carried from the queue
  brief. The CLI's `claude --resume <id>` does, from any folder since
  2.1.223.
- **Whether the `allowed-tools` rule matches a command spelled with
  `~`.** It only pre-approves, so a miss costs a prompt; the
  `/test-skill` probe shows which.
- **The Agent SDK's `get_session_messages()` and `list_sessions()`**,
  measured by `904b857` and carried, not re-measured: the first lacked 31
  of the 50 prompts typed in one long session, which is why the script
  reads the files itself.
- **The `/resume` picker's own search**, beyond its showing a session's
  name (`2a12f4a`).
- **Subagent transcripts** (`<project>/<session>/subagents/`) **and cloud
  sessions**, which the script does not read. Remote Control sessions run
  locally (data-usage), so theirs are on disk and searched.

## Frontmatter

```yaml
---
name: find-session  # repo linter requires it; max 64 chars; lowercase/digits/hyphens; no "anthropic"/"claude"
# model: inherit  # ALWAYS PRESENT, ALWAYS COMMENTED under skills/workflow/: an active model: key breaks Copilot slash dispatch and fails lint-frontmatter.py
effort: max  # ALWAYS PRESENT; the floor every behavioural skill here pins but commit
disable-model-invocation: false  # ALWAYS PRESENT; repo policy: false everywhere
argument-hint: "[words from the session]"  # optional; shown in the / menu
allowed-tools: Bash(uv run --no-project ~/.claude/skills/find-session/scripts/find-session.py *)  # optional; pre-approves the one read-only command for the invoking turn, as code-review and prune-branches pre-approve their reads
description: "…"  # required; the whole model-invoked trigger; gated at 1,024 — see Description char count
when_to_use: "…"  # optional; the recall phrasings; gated at 512, Claude Code only
---
```

The `allowed-tools` rule is the script's full command and nothing
wider: `Bash(uv run --no-project *)` would pre-approve any script in any
folder for that turn. No `paths:`, since a session is recalled in
conversation, not by opening a file. No `context: fork`: one command and
a report gain nothing from a subagent.

## Description char count

- `description`: 549 / 1,024
- `when_to_use`: 295 / 512

Counted against the shipped file by `yaml.safe_load` on 2026-10-06, the
same as the draft wording's `len()`. Every session on the machine lists
both, so neither is padded toward its cap: 844 of the 1,536, where
`recreate-repo` spends 1,459.

## Body structure outline

1. **What it finds, and why a name is not enough.** Claude Code titles a
   session once, from its first prompt, so the words are the index; the
   script reads every repo's transcripts.
2. **Search.** The command by its deployed path with `--no-project` and
   why; two or three of the user's own distinctive words, every one
   required; a leading `/` dropped, since Git Bash rewrites it into a Git
   install path and the miss reads as an honest exit 1, while the script
   spells a typed command so the bare word still finds it; PowerShell
   passes the slash and the `~` intact.
3. **Read the hits.** A sample of the three lines a hit prints and the
   summary line; where the terms met, and "some terms; the rest
   elsewhere" as the weak case; the first hit as the tightest, not the
   newest; the summary's oldest transcript as the reach.
4. **Narrow or widen.** `--repo`, `--days`, `--limit`, `--replies`,
   `--probes` and the two probe marks, `--json` and its UTC stamps.
5. **When nothing matches.** Exit 1: fewer or other terms, `--replies`,
   `--probes`; then the reach, past which a session is gone, said so
   rather than searched for by hand. The two exits 2 told apart by their
   stderr, and the format change reported, not worked around.
6. **Report.** The top hit or two with their passage and their
   `claude --resume <id>`, which works from any folder; VS Code by id
   unverified; never Read a transcript whole to answer from it.
7. **Constraints.** Reads only; `/rename` names the current session;
   `ListAgents` and `claude agents` find live ones by name; subagent and
   cloud transcripts are out of reach.

## Changes from source proposal

Derived from the queue brief `find-session-skill.md` (`71ca469`), which
this file replaces at the skill's own name, since `/test-skill` step 1
reads `docs/handoffs/execute/<skill-name>.md`. Departures and additions:

- **The reach is read off the disk, not stated.** The queue brief had
  "Reach is `cleanupPeriodDays`, 15 … A session older than that is gone:
  say so rather than search harder". The store held 7 days, cause not
  found, so a stated 15 would have the skill call a deleted session
  findable. The script's summary line now names the oldest transcript,
  three lines in the moved script and one case in its suite, and the
  skill points at that line and names the setting only as the cap.
- **The suite stays at `tests/scripts/find-session/`, re-pointed**, the
  user's choice on 2026-10-06, as `stage-part`'s and `never-prompted`'s
  are; the queue brief left it open.
- **`scripts/README.md`'s bullet goes**, also the user's choice: that
  list names files in `scripts/`, neither precedent is in it, and its
  rationale is in the script's docstring, which gains the suite's path
  as `never-prompted.sh`'s header names its own.
- **The docstring changes where it went stale**: its usage lines run
  `uv run --no-project` on the skill's path; "Newest first" becomes
  tightest first, which the code has done since `904b857`; the reach
  sentence follows the change above.
- **`allowed-tools` is set**, narrowly, for a read-only command, as
  `code-review` and `prune-branches` pre-approve theirs.
- **Added from today's drilling**: the two exits 2; `--json`'s stamps
  are UTC; `claude --resume <id>` from any folder (cli-reference); a
  transcript too large to Read whole (median 623 KB, largest 36.6 MB).
- **Dropped**: the queue brief's `\\`-to-`\` Bash trap, which
  `claude/CLAUDE.md` § "Shell traps" already carries into every session;
  a second home would be a second copy to drift.

## Tag

`personal`

## Portability caveats

N/A — personal scope. For the record: it runs the script by this
machine's junction path, `~/.claude/skills/find-session/`, which a
portable copy would replace with `${CLAUDE_SKILL_DIR}`; it reads
Claude Code's internal transcript format; the leading-slash trap is
Git Bash's; `effort` and `when_to_use` are Claude Code fields a portable
copy drops with no loss.

## Cross-reference dependencies

- `scripts/find-session.py` — (a) already converted; moved into the
  skill by this change.
- `tests/scripts/find-session/test-find-session.sh` — (a); re-pointed,
  and one case added for the summary's reach.
- `scripts/README.md` — (a); its `find-session.py` bullet is removed.
- `claude/hooks/name-session.sh` (`2a12f4a`) — (a). Names a session from
  its first prompt; the search is its complement, for what a name misses.
- `claude/hooks/prune-probe-sessions.py` (`e699dc8`) — (a). Its two probe
  marks are the script's `--probes` marks.
- `/rename`, `ListAgents`, `claude agents`, `claude --resume` — (c)
  Claude Code built-ins, named for disambiguation and the report.
- `commit` and `land` — (a). The script-in-a-skill precedent only; the
  body does not name them.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief; brief-specific observations belong in Notes below.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**The brief changed its name at the drafting; the worktree did not.**
The worktree was made as `find-session-skill`, the queue brief's stem;
this file takes the skill's name, which `/test-skill` step 1 reads. The
queue view pairs a worktree with a brief by the directory's name, so the
landing moves the worktree to `.claude/worktrees/find-session`, from the
main checkout once this session has left it.

**Edits outside `/author-skill`'s usual diff**, each authorized by the
queue brief, the user's answers on 2026-10-06 or the first departure
above: the moved script, its docstring and its summary line; the suite's
path and its one new case; the `scripts/README.md` bullet.

**The move takes the script out of `ruff-check`**, whose `files:` is
`^scripts/.*\.py$`, as `stage-part.py` already is. Both passed
`ruff check --config ruff.toml` by hand on 2026-10-06. Widening the hook
to skill scripts is its own change.

**The 7-day reach is a finding beyond this skill**: the setting says 15,
and nothing found says why the store holds 7.

**A behavioural probe needs a target that outlives the test.** At the
reach measured today, `contributing-md` (`053abce6`, last written
2026-09-29 23:18 local) may be gone tonight, not around 2026-10-15 as the
queue brief expected. Plant one, or choose one at test time from what
the summary line says is on disk. Set `CLAUDE_CONFIG_DIR` for the
script's call alone: this machine's login is
`~/.claude/.credentials.json`, inside the config folder, so a probe
session started under a fake one has none. Start a probe from a repo
with `-n "probe: find-session …"`, and the sweep deletes it two days
later.

**Trigger queries for `/test-skill`**, each in a fresh session in a repo
other than agent-config, against a `--safe-mode` baseline:

- "There was a session a few days ago where I was exploring how to
  rename and group my Claude Code sessions. Can you find it?" — must run
  the script by its deployed path, not grep `~/.claude/projects` by hand.
- "Find the conversation where we decided to keep cleanupPeriodDays at
  15." — must search content words, not the phrase "the conversation".
- "Which session did I run /test-skill on prune-branches in?" — must drop
  the leading slash from Git Bash, or run it from PowerShell.
- "Reopen the chat about the Fabric eventhouse from last month." — must
  report the reach from the summary line and say the session is gone,
  not search harder.
- Negative: "Rename this session to drift-audit." — `/rename`, not this.
- Negative: "What sessions are running right now?" — `ListAgents` or
  `claude agents`, not this.

**After the move**, from this worktree on 2026-10-06: the suite passed
18 of 18, the new case included; `ruff check --config ruff.toml` and
`shellcheck` passed; the script on the live store printed `12 of 212
sessions matched, first 2 shown; oldest transcript 2026-09-29; times are
local`, `/test-skill` from Git Bash matched 0 of 212 with exit 1 where
`test-skill` matched 30, and `--bogus` exited 2 with argparse's `usage:`.

**Post-draft overlap** (`skill-overlap.py overlap --skill find-session`,
2026-10-06): the highest pair is `author-skill + find-session` at 12.18,
on generic tokens (`long`, `naming`, `disk`, `back`, `repo`), 315th of
the 324 pairs scoring 12 or more in the bare listing, whose top is 66.59.
No neighbour competes for the trigger.

## Confidence

- **Structure**: H — one command and its report, on a script with a
  passing suite and two precedents for living inside a skill.
- **Field specs**: M — the `allowed-tools` match on a `~` path is
  unproven until the probe, and the description's wording decides
  whether a recall phrased without "session" fires it.
- **Body content**: M — every claim traces to the script, the docs or a
  measurement today; the reach is the soft spot, since its cause is
  unknown and the next sweep could move it again.
