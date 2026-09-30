---
status: open
priority: 2
needs: [user]
blocked-by: []
written: 2026-09-30
---

# Handoff: `ListAgents` lists a never-prompted session as a live peer

- **Written**: 2026-09-30, from one inbox note of that day by a session
  landing a branch in a client repo, from VS Code. Re-measured against
  the payload at `c36583a`, which changed nothing in `land` or `commit`
  since the note searched it at `f9372ff`.
- **Kind**: a decision, the user's, then edits to two workflow skills
  and their behaviour retests. Nothing is drafted.

## What happened

`land` step 9 kept the local branch because `ListAgents` listed a second
session in the tree, and "Never `git switch` while another session is
live in the tree" is on its Absolute list. The user knew of no other
session, and when shown the row said they had closed it. Thirty seconds
later, by `Wait-Process`, the process was still running and still
listed, so the switch to `main` and the local delete went back to the
user as two commands. One landing put the question to the user three
times.

The session had run `git switch -c` with that process live, before
`commit` or `land` loaded, so HEAD sat on the branch for both. After the
merge and the remote delete, the tree stayed on a local branch whose
upstream was gone.

## What the listed session was

Measured by the note's session on 2026-09-30 at 09:22 local, extension
`anthropic.claude-code-2.1.284-win32-x64`: two `claude.exe` processes
started two seconds apart under one `Code.exe`, with identical command
lines. Both registry files, `~/.claude/sessions/<pid>.json`, read
`kind: interactive`, `entrypoint: claude-vscode` and one `cwd`. The
landing session's read `busy`, current. The other's read `idle`, its
`updatedAt` 355 ms after its `startedAt` and unchanged since, and no
transcript `.jsonl` existed for its `sessionId`. `ListAgents` printed
it as an `interactive · idle` row, the row a working peer gets.

Re-measured here on 2026-09-30 at 16:37, over the six sessions then
registered on this machine:

- **The signature reproduced.** One session in another repo's VS Code
  window, on 2.1.284, read `idle` with `updatedAt` 277 ms after
  `startedAt`, had no transcript, and `ListAgents` listed it as
  `interactive · idle`, started 11 minutes before. Its command line
  carried the same flags as a prompted session in that window. The five
  others had each been prompted, and each had a transcript and an
  `updatedAt` minutes to hours after its start.
- **The pairing did not.** Nothing started within seconds of it with
  the same command line. The nearest, 27 seconds later under the same
  `Code.exe`, was a `--claude-in-chrome-mcp` helper with no registry
  entry, not a session. Why the extension starts a process nobody
  prompts, and whether it always comes in a pair, is still not
  established, and a never-prompted entry can as well be a panel the
  user opened and has not typed in yet.

## The question

Does a session whose registry entry has not left `idle` since its start,
and whose `sessionId` has no transcript, count as live:

1. For `land`'s moves of HEAD, step 7's default route and step 9's move
   off the branch, and for the local delete that waits on them.
2. For `commit`'s "Ask them". A correction to the note, which says
   `commit` uses the same test: it uses `ListAgents` to find whom to
   ask, not to gate a move, and a `SendMessage` to such a process
   prompts it, making it a session with a transcript that spends a turn.
3. For the first `git switch -c`, which runs before either skill loads.
   `claude/CLAUDE.md` § "Branch naming" says when to branch and names no
   peer check, where this repo's root `CLAUDE.md` does.

Both signals read without messaging the process:

```bash
jq -b '{name, status, startedAt, updatedAt}' ~/.claude/sessions/<pid>.json
find ~/.claude/projects -maxdepth 2 -name '<sessionId>.jsonl'
```

Against relaxing the rule: the registry is undocumented Claude Code
state, which any release can rename or drop; `updatedAt` is not known to
move only on a prompt; and a panel opened a minute ago reads the same,
while its user may type into it next. For relaxing it: the safe answer
costs a round with the user at every landing where such a process is
listed, and "another session is live" reads as false to a user who
never opened one.

Options, none drafted:

- **Keep the rule and make the report exact.** A listed session is
  live, and the report says what it is: never prompted since a given
  time, no transcript, which window. The rounds stay, but the user can
  recognise the process.
- **Exempt it by those two reads**, and keep the rule for any session
  with a transcript or a later `updatedAt`. This moves an Absolute
  constraint, so it lands flagged, and it ties two workflow skills to an
  undocumented format.
- **Let the user clear it by name.** `land` names the process and its
  reads, and a yes for that process lets the move go ahead. This changes
  the Absolute list's "an instruction to do these is a stop", so it
  lands flagged too.

## Where it lands

`skills/workflow/land/SKILL.md`: step 1's "Check whether another session
is live in this working tree", step 9's "With anyone else live, keep the
local branch and say so" and its "Another session is live in the tree"
bullet, and the Absolute bullet "Never `git switch` while another
session is live in the tree". `skills/workflow/commit/SKILL.md` § "When
another session shares this tree", its "Ask them" bullet. Both skills
are behavioural, so either edit owes a `/test-skill` behaviour retest.
Item 3, if the answer reaches it, is a `claude/CLAUDE.md` edit: the
rule, its tell and one date there, the evidence in
`docs/evidence/user-claude-md.md`, then the deploy.

## Not checked

What ends a never-prompted process: the user's close did not within 30
seconds, and nothing here tried. Why the extension starts one. Whether
`updatedAt` moves for anything but a prompt. Whether a CLI session shows
the same signature.

## Scrubbing

The note's client repo is cited by kind and the user's words are
paraphrased. The session re-measured here sits in another client repo
and is not named.

## Re-measure before acting

```bash
grep -n "live in" skills/workflow/land/SKILL.md   # 2026-09-30: lines 56, 439, 483
grep -rn -i -e "never prompted" -e "claude-vscode" skills/ claude/   # 2026-09-30: nothing
ls ~/.claude/sessions/*.json   # the registry's shape then: <pid>.json beside <pid>.<hash>.key
```
