# Reading a failure: the witnesses

`SKILL.md` keeps the symptom table; this file keeps the evidence behind
it — where an activation is recorded, what a `-p` probe emits instead,
how to tell which model served a turn, and why the directory a probe
runs in is never the variable. Moved out of the skill body on 2026-09-13
when that body reached the linter's 500-line cap; the text is unchanged.

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
