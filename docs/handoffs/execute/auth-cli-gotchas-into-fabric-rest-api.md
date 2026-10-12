---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-12
---

# Handoff: fold fabric-auth, fabric-cli and fabric-gotchas into fabric-rest-api

- **Written**: 2026-10-12, as the `fabric-deploy` pilot landed, to carry
  the first item of its second wave. The user set its shape on
  2026-10-09 (`7240d9e`), and no brief held it until now. Measured at
  `1813e9d`.
- **Kind**: a restructure, done by hand, then
  `/test-skill fabric-rest-api`. Three skills become references of
  `fabric-rest-api` as they stand, and its entry gains one trigger. No
  platform fact is added, so nothing is drilled and `/author-skill` does
  not apply.
- **After the pilot**: `fabric-deploy` routed as well as the pair it
  replaced or better, at 943 listing characters against 2,468
  ([result](../../../tests/skills/fabric-deploy/README.md)), so the
  second wave is next, each candidate re-measured first.

## Why

- **Four entries, every session.** None of the four has a `paths:`, so
  each is always listed: 3,507 characters of description on 2026-10-12,
  `fabric-gotchas` 1,018, `fabric-cli` 997, `fabric-rest-api` 853 and
  `fabric-auth` 639, none with a `when_to_use`.
- **The surviving name is the hub.** 23 skills routed to
  `fabric-rest-api` on 2026-10-09, so folding into it renames the fewest
  mentions.
- **The gotchas become a symptom → owner index**, the user's shape: a
  symptom names the reference or the skill that owns its fix, rather
  than restating the fix.
- **It takes `fabric-auth`'s held trigger**: what authorizes a service
  principal, tenant settings and workspace roles rather than API
  permissions. That guidance landed under `fabric-auth`'s 401 heading,
  while its description, 639 characters on 2026-10-08 and still on
  2026-10-12, did not grow: the portfolio brief held the trigger rather
  than grow an always-listed entry (Part 2 of
  `git show 7240d9e^:docs/handoffs/execute/platform-skill-portfolio.md`).

## Shape

### Files

| Today | After |
| --- | --- |
| `fabric-auth/SKILL.md` | `fabric-rest-api/references/auth.md` |
| `fabric-cli/SKILL.md` | `fabric-rest-api/references/cli.md` |
| `fabric-gotchas/SKILL.md` | `fabric-rest-api/references/gotchas.md`, its index rows into the router |
| each one's `references/REFERENCE.md` | beside its body, renamed, since `fabric-rest-api` keeps its own |

Move each with `git mv`, so `git log --follow` keeps its history. Strip
each moved file's frontmatter and re-point its relative links. The names
are this brief's proposal.

### The router

`fabric-rest-api`'s body stays and gains, near its top, a table from the
job to the reference: tokens, audiences and what authorizes a service
principal to `auth.md`; the `fab` CLI to `cli.md`; an error or a symptom
to the index. The index is `fabric-gotchas` recast, each row a symptom
and its owner, a reference here or another skill. Whether it sits in the
body or in `gotchas.md` is for its size to settle; `fabric-gotchas` runs
to about 118 lines today.

**Left to this fold by the pilot**: `fabric-cli`'s `fab deploy` section
(§ "Workspace Deployment") and `fabric-rest-api`'s § "Git Integration
APIs" stayed put so `fabric-deploy` could name them, its brief leaving
their move to this wave, "which restructures both skills anyway".
Whether they move into `fabric-deploy`'s references is this fold's call.
Either way, re-point `fabric-deploy`'s route table, its failure index
and its "See also", which name `fabric-cli`, `fabric-rest-api` and
`fabric-auth`.

### Frontmatter

- `name: fabric-rest-api`, unchanged.
- The entry, `description` plus `when_to_use`: trigger vocabulary and no
  facts, adding the held trigger's words (service principal, tenant
  setting, workspace role) and the absorbed skills' (`fab`, token
  audience, error code). The pilot's entry held at 493 and 450
  characters; these four spend 3,507.
- No `paths:`. `disable-model-invocation: false`, `# model: inherit`
  and `effort` commented, as today.

## The rename trap

The largest of the folds: on 2026-10-12, 55 files outside the three
skills' own folders named one of them, 19 of them other skills'
`SKILL.md`. The pilot's list applies item by item
(`git show 1813e9d:docs/handoffs/execute/fabric-deploy-skill.md`,
§ "The rename trap"): `skillOverrides`, the stamps in `.tested.json`,
`skills/README.md`, the drift registry's rows, open briefs, and a name
backticked in a description, which fails
`scripts/skill-overlap.py routing`. `fab` stays the CLI's name, and
prose about the CLI keeps it. `docs/audits/` stays as written.

```bash
grep -rnE 'fabric-auth|fabric-cli|fabric-gotchas' --exclude-dir=audits --exclude-dir=.git .
```

**Client repos**: relink each with exactly the groups it holds, as the
pilot did; the relink prunes the three dangling junctions.

## Verify

1. `pre-commit run --all-files`, and
   `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-rest-api/SKILL.md`
   is clean.
2. `/test-skill fabric-rest-api`, behaviour, against a `--safe-mode`
   baseline and the four skills as they stand, exported with
   `git archive` before the fold reaches `main`, as the pilot's
   [README](../../../tests/skills/fabric-deploy/README.md) runs them.
   Cases to settle when it runs:

   | Case | Prompt, in short | Passes when |
   | --- | --- | --- |
   | Service principal | a service principal whose app registration holds Fabric API permissions is refused | names the tenant setting and a workspace role, not more API permissions |
   | `fab` | list a workspace's items with `fab` | reads `references/cli.md` |
   | Symptom | an error code from a Fabric call | the index names its owner |
   | Plain REST | poll a long-running operation | answers from the body |

3. **Listing**: the router's entry against the four's 3,507.

## Re-measure before acting

- `uv run --with pyyaml python scripts/skill-telemetry.py coverage`
  rows for the four, and the grep and sizes above.
- Which folds have landed: they edit the same shared files.
  `platform-persona-groups.md` may land before or after this one, which
  stays inside its `fabric-core` group.
- `ListAgents` and `git worktree list`: a peer may hold a fold touching
  these skills.

## Not checked

Whether the router is invoked when auth, CLI or error work happens:
`skill-telemetry.py triggers` after a few weeks of client sessions.

## Scrubbing

Client repos are named by kind, and no workspace, item or tenant is
named.
