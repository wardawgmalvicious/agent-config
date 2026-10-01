# Staging part of a file through the index

When one file's changes belong to more than one commit and `git add -p`
cannot be driven, build each commit's version of the file as a blob and
put it straight into the index. The working tree stays at its final
state throughout, `git diff --cached` shows exactly what the next commit
takes, and an empty `git status --short` after the last commit proves
the commits add up to the file on disk, with no separate check.
[stage-part.py](../scripts/stage-part.py) builds that blob from the
blocks a regex picks; below a block, build it by hand.

## The script

Run it from the repository's top level, once per commit, and read the
index before committing:

```bash
uv run --no-project python ~/.claude/skills/commit/scripts/stage-part.py . <path> include '<regex>'
git diff --cached -- <path>
```

`~/.claude/skills/commit` is this skill's directory where it is deployed
at user scope. `<path>` is relative to the top level, as
`git status --short` prints it there, and `exclude` in place of
`include` takes every block the regex does not match. `--no-project`
keeps uv from syncing the repository's own Python project first, where
it has one.

It prints one line per block, then what it staged:

```text
  TAKE  -1 +1  line 5: line 05 alpha
  skip  -1 +1  line 7: line 07 beta
f.txt: staged 34d4fb468e, 1 of 2 blocks
```

Each line gives the lines the block removes and adds, the working-tree
line it sits at, and its first line with text. **Read them before
`git diff --cached`**: a block taking more lines than your change has,
`-2 +2` for a one-line edit, carries a second change in it. The working
tree never moves, so its line numbers hold for every commit of the
split.

The diff is taken against the index, not `HEAD`: after each commit the
next run sees only what is left, a second run before a commit adds to
the first, and `git restore --staged -- <path>` starts the path over.
Exit 0 means a blob was staged. **Exit 1 means nothing was taken**, the
index untouched, which is what a regex matching no block looks like.
Exit 2 is a usage error or a path it refuses: not in the index,
unmerged, binary, or not a regular file. Any other code is git's own,
with git's message on stderr.

## What a block is

A block is a run of changed lines between two unchanged ones, in a line
diff of the index version against the working tree's, so **one
unchanged line separates two blocks**. A `git diff` hunk is wider: at
git's default three lines of context it holds two changes up to six
unchanged lines apart, and splits them only at seven (measured
2026-09-30, git 2.55.0). The regex is tested against every line a block
removes or adds, so a removed line can match too.

The line diff is Python's `difflib`, not git's, and on repetitive text
the two can pair lines differently, so a block need not be the hunk you
expected. The audit lines are the check.

## Line endings

The working-tree side is read through git's clean filter, as `git add`
would store it, by `git hash-object -w -- <path>` and
`git cat-file blob`, so a file checked out CRLF stages LF and keeps its
CRs on disk (measured 2026-09-30, a `.ps1` under `text eol=crlf`).
Reading the file's raw bytes, as the script's first version did, set
every line against an index git had normalized: one block of the whole
file, every change taken, and a CRLF blob staged, `i/crlf` (measured the
same day). `hash-object -w` leaves one unreferenced blob behind and
changes nothing else.

## Below a block: the blob by hand

Two changes with no unchanged line between them are one block, taken or
skipped whole, and a new file is one block from its first line to its
last. Build that commit's version by hand instead, still without
touching the working tree:

```bash
git cat-file blob :<path> > <scratch>/next          # the index version
# edit <scratch>/next to the next commit's state
git hash-object -w --path=<path> <scratch>/next     # prints <sha>
git update-index --cacheinfo <mode>,<sha>,<path>
```

`<mode>` is the first field of `git ls-files --stage -- <path>`. For a
new file, write its first version to the scratch copy and stage it with
`git update-index --add --cacheinfo 100644,<sha>,<path>`. `--path` runs
that path's clean filter, as `git add` would, so a copy that picked up
CRs still stages LF where the repo's attributes normalize (measured
2026-09-30); where none do, `git diff --cached` showing every line
changed is the tell. Keep the copy in the session scratchpad: in the
working tree it is one more untracked file for a `git add` to sweep up.

Stepping the file on disk, as `SKILL.md` describes, also reaches below a
block, but rewrites the working tree between commits.

## In a contended tree

The script and the blob by hand write only the index, so a peer's
uncommitted text stays on disk, untouched, where stepping would rewrite
it. Measured 2026-09-30:

- A peer's edit one unchanged line from yours is a block of its own,
  which a regex matching only your lines leaves unstaged.
- A peer's edit on the line next to yours shares your block, and
  `include` takes both: the `TAKE` line reads `-2 +2` for your one-line
  edit, and nothing prevents it. Build your version by hand then, or
  leave the block and name it in your commit message.

The index is still shared, so `SKILL.md`'s gate under "When another
session shares this tree" applies as written. The script reads the
path's index entry and writes it back a moment later, so a peer's
`git add` of that path in between is overwritten, and
`git restore --staged` drops whatever they had staged in it.

## Provenance and limits

First used 2026-09-27 in a client repo, splitting workflow files and a
README across seven commits: every `git diff --cached` showed exactly
the intended blocks, each intermediate commit's YAML still parsed, and
`git status --short` came back empty after the last commit. Each
measurement above is a case in agent-config's
`tests/scripts/stage-part/test-stage-part.sh`.

Not run: a symlink or a submodule, which the script refuses by mode; a
clean filter other than end-of-line conversion, under which the diff is
between the filter's outputs, Git LFS pointers for one; and bytes that
are not UTF-8, which print as U+FFFD in an audit line.
