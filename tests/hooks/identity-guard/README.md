# identity-guard hook test

Exercises [claude/hooks/identity-guard.sh](../../../claude/hooks/identity-guard.sh)
without a session: [test-identity-guard.sh](test-identity-guard.sh)
builds throwaway repos, hands the hook the JSON Claude Code would send
for `PreToolUse` / `PostToolUse` on `Bash` and `PowerShell`, and asserts
every exit code.

```bash
bash tests/hooks/identity-guard/test-identity-guard.sh                        # repo copy
HOOK=~/.claude/hooks/identity-guard.sh bash tests/hooks/identity-guard/test-identity-guard.sh   # deployed copy
```

Run the second form after `scripts/link-claude.ps1` — hooks are copies,
so the repo passing says nothing about what is live.

## What it asserts

| Case | Event / command | Expected |
| --- | --- | --- |
| Non-git command, `git log --grep push`, a non-shell tool | any | 0 — never looked at |
| Denylist file absent | `git commit` | 0 — no check, by design |
| Staged diff adds a denylisted term | `git commit` (Bash and PowerShell) | 2 |
| `git -C <path> --no-pager commit` | global options between `git` and the subcommand | 2 — still gated |
| Staged diff *removes* a term | `git commit` | 0 |
| Term only in the unstaged working tree | `git commit` / `git commit -a` | 0 / 2 |
| HEAD message carries a term | `PostToolUse git commit` | 2, and the feedback says to reword |
| Unpushed commit with a term in its message or added lines | `git push` | 2 |
| `git push origin <ref>` names a ref other than HEAD | that ref is what is scanned | 2 / 0 |
| Everything already on the remote | `git push` | 0 |
| Repo under an `exempt:` root | `git commit` with a term staged | 0 |

The denylist is generated with made-up terms (`contoso`,
`fabrikam-tools`) and passed through `IDENTITY_DENYLIST`, so the run
never depends on, or reveals, the machine's real list.

## Traps

- **`jq` on Windows ends lines with CRLF.** Every field the hook reads
  from its JSON input is stripped of `\r`; without that, `tool_name`
  is `Bash\r`, matches nothing, and the hook allows everything. That
  was the first version's failure and every case passed with exit 0.
- **Do not gate on a regex over the command.** An ERE with nested
  quantifiers spanning a Windows path hung glibc's matcher for minutes
  on `git -C "<path>" --no-pager commit`. The hook tokenizes instead.
- **It is slow here, and slow looks like hung.** A process spawn under
  the Claude Code tool shells costs ~0.4 s on this machine (measured
  2026-09-04: 120 git/date spawns in 46 s, the same from a real console
  window), so the full run takes several minutes and any cap under ten
  minutes reports a "hang" that is nothing of the kind. Half a day went
  to that before the arithmetic was done. Run it in the background with
  a long timeout, or from an interactive terminal, and never judge a
  run by a 60-second cap. `HOOK_SHELL="bash -x"` traces the hook itself
  when a case genuinely misbehaves; compare against a direct invocation
  with the same JSON before blaming the script.
