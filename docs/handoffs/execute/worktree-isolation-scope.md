# Handoff: what a worktree actually isolates

- **Written**: 2026-09-22, from the user's question about guardrails for
  concurrent sessions, after drilling
  `code.claude.com/docs/en/worktrees`, `/cross-session-messaging` and
  `/agent-teams`.
- **Kind**: one scope correction to [CLAUDE.md](../../../CLAUDE.md) §
  "Branching and concurrent sessions", one open flag in that same
  section closed, and one **settings decision** that is payload and is
  not obvious. Plus one probe, which is the only part needing a session.
- **Status**: **Open.** The scope correction is argued from documentation
  and four local measurements and needs no run. The probe is what would
  confirm the enforcement fires on this CLI version.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## The standing conclusion is right, and scoped to a different axis

[CLAUDE.md](../../../CLAUDE.md) § "Branching and concurrent sessions"
says a worktree is *"either unnecessary or ineffective, with no case in
between"*, measured 2026-09-02 by deploying to a real worktree and
probing it cold. That measurement asked **can a worktree isolate my
payload?** The answer was no, because user scope outranks project scope
and a worktree copy of a user-scope skill is inert. That is still true
and nothing here disputes it.

It is not the question the collision raises. `--worktree` and
`EnterWorktree` are a different mechanism from the `git worktree add`
plus `link-claude.ps1` that was measured, and they carry something the
hand-rolled worktree had none of: **enforcement**. Four checks, applied
to the session and to every subagent it spawns:

- An `Edit`, `Write` or `NotebookEdit` targeting a path in the main
  checkout is blocked.
- A Bash, PowerShell or Monitor command whose working directory resolves
  to the main checkout is blocked.
- A command redirecting git into the main checkout — `git -C`,
  `--git-dir`, `GIT_DIR`, `GIT_WORK_TREE`, or a `cd` first — is blocked.
- A command whose text cannot be verified to keep git inside the
  worktree is blocked, and **that check cannot be turned off.**

So the 2026-09-02 conclusion answers *payload isolation* and this brief
answers *file and index isolation*. Both can be true. Edit the section to
say which it measured rather than replacing it.

## What it buys, precisely: the index, not the document

**Buys — the shared git index.** Each worktree has its own index. The
loss root `CLAUDE.md` records for 2026-09-12 — a `skill-status.py
--stamp` entry in `tests/skills/.tested.json` lost twice to the other
session's commits, *"once from the working tree, once from the working
tree and the index while it sat staged"*, most plausibly to pre-commit's
stash/restore — is an index collision. In separate worktrees it does not
happen. `CLAUDE.md`'s *"the index is shared too, so staging is not
isolation — only a commit is"* stops being true there, and that sentence
should say it is scoped to one tree.

**Does not buy — the shared document.** Two worktrees are two branches,
so two divergent versions of
[docs/handoffs/execute/README.md](README.md), and this repo integrates
`--ff-only` with no merge commit in 324+ commits by its own stated
convention. A worktree converts a silent overwrite into a merge conflict
in a repo whose convention forbids merges. **A worktree is the right tool
for divergent state and the wrong one for convergent state** — and the
user's own narrowing is that divergent work already causes no trouble
here, while the convergent index is what recurs. That half is settled
separately: the count line both sessions had to touch was deleted
2026-09-23 in `7d31355`, and the number now has one source in
`handoff-status.py`.

State both halves in the section. The tempting one-liner — "worktrees
solve concurrent sessions" — is wrong in this repo specifically.

## The open flag can be closed without a probe

That section currently says:

> **The 2026-09-09 scope split reopens that last bullet, and it has not
> been re-measured.** [...] so a worktree plausibly does isolate them,
> which would be the in-between case the bullet says cannot exist.

The documentation now states the rule outright: a worktree whose checkout
has its own `.claude/skills` loads only that copy, and the main
checkout's project skills read through **only when the worktree has
none**. Measured here 2026-09-22: `git ls-files .claude/skills` returns
**9 tracked files**, so a worktree checkout of this repo always has its
own copy.

**The in-between case is real.** The five project-scope skills do isolate
in a worktree, exactly as the reopened bullet suspected, and the
dichotomy holds only for the deployed groups.

Two honest limits on that, both of which belong in the edit. It is
derived from documentation plus one `git ls-files` count, **not from a
run** — the probe below is what would witness it. And the read-through
half is documented as requiring v2.1.277; this machine is on **2.1.268**,
so that path is untested here, though it is not the path this repo takes.

## Preconditions, measured in this repo 2026-09-22

No blockers. Worth recording because two of these would surface as
something else entirely:

- **No `includeIf` in this repo's own `.git/config`.** A conditional
  include there is one of four conditions that refuse worktree creation
  outright, and the refusal names git config rather than worktrees — it
  would read as a git-identity problem. The docs exempt a **global**
  `includeIf`, which is where this machine's identity scoping lives, so
  it does not fire. Confirm per repo rather than assuming; a client repo
  could carry a local one.
- The `[lfs]` section in `.git/config` carries only
  `repositoryformatversion`, not `lfs.customtransfer.<name>.path` or
  `lfs.standalonetransferagent`, which are the two keys that refuse.
- `.claude` and `.claude/skills` are real directories. A symlink at
  `.claude`, `.claude/worktrees`, or the worktree path itself refuses
  creation.

## The settings decision, which is payload and is not obvious

Two prep items if worktrees are adopted at all:

- `.gitignore` carries no `worktrees` line, so `.claude/worktrees/` would
  appear as untracked in the main checkout. One line.
