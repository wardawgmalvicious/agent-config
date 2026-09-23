---
name: commit
# model: sonnet  # any model: value blocks Copilot slash invocation
effort: xhigh
disable-model-invocation: false
description: "Splits working-tree changes into logical, self-consistent commits (ordering so nothing dangles, stepping files that straddle commits through intermediate states), writes conventional-commit messages (feat/fix/docs/refactor/chore) with motivation in the body, stages explicit paths only, uses git mv for renames, never pushes/amends/skips hooks unless explicitly asked, and ends by reporting the resulting hashes against a clean tree. Includes pre-commit checks for Fabric Git-synced repos (core.autocrlf, .gitattributes, whitespace-only portal diffs). In a working tree another session is editing at the same time, gates the commit on the branch and on the index exactly as read, so nothing of theirs is swept in and nothing lands on a branch a peer switched to."
when_to_use: "Use when asked to commit changes — /commit, 'commit this', 'make the commits', 'commit these split logically' — and when the commit has to be made in a tree another session is working in: 'another session is live in this tree', 'commit mine without touching theirs'."
---

# Commit workflow

Turn the current working-tree changes into one or more well-formed
commits. Committing only — pushing, amending, rebasing, and tagging
happen only when explicitly requested, never as follow-through.

## Survey first

1. `git status --short` — full picture of modified, renamed, untracked.
   Note anything **already staged that you did not stage**.
2. `git log --oneline -10` — calibrate message style against this
   repo's actual history, not assumptions.
3. Read the diffs (`git diff`, `git diff --stat`, plus untracked
   files) well enough to explain *why* each change exists, not just
   what it touches. Never commit content you haven't looked at.
