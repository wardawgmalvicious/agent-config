# Handoff: `claude/CLAUDE.md` loads twice in sessions here

- **Written**: 2026-09-24, at the close of the root `CLAUDE.md` trim
  (`61584f5` and the commits around it), which left this out as a
  separate change: the exclude's Windows path matching is unmeasured.
- **Kind**: one key in `.claude/settings.json`, measured first. Project
  scope and deployed nowhere, so once committed it reaches every session
  started here, with no deploy step.
- **Status**: **Open, nothing landed.** The double load has two
  witnesses; whether the exclude matches a Windows path has none.
- **Run in**: this repo, with cold `claude -p` probes. No tenant and no
  deploy.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## The double load

A session here loads `~/.claude/CLAUDE.md` at launch, and Claude Code
loads a subdirectory's `CLAUDE.md` when it Reads a file there. This
repo's `claude/CLAUDE.md` is the source of that same user-scope file, so
the first Read of anything under `claude/` loads it a second time. On
2026-09-24 the two were byte-identical: 188 lines and 9,913 bytes each.

Two witnesses, both 2026-09-24 on 2.1.281:

- **Transcripts.** Two cold `claude -p` probes from the repo root Read
  files under `claude/`, and each transcript holds a `nested_memory`
  attachment for `C:/Repos/Personal/agent-config/claude/CLAUDE.md`.
  Session `65de8af5` Read only `claude/mcp/.mcp.global.template.json`
  and `copilot/.source-hashes.json`, and got it beside the
  `deploy-scripts.md` and `copilot-payload.md` rules; session `e9ff8b72`
  got it among its fifteen `nested_memory` attachments.
- **The hook log.** The user-scope `InstructionsLoaded` hook writes every
  load to `~/.claude/logs/instructions-loaded.log`. It held 15
  `nested_traversal` loads, dated 2026-08-28 to 2026-09-24, and **every
  one was `agent-config/claude/CLAUDE.md`**: the only nested load this
  machine has logged, and one that ordinary sessions hit, not only
  probes.

It recurs after `/compact`, since a nested `CLAUDE.md` reloads as Claude
reads files it applies to (docs, below). And it costs more than bytes:

- `claude/CLAUDE.md` is the user-scope payload, not guidance for editing
  `claude/`. `.claude/rules/editing-claude-md.md` rules out a
  subdirectory `CLAUDE.md` here for exactly this load; this one exists
  only because the deployed file's name is fixed.
- While `claude/CLAUDE.md` is being edited, the nested copy is the new
  text beside the deployed old one: two versions of one set of
  instructions in one context. The Read before the edit already shows
  the new text.
- A clone that never deployed hands its session the user's machine
  instructions on its first Read under `claude/`.

## The setting, per the docs

From `code.claude.com/docs/en/memory`, fetched 2026-09-24, on when a
subdirectory's file loads:

> Claude also discovers `CLAUDE.md` and `CLAUDE.local.md` files in
> subdirectories under your current working directory. Instead of
> loading them at launch, they are included when Claude reads files in
> those subdirectories.

And on the setting:

> Patterns are matched against absolute file paths using glob syntax.
> You can configure `claudeMdExcludes` at any settings layer: user,
> project, local, or managed policy. Arrays merge across layers.

A managed-policy `CLAUDE.md` cannot be excluded, and the patterns apply
to `AGENTS.md` too; none is tracked here. The page's examples are
`**/monorepo/CLAUDE.md` and a POSIX absolute path. **Nothing on it says
how a Windows path is matched.** No settings file on this machine set
`claudeMdExcludes` on 2026-09-24.

## The Windows question is the whole test

The candidate is one entry in `.claude/settings.json`:

```json
"claudeMdExcludes": ["**/claude/CLAUDE.md"]
```

A `**/` lead names no drive and no user path, so it can be committed,
and it serves a clone as well. What is unmeasured is whether it matches
this machine's paths at all. Each of the 4,020 parseable lines in the
hook log records a backslashed path, and the drive letter's case is not
stable: the log's `cwd` reads `c:` 3,121 times and `C:` 899 times, its
`file_path` `c:` 1,358 times and `C:` 2,662 times. So a forward-slash
glob works only if Claude Code normalizes separators before matching,
and a pattern naming the drive could match one launch and miss the
next. **A pattern that matches nothing fails silently**, like a wrong
`paths:` glob.

