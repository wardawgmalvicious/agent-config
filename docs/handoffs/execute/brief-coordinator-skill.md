---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-12
---

# Handoff: a coordinator that runs briefs, each in a fresh session

- **Written**: 2026-10-12, by a session in this repo, measured at
  `c2a01f7` on Claude Code 2.1.293. The user runs briefs by hand, one
  new session per brief in an order a session recommends, and asked for
  a coordinator that takes a brief and runs it and whatever blocks it,
  each in a fresh session. They will stand by for permission prompts.
- **Kind**: one new behavioural skill, by `/author-skill` after a probe.
  Its step 5 replaces this queue brief with its own, carrying what is
  below.
- **Run in**: this repo. Step 1 runs from the main checkout, since it
  probes what a coordinator there sees; the rest in a worktree named
  after this brief.

## Decided

- **Build it** (the user, 2026-10-12), on the design below, which step 1
  confirms or corrects.
- **Other repos too, once it proves out here** (the user, 2026-10-12):
  "not just for this repo, but others as well if this format does work".
  So the loop names nothing of this repo's, and where the skill lives is
  put to the user at `/author-skill` step 3; see § "Other repos".

## The design

A session in the main checkout runs the skill as the coordinator, typed
as `/run-briefs <brief>` or whatever name step 2 settles; one headless
session per brief does the work.

1. **Resolve the order.** Walk the target's `blocked-by` back to briefs
   with no open blocker, and run blockers first. Stop before any brief
   in the chain that is deferred, carries a `needs` other than `[]`, or
   is in flight in another session, a worktree by its name.
