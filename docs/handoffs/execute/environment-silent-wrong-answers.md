# Handoff: four more commands on this machine that return a wrong answer with exit 0

- **Written**: 2026-09-22, consolidating the environment halves of two
  inbox notes —
  `2026-09-22-no-tzdata-and-shared-tree-commit-guard.md` learnings 1, 3
  and 4's sibling, and
  `2026-09-15-land-in-a-shared-tree-and-windows-file-writes.md`
  learnings 2 and 5 — plus one item from
  `2026-09-22-kusto-alter-table-semantics-and-branch-consumers.md`
  learning 6 that is listed here mainly so it can be declined on the
  record.
- **Source notes deleted** 2026-09-22, with the user's explicit approval,
  once this brief carried their content — so this file and `git log` are
  now the only record of them.
- **Kind**: prose additions to `claude/CLAUDE.md` § "Local environment"
  and its Python subsection, one addition to
  `claude/rules/coding-bash.md`, and one clause in
  `skills/workflow/commit/references/concurrent-sessions.md`. Deploys by
  **copy** except the last, which is junctioned.
- **Status**: **Open, nothing landed.** Items 1 and 2 are reproduced and
  should land. Item 3 is reproduced but must argue for its slot. Item 4
  is a design rule carried on the user's explicit choice, never a
  measured failure, and says so. Item 5 is a **declination candidate**.
- **Run in**: this repo.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## The class, and the one item that is not in it

`claude/CLAUDE.md` already collects a specific failure shape and names
it repeatedly without naming the class: **exit 0, plausible output,
wrong.** `grep -c $'\r'` counting carriage returns in both directions.
`"$TMPDIR/x"` writing into the Git install. `/tmp` resolving to two
different directories either side of the MSYS boundary. Python's cp1252
stdout dying mid-print.

Items 1, 2, 3 and 5 below are four more of exactly that. Item 4 —
secrets on argv — is **not**; it is a design rule that rides along
because it came from the same note and lands in the adjacent file. It is
kept separate rather than filed under a heading it does not belong to.

**The reason the class matters more than any member:** every one of these
defeats the obvious verification by the same mechanism that causes it.
Where a translation layer sits on both the read and the write, a
round-trip check proves nothing. Go under it, or check from the other
side. That sentence is arguably the most valuable thing in this brief
and it belongs in the file whatever else is declined.

---

## 1. No IANA tzdata: `TZ=America/… date` silently answers GMT

**Reproduced twice, different inputs, and this one should land.**

A bash wrapper needed "now minus N days, in the source system's local
zone". `TZ='<zone>' date -d "7 days ago" '+%Y-%m-%d %H:%M:%S'` returned a
timestamp, exit 0, nothing on stderr — and `TZ='<zone>' date '+%Z %z'`
under the same zone printed `GMT +0000`. The filter would have looked
right and been four hours wrong, matching nothing for the first four
hours of every window.

**Root cause, both sides.** Git for Windows' MSYS2 runtime ships no IANA
database — `ls /usr/share/zoneinfo` answers *no such file or directory*
— and coreutils `date` falls back to UTC for a `TZ` it cannot resolve,
labelling it `GMT` with no diagnostic. That is ordinary C-library
behaviour, so there is nothing to report upstream. uv's CPython has the
same hole from the other side: `zoneinfo` reads the system database
first and falls back to the `tzdata` PyPI package, and with neither
present `ZoneInfo('America/Chicago')` raises
`zoneinfo._common.ZoneInfoNotFoundError`, exit 1. `python3.13`, the uv
shim, behaves the same.

**Note which half is loud.** Python *raises*; bash returns an answer.
Only the bash half is in the silent class, and it is the half that
wrecked the filter.

**Correct approach.** Convert in Python with the package pulled in for
the call, and treat `--with tzdata` as **required rather than
belt-and-braces**:

```bash
uv run --no-project --with tzdata python -c '...'
```

