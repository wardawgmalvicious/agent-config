---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-06
---

# Handoff: past sessions need a `find-session` skill

- **Written**: 2026-10-06, by the session that built session naming:
  `2a12f4a` (the `name-session` hook), `e699dc8` (the probe sweep) and
  `904b857` (`scripts/find-session.py`), all deployed that day. The user
  chose the same day to make the search reachable from any repo, as a
  skill, and asked for this brief because that session had run long.
- **Kind**: an edit, by `/author-skill`: `skills/workflow/find-session/`,
  no `paths:` glob. Nothing is drafted; the script it wraps exists and
  passes its suite.

## Why a skill

The script searches every repo's sessions, but only a session in this
repo learns that it exists: root `CLAUDE.md` is at its 200-line cap, so §
Commands does not list it, and `claude/CLAUDE.md` takes no repo paths, by
the user's standing preference. The ask comes in words, "there was a
session in which I was exploring…", which is what a description catches;
answered by hand on 2026-10-06 it took a dozen tool calls and two shell
traps. Of 195 sessions with a first prompt that day, 134 ran in this repo
or its worktrees and 32 in a client repo, the next largest. Both hooks
from the same work deploy to `~/.claude` and act in every repo, so the
search is the one piece only this repo knows about.

## Decided, to confirm at `/author-skill` step 3

- **Name** `find-session`, the verb invoked. **Group** `workflow`: it acts
  on the user's sessions in any repo, not on this repo, and it is not
  payload upkeep, so not `meta`. Copilot is moot: that payload is being
  retired and `copy-copilot.ps1` is no longer run (`editing-skills.md`).
- **The script moves into the skill**, by `git mv scripts/find-session.py
  skills/workflow/find-session/scripts/find-session.py`, so the skill's
  junction makes it live everywhere and no repo path is baked into the
  skill. Then re-point `tests/scripts/find-session/test-find-session.sh`,
  which runs `$repo/scripts/find-session.py`, and `scripts/README.md`'s
  entry, or move the suite beside the skill's tests: that choice is open.
- **One thin skill**: when to run it, how, how to narrow, how to report.
  `effort: max`, `disable-model-invocation: false` and `# model: inherit`
  commented, per `editing-skills.md`. Keep `description` and
  `when_to_use` short: every session on the machine pays for them.

## What the skill must carry

- **Run it as `uv run --no-project <skill dir>/scripts/find-session.py
  <terms>`.** Without `--no-project`, uv in a repo that has its own Python
  project syncs that project first (the `commit` skill's
  `references/index-staging.md`). It needs nothing else.
- **A term starting with `/` is rewritten from Git Bash** into a Git
  install path before the native interpreter sees it, silently: search
  `rename`, not `/rename`, or run it from PowerShell. Seen twice on
  2026-10-06: `claude -p "/rename"` reached the model as a path, and a
  test's `jq --arg p '/test-skill x'` arrived as
  `C:/Program Files/Git/test-skill x`. And `\\` typed into the Bash tool
  reaches the command as `\` (`claude/CLAUDE.md` § "Shell traps").
- **What a hit means.** Every term must appear in the session: its name,
  a typed prompt, or a compaction summary; `--replies` adds Claude's text.
  Hits rank by tier, every term in a name, then in one prompt, one
  summary, one reply, then only scattered, printed as "some terms; the
  rest elsewhere", and newest first within a tier. `--repo`, `--days`,
  `--limit`, and `--json` for a session to parse; exit 1 is no match, exit
  2 a transcript format it can no longer read.
- **Reach is `cleanupPeriodDays`, 15**, which the user kept on 2026-10-06;
  that day the oldest transcript on disk was last written 2026-09-29. A
  session older than that is gone: say so rather than search harder.
- **Probes are left out unless `--probes`**, by the marks the sweep uses:
  a cwd in the temp folder, or a name starting `probe:`.
- **Not this skill**: naming the current session is `/rename`; live
  sessions are `ListAgents` and `claude agents`, whose `n:<text>` filter
  (2.1.287) and Ctrl+F (2.1.288) search running and background sessions,
  not history.

## Evidence (measured 2026-10-06, Claude Code 2.1.289)

- The Agent SDK's `get_session_messages()` returns only the chain since
  the last compaction: it lacked 31 of the 50 prompts typed in one long
  session, and 5 of 9 in another. So the script reads
  `~/.claude/projects/*/*.jsonl` itself, as `skill-telemetry.py` does.
  `list_sessions()` took about 10 s over 293 sessions, the script's whole
  scan about 2 s over 294.
- The first version ranked newest first and left the session it was
  written to find outside the first ten, behind compaction summaries that
  held every term far apart. One prompt holding every term now ranks
  first.
- Claude Code's generated title is written once, from the first prompt:
  all 233 titled sessions held exactly one. That is why names alone are a
  weak index, and why the search reads prompts.

## Testing

- No `paths:` glob, so `/test-skill` runs its behavioural phase only.
- The script's negative cases are
  `tests/scripts/find-session/test-find-session.sh`, 17 passing at
  `904b857`, over a fake store reached through `CLAUDE_CONFIG_DIR`.
- **A behavioural probe needs a target that outlives the test.** The
  2026-09-30 session behind all this (`053abce6`, named `contributing-md`)
  expires around 2026-10-15. Plant one, or choose one at test time.
- **Set `CLAUDE_CONFIG_DIR` for the script's call alone.** This machine's
  login is `~/.claude/.credentials.json`, inside the config folder, so a
  probe session started under a fake one has none.
- Start a probe from a repo with `-n "probe: find-session ..."`, and the
  sweep deletes it two days later.

## Where it lands

`skills/workflow/find-session/SKILL.md` and the moved
`scripts/find-session.py`, a `skills/README.md` row, the suite and
`scripts/README.md` re-pointed, then
`link-claude.ps1 -SkillGroups workflow,social,meta`, which already deploys
the group.

## Not checked

- Whether VS Code can open a session from the id the script prints; the
  CLI's `claude --resume <id>` does.
- Subagent transcripts (`<project>/<id>/subagents/`) and cloud or remote
  sessions, which the script does not search.

## Re-measure before acting

- `ls skills/workflow .claude/skills` and the session's skill listing,
  for a `find-session` or a plugin skill on the same trigger
  (`/author-skill` step 3).
- `git log --oneline -1 -- scripts/find-session.py`: still `904b857`.
- `uv run scripts/find-session.py rename group sessions` still lists
  `contributing-md` first, until it expires.
