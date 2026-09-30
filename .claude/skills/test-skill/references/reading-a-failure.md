# Reading a failure: the witnesses

`SKILL.md` keeps the symptom table; this file keeps the evidence behind
it — where an activation is recorded, what a `-p` probe emits instead,
how to tell which model served a turn, why the directory a probe runs
in is never the variable, what the write-tool flags leave open, what
the `--safe-mode` list still carries, and what it leaves within reach.
Moved out of the skill body on 2026-09-13 when that body reached the
linter's 500-line cap, the moved text unchanged; later sections landed
the same day, each time the cap was hit again. Five of step 8's
measurements followed on 2026-09-29, each under a new lead, to make
room in the body for instructions that had lived only here.

**The transcript is one of two witnesses.** It is at
`~/.claude/projects/<project>/<session-id>.jsonl`; an activation is a
record whose `attachment.type` is `skill_listing` with `isInitial`
**false**. The `isInitial: true` record is the startup listing and says
nothing about any file. `instructions-loaded.log`, `skills-invoked.log`
and `skillUsage` all count *invocations*, and a path-triggered skill is
loaded, never invoked — a zero there means nothing.

**A `-p` probe has the cheaper witness inline.** With
`--output-format stream-json --verbose`, the `Read` of a matching file
emits a `system` record of `subtype` `commands_changed` — between the
`tool_use` and its `tool_result`, before any `Skill` call — whose
`commands` snapshot names the skill where `init.slash_commands` did not.
No session id to locate. It is a **snapshot, not a delta**: a second
`Read` of the same file re-emits it unchanged, so count names, never
records; and MCP prompts that connect after startup land in the same
snapshot, so assert the names you expect rather than diffing it whole
against `init`. **Undocumented** on 2.1.268 — not on the headless page
or in the changelog, with an open upstream issue asking for the message
types to be listed — so a `drift-audit` may find it renamed. Measured
2026-09-12 across two files and three skills: `cultures/en-US.tmdl`
took the listing from 67 to 73 with the cultures skill present;
`model.tmdl` to 72 with `fabric-tmdl` and `fabric-tmdl-api` present and
the cultures skill correctly absent. The `--safe-mode` baseline and a
cold slash probe emitted none.

**A slash run's witness is the NL run beside it.** A slash-invoked skill
is inlined as a command expansion and makes no `Skill` call, so step 8
pairs the slash arm with an NL arm on the same query. Measured
2026-09-13 on `fabric-cli` — NL 3 turns with `Skill fabric-cli`, slash 1
turn with none, the same GUID-vs-friendly-name table in both; the first
slash run, on a section that hands off to `fabric-deployment-pipelines`,
showed only that skill's call.

**Read the answers rather than grepping them.** On 2026-09-12 an
`/owns|owned/` scan missed "items you own" and nearly recorded a passing
assertion as a failure.

**The transcript also witnesses which *model* served a turn**, which is
what checks a `model:` pin in `.claude/skills/`. Each assistant record
carries `message.model`; a real API turn carries a `msg_…` id and
non-zero `usage`, while a client-side refusal reads `<synthetic>` with a
UUID id and zero tokens. Check that value, not the console: a pin can
resolve to a *different* model than the one named and still answer
perfectly (`model: fable` ran `claude-fable-5` on CLI 2.1.252), and a
`[claude-code:unrecognized_model]` warning can print on a call that
nevertheless succeeds. Measured 2026-09-12.

Directory properties do **not** affect activation: a scratch directory
outside any repo behaves exactly as this one does. If a run only
reproduces in one directory, the variable is the tool, not the location.

**The write-tool flags leave two shells and one API open.** With
`--disallowedTools "Bash,PowerShell,Edit,Write,NotebookEdit"` a probe
still holds `Monitor`, whose `command` is "a shell command or script"
run "in the same shell environment as Bash"; `Agent`, which spawns a
subagent carrying its own tool set; and every tool the user-scope
`MCP_DOCKER` gateway re-exports — `merge_pull_request`, `push_files`,
`delete_file` — because a `--disallowedTools` list naming shell tools
says nothing about MCP. `--strict-mcp-config` closes the last, and the
list gains `Monitor,Agent`. Two `land` probes on 2026-09-13 ran with
the shorter list: each found `Monitor`, wrote that it "does take a
`command` and run it", and declined to route `git push origin main`
through a tool whose prompt says "watching a log file" — sound
judgement, and exactly the restraint the flags exist not to depend on.
`Monitor` is verified against its schema; `Agent` is listed on
reasoning, since whether the flag reaches a subagent's tools was not
probed.

