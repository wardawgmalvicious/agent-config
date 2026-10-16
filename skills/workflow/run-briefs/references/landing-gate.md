# The gate and the landing

Commands and shapes for `SKILL.md` steps 5 and 6. `$S` is the
scratchpad, `<stem>` the brief's filename less `.md`, `<queue>` the
repo's brief directory. Everything dated was measured in this repo on
2026-10-12, CLI 2.1.293, unless it names a page.

## Reading the result

`--output-format json` prints one object, the Agent SDK's
`SDKResultMessage`. Pass `jq -b` in Git Bash on Windows, where `jq`
otherwise writes CRLF (jq 1.7 or later).

```bash
J="$S/<stem>.json"
jq -b -r '[.subtype, .is_error, (.permission_denials | length), .num_turns, .total_cost_usd, .session_id] | @tsv' "$J"
jq -b -r '.result' "$J"                                                          # the worker's reply, STATUS/COMMITS/OWED/NOTES at its end
jq -b -c '.permission_denials[] | {tool_name, command: .tool_input.command}' "$J" # empty when nothing was denied
jq -b -r '.errors[]?, (.startup_failure_reason // empty)' "$J"                    # error variant only; prints nothing on success
```

**The success variant** carries `type: result`, `subtype: success`,
`is_error`, `num_turns`, `duration_ms`, `result`, `session_id`,
`total_cost_usd`, `usage`, `modelUsage`, `permission_denials` and
`stop_reason`. A committing worker read: 6 turns, 33 s, est. $0.29,
`permission_denials: []`.

**A denial does not make an error.** The worker denied
`rm -rf "$PROBE_UNSET/probe-nonexistent-dir"` returned `subtype:
success`, `is_error: false`, exit 0, and:

```json
"permission_denials": [
  {
    "tool_name": "Bash",
    "tool_use_id": "toolu_01C4ke8Yp6ip248qVYLzGNJj",
    "tool_input": {
      "command": "rm -rf \"$PROBE_UNSET/probe-nonexistent-dir\"",
      "description": "Run the requested rm command"
    }
  }
]
```

The reason, `[Unverifiable Deletion Target]`, appears only in the
worker's prose. The SDK page calls `permission_denials` on the result
"the authoritative record"; the `permission_denied` stream events are
best-effort.

**The error variant** has `subtype` one of `error_max_turns`,
`error_during_execution`, `error_max_budget_usd`,
`error_max_structured_output_retries`, plus `errors: string[]` and,
when the start failed, `startup_failure_reason`. A `--resume` that
cannot re-enter its worktree returns `error_during_execution` with
`startup_failure_reason` `worktree_resume_refused` or
`worktree_unverified` and a stderr error (worktrees page).

**A failed run can also be silent**: `--resume` by a `-n` name exited 1
with 0 bytes on stdout and only the MCP-policy warning on stderr, three
times. So read the exit code and the byte count before `jq`.

**stderr** carries `Warning: claude.ai MCP server blocked by enterprise
policy: claude.ai Claude Docs` on this machine (a `deniedMcpServers`
entry), 82 bytes, on every run. It is not a failure.

## Reading the branch and the trees

```bash
B=worktree-<stem>; W=.claude/worktrees/<stem>
git cat-file -e "$B:<queue>/<stem>.md" 2>/dev/null && git show "$B:<queue>/<stem>.md" | grep -c '^status: deferred'   # nothing: the brief is gone; 1: deferred; 0: still open, stop
git -C "$W" status --porcelain            # must print nothing
git rev-list --count HEAD.."$B"           # at least 1
git status --porcelain                    # must match preflight
git log --oneline HEAD.."$B"              # the commits, pre-rebase SHAs
```

A worker that stopped leaves a worktree with uncommitted edits or no
commit; a worker that finished leaves a clean worktree whose tip lacks
the brief. A worker that deferred leaves the brief with
`status: deferred` and a `reopen-when`, and `lint-briefs` fails the
commit without one, so a deferral that passed `/commit` has it.

## The stop

```text
claude --resume <session_id>
```

Interactive, from the main checkout: the session returns to its
worktree (worktrees page; a `-p` resume by id did so on 2026-10-12,
`TOPLEVEL` the worktree, `BRANCH` its branch). Print with it the
worker's `result`, the denials and the errors. Leave the worktree and
branch; the queue view reads the worktree as `parked` until someone
resumes or removes it.

## The lock

A `-p` run leaves the lock it took "until a later session's stale-lock
sweep releases it" (worktrees page). Measured: three of five worktrees
were unlocked within two minutes of their runs' exit, two still read
`locked claude session <stem> (pid N)` with the pid gone at two minutes
and at 86 seconds.

```bash
git worktree list --porcelain | grep -E '^locked'   # locked claude session <stem> (pid N)
tasklist //FI "PID eq N" //NH                        # Git Bash; pwsh: Get-Process -Id N
git worktree unlock .claude/worktrees/<stem>          # only with the pid gone
```

`git worktree remove` on a locked worktree: `fatal: cannot remove a
locked working tree, lock reason: claude session <stem> (pid N)` /
`use 'remove -f -f' to override or unlock first`, exit 128. `unlock` on
an unlocked one: `fatal: '<path>' is not locked`, exit 128. A pid still
alive is a session at work there: stop.

## This repo's landing

From `.claude/rules/handoff-briefs.md`, which is the authority; this is the
order the coordinator runs it in.

