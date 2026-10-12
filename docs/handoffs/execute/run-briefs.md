---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-12
---

# Skill handoff brief: run-briefs

Last verified: 2026-10-12

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.
>
> Guidance: The frontmatter is this brief's whole queue state: `scripts/handoff-status.py` prints the queue from it, and pre-commit's `lint-briefs` fails a commit on a brief without it or with a placeholder left in. Pick `priority` — 1 now, 2 next, 3 later — list in `needs` what a session cannot supply alone (`user` for a decision), name any brief this waits on in `blocked-by`, and state none of it in the body.

## Artifact path

Payload, deployed by group:

- Repo: `skills/workflow/run-briefs/SKILL.md`, with
  `references/worker-prompt.md` and `references/landing-gate.md`.
- Deployed: `~/.claude/skills/run-briefs/`, one junction, by
  `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta` from the
  main checkout once this branch has landed. Until that run the skill is
  invisible everywhere and `/run-briefs` answers `Unknown command`.
- Copilot: no copy. The Copilot payload is being retired
  (`copilot-payload-retirement.md`), so `copy-copilot.ps1` is not run.

The user chose this tree over `.claude/skills/` on 2026-10-12: the skill
runs in the main checkout of any repo whose briefs carry frontmatter, five
on this machine, and [.claude/skills/README.md](../../../.claude/skills/README.md)
records that scope follows where a skill runs, the lesson `land` and
`learn` each paid for. It is written portable: nothing in it names this
repo except as the worked example of a landing.

## Scope

Runs one handoff brief and whatever blocks it, one brief at a time, each
in a fresh headless `claude -p` session. The coordinator is the typed
session in the main checkout; it resolves the order from the briefs'
`blocked-by`, launches a worker per brief, waits for it in the
background, gates the run on its JSON result and its branch, lands the
branch as the repo's instructions say, then re-reads the queue and goes
on until the target brief has landed or a run stops. It keeps no state.
Inline, **manual-only** (`disable-model-invocation: true`, the first in
this repo), not path-scoped; `context: inline` because the landing's
prompts are where the user stands by.

## Sources drilled

Drilled, all on 2026-10-12, CLI 2.1.293 and this session on 2.1.296:

- **The probe** the queue brief's step 1 asked for, nine Sonnet workers
  in this repo, sessions `8d669194` (worker's life), `ca4107ac` and
  `08dd71a3` (denials), `12e02e22` (EnterWorktree under `-p`), `8f387236`,
  `969dda6e` and `5ea4df62` (agent listings), plus three resumes. It
  established: a worker writes and commits through `/commit` in a
  `--worktree` (33 s, 6 turns, est. $0.29) and a worker started in the
  main checkout enters a worktree by `EnterWorktree` name; worktrees and
  branches outlive a run; the lock a run takes stays until a later
  session's sweep (three of five released within two minutes, two still
  held with the pid gone); `--output-format json` carries
  `permission_denials` with `tool_name`, `tool_use_id` and `tool_input`,
  and a denied run still reads `subtype: success`, `is_error: false`; the
  worker stopped on the denial as told; `git rebase main` was not denied;
  `--resume <session_id> -p` re-entered the worktree and `--resume <-n
  name>` exited 1 with empty stdout; a running worker is listed by
  `claude agents --json` (kind `interactive`, cwd the worktree) and
  `ListAgents`; `find-session --probes` lists workers by `-n` name;
  background Bash in this interactive session ran 630 s under a 600 s
  timeout; detached processes outlived their tool calls.
- **code.claude.com/docs/en/headless**: `-p` loads an interactive
  session's context; `--permission-prompts none` denies and tells Claude
  not to retry; `/skill` in the prompt expands; a `-p` run waits for its
  own background commands, ten-minute idle cap
  `CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS`; SIGTERM exits 143 and kills the
  process tree of a running Bash command; stdin capped at 10 MB.
