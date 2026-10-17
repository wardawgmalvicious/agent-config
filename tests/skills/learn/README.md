# `learn` — behaviour cases

`learn` is unconditional, so it has no activation contract; these three
cases test what its body says in note mode, the mode it runs in outside
this repo, against a `--safe-mode` baseline. Between them they reach
Step 3's destinations, Step 4's coverage search, Step 5's verification
routes and Step 7's note, and they carry the two claims
[brief 09](../../../docs/audits/2026-10-08/prompt-audit/completed/09-correct-the-user-scope-skills.md)
of the 2026-10-08 prompt audit changed: a trigger fix covers
`when_to_use` and its 512 cap (finding 8), and a note carries
**Scrubbing:** (finding 34).

## The cases

| Case | Sent as | Passes when |
| --- | --- | --- |
| `kql` | `/learn` | the Kusto emulator, `--accept-eula` held for the user's agreement, the engine build and `Kusto emulator, <date>; not yet run in Fabric`; no `gotchas.md` row for a one-product error; no `Skill` call, every turn on the session model |
| `hook` | `learn!` | `code.claude.com/docs/en/hooks.md` to read; the version from the session's transcript; the repo's own hook kept out of the note |
| `trigger` | `learn!` | the verb goes in `when_to_use`, measured against 512; `description` left alone |

All three also need note mode: a path under
`~/handoff-inbox/agent-config/`, **Scrubbing:** and **Coverage:**, the
latter naming the tree searched, `/triage` as the next step, and nothing
written. Both `learn!` arms call `Skill learn`. A case measures Steps 5
and 7 only while its learning is uncovered: once `coding-kql` covers
serialized row sets, `coding-bash` PostToolUse, or `prune-branches`'
trigger text says tidy, swap in a learning of the same shape.

The prompts, verbatim, after `/learn ` or `learn! `:

```text
kql: Earlier in this session queries/top_errors_by_service.kql failed in our Fabric Eventhouse with `Function 'row_number' cannot be invoked in current context. Details: the row set must be serialized`. The query went straight from `summarize Errors = count() by Service, ErrorCode` into `extend Rank = row_number(1, prev(Service) != Service)`, and putting `order by Service asc, Errors desc` between the two fixed it; the committed file is the fixed version. The coding-kql rule was loaded when I opened the file and says nothing about row_number, prev or serialized row sets. My reading is that summarize output is not serialized while order by, serialize and top produce serialized output, so any window function needs one of those after the last summarize, but we only ever saw the one failure. Capture this.

hook: Earlier this session our PostToolUse hook, .claude/hooks/lint-on-edit.sh, exited 2 on a ruff failure, and we expected that to block the edit the way a PreToolUse hook's exit 2 blocks a tool call. It did not: the Edit had already landed on disk, and Claude only got the hook's stderr back as feedback, so a bad file sat in the tree until the next edit. The coding-bash rule loaded when I opened the hook, and its Claude Code hooks section explains exit 2 for PreToolUse, PreCompact and SessionStart but never mentions PostToolUse. We have since moved the lint gate to PreToolUse in this repo, so nothing here needs fixing; I want the next session that writes a hook to know.

trigger: Earlier in this session I asked you to tidy up the stale branches in this repo, and the prune-branches skill never loaded: you went straight to `git branch -d` on three branches, one of which still carried unmerged work that I only caught by eye. Typing /prune-branches afterwards ran the proper audit. Its trigger text talks about cleaning up, pruning or auditing branches and never says tidy. Capture this so the next session reaches the skill.
```

## Running them

One scratch git repo per case, outside this repo:

- `kql`: `queries/top_errors_by_service.kql`, the fixed query below,
  and a README naming a Fabric Eventhouse.
- `hook`: `.claude/hooks/lint-on-edit.sh`, a PostToolUse hook that
  exits 2 on a `ruff` failure and is wired nowhere, and a README.
- `trigger`: a README and three branches besides `main`.

```kql
AppErrors
| where Timestamp > ago(1d)
| summarize Errors = count() by Service, ErrorCode
| order by Service asc, Errors desc
| extend Rank = row_number(1, prev(Service) != Service)
| where Rank <= 3
| project Service, ErrorCode, Errors, Rank
```

Run each arm from its case's repo, with
`CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS=1` and a settings file holding
`{"crossSessionInbound":"refuse"}`:

```powershell
claude -p '<prompt>' --output-format stream-json --verbose --model opus --effort max --tools Skill,Read,Grep,Glob --strict-mcp-config --settings <file> --max-budget-usd 6 --disallowedTools 'Read(~/handoff-inbox/**)'
```

The baseline takes `--safe-mode --tools Skill` in place of the payload's
tools. Launch the `kql` arm from PowerShell, since Git Bash rewrites a
leading `/`. Each fence below comes from the first run's failures; the
measurements are in `test-skill`'s `references/reading-a-failure.md`:

- **Baselines hold no file tool.** With them, two found this checkout
  from their own working directory, read the skill off disk and each
  opened a pending inbox note.
- **Every arm is denied the inbox.** A payload arm, with
  `~/.claude/CLAUDE.md` in context, grepped pending notes for a
  duplicate. The deny also hides the inbox README, so a **Scrubbing:**
  field comes from the template alone.
- **Each round gets a fresh directory.** The arms grep their transcript
  folder for the session's version, so a rerun from one directory reads
  what an earlier round read.

## Result, 2026-10-14

All three separated, one run per arm, on 2.1.293, Opus 5.5 at `max`,
against the body `3cd39dc` left:

| Case | Payload | Baseline |
| --- | --- | --- |
| `kql` | pass: the emulator, the licence held for the user's agreement, the build and the not-yet-run-in-Fabric line; no `gotchas.md` row; no `Skill` call, every turn `claude-opus-5-5` | test queries to run in the Eventhouse; no note |
| `hook` | pass: `hooks.md` to read, 2.1.293 from its transcript, and the exit-2 strings read out of that build's binary | the docs cited from memory; a bullet straight into `coding-bash` |
| `trigger` | pass: `when_to_use`'s first clause, 481 to 490 of 512 | `description` edited, no cap in view |

`init` listed 71 commands on a payload arm and 58 on a baseline, `learn`
absent. Each payload arm was refused at the inbox README, and the
`trigger` arm again listing the notes' folder. $5.64 for the six arms;
the stopped first round went unpriced.
