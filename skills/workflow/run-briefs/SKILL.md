---
name: run-briefs
# model: inherit  # any model: value blocks Copilot slash invocation
effort: max
disable-model-invocation: true  # typed only: a run spends usage and lands branches, so its description documents and never fires
argument-hint: "[brief-stem]"
allowed-tools: Bash(git worktree list *) Bash(git status *) Bash(git log *) Bash(git rev-parse *) Bash(git rev-list *) Bash(git cat-file *) Bash(git show *) Bash(git merge-base *) Bash(claude agents *) Read Grep Glob
description: "Runs one handoff brief and whatever blocks it, each in a fresh headless session, from the main checkout of a repo whose briefs carry frontmatter: resolves the order from each brief's blocked-by, launches one claude -p worker at a time in a worktree named after its brief, gates every run on its JSON result (no permission denial, the brief deleted or deferred at the branch tip, a clean worktree), lands the branch as the repo's own instructions say, and goes on to the next. Stops at the first failure with the claude --resume command that finishes that worker by hand. Never pushes, never runs two briefs at once, never decides a brief's needs. Typed only, as /run-briefs <brief-stem>: a run spends usage and lands branches, so its description never fires it."
---

# Run briefs

Take a **brief stem**, the filename less `.md`, and run that brief and
whatever blocks it, one brief at a time, each in a fresh headless
session. This session is the coordinator: it launches the workers,
waits, gates, lands and goes on. The user stands by for the prompts the
landing raises, which is where their attention goes instead of a session
per brief.

**The coordinator keeps no state.** Every round re-reads the briefs'
frontmatter, `git worktree list` and the branches, so a compaction or a
restart resumes from the last landing, and nothing it writes outlives a
run but the commits the workers made.

Measured 2026-10-12 on CLI 2.1.293 in this repo, with the figures in
[references/landing-gate.md](references/landing-gate.md); the worker's
prompt and why each sentence is there is
[references/worker-prompt.md](references/worker-prompt.md).

## 1. Preflight, from the main checkout

```bash
git rev-parse --path-format=absolute --git-dir --git-common-dir   # two equal paths: the main checkout; a worktree cannot land
git rev-parse HEAD                                                 # kept: every branch tip is compared to it
claude --version                                                   # the CLI the workers run; this session may run another binary
for d in docs/handoffs/execute docs/handoffs; do [ -d "$d" ] && { echo "$d"; break; }; done   # the queue directory: execute/ where it exists, else docs/handoffs/; never ls -d, which sorts its operands
grep -n -A1 '"worktree"' .claude/settings.json                     # must read "baseRef": "head"
```

**Stop before launching anything if one of these fails.** A worktree
cannot be the coordinator: workers hang their worktrees off the main
checkout and the landing fast-forwards it. Under the default
`worktree.baseRef`, `fresh`, every worktree branches from the remote's
default branch, so a brief landed here without a push is missing from
the next brief's worktree with nothing said. And the landing is the
repo's own: read its instructions for a brief's worktree before the
first worker runs. In this repo that is `docs/handoffs/CLAUDE.md`, which
lands by fast-forward with no push. A repo whose instructions say
nothing about landing a brief's worktree gets no worker: say what is
missing and stop, since a worker's branch would wait for a landing nobody
has written down.

## 2. Resolve the order

Read the target brief's frontmatter, then each brief its `blocked-by`
names, recursively. Blockers run before what they block; within one
level, the oldest `written` first. The chain ends at the target.

**Stop before any brief in the chain that a session cannot run alone**:

- `status: deferred`, or a `needs` other than `[]`. A `needs: [user]` is
  a question for the user, not a call to make for them.
- A worktree at `.claude/worktrees/<stem>`, whatever its state: another
  session claimed it, or left it parked or merged. Print what
  `git worktree list --porcelain` shows for it, and the queue view's
  reading where the repo has one (`uv run scripts/handoff-status.py`
  here).
- A brief untracked or modified in the main checkout:
  `git status --porcelain -- <queue>/<stem>.md` prints a line. The
  worktree branches from `HEAD` without that change, and for an
  untracked brief the gate's "brief gone" passes with nothing done
  (2026-10-12).

Print the chain before the first launch, with what stops it where it
does. The user typed the command; nothing is asked.

## 3. Launch the worker

Fill [references/worker-prompt.md](references/worker-prompt.md) for the
brief and write it to the scratchpad. Then, in the main checkout, in the
background:

```bash
claude -p "$(cat "$S/<stem>.prompt")" -n "brief: <stem>" --permission-mode auto --permission-prompts none --output-format json < /dev/null > "$S/<stem>.json" 2> "$S/<stem>.err"; echo "exit=$?"
```

Add `--model <alias>` to pin the worker's model and `--max-budget-usd <n>`
to cap its estimated spend; both are the user's to pass. Pass nothing
else: `--bare` drops the instruction files, hooks and skills the worker
needs, and `bypassPermissions` is what auto mode exists to avoid.

**The worker starts in the main checkout and enters its worktree by
name.** The prompt has it re-measure the brief's evidence first, writing
nothing, then call `EnterWorktree` with the stem. Both routes work under
`-p`; this one lets a brief measure another repo, which the worktree
guard refuses from inside. The worktree, its branch `worktree-<stem>`
and the lock named after the session appear when it enters, and the
worktree claims the brief in the queue view from then on.

**The worker is visible while it runs**: `claude agents --json` lists it
as kind `interactive` with its pid, its `-n` name and its cwd, the
worktree once entered, and `ListAgents` names it. `-n` outranks the
`name-session` hook, so the name is the one passed. Its stderr carries a
warning about a blocked claude.ai MCP server; that is not an error.