- **code.claude.com/docs/en/cli-reference**: `--resume` by id searches
  the project, its worktrees, then every project; `--max-budget-usd`
  stops at a client-side estimate, print mode only, subagents count,
  overshoot possible; `--worktree` reopens an existing name; `--help`
  omits flags.
- **code.claude.com/docs/en/tools-reference**: no time limit on
  background commands in a local session; unattended runs get 30 minutes
  by default, 10 under `-p` with a text prompt, 2 hours maximum via
  `timeout`; `EnterWorktree` by name from the main checkout, by `path`
  from inside a worktree.
- **code.claude.com/docs/en/worktrees**: a `-p` run's lock stays "until
  a later session's stale-lock sweep releases it"; the sweep keeps a
  worktree with changed files or unpushed commits; `--resume` returns a
  `-p` session to its worktree, refusing with `error_during_execution`
  and `startup_failure_reason`; the transcript follows the worktree;
  `worktree.baseRef` `fresh` branches from the remote's default branch.
- **code.claude.com/docs/en/sessions**: `-p` sessions are out of the
  picker and resumable by id only; name resolution opens the picker when
  ambiguous; a `-p` run gets no generated title.
- **code.claude.com/docs/en/agent-sdk/typescript**: `SDKResultMessage`
  success and error variants, `permission_denials` on both, `errors`,
  `startup_failure_reason`; "permission_denials on the result message is
  the authoritative record".
