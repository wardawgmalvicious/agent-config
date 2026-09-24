---
paths:
  - "tests/README.md"
  - "tests/*/*/README.md"
  - "tests/skills/*-triggers/expected_activations.md"
  - "scripts/test-activation.ps1"
  - "scripts/activation-expect.py"
  - "scripts/skill-telemetry.py"
  - "scripts/instructions-log"
---

# Activation testing, and what can witness an activation

- Activation is keyed to the `Read` tool, not to the file: a `cat` through
  Bash, or a `Grep`, loads no skill and no rule, and auto mode, which every
  session on this machine starts in, prefers `cat`. `--allowedTools` alone
  removes nothing, so a probe measuring activation pins
  `--allowedTools Read --disallowedTools Bash …` and asserts each `tool_use`
  really was a `Read` (2026-09-01).
- The session transcript, `~/.claude/projects/<project>/<session-id>.jsonl`,
  is the one complete witness. A skill match appends a
  `{"type":"attachment"}` record whose `attachment.type` is `skill_listing`,
  with `isInitial` false and `names` naming the skills; a rule match appends
  a `nested_memory` attachment naming the rule file (2026-09-01, 2.1.252).
- `isInitial: true` is the startup listing: its `names`, `skillCount` and
  rendered `content` are the only record of what was offered, which
  separates "listed and not chosen" from "never listed".
- `isInitial: false` is not proof of a glob match. Editing a `SKILL.md`
  re-announces that skill, and a `link-claude.ps1` run re-announces all it
  deployed, each indistinguishable from an activation; in this repo they are
  most of the deltas (2026-09-03). A delta witnesses activation only if
  nothing wrote that skill earlier in the session. `skill-telemetry.py`
  subtracts the explainable ones, and anything else counting deltas must.
- No log sees a skill's conditional activation. `skills-invoked.log` and
  `skillUsage` count invocations, and a path-triggered skill is loaded,
  never invoked. `instructions-loaded.log` logs `CLAUDE.md` and rule loads,
  path matches included, never skills, and missed two of four confirmed rule
  loads in short `claude -p` sessions (2026-09-01). `--debug-file`'s
  `N conditional skills stored` and
  `Sending N skills via attachment (initial)` both print before any Read. An
  absence in any of them proves nothing.
- A skill match injects its listing entry, not its body, which loads only on
  invocation: cost a skill activation at listing size. A rule match injects
  the whole rule.
- Activation is a per-session cumulative delta, for rules and skills: a
  second file matching something already active emits nothing. That is
  deduplication, not a failed match, and no base for a per-file cost model;
  it is also why one session covers a whole fixture set. Attachments flush
  in batches, so attribute one to the run of files Read since the last.
- Directory properties do not matter: a scratch directory outside any repo
  activates exactly as this repo does, given the same user-scope payload.
  Not being a git repo, sitting under `AppData/Local/Temp`, lacking
  `.claude/settings.json`, an 8.3 short path and fixture depth were each
  ruled out, so control the tool, not the directory. This repo's own
  `.claude/rules/` and `.claude/skills/` do not travel.
- `./scripts/test-activation.ps1 -Set pbip|fabric` runs the real-path test:
  deploy to a throwaway probe, one cold session, a transcript assertion,
  teardown in a `finally`. `-StaticOnly` checks the globs against the tables
  alone with no session, which makes it the cheap regression; it prints
  fixtures checked, not a skill count. A cold session only proves the
  harness agrees with the globs.
- `scripts/instructions-log` queries the two hook logs: rule loads,
  unreliably, and skill invocations, never a skill's `paths:` activation.
- Another session may be editing an `expected_activations.md` too. Re-read
  it right before each edit, or your write silently drops their rows, and
  leave a line that is not in `HEAD` to them: root § "Branching and
  concurrent sessions" has the check (2026-09-02).