```bash
set -o pipefail; claude agents --json \
  | jq -b -n --raw-output0 --arg me '<session-id>' 'def mine: .sessionId == $me or (.pid | tostring) == $me; (input? // []) | if any(.[]; mine) then .[] | select(mine | not) | .name else error("no row is this session") end' \
  | xargs -0 -r bash ~/.claude/skills/land/scripts/placed-elsewhere.sh; echo "exit=$?"   # anything but exit=0: stop
git -C .claude/worktrees/<stem> rebase main            # auto mode may refuse it as [Git Destructive]: the user's word lets it run
(cd .claude/worktrees/<stem> && pre-commit run --all-files)   # nothing hooks a rebase or a fast-forward
git merge --ff-only worktree-<stem>
git log --oneline <preflight-HEAD>..HEAD               # the landed commits, post-rebase SHAs
./scripts/link-claude.ps1 -SkillGroups workflow,social,meta   # pwsh; when claude/ or a deployed group changed; -Force for claude/CLAUDE.md or claude/settings.json
ls ~/.claude/skills | grep -E '^(fabric|pbir|pbid|pbip|powerbi|msix)-'   # after any deploy: must print nothing
git worktree remove .claude/worktrees/<stem> && git branch -d worktree-<stem>   # only with the brief gone from main
```

**The first line places every session but this one**, and anything but
`exit=0` stops the landing. `land`'s `placed-elsewhere.sh` places each
by git's top level for its `cwd`: a session in any directory of the main
checkout shares its HEAD, and one in a linked worktree has its own
(`land`'s `references/never-prompted-sessions.md` § "Where a listed
session sits"). It keeps in this tree a row it cannot place, a name two
sessions share among them, and exits 1, which `xargs` returns as 123.
`-0` hands it each name as one argument, since a hook's `brief: <slug>`
holds a space, and `-r` runs nothing when no other session is listed,
where the script, given no name, exits 2. No match on the `cwd` string
places a session: on 2026-10-16 (2.1.293) the suffix this line held,
`endswith("agent-config")`, missed an idle session started in
`skills\`, which this line placed in this tree.

**`<session-id>` is this session's own id**, the directory above
`scratchpad` in its scratchpad path. Both checked on 2026-10-12 matched:
an interactive session's row and a `-p` coordinator's. Never leave this
session's row out by name: a `claude --resume <id> -p` dropped its `-n`
name, and the resumed coordinator was listed as `agent-config-15`.
Whether a resumed row keeps its `sessionId` is unmeasured; both
coordinators that day found themselves by walking their process ancestry
instead (`Get-Process -Id $PID`, then `.Parent`, up to the `claude`
process), and that pid, passed as `<session-id>`, leaves out the same
row. A list without that row stops the landing, with jq's `no row is
this session` and exit 5, as an empty read, output that is not JSON,
`[]` and a wrong id each did on 2026-10-16; without the check, a list
that read as nothing would show no one, and pass.

`git worktree remove` refuses a dirty worktree, `fatal: '<path>'
contains modified or untracked files, use --force to delete it`, and
`git branch -d` refuses an unmerged branch, `error: the branch '<b>' is
not fully merged`; after a fast-forward neither applies. All of these
ran unprompted in an auto-mode session on 2026-10-12, on worktrees the
session's own workers had created.

**The subshell keeps this session in the main checkout.** The Bash
tool's working directory persists between calls, and on 2026-10-12
(2.1.296) a bare `cd .claude/worktrees/<stem> && pre-commit run
--all-files` left the coordinator there: the harness then named the
worktree the session's primary working directory, with the note "Do NOT
cd to the original repository root". From there, `git merge --ff-only
worktree-<stem>` merges the branch into itself: `Already up to date.`,
exit 0, `main` unmoved (a scratch repo, same day). No `EnterWorktree`
was behind the move, so no guard held: a `git -C` read of the main
checkout ran, and so did the `cd` back.

**The rebase and the classifier.** On 2026-10-06 (2.1.289) auto mode
refused `git rebase main` in a brief's worktree as `[Git Destructive]`
until the user said to run it. On 2026-10-12 (2.1.293)
`claude auto-mode defaults --label 'Git Destructive'` read that
"Reshaping the agent's own work — `--amend`, rebase, force-pushing a
personal branch containing only their commits — is the normal iteration
loop, not this rule", and a worker's `git rebase main` ran. Handle both:
a refusal goes to the user; an allowed rebase proceeds.

## Another repo's landing

Four other queues held briefs on 2026-10-12: one under `docs/handoffs/`
with no `execute/`, three under `docs/handoffs/execute/`. Their
instructions decide how a brief's worktree lands; `/land` pushes and
opens a pull request, and its step 1 defers to a repo whose instructions
land without a push. Where a repo says nothing, step 1 stops before the
first worker. Their `.claude/settings.json` must set
`worktree.baseRef` to `"head"`, or a brief landed without a push is
missing from the next worktree.

## Waiting, if the coordinator is not interactive

In an interactive session a background command has no time limit
(tools reference), and a `sleep 630` under `run_in_background` with a
600 s `timeout` completed on 2026-10-12. Under `-p`, a background
command gets 10 minutes by default and up to 2 hours by `timeout`
(7200000), raised further by `BASH_DEFAULT_TIMEOUT_MS` and
`BASH_MAX_TIMEOUT_MS`; a `-p` run also waits for its own background
commands at exit, ten minutes of idle by default
(`CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS`). `Monitor` watches at most 30
minutes per arming. A detached start, `Start-Process` in pwsh or
`nohup ... &` in Git Bash, outlived its tool call by 12 minutes on
2026-10-12; SIGTERM to a `-p` run "terminates the process tree of any
Bash command that is still running" (headless page), so a worker
launched from a `-p` coordinator's Bash dies with it, while a detached
one does not.
