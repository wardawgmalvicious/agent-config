---
status: open
priority: 3
needs: []
blocked-by: []
written: 2026-09-30
---

# Handoff: fabric-rest-api says nothing about the Git integration APIs

- **Written**: 2026-09-30, from one inbox note of 2026-09-30 by a session
  working a Git-connected sandbox workspace whose Git side is a client
  sample repo. Re-measured against the payload at `1e106a1`, where the
  Git APIs appear only as links, in
  `skills/fabric/fabric-rest-api/references/REFERENCE.md` § "Git
  integration and CI/CD via REST".
- **Kind**: an edit, a new `## Git Integration APIs` section in
  `skills/fabric/fabric-rest-api/SKILL.md`. Nothing is drafted. The
  symptom it explains already has its row, `Git_HeadNotSynced` in
  `fabric-gotchas`, landed by the same triage; this is the depth behind
  that row.

## Evidence status, per item

| Item | Status |
| --- | --- |
| 1, the two heads and the minimal update | Documented: Learn's Get Status and Update From Git pages, read here 2026-09-30 |
| 1, the stranded workspace and its fix | Observed once by the note's session, 2026-09-30, on GitHub with Git folder `/`; not reproducible from here |
| 1, `Location` naming a regional host | Observed once by the note's session; polling the `Location` URL itself was never tried |
| 2, item types outside the enum | Observed once by the note's session, one call, three items; the enum re-read here 2026-09-30 |

## 1. Two heads, and an update that refuses rather than overwrites

`GET /v1/workspaces/{id}/git/status` returns `workspaceHead`, the commit
the workspace is synced to, `remoteCommitHash`, the branch head, and
`changes[]`, each change carrying `workspaceChange`, `remoteChange` and
`conflictType`. Differing heads with no `remoteChange` on any item is the
state the `fabric-gotchas` row names: an incoming commit with no incoming
item, for which the Source control pane offers no button.

`POST …/git/updateFromGit` requires `remoteCommitHash` and takes
`workspaceHead`, which the service checks against its own head, failing
`WorkspaceHeadMismatch` otherwise. It will not start with items in
conflict and no `conflictResolution`, nor with incoming items and no
`options.allowOverrideItems`. So the two-hash body is the safe default,
and the other two fields go in on purpose. It updates only the items the
incoming commits changed.

Both calls need the caller's Git credentials: `GET …/git/myGitCredentials`
reads them, and the note's session read `"source": "ConfiguredConnection"`.
Both are long-running, answering `200`, or `202` with `Location`,
`x-ms-operation-id` and `Retry-After`, and Learn says not to call Get
Status while an update runs.

The note's one update answered `202` with `Retry-After: 20` and finished
in under a second. Its `Location` named a regional cluster host, not
`api.fabric.microsoft.com`, and polling
`api.fabric.microsoft.com/v1/operations/{x-ms-operation-id}` worked,
which is what the skill's LRO section already says to poll.

## 2. `git/status` types items outside its documented enum

The note's call typed a semantic model, a Plan and a SQL database as
`dataset`, `Planning` and `SQLDbNative`. Learn's `ItemType` enum, read
here 2026-09-30, lists `SemanticModel`, `Plan` and `SQLDatabase`, and none
of the three. A script that filters `changes[]` on documented types skips
those items without a word. Match on `itemMetadata.itemIdentifier`
instead: `logicalId`, or `objectId` for an item Git has not seen yet, the
fallback Learn documents.

## Where it lands

`skills/fabric/fabric-rest-api/SKILL.md`, a `## Git Integration APIs`
section after `## Definition APIs`: items 1 and 2 at the strength the
table above allows, a few lines each, linking the two Learn pages. Then:

- point the `fabric-gotchas` row's fix at the new section, beside its LRO
  pointer;
- the description, 769 of 1,024 characters on 2026-09-30, has room for a
  trigger such as "Git integration APIs (git/status, updateFromGit)";
- `references/REFERENCE.md` keeps its links and needs nothing.

`skill-status.py` lists `fabric-rest-api` as a reference skill,
`untested`, so the edit leaves no retest. Lint the skill with
`uv run --with pyyaml scripts/lint-frontmatter.py`.

## Not checked

- Whether the pane hid **Update all** because no item changed or because
  the head was a merge commit. A single-parent commit touching only a
  root file, then `git/status` and the pane, would separate them.
- A workspace connected to a subfolder rather than `/`, and Azure DevOps.
- The item-type names on a second call, or in another tenant.

## Scrubbing

The note came from a client's sandbox workspace. Its commit SHAs,
workspace GUID, request IDs and regional host are left out, and its items
are named by type.

## Re-measure before acting

- `git log -1 --format=%h -- skills/fabric/fabric-rest-api/SKILL.md`:
  `3b80a5c`, 2026-09-12, on 2026-09-30.
- `grep -rn "updateFromGit" skills/`: the `fabric-gotchas` row alone, on
  2026-09-30.
- Learn's Get Status and Update From Git pages, before the section quotes
  a field or an error code.