Measured 2026-09-22 23:09Z cold: `Installed 1 package in 237ms`, `real
0m2.649s`; cached thereafter. Or do it in .NET from `pwsh`, which
resolves IANA ids itself and needs nothing installed —
`[TimeZoneInfo]::FindSystemTimeZoneById('America/Chicago')` then
`[TimeZoneInfo]::ConvertTimeFromUtc([datetime]::UtcNow, $z)`, which gave
`2026-09-22 20:22` with `IsDaylightSavingTime` true at 01:22Z on
pwsh 7.6.6. **Never `date` with a `TZ` other than UTC.**

**The tell to write down:** `date '+%Z'` printing `GMT` for a zone that
is not GMT.

**Destination.** `claude/CLAUDE.md` § Local environment, a new `###`
subsection beside "Counting carriage returns", since it spans bash and
Python. Optionally one line in `claude/rules/coding-bash.md` § Preflight:
zone arithmetic goes through `uv run --with tzdata`, and `uv` is then a
tool to preflight.

**Verification.** 2026-09-22 23:08Z: two `America/…` zones →
`GMT +0000`; no `/usr/share/zoneinfo`; the `zoneinfo` traceback.
2026-09-23 01:19Z: `America/Chicago`, `Europe/London` and `UTC` all
`GMT`; `--with tzdata` → `20:19 CDT`; the `pwsh` path as above. git
2.55.0.windows.3. **Use a neutral zone in the landing text** — the
original measurement used the origin estate's configured zone, which
names its source system's locale; `America/Chicago` is already to hand
from the second run.

---

## 2. `Path.write_text()` on Windows writes CRLF, and `read_text()` hides it from the obvious assertion

**Reproduced twice, and this is the sharpest member of the class.**

A six-line edit applied to two tracked Markdown files with
`Path.write_text()` staged as **440 insertions / 408 deletions** — every
line of both files rewritten. The script had asserted
`s.count(chr(13)) == 0` and passed. One commit had already captured a
file as `i/crlf` before the staging count gave it away.

**Two halves, and the second is what makes it dangerous.** Text-mode
writes on Windows translate `\n` to `os.linesep`, so `write_text()` puts
`\r\n` on disk. Text-mode *reads* enable universal newlines and
translate it back — so an in-Python CR check reads the translated string,
never the bytes, and **cannot** see the corruption it is meant to catch:

```text
bytes actually on disk : b'a\r\nb\r\n'
CR count, read_bytes   : 2
CR count, read_text    : 0     <-- the assertion that passed
after write_bytes      : b'a\nb\n'
```

**There is no general "git will catch it."** In the repo at hand
`core.autocrlf` was `false` and `.gitattributes` covered several
directories plus a **root-anchored** `/*.md`, so `git check-attr text
eol` on `docs/handoffs/*.md` returned `unspecified` for both and nothing
normalized the file. A repo can be configured so nothing does.

**Correct approach.** Rewrite tracked text files in binary —
`read_bytes()` / `write_bytes()` — or pass `newline=""` to `open()`.
**Verify on the byte side, never the text side**: `tr -cd '\r' < f | wc
-c` must print `0`, or `git ls-files --eol <path>` must read
`i/lf w/lf`. Treat an implausible insertion/deletion count on a small
edit as the tell.

**Two destinations, and the split matters** because one is adjacent to
text that must not be duplicated:

- `claude/CLAUDE.md`, **the Python subsection**, beside the cp1252
  stdout paragraph it rhymes with — the general fact, the `read_text`
  blindness, and the binary remedy. This is the missing home: today the
  fact exists only inside a patch-cutting reference.
- [`commit/references/concurrent-sessions.md`](../../../skills/workflow/commit/references/concurrent-sessions.md)
  lines 41–51 **already cover the cause and the `tr -cd` check** for
  patch files. Add **only** the false-assertion warning — that an
  in-Python CR count on `read_text()` output is a green light on a CRLF
  file — and at most a pointer to the general fact. Do not restate the
  mechanism there.

**Verification.** Reproduced twice by the filing session: `git ls-files
--eol` read `i/crlf` after `write_text` and `i/lf w/lf` after the binary
rewrite; the four-line transcript above run standalone 2026-09-15 under
`uv run --no-project python`. **And once more in this repo, 2026-09-22**,
in the session that wrote this brief — a Python rewrite of a tracked
`.md` through `io.open(..., newline='')`, checked afterwards with both
`git ls-files --eol` (`w/lf`) and `tr -cd '\r' | wc -c` (`0`), with the
diff coming back 150/20 rather than whole-file. That is the remedy
working, which is the half the original note could only assert.