**The deny list went stale; an allowlist cannot.** On 2.1.282 a `-p`
probe denied the step 8 list, the file and web tools, `ListAgents` and
`SendMessage`, and still held 16 tools: among them `Workflow`, which
spawns agents as `Agent` does; `EnterWorktree`, a git write;
`CronCreate`, `RemoteTrigger` and `ScheduleWakeup`, which run work
later or elsewhere; `PushNotification`; and three `Artifact` tools.
The user-scope cold-probe recipe's shorter list, run from this repo,
left 82: `Monitor`, `Task`, `Workflow`, and `github-mcp`'s
`push_files`, `merge_pull_request` and `delete_file` from the project
`.mcp.json`. `--tools Skill` left `Skill` alone, with `test-skill`
still listed, and `--tools ""` left nothing; `--tools` names built-in
tools only, so `--strict-mcp-config` stays. Read off `init.tools`
2026-09-29; what the leftover tools could reach was not probed.

**Disabling the shell stops an *acting* run at step 1.** What a probe
measures is what the skill says, so the flags cost nothing on a query
that asks for an explanation — and on one that asks the skill to act,
the run stops at the first command it cannot issue and the later steps
go unmeasured on that arm. Measured 2026-09-13 on `land`, three payload
arms, same skill and flags throughout: "take it from here to merged"
(slash) and the squash-and-merge adversarial query both stopped at
preflight on the missing shell, 3 and 6 of 11 discriminators; "walk me
through … the exact commands start to finish" reached step 9 with 11 of
11. A skill whose body is commands wants one walkthrough arm, or the
later steps are never rendered.

**The `init` record is what proves the strip.** Measured 2026-09-12 on
`fabric-catalog-governance` — 21 commands with the skill absent against
33 with it present — which is what made "the baseline reproduced this
finding unaided" a result rather than a guess.

**The `--safe-mode` list still carries every built-in.** The proof that
the payload was stripped is a payload name missing from
`init.slash_commands`, and `code-review` is not one: the CLI ships a
built-in command of that name, so it stays listed with the payload off.
Measured 2026-09-13 on `land`: 54 commands under `--safe-mode`,
`code-review` present, `land`, `commit` and `linkedin-highlights`
absent, `mcp_servers` 0; 57 with the payload and all four present. A
grep for `code-review` reads as a leaked payload when nothing leaked,
and on the day `code-review` itself is under test its absence cannot be
read off the list — assert its siblings instead, and read the count
drop as the payload minus one.

**`--safe-mode` does not strip the web tools.** It removes the payload,
not `WebFetch` and `WebSearch`, so against a skill that caches public
docs the baseline can fetch its way to the same answer. Measured
2026-09-12 on `fabric-deployment-pipelines`: the baseline fetched the
exact five Learn pages the skill was drilled from and re-derived most of
its content, the skill's own headline finding included. That is a
second, distinct reason a baseline comes back close — the model is
*reading the sources*, not recalling the domain — and its remedy
differs. Compare on synthesis that sits on **no single page**, or add
`--disallowedTools WebFetch,WebSearch` **to both runs** to measure the
cache against unaided recall — on the payload side too, or a pass cannot
separate "the skill delivered it" from "the model fetched the page the
skill cites" (2026-09-12: with web off on both, the payload still
produced the Learn fact). Cost separates when content does not: 4 turns
to 8.

**The two flags leave the Learn MCP server open to the payload arm.**
Measured 2026-09-13: `fabric-eventstream`'s first payload run blocked
both web tools and still fetched all four drilled Learn pages. The
`init` record's `tools` count was 29 with the servers and 22 under
`--strict-mcp-config`, matching the baseline.

