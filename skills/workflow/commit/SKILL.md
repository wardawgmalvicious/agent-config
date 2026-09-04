---
name: commit
model: sonnet
effort: xhigh
disable-model-invocation: false
description: "Splits working-tree changes into logical, self-consistent commits (ordering so nothing dangles, stepping files that straddle commits through intermediate states), writes conventional-commit messages (feat/fix/docs/refactor/chore) with motivation in the body, stages explicit paths only, uses git mv for renames, never pushes/amends/skips hooks unless explicitly asked, and ends by reporting the resulting hashes against a clean tree. Includes pre-commit checks for Fabric Git-synced repos (core.autocrlf, .gitattributes, whitespace-only portal diffs)."
when_to_use: "Use when asked to commit changes — /commit, 'commit this', 'make the commits', 'commit these split logically'."
---

# Commit workflow

Turn the current working-tree changes into one or more well-formed
commits. Committing only — pushing, amending, rebasing, and tagging
happen only when explicitly requested, never as follow-through.

## Survey first

1. `git status --short` — full picture of modified, renamed, untracked.
2. `git log --oneline -10` — calibrate message style against this
   repo's actual history, not assumptions.
3. Read the diffs (`git diff`, `git diff --stat`, plus untracked
   files) well enough to explain *why* each change exists, not just
   what it touches. Never commit content you haven't looked at.

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
- **When one file straddles commits**, interactive `git add -p` is
  unavailable in this harness — instead, step the file through
  intermediate states: edit it down to the first commit's portion,
  commit, restore the next portion, commit again. Verify the final
  state matches the intended end state exactly. **This assumes you own
  the whole file.** If another session has uncommitted work in it,
  stepping it through intermediate states rewrites their in-flight
  text — commit only what is yours and leave the rest with a note.
- **Stage explicit paths only.** No `git add -A` / `git add .` — they
  silently sweep in untracked or unrelated files.
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
  the exit code says so. Confirm with `git log -1 --format=%B` before
  reporting the commit.

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