---

## 3. GitHub API timestamps are UTC, so a date derived from one is wrong for a third of every day

Two handoff documents were written carrying the **next day's date** in
four places, on a day that was locally the previous one throughout.
Caught in review before any commit, and only because the dates
contradicted PR merge times stated elsewhere in the same documents.

`gh pr view --json mergedAt` returned a `Z`-suffixed timestamp just past
midnight UTC. Read as a wall clock it says tomorrow; at UTC−4 it is
late evening today. **Every GitHub API timestamp is UTC**, and on a US
machine that makes the last four to five hours of every local day report
as tomorrow.

**Correct approach.** Date documents and commit messages from the local
clock — the harness supplies today's date directly — and never from an
API timestamp. Where an API timestamp is quoted, convert it explicitly
and show both, so a `Z` string cannot silently read as a different day.

**Generalization.** A `Z`-suffixed timestamp is correct data and a wrong
answer to "what is today". The failure is near-invisible because it is
off by exactly one day and only in the evening, so it survives
proofreading and reproduces inconsistently.

**Weigh the slot, and the note already did.** `claude/CLAUDE.md` is long
and the slot is expensive. The honest case for it there rather than in a
skill is that the trap fires anywhere a date is written — a commit
message, a handoff, a changelog — so scoping it to `land` or `commit`
leaves the other callers uncovered. **If it is refused a slot**,
`skills/workflow/land/SKILL.md` step 8 is the fallback, since that is
where `mergedAt` is actually read.

**Note the interaction with item 1.** Both are timezone traps and both
want § Local environment. They are *different* failures — one is a
missing database, one is correct data read against the wrong clock — but
landing them as two adjacent subsections with no cross-reference would
invite a later reader to merge them and lose one. Either write them as
one subsection covering both, or cross-reference explicitly.

---

## 4. A secret never travels on argv, and `coding-bash.md` has no credential-handling rule

**Not a member of the class above**, and filed here only because it came
from the same note and lands in the adjacent file.

A wrapper mints an OAuth token by POSTing a form body carrying four
long-lived secrets to a vendor token endpoint. The obvious
`curl --data "$BODY"` puts all four on curl's command line — readable in
`ps -ef`, Task Manager's command-line column and
`Win32_Process.CommandLine` by any process on the machine for the life of
the call, and captured by anything logging process starts.

Nothing in the rules says otherwise. `coding-bash.md` § Preflight covers
tool presence and *minting* a token (`az account get-access-token`) but
not how a secret is handed to a child process.

**Correct approach.** A secret reaches a child on stdin, in a file the
caller owns, or in the environment — **never as an argument**:

```bash
TOKEN_RESPONSE=$(printf '%s' "$TOKEN_BODY" | curl -sS -X POST "$URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data @- )
unset TOKEN_BODY
```

The same applies to a bearer header on later calls:
`-H "Authorization: Bearer $TOKEN"` is argv too. curl reads headers from
a file with `-H @file`, and `--config -` (`-K -`) takes both `header =`
and `data =` lines from stdin when one call needs both protected. The
origin script does the body on stdin and the bearer on argv — the
inconsistency a rule would have caught.

**Generalization.** *"Where does this value become visible?"* is the
question, and argv is the answer that gets forgotten: world-readable by
design on every OS, and unlike a file it has no permission bits to set.

**Destination.** `claude/rules/coding-bash.md` — a short `## Secrets`
heading between Preflight and Paths, or a paragraph closing Preflight.
Confirmed 2026-09-22 that no such heading exists: the file's headings are
Baseline, Header block, Strict mode, Preflight, Paths, Output streams,
Quoting and tests, Claude Code hooks, Anti-patterns.

