# Staging one hunk out of a contended file

Read this once you already know another session is writing the same
working tree — the gate is in `SKILL.md`, under "When another session
shares this tree". In a solo tree none of it applies.

## Why a hand-cut patch

`git add -p` is the right tool and an agent shell cannot drive it: there
is no interactive stdin, so the prompt either hangs until the tool
timeout or reads EOF. Applying a hand-cut patch to the index is one
non-interactive substitute. It touches the index only, so their hunk
stays on disk for them to commit. [Index staging](index-staging.md) is
the other, and reaches below a hunk, where a patch cannot: see "The
limit".

## The recipe

Write the patch to the **session scratchpad, not the working tree**. An
untracked `.patch` file in the tree is one more thing a `git add` can
sweep up.

```bash
git diff -- <path> > <scratch>/hunk.patch
# delete every hunk that is not yours
git apply --cached <scratch>/hunk.patch
git diff --cached -- <path>   # must show your hunk alone
```

Cut the patch while the path is **unstaged**, so the index still matches
`HEAD` and the patch has the base it was diffed against.

## The gotcha that makes it fail

**Delete whole hunks, `@@` header included. Never edit inside a hunk
body.** The header carries line counts; changing the body without
recomputing them makes `git apply` reject the patch — `corrupt patch at
line N`, which reads like a broken file rather than a miscount.

Whole-hunk deletion is safe: each surviving hunk relocates by its
context lines, and git absorbs the offset.

**Cut the patch in binary.** On Windows a text-mode write turns every
`\n` into `\r\n` — Python's `write_text`, or `open()` without
`newline=""` — and the CR lands on every context line, so
`git apply --cached` answers `patch does not apply` at the hunk's first
line. That reads as a stale base or a moved `HEAD`, and both check out:
the base is right and the bytes are wrong. Use `read_bytes` /
`write_bytes`, and count CRs before applying —
`tr -cd '\r' < hunk.patch | wc -c` must print `0`. Measured
2026-09-13: `git diff` wrote none, the cut copy carried one per line,
and the binary rewrite applied first time.

Count with `tr`, not in Python: `read_text()` turns each `\r\n` back
into `\n` before any check sees it, so a CR count on its output is a
green light on a file carrying one per line.

## The limit

A line *inside* their added block is not separable. It has no `HEAD`
version to stage apart from the block it belongs to, so no patch
granularity reaches it. Leave it, and name the deferred piece in your
commit message so `git log` carries it.

**A patch keeps or drops a hunk whole, and a hunk is wider than a
change**: it carries context lines on both sides, so their change a few
lines from yours shares your hunk
([where git splits two](index-staging.md#what-a-block-is)).
`git diff -U0` cuts one hunk per run of changed lines, but don't cut
finer that way: `git apply --unidiff-zero` places a pure addition by
its new-side line number, so with an earlier hunk dropped it lands off
by that hunk's line count, exit 0. Measured 2026-09-30 on git 2.55.0:
with a two-line insertion above it dropped, an inserted line staged two
lines low.

[Index staging](index-staging.md) goes below a hunk with no patch: one
unchanged line separates their change from yours, and only the index is
written, so their text stays on disk. Their edit on the line next to
yours still shares your block; its "In a contended tree" says what to
do then.

## The wrong instinct

Do **not** overwrite the file with a HEAD-plus-your-change version,
`git add`, then restore theirs. That puts their work off disk for a
window in which they may read the file or commit it, which is the
failure this whole procedure exists to avoid. Build that version in the
scratchpad and stage it as a blob instead
([the blob by hand](index-staging.md#below-a-block-the-blob-by-hand)).