**`--safe-mode` strips what the harness loads — not the working
directory, and not the project instructions.** Both confounds surface
on a project-scope skill, which `.claude/skills/` loads nowhere but this
repo, so the probe runs where the payload sits. Measured 2026-09-13 on
`test-skill`, one walkthrough query throughout. With `Read` available
the baseline opened the skill's own `SKILL.md`, `test-activation.ps1`
and `expected_activations.md` from the cwd, scored 7 of 9
discriminating claims and quoted the skill's sentences back, down to
`activation-expect.py:331`. With `Read,Glob,Grep,ToolSearch` added to
`--disallowedTools` on both arms it tried `find … -name SKILL.md`
through Bash, was denied, and scored 0 against the payload's 11 — and
that gap is still not the skill's margin, because root `CLAUDE.md` is
stripped with the payload and carried 15 of the skill's 16 claims; only
the MSYS2 trap was skill-only. The ablation is the payload arm with
`Skill` added to `--disallowedTools`, everything else identical: the
listing entry stays, the body cannot load, and `CLAUDE.md` stays in
context. It scored 9 of 12 to the skill arm's 11. Read the skill's
contribution off that gap, and expect it to be narrow wherever root
`CLAUDE.md` carries the same procedure — a narrow margin there is not a
redundant skill. It is the shape root `CLAUDE.md` (Validating a change)
gives the false-positive guard, with the body ablated instead of the
guard. **The measurement predates the 2026-09-24 trim of root
`CLAUDE.md`**, which cut it from 1,215 lines to under 200 and moved the
activation-testing procedure to `.claude/rules/activation-testing.md`.
That rule loads only on a matching `Read`, so with the file tools
disallowed no arm carries it, and root keeps a summary of it: the 15 of
16 no longer holds, and the ablation margin has not been re-measured
since.

**The ablation needs one tool declared, and `--tools ""` declares none.**
Under the allowlist the ablation above, `Skill` denied beside the file
tools, becomes `--tools CronList`, a read-only placeholder. Measured
2026-09-29 on `test-skill`, Opus 5.5 at max effort, one walkthrough
query: with no tool declared, the model wrote 14 calls as text, 7
`Read`, 5 `Glob` and 2 `Grep`, then wrote their results itself, among
them a `SKILL.md` for the query's skill, which does not exist, and cited
its invented lines as findings. A call written as text ends no turn, so
it ran to the output cap; the CLI injected "Output token limit hit.
Resume directly…", and a second turn followed: 230,085 output tokens to
the baseline's 111,909, 30 minutes, $5.68. A one-line Haiku check of
`--tools ""` had passed, too short to show it, and
`--tools Skill --disable-slash-commands` is the same trap: it drops
`Skill` with the skills, leaving `tools: []`. No arm with a tool
declared wrote a call as text: not the day's first two ablations, which
denied `Skill` beside the stale list above and kept 15 tools, none of
them a file tool, one turn each; nor a baseline whose one tool was
`Skill`. `CronList` alone held when a fresh session ran it to the end,
the same day, on a walkthrough of validating a new `tidy-worktrees`
skill: one turn, `end_turn`, no tool call and none written as text,
95,930 output tokens and $2.03 to its baseline's 94,582 and $1.93
(`51d7487`). The stream carried no thinking text, so that check covers
the answer alone; the first `CronList` arm was stopped early (below).

**A max-effort arm with nothing to call is silent for most of its run.**
Until its first content block closes, the stream holds only
`thinking_tokens` progress records. Measured 2026-09-29, same run: the
baseline thought 106,650 tokens before its first word, 17 minutes in
all at about 100 a second, while the payload arm's first block closed
at 7,400, its `Skill` call next. The `CronList` arm, stopped at 65,500
as a runaway, was on the baseline's course, and the one that finished
bore it out: 14.6 minutes to its baseline's 14.6 and the payload arm's
9.1. Pace an arm against the baseline, never the payload arm. Bound
spend at launch instead: `--max-turns` counts turns, and each arm here
ran one or two long ones. 2.1.282 has `--max-budget-usd`, which lets
the turn in progress finish (below).