**Evidence status, and it must ship with the text.** This is a **design
decision applied 2026-09-22, not a measured failure.** argv visibility is
documented OS behaviour and needed no reproduction. It is carried on the
user's explicit choice, and saying so is what stops a later drift audit
hunting for a measurement that was never taken.

---

## 5. Exit codes read from a command that did not produce them — a declination candidate

**Listed so it can be declined on the record**, which is the note's own
recommendation for it.

Two misreadings of the same shape, in one session: `cmd | tail -15; echo
$?` reporting `tail`'s status rather than the command's; and a
branch-cleanup chain exiting 1 solely because `git branch -a | grep -c
<pattern>` found **zero** matches — where zero *was* the success
condition. The chain reported failure on the outcome it was checking for.

`$?` after a pipeline is the last element's, and `grep` exits 1 on no
match, so **any verification of an absence has an exit code inverted from
its intent** — which is most cleanup and post-merge checks.

**The fact is already covered; the gap is about when the rule loads.**
`claude/rules/coding-bash.md` § Strict mode covers the grep half well, as
errexit behaviour 1, with the `|| true` remedy. Two things it does not
reach:

- It is framed for **scripts** running `set -euo pipefail`. Both failures
  were **ad-hoc agent tool calls** — no script, no strict mode.
- `coding-bash.md` is path-scoped and auto-loads only when a `.sh` file
  is in session scope. Neither failure had one open, so the rule that
  covers this was never in context.

`${PIPESTATUS[0]}` appears **only** in `skills/meta/learn/SKILL.md`
step 5 — which loads when `/learn` is invoked, i.e. after the mistake,
never during the work.

**The case against landing it.** The only home that would actually fire
is `claude/CLAUDE.md`, which is expensive real estate under a stated lean
constraint, and the payoff is one clause restating a fact the rules
already carry. **Declining is a real outcome** — record the reasoning in
the commit that lands the rest, per [README.md](README.md) § "A brief can
be a decision rather than an edit", so this is not rediscovered as a gap
in three weeks.

---

## Deployment

`claude/CLAUDE.md` and `claude/rules/` deploy by **copy**:

```powershell
./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force
```

Never bare — see [CLAUDE.md](../../../CLAUDE.md) § Commands. `-Force` is
required for `claude/CLAUDE.md`. Item 2's second destination is under
`skills/workflow/`, which is **junctioned**, so that half is live on save
and the other half is not — do not read the skill edit taking effect as
evidence the `CLAUDE.md` edit did.

## Verification

- `uv run --with pyyaml scripts/lint-frontmatter.py
  claude/rules/coding-bash.md` for item 4, and `pre-commit run
  --all-files` for the rest.
- **Item 2 verifies itself on landing.** Whatever writes the edits, check
  afterwards with `git ls-files --eol` on every touched file and reject
  an implausible insertion/deletion count. An edit to the paragraph
  warning about CRLF corruption that arrives *as* CRLF corruption is the
  one failure this brief cannot be allowed to produce.
- No skill body, `paths:` glob or fixture changes except item 2's
  reference file, which is a `references/` change — and per
  [CLAUDE.md](../../../CLAUDE.md) § "Validating a change", a
  `references/` change never requires a retest.

## Dependencies

- **This is now the only open brief queuing edits against
  `claude/CLAUDE.md`.** Two others were listed here, and both have
  landed.
  [peer-coordination-open-questions.md](peer-coordination-open-questions.md)'s
  edit went in on 2026-09-18.
  `bash-snapshot-and-mcp-credential-env.md` was executed and deleted on
  2026-09-23. Its `c22ef8c` rewrote § Local environment around two
  Bash launch modes, one snapshot-sourced and one a login shell, and
  its `7bb9913` added a profile-stdout bullet to `coding-bash.md` §
  "Output streams". Neither section was restructured. Re-read both before
  editing; this brief's quoted line numbers predate that pass.
- Item 3's fallback destination is `land` step 8. The land/commit
  guard brief that was also editing it landed 2026-09-23 and is
  deleted; its step 8 change is `570d6a5`, which named the command
  behind the last bullet. If item 3 is refused its `CLAUDE.md` slot,
  re-read step 8 as it now stands and add it there.
- Blocks nothing.
