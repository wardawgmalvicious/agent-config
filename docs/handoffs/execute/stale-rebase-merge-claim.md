# Handoff: retire the stale rebase-merge claim

- **Written**: 2026-09-08, after the second delete-and-recreate of this
  repo reset its merge settings to GitHub's defaults.
- **Kind**: edit. Two files, each a deletion plus a shorter replacement.
- **Status**: open.
- **Run in**: a fresh session. No dependencies, no ordering constraint —
  safe to do alone, and it is the cheaper of the two 2026-09-08 briefs.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## What is wrong

Two files assert that rebase-merge is **disabled** on `agent-config`,
and cite the API answering `405 Rebase merges are not allowed` on PR #6.

That was true of the repo that existed until 2026-09-08. It is not true
now. The repo was deleted and recreated that day (to purge a profile
name from history — the header comment in
`claude/hooks/identity-guard.sh` carries why a rewrite alone was not
enough), and **a recreate resets every merge setting to GitHub's
default**. All three merge types are enabled again.

This is a live trap rather than a dead one: it fires whenever a branch
is landed, which is ordinary work here, not the rewrite scenario that
produced it.

## Re-measure before acting — this row's own evidence

```bash
gh api repos/wardawgmalvicious/agent-config \
  --jq '{allow_squash_merge, allow_merge_commit, allow_rebase_merge}'
```

Measured 2026-09-08, immediately after the recreate: all three `true`.

**If `allow_rebase_merge` comes back `false`,** someone has disabled it
since. The claim is then true again and this brief should be closed as
no-longer-applicable rather than executed — record which in the commit
that deletes it.

Note that the *unauthenticated* read is worthless here, and that fact is
the substance of edit 2: `xh`/`curl` without a token returns `null` for
every `allow_*` field, so a tokenless check can neither confirm nor
refute the setting.

## Edit 1 — root `CLAUDE.md`

Currently at L348–351:

```
**Integrate by fast-forward.** Rebase-merge is **disabled on this
repo** — the API answers `405 Rebase merges are not allowed` — and
squash would collapse the logical split `/commit` just made. So land a
branch locally rather than through the merge button:
```

Replace with:

```
**Integrate by fast-forward.** Squash would collapse the logical split
`/commit` just made, and rebase-merge rewrites the SHAs it just wrote.
So land a branch locally rather than through the merge button:
```

**Delete the claim; do not replace it with a dated version of itself.**
The advice that follows — fast-forward, `--ff-only`, no merge commit —
never depended on rebase-merge being disabled. It stands on the squash
argument alone, so the sentence gets shorter and stops being a thing
that can rot. Four lines to three.

## Edit 2 — `skills/workflow/land/SKILL.md`

Currently at L154–158:

```
- **Rebase merge** — rewrites SHAs, and may be disabled outright. On
  `agent-config` the API answers `405 Rebase merges are not allowed`
  (recorded in root `CLAUDE.md`, verified there on PR #6). Merge
  settings and branch protection are not readable unauthenticated, so a
  rejection surfaces at merge time and not before.
```

Replace with:

```
- **Rebase merge** — rewrites SHAs, and may be disabled outright. Read
  the setting rather than assuming it: `gh api repos/<owner>/<repo>
  --jq '{allow_squash_merge, allow_merge_commit, allow_rebase_merge}'`.
  Unauthenticated, those fields come back `null` — so a check without a
  token proves nothing and a rejection surfaces at merge time. A repo's
  answer is not durable either: a delete-and-recreate resets all three
  to GitHub's defaults.
```

This one grows by a line, and that is the right trade — it swaps a
false specific for a check the reader can actually run. The cost is
paid in a skill that loads only when landing a branch, not in
`claude/CLAUDE.md`, which loads in every session on the machine.

The "not readable unauthenticated" half of the original is **correct**
and was re-confirmed 2026-09-08 — keep it. Only the `405` and the PR #6
citation go.

## Verification

1. No surviving reference to the dead claim:
   ```bash
   grep -rn -i -E '405|rebase merges are not allowed' skills/ claude/ CLAUDE.md
   ```
   Expect no hits. (Before the edit this returns four lines across the
   two target files.)
2. Frontmatter still lints — the edit is body-only, but run it anyway:
   ```bash
   uv run --with pyyaml scripts/lint-frontmatter.py skills/workflow/land/SKILL.md
   ```
3. Read both edited passages back in full. The test is that the
   surrounding argument still reads as complete with the clause gone —
   it should, because fast-forward was never justified by the 405.
4. `pre-commit run --files CLAUDE.md skills/workflow/land/SKILL.md`

No activation contract is touched (no `paths:` glob, no `description`),
so `test-activation.ps1` is not needed.

## Suggested commit

```
docs: drop the stale rebase-merge-disabled claim

The 405 was a property of the repo deleted on 2026-09-08; a recreate
resets merge settings to GitHub's defaults and all three are enabled
again. Root CLAUDE.md loses the clause outright — fast-forward never
depended on it — and land/SKILL.md swaps it for the authenticated
`gh api` check, plus a note that the setting is not durable across a
recreate.
```

Then delete this brief and its queue row in the same commit, per the
[lifecycle](README.md#lifecycle).