**`--max-budget-usd` does not stop a turn in progress.** Measured once,
2026-09-29 on 2.1.282 (`251f615`), in the first arm run under it to
reach its cap: a `--safe-mode` baseline capped at $4 spent its whole
first turn thinking, 127,999 of 128,000 output tokens, and the CLI
resumed it with "Output token limit hit". It had declared `Skill` and
wrote no call as text, so that resume alone is no sign of the
zero-tool trap above. The second turn crossed $4 partway through and
ran on to a whole answer after 199,195 thinking tokens, 32.6 minutes
in all, ending at $4.17. The `result` record read
`error_max_budget_usd`, `is_error` true, and had no `result` field at
all: read a capped arm's answer off its assistant records. Expect an
arm to spend its cap plus the rest of the turn that crosses it, $0.17
here.

**A routing arm needs only its first tool call.** `--max-turns 1` ends
it there: the `Skill` call is in the stream, the `result` reads
`error_max_turns` with `num_turns` 2, and the process exits 1, so a
runner chaining arms reports the batch as failed. Measured 2026-09-30 on
2.1.282, Opus 5.5 at max effort, on `triage`'s first test: each of three
routing arms made the expected call, `triage`, `learn` and
`author-skill`, for $0.17, $0.19 and $0.22, where the payload arms that
answered cost $1.27 to $1.46.

**`--safe-mode` keeps the session-start git snapshot**, and a retest
runs soon after the commit that made the claim under test, so the
snapshot can hand that claim to the baseline. Measured 2026-09-29 on
`test-skill`: every file tool was off, and the peers claim sat only in
this file, yet all six arms, both baselines included, cited `96e6f00`
by its subject, "parallel probes read each other as peers", and planned
their probes one at a time for it. A Haiku probe under `--safe-mode`
quoted the two newest commits verbatim; with
`CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS=1` it answered `NONE`. Set the
variable on every arm. It also removes the built-in commit and PR
workflow instructions, per Claude Code's env-vars page (read 2026-09-29),
so for a skill whose claims overlap them, such as `commit` or `land`, it
thins the baseline beyond the snapshot: read the log for the claim
instead of setting it there.

**A conditional skill answers `Unknown command` cold.** Measured
2026-09-02 on 2.1.252: `/fabric-data-pipeline` was `Unknown command`
while `/fabric-gotchas` — same session shape, no `paths:` — ran normally.

**A new workflow skill has no junction until the linker runs once.**
`~/.claude/skills` holds one junction per skill, so a directory
`/author-skill` just wrote is invisible everywhere until
`link-claude.ps1 -SkillGroups workflow,social,meta` runs — absent from the
listing, `/<name>` answering `Unknown command` the way a conditional
skill does cold, from a different cause. The group being deployed says
nothing about the skill. Measured 2026-09-14 on `prune-branches`:
`ls ~/.claude/skills` showed four junctions and no `prune-branches`
immediately after the draft, while its brief said "live on save and
needs no deploy step". The run is the standing form, so there is no
prune to restore; `/author-skill` carries the same rule from `land`,
2026-09-02.

**The stamp's `commit` field can name a commit that lacks what was
tested.** `--stamp` writes `rev-parse --short HEAD`, so a run against an
uncommitted edit — the ordinary case, since the skill is junctioned and
therefore already live — records the commit *before* it. The verdict is
unaffected: it is derived from the content hashes, and nothing in
`skill-status.py` reads `commit` back. What it costs is provenance, and
the `test(…)` message is where that shows. So when the edit and the
stamp land in one `/commit` run, commit the skill first, re-stamp, then
stage the manifest. The `body` hash should not move across that
re-stamp, and that it does not is the proof that the committed content
is the tested content. `land`, 2026-09-17: stamped at `343003d`,
re-stamped at `a7b855c`, `body` `5b24a04f96e79be7` both times.

**A stamp is a working-tree write, so a peer's commit can take it.**
Another live session's commit discarded one, staged or not — twice on
2026-09-12, before a re-stamp chained into `git add` and `git commit`
landed (root `CLAUDE.md`, Branching and concurrent sessions; the
re-stamp above).

