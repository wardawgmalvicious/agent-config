---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-09-30
---

# Handoff: `commit` stages part of a file by writing the index

- **Written**: 2026-09-30, from the third learning of an inbox note of
  2026-09-27. Its session, in a client repo, split three workflow files
  and a README across seven commits. A re-run here the day this was
  written found one defect in the note's script and fixed it.
- **Kind**: an edit to `skills/workflow/commit/SKILL.md`, a script and a
  reference under `skills/workflow/commit/`, then `/test-skill commit`.
  Nothing is drafted.

## The gap

`commit` § "Splitting into commits", under "When one file straddles
commits", offers two routes: `git add -p`, which an agent shell cannot
drive, and stepping the file on disk through intermediate states.
`references/concurrent-sessions.md` adds a third for a contended tree, a
hand-cut patch applied with `git apply --cached`. **None selects below a
diff hunk without rewriting the working tree.**

- A hunk's edges come from diff context, not from where one change ends
  and the next begins. The patch recipe keeps or drops a hunk whole, and
  with git's default three lines of context, changes a few lines apart
  share one. The note's case was a single `@@ -27,14 +30,16 @@` hunk
  holding a comment for one commit and two action pins for another.
- Stepping on disk reaches below the hunk, but rewrites the working tree
  between commits, which the skill then verifies back to its final
  state, and it assumes the session owns the whole file.

## The route

**Build each intermediate version as a blob and put it straight into the
index.** The working tree stays at its final state throughout,
`git diff --cached` shows exactly what the next commit takes, and an
empty `git status --short` after the last commit proves the commits add
up to that state, with no separate check.

The note's session selected by a line diff, not by a patch.
`difflib.SequenceMatcher` over the index version and the working-tree
version yields blocks, each a run of changed lines between two unchanged
ones, and a regex over a block's lines says whether it is taken. One
unchanged line between two changes is enough to separate them. Each
block prints `TAKE` or `skip` with its first line: the audit before
`git diff --cached` is.

The script as corrected and run here on 2026-09-30, a starting point for
the skill's copy:

```python
"""Stage part of a file's working-tree changes, leaving the working tree alone.

Usage: stage_part.py <repo> <path> include|exclude <regex>

A block is one run of changed lines between two unchanged ones. `include`
stages every block with a line matching <regex>, `exclude` every block
without one. The working-tree side is read through git's clean filter, as
`git add` would store it, so a file checked out CRLF stages LF.
"""
import difflib
import re
import subprocess
import sys


def git(repo, *args, data=None):
    return subprocess.run(["git", "-C", repo, *args], input=data,
                          capture_output=True, check=True).stdout


repo, path, mode, pattern = sys.argv[1:5]
rx = re.compile(pattern.encode())
old = git(repo, "show", f":{path}")
new_sha = git(repo, "hash-object", "-w", "--", path).decode().strip()
new = git(repo, "cat-file", "blob", new_sha)
a, b = old.splitlines(keepends=True), new.splitlines(keepends=True)
out = []
for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(
        a=a, b=b, autojunk=False).get_opcodes():
    if tag == "equal":
        out += a[i1:i2]
        continue
    hit = any(rx.search(line) for line in a[i1:i2] + b[j1:j2])
    take = hit if mode == "include" else not hit
    out += b[j1:j2] if take else a[i1:i2]
    first = (b[j1:j2] or a[i1:i2])[0].decode(errors="replace").strip()[:70]
    print(f"  {'TAKE' if take else 'skip'} {tag} -{i2 - i1}/+{j2 - j1}: {first}")
sha = git(repo, "hash-object", "-w", "--stdin", data=b"".join(out)).decode().strip()
filemode = git(repo, "ls-files", "-s", "--", path).decode().split()[0]
git(repo, "update-index", "--cacheinfo", f"{filemode},{sha},{path}")
print(f"{path}: staged {sha[:10]}")
```

It ran as `uv run --no-project python <script> <repo> <path> include
'<regex>'` with `PYTHONIOENCODING=utf-8` set. It reads and writes bytes,
so the text-mode CR trap in `concurrent-sessions.md` cannot arise.

## Measured

