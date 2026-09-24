# Reading a failure: the witnesses

`SKILL.md` keeps the symptom table; this file keeps the evidence behind
it — where an activation is recorded, what a `-p` probe emits instead,
how to tell which model served a turn, why the directory a probe runs
in is never the variable, what the write-tool flags leave open, what
the `--safe-mode` list still carries, and what it leaves within reach.
Moved out of the skill body on 2026-09-13 when that body reached the
linter's 500-line cap, the moved text unchanged; later sections landed
the same day, each time the cap was hit again.

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