- **`worktree.baseRef` is unset in every settings file on this machine**
  — `claude/settings.json`, `.claude/settings.json` and the live
  `~/.claude/settings.json` all lack it — so it defaults to `"fresh"`:
  branch from `origin/<default-branch>`.

That default is a trap **here** and may be correct elsewhere, which is
what makes it a decision rather than a fix. As of 2026-09-22
`origin/main` is two commits behind `HEAD` in this repo
(`git rev-list --left-right --count origin/main...HEAD` → `0 2`). A
worktree cut that day would silently not contain them. For a repo whose
convention is that every commit lands on `main` and whose pushes lag,
`"head"` is right. For a client repo where the point of a worktree is a
clean base matching the remote, `"fresh"` is right.

The decision is where to set it, and both answers cost something:

- **`claude/settings.json`** (user scope, deployed, needs
  `link-claude.ps1 ... -Force`) applies the choice to every session on
  the machine, including client repos where the other value may be
  wanted.
- **`.claude/settings.json`** (this repo only, deployed nowhere) fixes
  agent-config and leaves every other repo on the default.

**This item has a different clock from the rest of the brief.** The trap
fires whether or not worktrees are adopted deliberately, because
`EnterWorktree` triggers on the words "work in a worktree" in any
session — so the first accidental worktree in this repo gets the stale
base regardless of what this queue decides.

## The probe

One fresh session, this repo. It is not the same run as the collision
probe — see Dependencies.

```bash
claude --worktree probe-isolation
```

Assert, in the worktree session:

1. An `Edit` targeting a main-checkout path is refused, and the refusal
   names the worktree.
2. A Bash command that `cd`s to the main checkout and runs git is
   refused.
3. The command-shape check fires on a computed command name — the one
   that cannot be turned off.
4. **The skills question**: does the session list the five
   project-scope skills, and are they the *worktree's* copies? Use the
   2026-09-02 marker technique that section already records — put a
   marker in the worktree's
   `.claude/skills/author-skill/SKILL.md` description and check whether
   the listing carries it.

Teardown: `ExitWorktree` with `remove`, or `git worktree remove`. Confirm
with `git worktree list` that only the main checkout remains.

### Two traps that will make you read the result wrong

**Do not run `link-claude.ps1` at any point in this probe.** The
2026-09-02 measurement records the trap: running the main tree's copy
with `-ClaudeDir <worktree>` relinks every junction back to the main
tree, reporting `Relink` and ending `Done`. This probe is about project
scope and file enforcement, not payload deployment, and the linker can
only contaminate it.

**The workflow skills still being the main tree's files is not an
enforcement leak.** `~/.claude/skills/<name>` is a junction into the
**main checkout's** `skills/`, so a worktree session's `commit`, `land`
and `learn` are the main tree's copies, and a `SKILL.md` edit in the
worktree changes nothing live. That is the 2026-09-02 shadowing result
holding, exactly as documented, and reading it as the enforcement
failing would report a false negative on a correct implementation.

## What was ruled out, and why it stays ruled out

**Agent teams — no.** Experimental, off by default behind
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`, and the docs describe this
repo's exact problem as a known failure: *"Two teammates editing the same
file leads to overwrites."* Teams are for work that splits cleanly across
files; the contended index is the file that does not split. Three further
reasons to record so this is not re-litigated: enabling it changes
ordinary delegation, since a subagent Claude names launches as a teammate
and a team can form unasked; teammates are scoped to one session, while
the situation here is two independent sessions; and split-pane mode is
explicitly unsupported in VS Code's integrated terminal, which is where
these sessions run.

**Cross-session messaging keeps one thing, and it is not payload.**
`CLAUDE.md` treats the `<cwd-basename>-<hash>` naming as structural —
*"filtering peers by repo-name prefix silently misses one working in a
subdirectory"* — and it is the **fallback**. `--name` at launch and
`/rename` in session set a real one, which is what peers address. That is
an operator habit costing no context, so it belongs in prose as an aside
at most. `crossSessionInbound` and `isolatePeerMachines` are both unset
here and should stay unset: the default already decides per message from
the two sessions' permission-mode classes, and `auto` counts as
prompting, so messages are delivered.

**One subtraction to weigh while editing.** The documented behaviour of
an incoming peer message already states most of `claude/CLAUDE.md`'s
escalation paragraph — cannot approve, cannot change configuration,
commands arrive as plain text and never run. What is **not** redundant is
the two additions from 2026-09-18: the subagent-laundering test and the
inbox-delete rule. Trimming the redundant half would suit a file under a
stated lean constraint, but it is a payload edit affecting every session
and is listed here as a candidate, not a decision.

## Dependencies

- The sibling brief owning the half a worktree does not fix — the
  queue's count line — landed 2026-09-23 in `7d31355` and its brief is
  deleted. It never blocked this one, and the two were deliberately not
  bundled: that was a repo-index deletion, this is a payload edit.
- `peer-coordination-open-questions.md` closed on 2026-09-23. Its
  cold re-run of the 2026-09-17 probe called `ListAgents` before its
  first edit (transcript `695a54ec`). **That was a different setup
  from this one**: one cold session in the *shared* tree, live peers
  and no scripted collision, against one session in a worktree. It
  settles nothing here. Nor did it settle the ablation blocking the
  peer-session article in
  [linkedin-article-skill.md](linkedin-article-skill.md). It is only
  that ablation's loaded half. The run with the peer subsection
  stripped is still missing.