2. **Re-measure first.** A brief's evidence is measured from the main
   checkout before its worktree is entered, since the guard refuses git
   in another repo ([README](README.md#every-brief-takes-a-worktree)).
   `claude -p --worktree` enters at start, so either the worker starts
   in the main checkout and calls `EnterWorktree` by name once it has
   measured, or the coordinator measures and passes the readings in the
   prompt. Step 1 settles which.
3. **Launch a worker** with the prompt below. It loads what an
   interactive session loads, its worktree claims the brief in the queue
   view, and the worktree outlives the run:

   ```bash
   claude -p "<prompt>" --worktree <stem> -n "brief: <stem>" \
     --permission-mode auto --permission-prompts none --output-format json
   ```

4. **Gate the landing.** Land only when the run ended without error, its
   result lists no `permission_denials`, the brief is gone at the branch
   tip or its frontmatter now defers it, and the worktree is clean.
   Anything else stops the run and prints `claude --resume <session_id>`
   for the user to finish that worker by hand.
5. **Land** as [../CLAUDE.md](../CLAUDE.md) says, opening with
   `git worktree unlock`, since a `-p` run leaves its lock in place. Auto
   mode denies the rebase as `[Git Destructive]` until the user says to
   run it ([README](README.md#a-briefs-worktree-lands-without-a-push)):
   that prompt, and any deploy, is where the user's standby goes. Then
   run the post-landing checks and `/test-skill` stamps the worker's
   report names, on `main`.
6. **Re-read the queue and go on.** The next worktree branches from the
   new `HEAD`, since `.claude/settings.json` sets `worktree.baseRef` to
   `"head"`.

The coordinator keeps no state of its own. Each round re-reads the
queue, the branches and the worktrees, so a compaction or a restart
resumes from the last landing.

### The worker's prompt, a first draft

```text
Execute docs/handoffs/execute/<stem>.md, as docs/handoffs/CLAUDE.md
says. A coordinator started you, and nobody can answer a permission
prompt or a question. Commit with /commit; the commit that finishes the
work deletes the brief. Do not rebase, merge, push or remove the
worktree: the coordinator lands from the main checkout. If an action you
need is denied, or the brief needs the user's decision, stop without
working around it. End with: finished or stopped, and why; your commits;
and what landing owes, such as a deploy, a check on the deployed payload
or a /test-skill stamp.
```

### Limits for the first version

- **One brief at a time.** The queue lets briefs in one priority run in
  parallel ([README](README.md#no-file-lists-the-queue)), but folds edit
  the same hand-kept lists: `abb9a74`, the `fabric-deploy` fold, changed
  `.claude/settings.json`, `skills/README.md` and
  `scripts/skill-overlap.py`, and two such branches meet at rebase.
  Parallel runs wait for briefs that name the paths they touch.
- **Stop at the first failure**, and bound each run by a target brief or
  a count. Each brief costs what it does by hand, but an unattended run
  can spend a plan's usage window in one sitting. The headless page
  names a `--max-budget-usd` flag; what it caps on a subscription login
  was not read.
- **The user keeps** every decision a brief's `needs` names, client-repo
  relinks, and pushes: a brief here lands with none.
- **Check for a session live in the main checkout before each landing**,
  by `ListAgents`: the fast-forward moves the tree under it as a
  `git switch` would, root `CLAUDE.md` § "Branching and concurrent
  sessions".
- **`model:` lasts one turn**, and only when slash-invoked
  ([editing-skills.md](../../../.claude/rules/editing-skills.md)), so
  the coordinator runs on the session's model after its first turn. A
  worker's model is its `--model` flag.

## Why headless workers

- **Agent teams** were ruled out here twice, in
  [the root ledger](../../evidence/root-claude-md.md) on 2026-09-22 and
  in [README](README.md#no-file-lists-the-queue) on 2026-09-27. A docs
  subagent's reading on 2026-10-12 moves neither: still experimental,
  teammates not isolated in worktrees, and no team under `-p`.
- **`claude --bg`**, agent view, a research preview, is the one route
  where the user answers a worker's prompt live, by attaching to it. But
  it moves into a worktree whose name the page does not give, so the
  view claims nothing, and having isolated itself it "commits without
  asking, and pushes the branch when the repository has a remote", held
  back only by a git instruction in the task, `CLAUDE.md` or memory.
  Started inside a worktree that already exists, it stays put and
  "still asks before committing". Worth a probe if headless workers
  stall too often.
- **Subagents with `isolation: worktree`**: their prompts reach the main
  session, but the Agent tool takes no worktree name, a worktree
  subagent takes its instruction files from the main conversation
  rather than its worktree, and it is no session to resume or find
  later.

## Evidence

Read firsthand on 2026-10-12, against 2.1.293:

- **code.claude.com/docs/en/worktrees**: `claude -p --worktree`
  "proceeds without" the trust check; a worktree is
  `.claude/worktrees/<name>/` on branch `worktree-<name>`;
  "Non-interactive runs with `-p` have no exit prompt, so Claude doesn't
  clean up their worktrees, and Claude Code leaves the lock it took on
  each one at creation in place"; `--resume`, interactive or under `-p`,
  returns a session to its worktree; the isolation checks apply "whether
  the session is interactive or runs in the background".
- **code.claude.com/docs/en/headless**: without `--bare`, `claude -p`
  "loads the same context an interactive session would"; with no
  permission host, prompts "are denied either way";
  `--permission-prompts none` (2.1.259) tells Claude "not to retry it",
  removes `AskUserQuestion` and lets the run continue; under
  `--output-format stream-json` "the final result message lists them in
  `permission_denials`"; `/skill-name` in the prompt expands; `--resume`
  finds a session "in any project on this machine"; `-p` rejects
  `--bg`; a background command the run started holds it open "until the
  command exits or reaches its time limit".
- **code.claude.com/docs/en/agent-view**, the first 100,000 of its
  137,050 characters: the quotes above, "Agent view is in research
  preview", and `worktree.bgIsolation: "none"`.

Reported by a docs subagent and not re-read: agent teams' switch,
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`, their prompts appearing in the
lead session, and `/resume` not restoring in-process teammates; that a
background subagent's prompts surface in the main session;
`claude agents --json` and `claude attach`; a scripted `--bg` start in
an untrusted folder failing `Workspace not trusted` (2.1.281); and
cross-session messaging on native Windows from 2.1.234, with
`notify_when_idle` from 2.1.236.

Not read: the tools reference on a background command's time limit, and
the Agent SDK's result types.

## Step 1: probe from the main checkout

A throwaway task, named `probe: run-briefs` so `find-session` hides it
by default, on `--model sonnet` to keep it cheap:

1. **A worker's life.** Run the step 3 command on a task that writes one
   file and commits it with `/commit`. After the run, do the worktree,
   its branch and its lock stand (`git worktree list --porcelain`)? Did
   `-n` name the session (`find-session --probes`)? Did `/commit` run
   under `-p` on the model's own call?
2. **A denial.** Ask for something auto mode refuses, such as
   `git rebase main`, refused as `[Git Destructive]` on 2026-10-06. Is
   the denial in `--output-format json`'s result, or only under
   `stream-json`? Did the worker stop as told, or work around it?
3. **The wait.** Can a coordinator wait out a worker that runs past 15
   minutes: by a Bash `run_in_background` that re-invokes it on exit, a
   Monitor, or a detached start polled for its output file? Does a
   worker survive its coordinator being killed mid-wait?
4. **The re-measure order.** Under `-p`, can a worker started in the
   main checkout call `EnterWorktree` by name, and does that worktree
   outlive the run as a `--worktree` one does?
5. **Resume and clean up.** `claude --resume <session_id>` from the
   main checkout re-enters the worktree; then `git worktree unlock`,
   `git worktree remove` and `git branch -D` on the probe's branch.

Carry what each shows into `/author-skill`'s brief, under Sources
drilled.

## Step 2: author it

Run `/author-skill` with this brief as its topic. Its step 1 hold covers
Fabric and Power BI skills only. Put to the user at its step 3:

- **The name.** `run-briefs`, the verb typed, is the proposal.
- **The tree.** Step 3 sends a skill acting on this repo's handoff queue
  to `.claude/skills/`, and one acting on any repo to `skills/workflow/`.
  Either project scope while it proves out here, then a move, or
  `skills/workflow/` from the start, written to be portable.
- **Invocation.** It spends usage and lands branches, so it should run
  only when typed. `disable-model-invocation` is `false` everywhere here
  ([editing-skills.md](../../../.claude/rules/editing-skills.md)):
  weigh `true` against a description narrow enough not to fire unasked.

The gate and the worker prompt go to its `references/`.

## Step 3: test it

The coordinator runs in the main checkout, so its behaviour test waits
until it has landed, whichever tree holds it. After `/test-skill`, two
pilot runs: one whose target is a small ready brief, end to end, and one
whose worker is made to stop on a denial, to see the run halt and hand
over its resume command.

## Other repos

Five repos held a frontmatter queue on 2026-10-12, by
`uv run scripts/handoff-status.py --no-inbox`: this one, `machine-config`
under `docs/handoffs/`, and three client repos under
`docs/handoffs/execute/`. What differs between them:

- **How a brief lands.** Here, by a fast-forward from the main checkout
  with no push; `/land` pushes and opens a PR, and its step 1 defers to
  a repo's own landing. The loop takes the landing from the repo's
  instructions, and stops where it finds none.
- **`worktree.baseRef`.** This repo sets `"head"`. Under the default,
  `"fresh"`, a worktree branches from the remote's default branch, so a
  brief landed without a push is missing from the next brief's
  worktree, with nothing said. Such a repo needs `"head"`, or a push
  between briefs.
- **The queue reader.** `handoff-status.py` prints text only, with no
  `--json` (2026-10-12, `--help`), and a deployed skill runs its own
  scripts. A skill in `skills/workflow/` bundles a reader in its
  `scripts/` that takes the repo from the working directory
  ([editing-skills.md](../../../.claude/rules/editing-skills.md)
  § "Bundled scripts").
- **Names.** Nothing it writes in a client repo names a personal repo.

## Not in scope

- Running briefs in parallel.
- Deciding briefs that need the user, a tenant or Desktop. Gathering
  their questions into one sitting could come later.
- Audit follow-ups under `docs/audits/`, which `/drift-update` walks,
  and inbox notes, which `/triage` takes.

## Re-measure before acting

```bash
claude --version   # 2.1.293 on 2026-10-12; re-read the three pages above if it moved
uv run scripts/handoff-status.py --help                     # no --json on 2026-10-12
uv run scripts/handoff-status.py --no-inbox | grep '^=='    # five repos on 2026-10-12
grep -n -A1 '"worktree"' .claude/settings.json              # "baseRef": "head"
ls .claude/skills skills/workflow | grep -i brief           # nothing on 2026-10-12
```
