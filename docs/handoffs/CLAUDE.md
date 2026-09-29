# Before touching a brief

What a session must know before it writes, starts or lands a brief here;
[execute/README.md](execute/README.md) keeps the reasoning.

- **No file lists the queue**: `uv run scripts/handoff-status.py` prints
  it from each brief's frontmatter, grouped ready, needs you, needs
  something else, blocked and deferred, by priority, then oldest first.
  `. --no-inbox` gives this repo alone. Starting or landing a brief edits
  no shared file.
- **A brief's frontmatter is its whole state**, and its body restates none
  of it. `lint-briefs` fails a commit on a bad value, on a `blocked-by`
  naming a brief that is gone, and on a brief with no frontmatter.

  | Key | Takes |
  | --- | --- |
  | `status` | `open` or `deferred`; landing deletes the brief |
  | `priority` | `1` now, `2` next, `3` later; no order within one |
  | `needs` | a list: `user`, `tenant`, `desktop` or a short phrase; `[]` when a session can act alone |
  | `blocked-by` | a list of brief filenames in `execute/` |
  | `reopen-when` | the trigger; required when `deferred` |
  | `written` | `YYYY-MM-DD` |

  Each is `key: value` or `key: [a, b]`, and no value opens with a
  backtick or a quote, which YAML would misread.
- **A worktree named after a brief marks it in flight** in that view; root
  `CLAUDE.md` § "Branching and concurrent sessions" says when to take one.
- **A brief's worktree lands from the main checkout, with no push**, so
  not through `/land`, which pushes. Its session gets there by
  `ExitWorktree` `keep` when the user asks, or ends and keeps the
  worktree: `/exit` offers to remove it, which deletes the branch. Then:

  ```bash
  git merge --ff-only <branch>   # refused: main moved; git -C <worktree> rebase main
  git worktree remove .claude/worktrees/<brief>   # refused as locked: a session holds it; /prune-branches if its pid is dead
  git branch -d <branch>
  ```

  Deploy after the merge, as root `CLAUDE.md` § "Commands" says.
- **Re-measure a brief's evidence before acting on it**, and record which
  way it moved: a commit elsewhere can satisfy or void a brief silently.
- **`needs: [user]` is a question for the user**, not a call to make for
  them. A decision lands as yes, no or defer, the reasoning in the commit;
  a defer keeps the brief, `deferred` with its `reopen-when`.
- **Landing deletes the brief** in the commit that lands its work: drop
  its name from every `blocked-by`, and re-point whatever linked to it.
- **A skill brief beside a skill that exists means `/test-skill` has not
  run**; `uv run --with pyyaml scripts/skill-status.py --stale` says which
  skills need a retest.
- **Audit briefs are a second queue**, which the view prints after the
  first from their logs: one left open carries a `**Needs**:` line, and
  gains a `**Closed**:` line in the commit that lands its work
  ([why](execute/README.md#audit-briefs-are-a-second-queue)).
- **A filename is a link target**, so it carries no date or number.