## 4. Wait

Launch with `run_in_background`. The Bash tool re-invokes this session
when the worker exits, with the exit code, so nothing polls. In an
interactive session a background command has no time limit; a 630 s one
ran out under a 600 s `timeout` (2026-10-12). A coordinator that is
itself a `-p` run has ten minutes per background command by default:
pass `timeout` up to 7200000 there.

While a worker runs, touch nothing in the main checkout and launch no
second worker: two folds that edit the same hand-kept list meet at the
rebase, which is why one brief runs at a time.

## 5. Gate

Read the JSON and the branch, with the commands in
[references/landing-gate.md](references/landing-gate.md). Land only when
all of these hold:

- the command exited 0, `subtype` is `success` and `is_error` is false;
- `permission_denials` is empty. **A denied run still reads
  `subtype: success`**, so this array, not `is_error`, is the signal;
- the brief is gone at `worktree-<stem>`, or its frontmatter there reads
  `status: deferred` with a `reopen-when`;
- `git -C .claude/worktrees/<stem> status --porcelain` is empty and the
  branch holds at least one commit past HEAD;
- the main checkout's `git status --porcelain` is what preflight saw: the
  worker wrote nothing here.

**Anything else stops the run.** Print the worker's `result`, each
denial's `tool_name` and command, any `errors` or
`startup_failure_reason`, and:

```text
claude --resume <session_id>
```

The id is the result's `session_id`. Resume by id, never by the `-n`
name: `-p` sessions are kept out of the picker that name resolution
uses, and a name resume exits 1 with nothing on stdout. An interactive
resume returns to the worktree, where the user finishes the worker's
turn. Leave the worktree and branch where they are.

## 6. Land

As the repo's instructions say. This repo's, from `docs/handoffs/CLAUDE.md`,
with what the coordinator adds in front:

1. **Another session live in the main checkout stops the landing.**
   `claude agents --json` rows carry a `cwd`; one at the main checkout
   that is not this session means the fast-forward would move the tree
   under it, as a `git switch` would. `ListAgents` names the session but
   not where it sits. Say who, and wait for the user's word.
2. **The lock.** `git worktree list --porcelain` may still read
   `locked claude session <stem> (pid N)`: a `-p` run leaves its lock
   for a later session's sweep. With the pid gone, `git worktree unlock`
   it; with the pid alive, stop, since a session holds it.
3. **Rebase and check**: `git -C .claude/worktrees/<stem> rebase main`,
   then `(cd .claude/worktrees/<stem> && pre-commit run --all-files)`,
   because no hook runs on a rebase or a fast-forward. **Keep the
   subshell**: a bare `cd` persists, and step 4 run from the worktree
   prints `Already up to date.`, exits 0 and leaves `main` unmoved
   ([references/landing-gate.md](references/landing-gate.md)). Auto
   mode may refuse the rebase as `[Git Destructive]`; it did on
   2026-10-06 and did not on 2026-10-12, whose rule text exempts a
   rebase of the agent's own branch. A refusal goes to the user, whose
   word in the conversation lets it run.
4. **Fast-forward**: `git merge --ff-only worktree-<stem>`. Cite the
   branch's SHAs only after the rebase, checked with
   `git merge-base --is-ancestor <sha> main`.
5. **Deploy** when the landed paths include `claude/` or a deployed skill
   group: `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`,
   with `-Force` when `claude/CLAUDE.md` or `claude/settings.json`
   changed, then `ls ~/.claude/skills | grep -E '^(fabric|pbir|pbid|pbip|powerbi|msix)-'`
   must print nothing.
6. **What the worker said landing owes**, from its `OWED:` line. Run the
   mechanical ones: a deploy, a check on the deployed payload, a stamp
   whose test the worker reports passed. Print the ones that need a
   fresh session, a `/test-skill` run above all, for the user.
7. **Remove or keep.** With the brief gone from `main`, remove the
   worktree and delete the branch. With the brief still there, a skill
   brief waiting for `/test-skill` step 10, leave both: the view reads
   `merged`, and the worktree holds the claim until the check passes.

## 7. Go on, and report

Re-read the queue and take the next brief in the chain; its worktree
branches from the new HEAD under `baseRef: head`. Stop at the target, or
at the first run the gate refused.

Report per brief: landed or stopped, and why; the session id and its
resume command; the commits, by their post-rebase SHAs; the run's
`total_cost_usd`, an estimate; what landing still owes. Then the totals.

## 8. Constraints

- **One brief at a time, and stop at the first failure.** Each brief
  costs what it does by hand; an unattended loop can spend a usage window
  in one sitting, which is why a run is bounded by its target.
- **Never work around a denial.** The classifier's own rule says the
  response is another safe alternative or the user; a worker that
  tunnels the same action is the bypass that rule names. Stop and hand
  over the resume command.
- **The user keeps** every decision a `needs` names, a client repo's
  relink, and every push: a brief lands with none.
- **Never `git switch`, `checkout`, `stash` or `reset` in the main
  checkout**, and never remove a worktree that holds work `main` does not.
- **This skill's `model:` lasts one turn**, so after its first turn the
  coordinator runs on the session's model; a worker's model is its
  `--model` flag.
- **Not in scope**: running briefs in parallel; deciding briefs that
  need the user, a tenant or Desktop; audit follow-ups under
  `docs/audits/`, which `/drift-update` walks; inbox notes, which
  `/triage` takes.