It must not over-match either. `~/.claude/CLAUDE.md` sits in `.claude`,
not `claude`, so the candidate should miss it; prove that rather than
assume it. Only two `CLAUDE.md` files are tracked, root and
`claude/CLAUDE.md` (`git ls-files '*CLAUDE.md'`).

## The test

Measure through `--settings <scratch file>`, not by editing
`.claude/settings.json`, which is live for every session started here
while it stands. Run one cold probe per variant from the repo root,
pinned to Read as activation probes are
(`.claude/rules/activation-testing.md`):

```bash
claude -p 'Read claude/mcp/.mcp.global.template.json with the Read tool, then reply done' \
  --model haiku --output-format json --settings "<scratch>/<variant>.json" \
  --allowedTools Read --disallowedTools Bash PowerShell Grep Glob Write Edit NotebookEdit
```

| Variant | `claudeMdExcludes` | Answers |
| --- | --- | --- |
| control | none | whether today's CLI still loads it twice |
| candidate | `**/claude/CLAUDE.md` | the only committable form |
| absolute | `C:/Repos/Personal/agent-config/claude/CLAUDE.md` | whether an absolute path matches |
| lower drive | the same, with `c:/` | whether the drive letter's case matters |
| backslash | the same, with JSON-escaped `\\` separators | whether separators are normalized |

The last three are for the ledger, to record how a Windows path
matches; none gets committed.

Read the result off each probe's transcript,
`~/.claude/projects/<project>/<session id>.jsonl`, taking the session id
from the JSON result:

- its `instructions` attachment lists the files loaded at launch, by
  path;
- each `nested_memory` attachment is a file loaded on a Read, rules and
  nested `CLAUDE.md` alike.

The hook log is a second witness, read through
`scripts/instructions-log`, which skips the log's unparseable lines (24
of 4,044 on 2026-09-24). An absence there proves nothing: two probes
launched in parallel from one script that day logged no line at all.

The candidate passes when all three hold:

1. No `nested_memory` attachment for `claude/CLAUDE.md` follows the
   Read.
2. `deploy-scripts.md` still attaches on that Read: the exclude leaves
   rules alone.
3. The `instructions` attachment still lists root `CLAUDE.md` and
   `~/.claude/CLAUDE.md`.

Then commit the entry to `.claude/settings.json`, re-run the candidate
probe with no `--settings` so the committed file is what gets proven,
and run `pre-commit run --all-files`: `lint-skill-overrides.py` parses
that file.

If no variant matches, stop and put it to the user. Every fallback
costs something:

- An absolute pattern in the gitignored `.claude/settings.local.json`
  fixes one machine, and misses whenever the drive letter's case flips.
- Keeping the payload under another name and deploying it as
  `CLAUDE.md` touches `link-claude.ps1`, `lint-claude-md.py`, its hook's
  `files:` pattern and every citation of `claude/CLAUDE.md`.
- Leaving it costs 9,913 bytes on a session's first Read under
  `claude/`, and again after each `/compact`.

## Where it is written down

A JSON file takes no comment, so the reason goes in prose.
`.claude/rules/editing-claude-md.md` opens with where each `CLAUDE.md`
loads, so a clause there reaches whoever edits either file. Root is at
192 of 200 lines, and a line added there has to move another out. The
evidence goes to `docs/evidence/root-claude-md.md` as a dated entry at
the end of § "Editing conventions": both witnesses above, each variant's
result, and the CLI version.

## Out of scope

- User scope. The double load happens only in sessions in this repo, so
  the key belongs in project settings.
- Any other `CLAUDE.md`. A worktree under `.claude/worktrees/` carries
  its own `claude/CLAUDE.md`, which the candidate matches too; that is
  right, and [worktree-isolation-scope.md](worktree-isolation-scope.md)
  needs nothing from it.