**A stamp taken in a linked worktree can name a commit `main` never
gets.** Landing rebases the branch onto `main` before the fast-forward
(`docs/handoffs/CLAUDE.md`), and whenever `main` has moved, that
rewrites the commit `rev-parse` named. `test-skill`, 2026-09-29: the
no-X arm, walking a retest through in a brief's worktree, stamped there
and landed by `--ff-only`, noting that a rebase "would leave the stamp
pointing at a commit main doesn't have" (`b4e097b`). Only provenance
suffers, as above, so step 10 stamps on `main` once the fast-forward
lands, where `HEAD` is the landed commit.

**A brief outlives its test unless step 10 removes it, and an edit brief
leaves no trace at all.** On 2026-09-12 a brief whose skill had been
tested and landed that morning was still on disk that afternoon,
reading as "authored, untested". `land`, 2026-09-13: `31d2f4f`
implemented `land-branch-cleanup.md` and deleted it in one commit, and
the skill went twelve commits unstamped.

**Pick the discriminating claim after reading the baseline, not before.**
The claim that reads as a skill's sharpest is not thereby one only the
skill makes, and choosing it up front biases a run toward measuring
nothing. On `land`, 2026-09-17, the `--delete-branch` trap was picked a
priori — a subtle `gh` behaviour, and so a plausible-looking
discriminator — and *both* `--safe-mode` arms volunteered it
unprompted, mechanism included ("gh checks out the base branch first").
The claim that did separate was visible only in what the baseline got
*wrong*: asked to land a 3-commit branch in a shared tree, it answered
`gh pr merge --squash` — "Default to squash." — where the payload
answered `git push origin BRANCH:main`, preserving every SHA. Read the
baseline first, diff the two answers, and let the discriminator fall out
of the disagreement.

**Scope the arms to the hash that moved.** The stamp keeps four,
`paths`, `routing`, `body` and `references` (`scripts/skill-status.py`),
and `--stale` names the one an edit moved as its verdict. Each has one
witness, and an arm can witness only what its invocation path reads:

| Verdict | Hash covers | Arm that reads it | Witness |
| --- | --- | --- | --- |
| `retest-activation` | the `paths:` glob | Phase A | the transcript's `skill_listing` record, `isInitial` false |
| `retest-routing` | `description` and `when_to_use` | a model-invoked trigger query | a `Skill` call naming the skill |
| `retest-behaviour` (`review-body` on a reference skill) | the body | any query that reaches the edited section, plus the slash arm on a pinned skill and the no-X arm for a check-shaped edit | the answer, read in full |
| `refs-only` | `references/` | none; a note, not a debt | — |

A slash arm reads none of those: it inlines the body past the listing,
so it cannot see a `description` edit, and on a body edit it shows
nothing the model-invoked arm did not unless `model:` pins a model.
What it alone tests, no hash tracks: that `/<name>` resolves and
expands, and a `model:` pin, which only that path honours, so on a
pinned skill it alone runs the body on the model `/<name>` gets. So a
skill's first test runs both paths, and a retest adds the slash arm for
a body edit on a pinned skill and for a `model:` or `name:` edit.
`learn` pins `fable`, which a model-invoked arm at `--model opus` never
runs; list the pins with `grep -rn "^model:" .claude/skills skills`,
where `inherit` pins nothing. Nothing flags a `name:` edit either:
`lint-frontmatter.py` does not tie `name:` to the directory, which keys
the stamp, so a frontmatter rename reads as current. Read off
the script 2026-09-29, after `4b1a5c9`'s message booked a slash arm
for a `description` edit, which one could not have seen; `51d7487`'s
"the routing hash is unchanged, so no slash arm ran" reads as though a
routing change would want one.

**A change in the payload arm is not yet the edit's doing.** The stamp
names the edit that staled the test; it does not say the edit caused
what the retest found. To attribute it, run the pre-edit body under
another name at project scope in the probe directory — user scope
cannot be swapped without changing every live session, and project
scope only adds names user scope lacks, so the rename is what makes it
load:

