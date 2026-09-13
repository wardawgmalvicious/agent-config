# Reading a failure: the witnesses

`SKILL.md` keeps the symptom table; this file keeps the evidence behind
it — where an activation is recorded, what a `-p` probe emits instead,
how to tell which model served a turn, why the directory a probe runs
in is never the variable, what the write-tool flags leave open, and
what the `--safe-mode` list still carries. Moved out of the skill body
on 2026-09-13 when that body reached the linter's 500-line cap, the
moved text unchanged; the last three sections landed the same day, when
the cap was hit again.

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