**In the note's session**, 2026-09-27: six runs over five of seven
commits, a README with one block excluded and workflow files with a
block included or excluded. Every `git diff --cached` showed exactly the
intended blocks, the working tree was never edited, and
`git status --short` came back empty after the last commit. Each
intermediate commit's three workflows parsed with `yq`, and
`git ls-files --eol` read LF throughout.

**Here**, 2026-09-30, git 2.55.0, in a scratch repo whose
`.gitattributes` pinned `*.ps1` to `text eol=crlf`, as this repo's does:

| Case | The note's script | Reading through the clean filter |
| --- | --- | --- |
| Two changes one unchanged line apart, LF file; `git diff` shows 1 hunk | staged the one block asked for; `git status --short` empty after both commits | the same |
| The same edit in a file checked out CRLF, `i/lf w/crlf` | **one block of all 6 lines, both changes taken, a CRLF blob staged**: `i/crlf`, numstat `6 6` | two blocks, one taken: `i/lf`, numstat `1 1`, the working tree's CRs untouched |
| `exclude`, LF file | not run | took the block with no match |

**The note's script read the working-tree file's raw bytes.** Against
an index that git normalizes, every line then differed, so the regex
chose for the whole file and the staged blob carried CRs the index
never holds. The note listed CRLF files as not checked, and every
`.ps1` here is one: `git ls-files --eol scripts/repo-settings.ps1`
reads `i/lf w/crlf`. The corrected script reads that side as `git add`
would store it, through `git hash-object -w -- <path>` and
`git cat-file blob`, which writes one unreferenced blob and changes
nothing else.

## The edit

- `SKILL.md`, the "When one file straddles commits" bullet: index
  staging is the non-interactive substitute for `git add -p`, and
  stepping on disk the fallback for what it cannot split.
- The script ships inside the skill, so it travels with the junction.
  `skills/powerbi/pbid-tom-live/scripts/` is the one precedent, named
  from its `SKILL.md` by a relative link. A short reference beside it
  holds the measurements and the limits below.
- `references/concurrent-sessions.md` § "The limit" gains the context
  limit on its own recipe, and says how far this route goes in a
  contended tree, once that is checked.
- The `description` says "stepping files that straddle commits through
  intermediate states". Rewording it moves the routing hash, so
  `/test-skill` re-runs activation too; leaving it costs nothing.

## Not checked

- **A contended tree.** The index is shared, so `commit`'s gate under
  "When another session shares this tree" still applies. A peer's edit
  adjacent to yours lands in one block with it, which the `TAKE` line
  and `git diff --cached` show and nothing prevents.
- A new file. It has no index version, so `git show :<path>` fails and
  the script stops; after `git add -N` the whole file is one block.
- Two changes with no unchanged line between them: one block, taken or
  skipped whole. Stepping on disk is still the route.
- How far apart two changes must sit to get hunks of their own. Six
  unchanged lines or fewer should share one, by the context width; only
  the one-line case was run.
- `git apply --cached --unidiff-zero` over a subset of `-U0` hunks, the
  patch recipe's own way to finer hunks. The note reasoned it fragile,
  a zero-context addition having nothing to anchor on, and did not try
  it.
- Binary files, an unmerged path, a clean filter other than end-of-line
  conversion, and bytes that are not UTF-8 in a `TAKE` line.

## Verification

- `uv run --with pyyaml scripts/lint-frontmatter.py
  skills/workflow/commit/SKILL.md`.
- The table's three cases against the landed script, the CRLF one on a
  `.ps1` in a scratch clone of this repo.
- `uv run --with pyyaml scripts/skill-status.py --stale` lists `commit`
  after the body edit, and `/test-skill commit` clears it. `commit` is
  in a deployed group, so that runs on `main` after the merge
  ([README.md](README.md) § "Every brief takes a worktree").
- `./scripts/copy-copilot.ps1 -CopilotDir ~/.copilot -SkillGroups
  workflow` afterwards, while that copy is kept
  (`.claude/rules/editing-skills.md`;
  [copilot-client-repo-findings.md](copilot-client-repo-findings.md)).
- `pre-commit run --all-files`.

## Scrubbing

This repo is public. The note was genericized, and its files are cited
here by kind; the client repo, its workflows' names and their contents
stay out of the skill and the commit messages.
