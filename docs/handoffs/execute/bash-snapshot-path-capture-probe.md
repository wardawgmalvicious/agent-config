# Handoff: probe — did the profile-stdout fix reach the snapshot?

- **Written**: 2026-09-22, from finding 4 of the inbox note
  `~/handoff-inbox/agent-config/2026-09-22-bash-snapshot-and-mcp-credential-env.md`,
  after the user reported the `.bashrc` side already corrected in
  `machine-config`.
- **Kind**: one verification probe. **No payload edit.** It produces the
  measurement that finding 4's worked example in
  [bash-snapshot-and-mcp-credential-env.md](bash-snapshot-and-mcp-credential-env.md)
  is written against — present tense or past tense, and whether the rule
  ships with a live example or a dated one.
- **Status**: **Open.** The fix is reported landed in `machine-config`;
  nothing on the agent-config side has confirmed it reaches a Claude Code
  shell snapshot, and the session that found the problem cannot check.
- **Run in**: a **fresh session**, any repo. The snapshot is per session,
  not per repo.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## What was measured broken

Session `agent-config-be`, 2026-09-22, CLI 2.1.268. `$PATH` in the Bash
tool began with the profile's startup banner, ANSI escapes and all:

```text
^[[32mProfile and functions loaded. Azure: none, personal (repo) has no tenant^[[0m
^[[33mCheck configs\azure\config for Azure CLI settings.^[[0m
/c/Users/<user>/bin:/mingw64/bin:/usr/local/bin:...
```

Line 221 of that session's snapshot under `~/.claude/shell-snapshots/`
held the same string as its single `export PATH=...`. The peer session
that filed the note reproduced it across all five snapshots then present
on the machine, with the banner text varying by the tenant pinned at
capture time — which is also what shows the capture happens once per
session start.

A third session, `agent-config-d1`, reported the same reading from a
**different file** — `snapshot-bash-1790121658018-wd2w9y.sh` against the
note's `-1790120456592-b1arcf` — with the banner again at line 221 and
`grep -c '^export '` again returning 1. Three sessions, three files, one
structure. That is the pre-fix baseline this probe is measured against;
read a `fail` against these rather than against a recollection.

**The practical cost on that date was zero, and the brief should say so
rather than imply urgency.** The swallowed entry is `/c/Users/<user>/bin`,
which does not exist on this machine. `~/scripts` survived at PATH
position 36 and `network-doctor.ps1` resolved from it normally. What the
corruption actually buys is a live booby trap: the next banner edit, or
the next directory added ahead of `~/scripts`, swallows something real.

## The mechanism, stated precisely — it is not "the profile runs per call"

Worth getting exactly right in the probe's write-up, because the obvious
summary is wrong in a way that makes the probe look like it passed.

The Bash tool does **not** source the profile per call. `/proc/$$/cmdline`
reads `bash -c source ~/.claude/shell-snapshots/snapshot-bash-<id>.sh ...
&& eval '<your command>'` — no `-l`, no profile. The profile runs **once,
at session start, in the login shell that generates the snapshot**. That
generator serializes the profile's *functions* into the snapshot and
captures `PATH` by reading the shell's output — so anything the profile
printed to **stdout** during generation lands inside the captured `PATH`
value.

That single mechanism explains all three symptoms at once: functions like
`AzLogin` are present, exported variables other than `PATH` are absent,
and the banner is inside `PATH`.

## Why the finding session cannot run this probe

Snapshots are generated at session start and the old ones persist on
disk. A session that began before the `.bashrc` fix is still sourcing a
pre-fix snapshot and will keep reporting the old reading for its whole
life, however many times it re-measures. `agent-config-be` is such a
session.

So: **fresh session, started after the `machine-config` fix commit.**

## The probe

Four commands, one Bash tool call, in a session started after the fix.

```bash
# 1. Which snapshot did THIS session actually source? Do not guess by mtime.
tr '\0' ' ' < /proc/$$/cmdline | grep -o 'snapshot-bash-[^ ]*\.sh'

# 2. Live PATH, first 120 chars, escapes made visible.
echo "$PATH" | head -c 120 | cat -v

# 3. Is PATH's first element a real directory?
echo "$PATH" | tr ':' '\n' | head -1 | cat -v

# 4. The snapshot's own export line.
grep -n "^export PATH" ~/.claude/shell-snapshots/<the file from step 1> | head -c 200 | cat -v
```

**Pass** — every one of:

- Step 2 shows no `^[` escape and no banner text.
- Step 3 names a directory that exists (`test -d` it).
- Step 4's line begins `export PATH='/` or equivalent, with no banner.

**Fail** — any banner text inside `PATH`, in either the live value or the
snapshot.

## Two traps that will make you read the result wrong

**The banner still appearing in tool output is not a failure.** If the
fix was "print to stderr" rather than "print only when interactive", the
banner is still emitted and the Bash tool still shows it — stderr is
captured and displayed. The assertion is about `PATH`, nothing else.
Judging the fix by whether you can still see the banner will report a
false failure on a correct fix.

**A stale snapshot is not a failure either.** Confirm the snapshot named
in step 1 has an mtime *after* the `machine-config` fix commit before
reading a fail as real:

```bash
ls -l --time-style=full-iso ~/.claude/shell-snapshots/<file from step 1>
```

If it predates the fix, the session predates the fix. Start another one.

## Also worth one line while you are in there

`pwsh` is launched `-NoProfile`, so the PowerShell profile never runs in
a tool call and cannot be captured this way. The note flags that
`machine-config`'s PowerShell profile deserves the same stdout check
anyway — that is **that repo's** call, not this one's, and it is not part
of this probe. Do not widen the probe to cover it.

## What to do with the result

- **Pass** → finding 4's worked example in the sibling brief becomes past
  tense with the fix date, and
  [claude/rules/coding-bash.md](../../../claude/rules/coding-bash.md)
  still gets the rule. The rule is the durable artifact; the incident is
  only its evidence, and a fixed incident is no argument against a rule
  that prevents the next one.
- **Fail** → the `machine-config` fix did not reach the capture path.
  Say so in a note back to `~/handoff-inbox/machine-config/` rather than
  fixing it here; the `printf`s are that repo's file. Record the failing
  snapshot id and its mtime.

Either way, record the reading and its date in the sibling brief before
deleting this one.

## Dependencies

- Sibling to
  [bash-snapshot-and-mcp-credential-env.md](bash-snapshot-and-mcp-credential-env.md),
  which carries the payload edits from the same inbox note. That brief
  does **not** block on this probe — the `coding-bash.md` rule lands
  either way; only the tense of its worked example depends on the result.
- The inbox note the pair came from stays in `~/handoff-inbox/agent-config/`
  until **both** are spent and the user explicitly approves the delete.
