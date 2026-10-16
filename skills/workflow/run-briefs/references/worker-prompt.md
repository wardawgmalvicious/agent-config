# The worker's prompt

The text below is the whole prompt a worker gets, with `<queue>` the
repo's brief directory (`docs/handoffs/execute` here) and `<stem>` the
brief's filename less `.md`. Write the filled text to the scratchpad and
pass it as the `-p` argument, as `SKILL.md` step 3 shows. It is well
under the 32,767-character Windows command line, and stdin is redirected
from `/dev/null` so the run never waits on it.

```text
Execute <queue>/<stem>.md, as the repository's instructions for its
handoff briefs say. A coordinator started you: nobody can answer a
permission prompt or a question, and the run ends when you stop.

You are in the main checkout. Re-measure the brief's evidence from
here first, changing nothing. Then call EnterWorktree with the name
<stem> and do every edit there; write nothing in the main checkout.

Commit with /commit. The commit that finishes the work deletes the
brief, or, if the brief must wait, sets status: deferred with a
reopen-when in its frontmatter. Do not rebase, merge, push, or remove
the worktree: the coordinator lands from the main checkout.

If an action you need is denied, or the brief needs a decision only
the user can make, stop at once without working around it.

End your reply with four labelled lines:
STATUS: finished or stopped, and why.
COMMITS: each commit's hash and subject, or none.
OWED: what landing still owes, such as a deploy, a check that needs
the deployed payload, or a /test-skill run and stamp; or nothing.
NOTES: anything the user should know, or none.
```

## Why each sentence is there

- **"as the repository's instructions ... say"**: a `-p` run without
  `--bare` loads what an interactive session loads, so the repo's
  `CLAUDE.md`, and here `.claude/rules/handoff-briefs.md` on the brief's
  first Read, govern the worker as they would a typed session.
- **"nobody can answer a permission prompt or a question"**:
  `--permission-prompts none` denies whatever would prompt and removes
  `AskUserQuestion`; the sentence stops the worker planning around an
  answer it cannot get.
- **"Re-measure ... from here first"**: a brief's evidence is measured
  from the main checkout before its worktree is entered, since the
  worktree guard refuses git into another repo
  (`docs/handoffs/execute/README.md` § "Every brief takes a worktree").
  A worker started in the main checkout entered its worktree by
  `EnterWorktree` name under `-p` on 2026-10-12, left nothing stray
  behind, and its worktree outlived the run.
- **"write nothing in the main checkout"**: the gate checks the main
  checkout's `git status --porcelain` against preflight, so a worker
  that edits before entering fails the gate rather than landing.
- **"Commit with /commit"**: the worker's transcript on 2026-10-12 held
  the Skill tool call `{"skill":"commit"}` and the commit message
  `chore(probe): add probe-run-briefs.txt`, so the skill runs on the
  model's own call, not only when `/commit` opens the prompt.
- **"deletes the brief, or ... deferred"**: landing deletes the brief in
  the commit that finishes its work, and a defer keeps it with a
  `reopen-when`; the gate reads the branch tip for one or the other.
- **"Do not rebase, merge, push, or remove the worktree"**: the
  coordinator lands from the main checkout; a worker that rebased would
  hand it a tree nothing checked, and a push publishes every unpushed
  serial commit beneath the branch.
- **"stop at once without working around it"**: the auto-mode
  `Auto-Mode Bypass` rule names tunnelling a denied action through
  another path as the bypass itself; the probe's worker, denied an
  `rm -rf` through an unset variable, stopped and quoted the denial.
- **The four labelled lines**: the gate reads `permission_denials` and
  the branch, not prose, but the landing needs `OWED:`, and the user
  needs `STATUS:` and `NOTES:` when a run stops.

## What a worker's reply looks like

From the probe's committing worker (session `8d669194`, 2026-10-12), the
`result` field read, after two sentences of summary:

```text
BRANCH: worktree-probe-run-briefs
TOPLEVEL: C:/Repos/Personal/agent-config/.claude/worktrees/probe-run-briefs
COMMIT: 6444adf
SKILL: yes
```

That prompt asked for those four lines; this one asks for `STATUS`,
`COMMITS`, `OWED` and `NOTES`. A worker that stops on a denial reads like
the probe's second: "The command was denied, so I stopped and did not
retry it ... Reason: [Unverifiable Deletion Target]." The denial's
reason reaches the coordinator only through this prose; the JSON's
`permission_denials` carries the tool name and input, not the reason.

## Options the user passes

- `--model <alias>`: the worker's model. The probe ran on `sonnet`,
  which the transcript recorded as `claude-sonnet-5-5`; a brief whose
  work is judgment runs better on the session's default, which is what
  an unpinned worker gets.
- `--max-budget-usd <n>`: stops the worker once its client-side estimate
  reaches the cap, subagents included; spend can pass it, and the page
  says nothing about what it measures on a subscription login
  (cli-reference, 2026-10-12).

## What the worker inherits

Everything a typed session here loads: the user-scope hooks
(`identity-guard`, the skill-invocation log, `name-session`, which
leaves a `-n` name alone), the project `.claude/settings.json` with
`worktree.baseRef: head`, and the MCP servers in `.mcp.json`. Its
transcript is written under the worktree's project directory,
`~/.claude/projects/<path-with-dashes>--claude-worktrees-<stem>/`, and
opens with `custom-title`, `agent-name` and `worktree-state` lines, which
is how `--resume <session_id>` finds the worktree again.