4. **On `main`? Check whether this repo lands changes by pull request**
   — its `CONTRIBUTING.md` or agent instructions, a pull-request rule
   on `main` (`land` step 7 has the two reads), or `(#<n>)` and
   `Merge pull request` subjects in the log above; a fast-forward
   landing leaves none. If it does, branch before the first commit and
   say so: `land` refuses to start from `main`, and
   `~/.claude/CLAUDE.md` § "Branch naming" has the convention. A repo
   whose convention is to commit straight to `main` answers *no*, and
   then you commit where you stand. In a shared tree `git switch -c`
   moves HEAD for everyone — see
   [below](#when-another-session-shares-this-tree).

**An empty `git status --short` is the whole answer.** Report that there
is nothing to commit and stop; don't work through the diffs to confirm
it. `git diff --stat` prints nothing on a clean tree, and reading that
silence as a failed command rather than as the answer is a real failure
mode — observed 2026-09-09, three tool calls spent re-asking the same
question.

## Splitting into commits

- **One logical unit per commit.** A rename, a new feature, and a
  docs catch-up are three commits even when they touch the same file.
  Test: could each commit's subject line be written without "and"?
- **Review grouping is not a commit boundary.** Parts approved
  together in one review are still separate commits when each stands
  on its own in history — independently revertible, citable, worth
  landing alone. Bundle only when the parts are mutually dependent
  for meaning: a claim and the caveat qualifying it, a rename and its
  call sites. Tiebreak for a docs batch — which shape would you
  rather read in `git log` a year from now?
- **Every commit must be self-consistent.** No commit may reference a
  name, file, or skill that doesn't exist yet at that point in
  history, and none may leave the repo in a broken intermediate state.
  Order accordingly (e.g. a rename lands before anything citing the
  new name).
- **When one file straddles commits**, reach for interactive
  `git add -p` where your harness offers it. Some do not: an agent
  shell with no interactive stdin cannot drive it, and the prompt
  either hangs or reads EOF. Where it is unavailable, step the file
  through intermediate states instead — edit it down to the first
  commit's portion, commit, restore the next portion, commit again.
  Verify the final state matches the intended end state exactly.
  **Stepping assumes you own the whole file.** If another session has
  uncommitted work in it, stepping rewrites their in-flight text —
  commit only what is yours and leave the rest with a note.
- **Stage explicit paths only.** No `git add -A` / `git add .` — they
  silently sweep in untracked or unrelated files.
- **Verify the index before each commit.** `git diff --cached --
  <paths>` must show your change and nothing else. The diff you read in
  the survey is not what `git add` staged: the file can change in
  between, and `git add <path>` takes every hunk in the file, not the
  hunk you meant. `--stat` is not enough — a foreign hunk in a file you
  also edited has a stat line that looks exactly right. This is the last
  point at which a swept-in change is free to fix — and in a shared
  tree it has to *gate* the commit rather than precede it; see
  [below](#when-another-session-shares-this-tree).
- **Renames go through `git mv`** (or are staged so git detects the
  rename) so history follows the file.

## Messages

- Subject: `<type>: <imperative summary>` — types in this order of
  likelihood: `docs`, `feat`, `refactor`, `fix`, `chore`, `test`.
  Lowercase after the colon, no trailing period.
- Body: explain **motivation and non-obvious decisions** — why the
  change exists, what prompted it, provenance ("derived from X, now
  deleted"), and any ordering or scoping rationale. Never restate the
  diff. Wrap near 72 columns. Trivial single-file changes may skip
  the body.
- Multi-line messages: from PowerShell, a single-quoted here-string
  (`@'` ... `'@`, closing delimiter at column 0); from Bash, prefer
  `git commit -F -` fed by a quoted heredoc over `-m`, which sidesteps
  the quoting entirely. **Crossing the two exits 0** — a PowerShell
  here-string handed to `-m` in the Bash tool commits `@` as the
  subject with the delimiters in the body, and neither the hooks nor
  the exit code says so. Confirm with `git log -1 --format=%B --stat`
  before reporting the commit — one call gives both the message actually
  recorded and the files actually in it.

## Safety rails

- Never push, amend, force, rebase, or tag unless the user asked for
  that in this conversation. Commit, report, stop.
- Never `--no-verify` / skip hooks; if a hook fails, fix the cause.
- If a change looks accidental or unrelated to the stated work, leave
  it uncommitted and flag it rather than sweeping it in.
- **Scan for identity strings — in the diff *and* in the message you
  are about to write.** An organization's account names (`AzureAD\…`,
  Entra accounts), tenant names, internal hostnames, and hardcoded
  `C:\Users\<name>` profile paths get genericized before the commit,
  whatever the repo's visibility. gitleaks does not cover this: it
  matches secrets, not identities, and the pre-commit hook only sees
  *staged content*, so the message is unguarded entirely. The trap is
  that a commit documenting machine- or tenant-specific behaviour is
  exactly where real account names read as the subject matter — and a
  message, unlike a file, cannot be fixed forward.
  **Assume nothing catches this for you.** A hook can: an
  `identity-guard` reading a local denylist blocks a commit whose
  staged diff adds a listed term, hands back a message that carries
  one, and blocks the push. But it is a *local* hook reading a *local*
  list — the list is itself the leak, so it lives in no repo and
  travels with no clone. Unless you installed both on this machine,
  nothing above is checked for you and the scan is entirely yours. Even
  where it does run it knows only what is on the list, so a name it has
  never seen is yours to catch, and then to add.

## When another session shares this tree

Two sessions in one working tree share every file, **the index and
HEAD**, so neither staging nor a branch isolates you — only a commit
does, and only if it lands on the branch you meant. Suspect it when the
survey shows a path you never touched, when something is already staged
that you did not stage, when `git diff --cached` holds a hunk you cannot
account for from this conversation, when HEAD is not on the branch you
left it on, or when the user says so. **Rule out the two innocent
explanations first**: your own stepping edits, and a hook that rewrites
files, which leaves its rewrite *unstaged*. Neither is contention.

- **Ask them.** `ListAgents` names every live session
  `<cwd-basename>-<hash>` — its working directory, not its repo — and
  `SendMessage` reaches one. **Read every row rather than filtering by
  repo name**: a peer sitting in a subdirectory of this tree is both the
  likeliest contender and invisible to a prefix match (measured
  2026-09-17). A peer is the only source for what is in its working tree
  and not in `HEAD` — "are you editing `<path>` right now?" is the
  question this section could not answer before. Ask before cutting a
  patch, not after a collision. What they say about *committed* state is
  as old as their session, so check that yourself.
- **Stage and read in one chained command, commit in a second, and
  read the branch inside both** — with `git write-tree` carrying the
  index you read into the commit. The gap between reading a diff and
  running `git add` is where their hunk gets swept in, and HEAD is
  shared the same way: a peer's `git switch` moves the branch your
  commit lands on, with no error on either side. `git status` cannot
  show it — it reports files relative to HEAD, so a clean tree after
  someone moved HEAD reads exactly like one before, and "the tree is
  clean, so nothing is at risk" has been said and been wrong. One
  chain from `add` to `commit` closes that gap by dropping the index
  check: nothing can be read between two `&&`, and a `git diff
  --cached` printed mid-chain exits 0 and gates nothing (measured
  2026-09-23: 3 of 3 probes on that form never verified the index).

  ```bash
  [[ "$(git branch --show-current)" == "<branch>" ]] \
    && git add <paths> && git diff --cached && git write-tree
  # read the diff -- your hunks and nothing else -- and note the tree id
  [[ "$(git branch --show-current)" == "<branch>" \
     && "$(git write-tree)" == "<tree>" ]] && git commit -F - <<'MSG'
  …
  MSG
  ```

  `git write-tree` hashes the whole index, so the second chain refuses
  if anything reached it since you read — their hunk in your file, a
  file of theirs — and ignores what they left unstaged, which `commit`
  would not take either (all four cases measured 2026-09-23). From
  PowerShell both tests have to be an `if`: pwsh's `&&` runs its right
  side whenever the left side *ran*, true or false, so a literal port
  never refuses (measured 2026-09-23, pwsh 7.6).

  ```powershell
  if ((git branch --show-current) -eq '<branch>') { git add <paths> && git diff --cached && git write-tree }
  if ((git branch --show-current) -eq '<branch>' -and (git write-tree) -eq '<tree>') { git commit … }
  ```

  A mismatch means someone moved HEAD: stop, `ListAgents`, ask —
  switching back is a HEAD move for them too. Recorded 2026-09-22, and
  `land` step 1 has the other seat: a peer's `git switch main` landed
  between this session's `switch -c` and its `git add`, and the commit
  went to `main` unnoticed for over an hour. If it already happened,
  propose the repair rather than run it — the stray commit onto
  `<branch>`, the wrong branch back to `<sha>^` — since both move refs
  a peer may be standing on, and resetting to the upstream instead
  would drop anything unpushed.
- **`fatal: Unable to create '.git/index.lock': File exists` is their
  git command in flight**, not a stale lock. Wait and retry; never
  delete it.
- **Record what you left.** Commit only what is yours, and name the
  deferred piece in the commit message so `git log` carries it rather
  than this conversation.

Staging one hunk out of a file they are also writing:
[references/concurrent-sessions.md](references/concurrent-sessions.md).

## Fabric Git-synced repos

Before the first commit in a repo containing `*.{ItemType}` folders:
check `git config core.autocrlf` and whether `.gitattributes` pins the
item folders (per `rules/fabric-git-serialization.md`). Whitespace-only
diffs (EOF newline, CR-stripping) in portal-owned files are
translation artifacts — do not commit them as "cleanup"; flag them and
fix the `.gitattributes` instead.

## Finish

- `git status --short` must come back clean, or every remaining line
  must be intentionally left and mentioned in the report.
- Report each commit: hash, subject, and one line on what it contains
  — plus an explicit note that nothing was pushed.