- **`claude auto-mode defaults`** (2.1.293): `Git Destructive` is a soft
  deny whose text exempts a rebase of the agent's own work; `Auto-Mode
  Bypass` says the response to a denial is "another safe alternative or
  ask the user"; `Self-Modification` treats files under
  `.claude/worktrees/<name>/` as ordinary project files.
- **This repo**: `docs/handoffs/CLAUDE.md` and `execute/README.md` (the
  landing, the view's `held`, `merged`, `parked`), `skills/workflow/land`
  step 1 (defers to a repo that lands without a push), the user-scope
  hooks a worker inherits (`name-session.sh` leaves a `-n` name alone;
  `prune-probe-sessions.sh` sweeps `probe:` sessions after two days),
  `.claude/settings.json` (`worktree.baseRef: head`).

Not drilled, and so not described by the skill: the agent view page
beyond the queue brief's reading, agent teams, the Python SDK and the
TypeScript SDK beyond the result type, `stream-json`'s `permission_denied`
events (the `json` result carries the authoritative list), the `--bg`
route, and killing an interactive coordinator (the SIGTERM behaviour is
documented for a `-p` run only). Not measured: a `--resume` by id of a
worker that entered its worktree by `EnterWorktree` (documented as the
same rule as `--worktree`), what `--max-budget-usd` caps on a
subscription login (the page is silent), and any landing but this
repo's: the four other queues land by their own instructions, which the
skill reads and stops without.

## Frontmatter

```yaml
---
name: run-briefs  # repo linter requires it; max 64 chars; lowercase/digits/hyphens; no "anthropic"/"claude"
# model: inherit  # ALWAYS PRESENT, ALWAYS COMMENTED under skills/workflow/: an active model: key blocks Copilot slash dispatch and fails lint-frontmatter.py
effort: max  # the behavioural-skill floor, editing-skills.md § "Invocation and spend fields"
disable-model-invocation: true  # typed only: a run spends usage and lands branches; first true in the repo, decided 2026-10-12; editing-skills.md and this template say so
argument-hint: "[brief-stem]"
allowed-tools: Bash(git worktree list *) Bash(git status *) Bash(git log *) Bash(git rev-parse *) Bash(git rev-list *) Bash(git cat-file *) Bash(git show *) Bash(git merge-base *) Bash(claude agents *) Read Grep Glob  # read-only; the launch, the rebase and the fast-forward are judged per call
description: "<counted below>"  # gated at 1,024; documentation only, since the flag above keeps it out of the model's listing
---
```

No `when_to_use`: it would never fire. No `paths:`. No `context: fork`:
the landing's prompts need the user's session.

## Description char count

- `description`: 761 / 1,024
- `when_to_use`: N/A — not set

## Body structure outline

1. **What this runs and where.** One brief and its blockers, one at a
   time, each a `claude -p` worker; the coordinator in the main checkout
   of a repo with a frontmatter queue; no state of its own.
2. **Preflight.** Main checkout, not a worktree; the queue directory;
   the repo's landing instructions, or stop; `worktree.baseRef` `head`,
   or stop; the CLI version the workers run; HEAD recorded.
3. **Resolve the order.** Walk `blocked-by`; blockers first; stop before
   a deferred brief, a `needs`, or a worktree by the stem.
4. **Launch the worker.** The command, started in the main checkout so
   it can re-measure, with the prompt in `references/worker-prompt.md`;
   background with `run_in_background`; how it shows in the listings.
5. **Wait.** The tool re-invokes on exit; no limit in an interactive
   session; the `-p` limits if the coordinator is itself headless.
6. **Gate.** The JSON fields, the branch tip, the two clean trees; the
   stop and its `claude --resume <session_id>`.
7. **Land.** Session live in the main checkout; the lock and its pid; the
   rebase and its possible denial; `pre-commit`; the fast-forward; the
   deploy and the post-landing grep; what the worker said landing owes;
   remove or keep the worktree.
8. **Go on and report.** Next brief from the new HEAD; the per-brief
   report and totals.
9. **Constraints.**

`references/worker-prompt.md` holds the prompt and why each sentence is
there; `references/landing-gate.md` holds the gate commands, the JSON
shapes, the lock facts, this repo's landing commands and what each
failure looks like, dated.

## Changes from source proposal

The source is the queue brief `brief-coordinator-skill.md` (`98f23e7`,
2026-10-12), which this brief replaces. Its design stands; the probe
moved these points:

- **Unlock is conditional.** The design opened the landing with
  `git worktree unlock`, since a `-p` run "leaves its lock in place".
  The lock is released by a later session's sweep, which caught three of
  five within two minutes, so the landing unlocks only a `locked` line
  whose pid is dead and stops on one whose pid is alive.
- **The rebase may not be denied.** The design relied on auto mode's
  `[Git Destructive]` refusal to put the rebase to the user. The current
  rule text exempts a rebase of the agent's own branch and the probe's
  ran, so the landing handles both: a denial goes to the user, an
  allowed rebase proceeds.
- **Resume by session id, never by name.** Added after `--resume` by the
  `-n` name exited 1 with nothing on stdout for every `-p` session tried.
- **The re-measure order is settled**: the worker starts in the main
  checkout, measures, then calls `EnterWorktree` by name. Both routes
  worked; this one lets a brief measure another repo, which the worktree
  guard refuses.
- **The denial is in `json`**, so the gate needs no `stream-json`.
- **The wait is `run_in_background`**, which re-invoked the coordinator
  on every exit and has no time limit in an interactive session; Monitor
  and a detached start are documented as the fallbacks for a headless
  coordinator.
- **The landing check uses `claude agents --json`**, whose rows carry a
  `cwd`; `ListAgents` names a worker but not where it sits.
- **Landing owes are split**: the coordinator runs a mechanical one, a
  deploy or a stamp whose test the worker reports passed, and prints one
  that needs a fresh session, a `/test-skill` run, for the user.
- **Decided by the user on 2026-10-12**: the name `run-briefs` over
  `execute-briefs`, since machine-config's queue has no `execute/`
  directory and `/drift-update` already owns that verb; the tree
  `skills/workflow/`; `disable-model-invocation: true`; one skill, the
  prompt and the gate in `references/`.

## Tag

`personal`

## Portability caveats

Claude Code only, by nature: `claude -p`, `--worktree`, `EnterWorktree`,
auto mode, `--permission-prompts none` (2.1.259 or later) and the `json`
result are the mechanism. Under Copilot nothing of it applies, and the
group is not copied there now. `disable-model-invocation`, `effort` and
`argument-hint` are Claude Code fields; a portable copy would drop them.

Across repos the skill assumes a frontmatter queue (`status`, `needs`,
`blocked-by`), a `.claude/settings.json` with `worktree.baseRef: "head"`
(under the default `fresh` a brief landed without a push is missing from
the next worktree), and landing instructions of the repo's own; it stops
where one is missing. `handoff-status.py` exists in this repo only, so the
skill reads frontmatter itself and uses the view where it is present.

## Cross-reference dependencies

- `commit` — (a) already converted. The worker commits through it.
- `land` — (a) already converted. Its step 1 defers to a repo whose
  instructions land without a push, which is how this repo's briefs land.
- `test-skill` — (a) already converted. Deletes this brief at its step
  10, and is what landing owes for a skill brief.
- `find-session` — (a) already converted. Lists workers with `--probes`
  only when named `probe:`; a `brief:`-named worker is listed by default.
- `prune-branches` — (a) already converted. Proposes the unlock of a
  stale lock the landing did not reach.
- `docs/handoffs/CLAUDE.md` — (a) this repo's landing procedure, which
  the skill follows here and names as the worked example.
- `.claude/rules/editing-skills.md` and
  `docs/handoffs/templates/skill-handoff.md` — (b) each carried "false
  everywhere" for `disable-model-invocation`; both gain the exception in
  this brief's work.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief; brief-specific observations belong in Notes below.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**Test plan for `/test-skill`.** Phase A has nothing to fixture: the
skill is unconditional and manual-only, so no description fires it and
the only route is typing `/run-briefs <brief-stem>`. Phase B is two pilot
runs from the main checkout, after this branch has landed and the linker
has run, since the skill is in a deployed group:

1. `/run-briefs <stem>` on a small ready brief with `needs: []` and no
   blockers (on 2026-10-12 the queue's P2 ready set held
   `drift-audit-owed-rechecks`, `kql-dax-rule-contradictions` and
   `auth-cli-gotchas-into-fabric-rest-api`; the user picks). Expected: one
   worker launched in the background, named `brief: <stem>`, visible in
   `claude agents --json` with the worktree as its cwd; on exit the gate
   reads the JSON and the branch; the landing stops for the user at a
   session live in the main checkout or a denied rebase, else lands by
   fast-forward and reports commits, cost and what is owed.
2. A denial. A throwaway brief whose work requires a command the
   classifier refuses, such as `rm -rf "$UNSET/x"` (denied as
   `[Unverifiable Deletion Target]` on 2026-10-12). Expected: the run
   halts after that worker, prints its `permission_denials` and
   `claude --resume <session_id>`, and leaves the worktree and branch.

The `--safe-mode` baseline cannot type the skill, so the comparison is
the second half of `/test-skill` step 8: what the base model does with
the same request and no skill, which is to run the brief in its own
session or ask.

**The worktree needs a move.** This brief was authored in the worktree
`brief-coordinator-skill`, the queue brief's stem. The view pairs a
worktree to a brief by name, so once this session has left,
`git worktree move .claude/worktrees/brief-coordinator-skill .claude/worktrees/run-briefs`
from the main checkout pairs it again.

**Policy exception, in two files.** `disable-model-invocation: true` is
the first in the repo. `.claude/rules/editing-skills.md` and the
template's field comment each said `false` everywhere; both now name the
exception.

**The probe's cost**: nine workers and three resumes, about $1.60 by the
runs' own `total_cost_usd`, all on Sonnet.

**A possible follow-up, not in scope**: a bundled `scripts/` reader that
resolves the chain and prints it, once a second repo's queue runs this
way; today the chain is short enough to read by hand.

## Confidence

- **Structure**: H — the template, the tree and the deploy step all have
  shipped precedents in `skills/workflow/`.
- **Field specs**: H — every field is one the linter and
  `editing-skills.md` already govern; the one new value, `true`, is
  documented upstream and not value-checked by the linter.
- **Body content**: M — the launch, the gate and this repo's landing are
  measured; the stop conditions around a parked worktree and another
  repo's landing are reasoned from the docs and the queue's README, not
  run. The two pilots are what settles them.
