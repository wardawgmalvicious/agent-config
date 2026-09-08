# Handoff: correct the leak-remediation claim, and decide whether the SHA-translation trap is worth recording

- **Written**: 2026-09-08, immediately after purging a profile name from
  this repo's history — a `git filter-repo` rewrite, a force-push, and
  then a second delete-and-recreate when the force-push turned out not
  to be enough.
- **Kind**: **one edit and one decision.** Parts 1 and 2 are edits. Part
  3 is a decision and must be put back to the user rather than executed
  — see [A brief can be a decision rather than an edit](README.md#a-brief-can-be-a-decision-rather-than-an-edit).
- **Status**: open. Part 3 already has a stated user position; read it
  before proposing anything.
- **Run in**: a fresh session.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## Read this first: the central evidence is NOT re-measurable

The queue tells you to
[re-measure a row before acting on it](README.md#re-measure-a-row-before-acting-on-it).
**That instruction cannot be followed here, and following it naively
will invert the conclusion.**

The finding in Part 1 was measured against pre-rewrite commit SHAs on
the old `agent-config`. Those commits no longer exist anywhere — the
repo was deleted and recreated on 2026-09-08 and every old SHA now
returns `404`. **A `404` today is the remediation having worked, not
evidence against the finding.** Do not "verify" this brief by re-running
the probe and reading the 404 as a refutation.

What was actually measured, on 2026-09-08, between the force-push and
the recreate:

| Probe | Result |
| --- | --- |
| `raw.githubusercontent.com/<owner>/agent-config/433dd13/claude/mcp/README.md` | `200 OK`, leaked line intact |
| `raw.githubusercontent.com/.../ea47603/settings.json` | `200 OK`, leaked line intact |
| `api.github.com/repos/.../commits/433dd13` | `200 OK` |
| the same three, after delete-and-recreate | `404` / `422` |

At the time of those `200`s the rewrite was complete and correct:
`main` was clean, `refs/heads/main` was the only ref, and the commits
were reachable from no ref at all. GitHub was still serving them by
explicit SHA because it had not garbage-collected.

If you want a fresh reproduction, it needs a **throwaway** repo — push
two commits, rewrite the first away, force-push, then request the
original SHA. Do not reproduce it on a repo that matters.

## Part 1 (edit) — `claude/CLAUDE.md` names only half the reason

Currently at L237–242 (the sentence begins mid-line 237):

```
And once pushed, history cannot be fixed either: GitHub's
`refs/pull/N/head` are permanent and pin every commit a PR ever
touched, so `git filter-repo` plus a force-push leaves the leak
reachable, and the only effective remedy is to delete and recreate the
repo — done for `agent-config` on 2026-09-04, at the cost of its stars,
PRs and creation date.
```

**Why it is wrong.** It attributes the futility of rewriting entirely
to `refs/pull/N/head`. That is one of two mechanisms, and it is the one
that does *not* apply to a repo with no PRs. On 2026-09-08 this repo had
**zero** PR refs, zero forks and one self-cast star — by that paragraph's
logic a rewrite plus force-push should have sufficed. It did not, for
the second reason the paragraph omits: GitHub keeps serving unreachable
objects by explicit SHA until it garbage-collects, on no schedule the
repo owner controls or is told about.

The practical consequence is the paragraph's own recommendation
surviving intact but for a better reason — and a reader currently has no
way to know the recommendation still holds when the PR count is zero.

Proposed replacement, deliberately near length-neutral:

```
And once pushed, history cannot be fixed either. **Two** things keep a
rewritten-away commit reachable, and the second is the one that gets
missed: `refs/pull/N/head` pin every commit a PR ever touched, and even
with **no** PR refs at all GitHub goes on serving unreachable objects by
explicit SHA until it garbage-collects — on no schedule you control or
are told about. Measured 2026-09-08: straight after a clean
`filter-repo` and force-push, with zero PRs and zero forks, the
pre-rewrite SHAs still answered `200 OK` on both
`raw.githubusercontent.com` and the commits API, leaked line intact. So
delete-and-recreate stays the only *immediate* remedy — done for
`agent-config` on 2026-09-04 and again on 2026-09-08. Rewrite first
regardless, so the recreate has clean history to push.
```

**Length is a live constraint on this file** and the user raised it
explicitly on 2026-09-08: `claude/CLAUDE.md` is ~321 lines and loads
into every session on this machine. The replacement above is six lines
of prose for six. If it cannot be kept to that, cut the probe detail
(the `raw.githubusercontent.com` / commits-API specifics) rather than
the mechanism — the mechanism is the part a reader cannot re-derive.

After editing, `scripts/link-claude.ps1 -Force` is required to push it
to `~/.claude/CLAUDE.md`; it is a copy, not a junction.

## Part 2 (edit) — the same partial claim, in the hook's comments

`claude/hooks/identity-guard.sh` carries the same
`refs/pull`-is-the-whole-reason framing in two places.

L12–15:

```
# staged content only. A message cannot be fixed forward, and once pushed
# neither can history: refs/pull/N/head pin every commit a PR ever touched,
# so a rewrite-in-place leaves the leak reachable and the only real remedy
# is delete-and-recreate. Hence a gate on push, not only on commit.
```

L263, inside the block that prints when the guard fires:

```
        echo "work around the guard: once pushed, refs/pull pin it forever."
```

Both are **comments and user-facing text, not logic** — the guard's
behaviour does not change. Bring them into line with Part 1: the L263
line is what a person reads at the moment they are blocked, so it
matters more than its size suggests, and "refs/pull pin it forever" is
simply not the reason when the repo has no PRs. Something like
`once pushed, GitHub serves it by SHA until it GCs — if it ever does.`

**Deployment note.** A hook edit is not live until
`scripts/link-claude.ps1` runs, and the deployed copy keeps executing the
previous version with nothing saying so. Since this change is
comment-only, the redeploy is not urgent and can ride along with the
next one — but if Part 1 is also applied, that run needs `-Force`
anyway, so do both together. Use this machine's default form:

```powershell
./scripts/link-claude.ps1 -SkillGroups workflow -Force
```

**Never run it bare** — omitting `-SkillGroups` silently undoes the
workflow-only prune. Confirm the prune held by name, not by count:
`ls ~/.claude/skills | grep -E '^(fabric|pbir|pbid)-'` must come back
empty.

If the hook is touched at all, re-run its test suite —
`tests/hooks/identity-guard/` — and then again against the deployed
copy. It is the one machine-checkable suite in this repo.

## Part 3 (DECISION — do not execute) — the SHA-translation trap

### The finding

A history rewrite renumbers every commit, so any doc citing a SHA goes
stale. `git filter-repo` leaves `.git/filter-repo/commit-map` to
translate old to new. **That map is not safe to read with
`grep '^<sha>' | head -1`.**

A repo that has been rewritten *before* carries two lineages — the live
branch, and whatever old tag or stash still points at the pre-rewrite
copy. Every logical commit therefore appears **twice** in the map, and
`head -1` returns whichever sorted first.

On 2026-09-08, six of seven translated SHAs landed on commits from a
`refs/tags/stash-sqlproj` lineage rather than `main`. They resolved
locally under `git cat-file -t` and `git log`, so the translation looked
correct from the machine that made it — and returned `422 No commit
found` on GitHub, because they were on no published ref. The stale SHAs
they replaced would at least have failed the same way in both places.

The check that catches it is one line, and asserts the property that
actually matters:

```bash
git merge-base --is-ancestor "$new" main
```

Resolving is not the test; being an ancestor of the ref you publish is.
The structural fix is to delete stale refs *before* rewriting, so the
ambiguity cannot arise.

### The decision

**Does this get recorded, and if so where?** The user's position on
2026-09-08, stated directly:

> "I'm hoping that there will be no more rewrites of the repo, so we
> won't have to worry about these anymore. Not going to add anymore to
> anything right now, especially claude/CLAUDE.md which seems to be
> getting a bit long."

That is a reasonable objection and it is not resolved by this brief.
Three options, in the order I'd rank them:

1. **Record it in `claude/hooks/identity-guard.sh`'s comment block, not
   in `claude/CLAUDE.md`.** The hook is where a leak remediation
   actually starts, it already carries the delete-and-recreate reasoning
   (Part 2), and a comment there costs **zero session tokens** — the
   file is executed, never loaded into context. This answers the length
   objection directly rather than arguing with it. Roughly six comment
   lines.
2. **Drop it.** The trap only bites during a rewrite, and the stated
   hope is that there are no more. The cost of being wrong is one
   session rediscovering it — which is real but bounded, and this brief
   in git history is itself a record.
3. **Add it to `claude/CLAUDE.md`.** Highest visibility, and the option
   the user has already pushed back on. Not recommended.

**Put these to the user; do not pick one and apply it.** If the answer
is 2, delete this brief and record the "no" in the commit message, per
the queue's convention that landing a no is a real outcome.

## Verification

For Parts 1 and 2 only — Part 3 has nothing to verify until it is decided.

1. `grep -n 'refs/pull' claude/CLAUDE.md claude/hooks/identity-guard.sh`
   — every surviving hit should now sit next to the second mechanism,
   not stand alone as the whole explanation.
2. `pre-commit run --files claude/CLAUDE.md claude/hooks/identity-guard.sh`
   (the hook is also covered by `shellcheck`/`shfmt`).
3. If the hook changed: `tests/hooks/identity-guard/` passes, both
   in-repo and against the deployed copy after the linker runs.
4. If either file changed: `./scripts/link-claude.ps1 -SkillGroups
   workflow -Force`, then confirm the prune held by name as above.

## Suggested commit

```
docs(claude): name both reasons a pushed leak survives a rewrite

refs/pull/N/head is one mechanism and not the one that applied on
2026-09-08, when this repo had zero PRs and a clean filter-repo plus
force-push still left the pre-rewrite SHAs answering 200 on raw and the
commits API. GitHub serves unreachable objects by SHA until it GCs.
Delete-and-recreate stays the only immediate remedy — the recommendation
is unchanged, the reason it holds at zero PRs was missing.
```

Delete this brief and its queue row in the same commit **only once Part
3 is also settled** — a decision recorded nowhere is the thing the queue
exists to prevent.