```bash
git show <edit>^:skills/<group>/<name>/SKILL.md \
  | sed '0,/^name: <name>$/s//name: <name>-old/' \
  > <probe>/.claude/skills/<name>-old/SKILL.md
```

Slash-invoke `/<name>-old` on the query the current body answered, from
that directory; `init.slash_commands` grows by one. Measured 2026-09-23
on `commit`: the same shared-tree walkthrough kept the `git diff
--cached` check in 2 of 2 old-body runs and 0 of 3 current ones, which
put the regression on the new code block rather than on the query or
the model.

**A check-shaped claim needs its no-case arm.** An edit of the form
"if X, do Y" passes the X arm whether it checks X or not, so a skill
that always does Y reads as a pass. Keep everything but X — same tree,
same diff, same prompt — and expect Y not to happen. Measured
2026-09-23 on `commit` step 4: the PR-free history committed on `main`
("No PR convention here") where the `(#n)` history had branched.

**Parallel probes read each other as peers, and only the payload arms
look.** A `-p` probe is a live session in the tree: `ListAgents` names
it by its directory, `agent-config-<hash>` here, lists it as
`interactive · busy` like any other, and shows the session running the
test beside it. User-scope `CLAUDE.md` says to list peers before
editing, and `--safe-mode` strips that line, so the baseline never
checks and the confound lands on one side of every comparison.
Measured 2026-09-29 on `drift-update`, eight arms in two batches: all
six payload arms called `ListAgents` and neither baseline did. The four
launched with both baselines each saw three to five sibling probes,
started seconds to minutes earlier, and each made them a question for
the user; one inferred "If you gave this prompt to more than one of the
sessions that started two minutes ago, tell only one of us to go
ahead." In the second batch one arm cited its sibling, "busy right
now", as a reason to accept a commit per brief, a guard under test. Add
`ListAgents` to `--disallowedTools` on every arm, which costs the
baseline nothing, unless the skill under test reads peers itself
(`commit`, `land`, `triage`, and `learn` until its doorbell went on
2026-09-30), where a shared tree is a branch it takes; there, launch the
arms one at a time. The first held on
2026-09-29 (`test-skill`, six arms launched together, `SendMessage`
denied too): both tools were absent from every `init.tools`, and no
arm raised a sibling as a peer. `--tools` removes both by
construction. The second held the same day on `learn`, whose two arms
ran one after the other: the `/learn` arm's `ListAgents` showed five
live sessions and no sibling probe.

**A peer can still message an arm, and the arm answers it as a second
turn.** The stream shows the turn, never the message: a second `init`,
on the session model, and a second `result`, between a pair of
`command_lifecycle` records. Measured 2026-09-29 on 2.1.282, on that
`/learn` arm, launched with `--tools Skill,ListAgents` and so without
`SendMessage`: a live session sent a heads-up to every session its
`ListAgents` showed, and the arm, its answer given on Fable, answered
the heads-up on Opus. The first `result` has `result_index` 0, the
second 1, and the second's `total_cost_usd` is the running total, $3.24
to the first's $2.75. So `select(.type=="result") | .result` prints both
answers back to back, and a read of the last `result` takes the peer's.
Grade the first, and print the count beside it:

```bash
jq -s -r '[.[] | select(.type == "result")] | "results: \(length)", .[0].result' arm.jsonl
```

The day's other three arms each carried one `init`, one `result` and no
`command_lifecycle`. Nothing marked the arm as a probe to its sender:
the listing names it by its directory, and whether `--name` would make
a peer leave one alone is unmeasured. So is a message landing
mid-answer, though `SendMessage`'s description says messages "drain at
the receiver's next tool round", and an arm that calls a tool has one.

**`crossSessionInbound` is the documented switch against it.** Claude
Code's cross-session messaging page, read 2026-09-30, says `refuse`
"drops each message without delivering it", and a `-p` session takes the
key from its `--settings` value, so
`--settings '{"crossSessionInbound":"refuse"}'` on every arm would keep
a peer's message from running as a second turn. Not yet run on an arm.
