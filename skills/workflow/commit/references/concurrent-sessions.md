# Staging one hunk out of a contended file

Read this once you already know another session is writing the same
working tree — the gate is in `SKILL.md`, under "When another session
shares this tree". In a solo tree none of it applies.

## Why a hand-cut patch

`git add -p` is the right tool and an agent shell cannot drive it: there
is no interactive stdin, so the prompt either hangs until the tool
timeout or reads EOF. Applying a hand-cut patch to the index is the
non-interactive substitute. It touches the index only, so their hunk
stays on disk for them to commit.

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

## The limit

A line *inside* their added block is not separable. It has no `HEAD`
version to stage apart from the block it belongs to, so no patch
granularity reaches it. Leave it, and name the deferred piece in your
commit message so `git log` carries it.

## The wrong instinct

Do **not** overwrite the file with a HEAD-plus-your-change version,
`git add`, then restore theirs. That puts their work off disk for a
window in which they may read the file or commit it, which is the
failure this whole procedure exists to avoid.
