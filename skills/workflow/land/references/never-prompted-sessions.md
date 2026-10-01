# A listed session that was never prompted

Everything behind step 1's exemption: what such a session is, what
[scripts/never-prompted.sh](../scripts/never-prompted.sh) reads to find
one, why any doubt reads as live, and what a switch under one costs.
Step 1 and the Absolute bullet carry the rule; `commit` asks the same
script before it messages a peer.

## What it is

On 2026-09-30 a landing in a client repo, from VS Code on 2.1.284, kept
its local branch because `ListAgents` listed a second session in the
tree. The user knew of none, and when shown the row said they had closed
it; thirty seconds later the process was still running and still
listed, so the switch and the delete went back to the user as two
commands, and the tree stayed on a branch whose upstream was gone. One
landing put the question to the user three times.

The listed process was one of two `claude.exe` started two seconds apart
under one `Code.exe`, with identical command lines. Its registry entry
read `idle`, its `updatedAt` 355 ms after its `startedAt` and unchanged
since, and no transcript existed for its `sessionId`. `ListAgents`
printed it as `interactive · idle`, the row a working peer gets.

The same afternoon another repo's window held one more: `idle` 277 ms
after its start, no transcript, and listed eleven minutes on, with
nothing started near it. Why the extension starts such a process is not
established, and a panel opened and not yet typed in reads the same.

## The two reads

| Read | Where | Never prompted when |
| --- | --- | --- |
| Registry entry | `<config>/sessions/<pid>.json`, the one whose `name` is the row's | `status` is `idle`, and `updatedAt` is under 1000 ms after `startedAt` |
| Transcript | `<config>/projects/**/<sessionId>.jsonl` | there is none |

`<config>` is `$CLAUDE_CONFIG_DIR`, else `~/.claude`. Claude Code
documents neither read, and its times are milliseconds since the epoch.

**`idle` alone says nothing.** On 2026-10-01 an `idle` row was a session
that had committed a minute earlier and exited fourteen seconds after it
was listed; its transcript and its `updatedAt` said prompted.

**`updatedAt` moves for more than a status change**: one session's moved
three and a half minutes past its `statusUpdatedAt` (2026-10-01,
2.1.283). So an `updatedAt` still within a second of `startedAt` means
nothing has touched the entry since the process started, which is
stricter than a status that never changed.

## Why a doubt reads as live

The script passes a name only when exactly one entry carries it, each
field it compares is present with the type above, and the transcript
lookup ran and found nothing. Any other outcome exits 1 and the session
is live: no entry, two (names can repeat, which is when `ListAgents`
adds a `[ref]`), a field renamed or retyped, a half-written file, a
directory gone, no `jq`. A release that changes the format then costs a
round with the user, as every listed session did before, and never a
switch under a peer. `tests/scripts/never-prompted/test-never-prompted.sh`
holds each case.

## What a switch under one costs

A never-prompted session holds no work, but it is not stateless: its
git snapshot is taken when its process starts, not at its first prompt.
On 2026-09-30 a session whose process started 23 seconds before its
first prompt carried a snapshot without a commit made 8 seconds after
it started. A panel typed into after `land` moved HEAD therefore starts
out believing in the branch HEAD was on, until its first `git` read
says otherwise. That stale belief is what the exemption risks, against
a round with the user at every landing where such a process is listed.

**Run the script in the same command as the move, ahead of it.** A
prompt that reaches the session between an earlier check and the switch
makes it a peer, and the chain then stops before the switch. Step 7's
default route, with one row the script passed at step 1:

```bash
bash ~/.claude/skills/land/scripts/never-prompted.sh <name> \
  && [[ "$(git branch --show-current)" == "<branch>" && "$(git rev-parse <branch>)" == "<sha>" ]] \
  && git switch main && git merge --ff-only <branch> && git push origin main
```

An exit 1 there makes the row a peer: step 7 takes its table's second
row, as for a peer who appeared after step 6, and step 9 keeps the local
branch.

## Not established

- What ends such a process: the user's close did not, within thirty
  seconds.
- Why the extension starts one, and whether it always comes in a pair.
- Whether a CLI session shows the same signature.
- Whether anything but a prompt moves a never-prompted entry's
  `updatedAt`. If something does, the session reads as live: the safe
  side.
