---
name: find-session
# model: inherit  # any model: value blocks Copilot slash invocation
effort: max
disable-model-invocation: false
argument-hint: "[words from the session]"
allowed-tools: Bash(uv run --no-project ~/.claude/skills/find-session/scripts/find-session.py *)
description: "Finds a past Claude Code session by what was said in it — words from a prompt the user typed, a compaction summary or the session's name — across every repo on this machine, and gives the claude --resume command that reopens it. Runs the script bundled with the skill over the transcripts on disk, ranks one prompt holding every term above terms scattered through a long session, and reports how far back the transcripts reach, since an older session is gone. Naming the current session is /rename; running and background sessions are claude agents."
when_to_use: "Use when the user recalls an earlier session, conversation or chat by what was in it and wants it back — 'there was a session where I was exploring…', 'find the conversation where we decided X', 'which session did I do Y in', 'reopen the one about Z' — or needs a past session's id to resume it."
---

# Finding a past session

The user remembers a session by what happened in it — "there was a
session where I was exploring…" — and wants it back. Its name is a weak
index: Claude Code titles a session once, from its first prompt, so one
that wandered keeps the title of where it began (each of 233 titled
sessions held exactly one title, 2026-10-06). The bundled script reads
the words instead, in every transcript under `~/.claude/projects/`, from
every repo on this machine.

## 1. Search

```bash
uv run --no-project ~/.claude/skills/find-session/scripts/find-session.py <term> <term> ...
```

- **Every term must appear in the session**, as a substring, ignoring
  case: in its name, a prompt the user typed, or a compaction summary.
  Take two or three of the user's own distinctive words, not a
  paraphrase; a common word matches most of the store. Words given after
  `/find-session` are the terms.
- **Keep `--no-project`.** Without it, `uv run` in a repo that has its
  own Python project syncs that project first. The script needs no
  dependencies.
- **Drop a leading `/`.** Git Bash rewrites `/test-skill` into
  `C:/Program Files/Git/test-skill` before the script sees it, quoted or
  not, and the search answers `0 of … sessions matched`, exit 1, which
  reads as an honest miss (2026-10-06). The script records a typed
  command as `/test-skill prune-branches`, so `test-skill` finds it.
  PowerShell passes the slash intact, and expands the `~` path as well.

## 2. Read the hits

```text
2026-09-29 23:18  agent-config  contributing-md
    prompt: …ood point. I always wanted to rename and group my Claude Code sessions to keep better track of them. Is there …
    claude --resume 053abce6-857e-4d2b-b5d8-77150b3e4e75
12 of 212 sessions matched, first 2 shown; oldest transcript 2026-09-29; times are local
```

- **The first line** is the last activity in local time, the repo (the
  folder the session ran in, a worktree counted as its repo) and the
  session's name: one set by `/rename`, `-n` or a hook, else Claude
  Code's title, else the start of the first prompt.
- **The second says where every term met**: `name`, `prompt`, `summary`
  or `reply`. `some terms; the rest elsewhere` means no one passage holds
  them all and the session matched only as a whole, which a long
  compaction summary makes common: a weak hit.
- **The first hit is the tightest, not the newest.** Hits rank by where
  every term met, a name, then one prompt, one summary, one reply, then
  scattered, and newest first within each.
- **The last line gives the reach**: the oldest transcript on disk. A
  session last active before that date can no longer be found.

## 3. Narrow or widen

- `--repo <folder>` keeps one repo, by its folder name; its worktrees
  count as it.
- `--days <n>` keeps transcripts written in the last n days.
- `--limit <n>` shows n hits, 10 by default; the last line counts them
  all.
- `--replies` searches Claude's text too, for what Claude said rather
  than what the user typed.
- `--probes` brings back probe sessions, left out by default: a working
  directory in the temp folder, or a name starting `probe:`.
- `--json` prints the hits for parsing: `session_id`, `title`, `repo`,
  `cwd`, `branch`, `first_active`, `last_active`, `match` and `resume`.
  Its stamps are UTC, where the text's times are local, and it prints no
  reach.

## 4. When nothing matches

Exit 1 with `0 of … sessions matched` is a miss. Before calling the
session lost:

- Retry with fewer terms, or the user's other words for the subject; a
  word only Claude used needs `--replies`.
- Add `--probes` if it may have been a test run.
- **Then read the reach.** A session last active before the summary's
  oldest transcript is gone. Claude Code deletes transcripts older than
  `cleanupPeriodDays`, 30 days by default, and the store can hold less
  than the setting says: 7 days against 15 on 2026-10-06, cause not
  found. Say it is gone; do not search the transcripts by hand.

Exit 2 has two meanings, told apart by stderr. `the transcript format
may have changed` means the script read transcripts and found not one
prompt in them, which is how a release changing Claude Code's internal
transcript format shows. Report that, and do not grep the transcripts as
a stand-in.
A `usage:` line means a bad flag. `no transcripts under <path>`, exit 1,
means the store is empty.

## 5. Report

- **The top hit or two**: name, repo, last activity, the passage that
  matched, and its `claude --resume <id>`. Say so when the best hit is
  only scattered.
- **`claude --resume <id>` works from any folder**: Claude Code looks in
  the current project and its worktrees, then every other project on
  this machine (2.1.223 or later). Whether VS Code opens a session by its
  id was not checked (2026-10-06).
- **Never Read a transcript whole** to answer from it. It holds every
  tool result: on 2026-10-06 the median was 623 KB and the largest
  36.6 MB. To learn what a session concluded, search again with
  `--replies` and words from the answer, or resume it.

## Constraints

- **Reads only.** This skill renames, resumes and deletes no session.
- **Not this skill**: naming the current session is `/rename`. Live
  sessions are `ListAgents` from inside a session, and background ones
  `claude agents` from a terminal, whose `n:<text>` filter (2.1.287) and
  Ctrl+F match names and tasks, not what was said.
- **Out of reach**: subagent transcripts, under
  `<project>/<session>/subagents/`, which the script does not read, and
  any session whose transcript is not under `~/.claude/projects/` on this
  machine, such as a cloud session's.
