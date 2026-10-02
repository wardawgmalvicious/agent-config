---
status: open
priority: 2
needs: [user]
blocked-by: []
written: 2026-10-01
---

# Handoff: two Shell traps wait for room in `claude/CLAUDE.md`

- **Written**: 2026-10-01, from two inbox notes of 2026-09-30 and
  2026-10-01 by sessions in a client Fabric Git-sync sandbox repo, in the
  Claude Code VS Code extension. Re-measured against the payload at
  `4f473d2`, where `claude/CLAUDE.md` is at its 200-line cap since
  `831d697`; the notes measured 197 and 199.
- **Kind**: a decision, the user's: which lines leave `claude/CLAUDE.md`
  for its ledger, about four, so these land. Both bullets and their
  ledger entries are drafted below. The two `claude/CLAUDE.md` edits the
  same triage landed were rewrites at zero net lines.

## 1. A link to a scratchpad file opens nothing

The scratchpad lives under `%TEMP%`, outside every workspace, and the VS
Code extension's prompt makes links workspace-relative, so a link to a
scratchpad file neither navigated nor opened it (observed 2026-09-30;
the user reports earlier occurrences, and asked for the rule). The
harness also hands the scratchpad over in 8.3 form,
`C:\Users\<USERNA~1>\…`, re-measured in this session's own prompt.
`cygpath -lw` expands it, exit 0, and `cygpath -l -u` prints its usage
text, so a test built on it answers "no" for a file that exists
(re-measured 2026-10-01). Untested: whether a `file:///` or
`vscode://file/` link opens.

```diff
 - **`/tmp` is `C:\tmp` to a native child**, which raises `FileNotFoundError`
   (2026-09-15). Use the scratchpad, or `cygpath -w`.
+- **A link to a scratchpad file opens nothing** (2026-09-30): give its path
+  in a code block, expanded from 8.3 (`USERNA~1`) by `cygpath -lw`.
```

## 2. A native program can't open `<(...)`, and a `diff` of two passes

Process substitution hands a command `/proc/<pid>/fd/63`, which exists
only inside the MSYS runtime. MSYS programs open it; a native one gets
the path verbatim. Re-measured here 2026-10-01 (GNU bash 5.3.15, MSYS
3.6.9, winget `jq` 1.8.2): `jq -b . <(echo '{"a":1}')` printed `Could not
open file /proc/<pid>/fd/63` and exited 2; `diff` of two such calls on
different objects exited 0; the piped form differed, exit 1;
`python3.13` received `'/proc/<pid>/fd/63'` as its argument. The original
hit was three false passes in one command comparing a JSON object across
two commits; behind `2>/dev/null` nothing would have shown. Same root as
the `/tmp` bullet. Untested: `/dev/fd/N`, `/dev/stdin`, and native
programs beyond `jq` and `python3.13`.

```diff
 - **Native `jq` writes CRLF** (1.8.2, 2026-09-30): `comm` and `diff` miss
   every LF line, `read` keeps the `\r` and `> file` is CRLF, while `grep`
   and a one-line `$(...)` hide it. Pass `-b` always, not only for payloads.
+- **Pipe into a native program, never `<(...)`** (2026-10-01): `jq` fails
+  on `/proc/<pid>/fd/63`, prints nothing, and a `diff` of two calls passes.
```

A one-line fallback, appended to the `jq` bullet at the cost of the
generalization: `It can't open <(...) either (2026-10-01): empty, so a
diff passes.`

## Where it lands

`claude/CLAUDE.md` § Local environment → Shell traps, and
`docs/evidence/user-claude-md.md` § Shell traps: a new `####` entry for
each, after "`/tmp` is two directories…" and "Native `jq` writes CRLF to
stdout", carrying the measurements above. Then the deploy:
`./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`.

## Not checked

Why the absolute link failed in the extension; the untested paths named
in each section.

## Scrubbing

The profile folder is `<username>` and its 8.3 form `USERNA~1`; the
client repo's commits and item names are left out.

## Re-measure before acting

- `uv run scripts/lint-claude-md.py`: 200 of 200 on 2026-10-01.
- `jq -b . <(echo '{}'); echo $?` in Git Bash: exit 2 on 2026-10-01.
