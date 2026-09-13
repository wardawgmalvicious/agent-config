# Handoff: add pause and resume to fabric-eventstream

- **Audit run**: 2026-09-10
- **Source**: `skills-for-fabric`
- **Window**: floor `2026-08-06` (diff base `912e06e0`) → head `65902bae`
  (2026-09-04)
- **Covers recommended actions**: 3
- **Kind**: content addition to a platform skill, from Microsoft Learn.
  No trigger or frontmatter change needed.
- **Target**: `skills/fabric/fabric-eventstream/SKILL.md`

## The problem

`fabric-eventstream` covers the Eventstream item — sources, destinations,
publishing, monitoring — and says nothing about pausing or resuming a
stream. The resume REST call has a required body that is easy to omit,
and Git sync and deployment pipelines silently reactivate paused nodes.
The skill's only mention of a paused state is the `EventStreamNodeStatus`
monitoring row (`SKILL.md` line 81).

## Evidence

Upstream trigger — `microsoft/skills-for-fabric` `CHANGELOG.md`,
`[0.3.11] - 2026-08-06` (release commit `2b3530e8`), under Fixed,
verbatim:

> **`eventstream-cli` lifecycle control** -- documented bodyless pause
> requests, the required resume `startType` body, and the correct
> source/destination pause and resume endpoint order.

Confirmed on Learn, 2026-09-10:

[Topology - Resume Eventstream](https://learn.microsoft.com/rest/api/fabric/eventstream/topology/resume-eventstream):

```http
POST https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/eventstreams/{eventstreamId}/resume

{
  "startType": "Now"
}
```

| Field | Required | Values |
| --- | --- | --- |
| `startType` | yes | `Now`, `WhenLastStopped`, `CustomTime` |
| `customStartDateTime` | no | UTC, `YYYY-MM-DDTHH:mm:ssZ` |

Scopes `Eventstream.ReadWrite.All` or `Item.ReadWrite.All`; user, service
principal and managed identity all supported; success is `200 OK`. The
enum is documented as open: "Additional start types may be added over
time."

[Pause and resume data streams](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/pause-resume-data-streams)
carries a per-node table: not every node can be paused, and resume
options differ by node. For example, the Custom endpoint source and
destination and the Eventhouse Direct Ingestion destination cannot be
paused; the Lakehouse, Eventhouse (event processing before ingestion),
Activator and derived-stream destinations offer all three resume
options; most CDC and Kafka-family sources offer only "When streaming
was last stopped".

[Eventstream CI/CD](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/eventstream-cicd)
lists **Pause/Resume State** under *Not Supported* in its component
matrix, and says, verbatim:

> After CI/CD (Git integration and deployment pipeline), all resources in
> the target eventstream become active, unless they fail due to
> connection or configuration issues.

The pause/resume page also documents a CDC-snapshot routing gap:
ingestion can start before routing, so initial data is not routed; the
mitigation is to untick **Activate ingestion**, publish, then resume
with **Custom time**. It surfaced in the same drill but is **not** part
of the audit's finding. Include it only if the new section plainly
needs it.

## What to change

1. **Add a short `## Pause and resume` section** to `SKILL.md`. It fits
   after `## Workspace monitoring (preview)` (line 72) or just before
   `## Gotchas` (line 123). Contents: the resume endpoint and its
   required `startType`, that support and resume options vary per node
   (link Learn's table rather than copying it), and the CI/CD reset.
2. **Add a row to the `## Gotchas` table**: paused nodes come back
   **active** after a Git sync or a deployment-pipeline deploy, because
   CI/CD does not carry pause/resume state.

## Constraint on the fix

- **The pause endpoint was not fetched.** Before writing that pause is
  bodyless, fetch
  https://learn.microsoft.com/rest/api/fabric/eventstream/topology/pause-eventstream,
  plus any source- or destination-level pause/resume pages. Upstream's
  "correct source/destination pause and resume endpoint order" is not
  confirmed on Learn — do not encode an order.
- Link the per-node support table; don't copy it. A copied table drifts
  every time a connector gains the toggle.
- The frontmatter `description` sits at the 1,024-character cap
  (measured roughly 2026-09-10). Leave it unless a trigger phrase is
  essential, and let the linter decide.

## Verification

1. `grep -n 'startType' skills/fabric/fabric-eventstream/SKILL.md` —
   present, with all three values.
2. `grep -niE 'pause|resume' skills/fabric/fabric-eventstream/SKILL.md`
   — the CI/CD reset appears in `## Gotchas`.
3. Re-fetch the resume REST page and confirm the enum is unchanged.
4. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-eventstream/SKILL.md`
5. `pre-commit run --all-files`

## Sequencing note

Briefs 02, 03 and 05 are the same *kind* of work — add a Learn-confirmed
fact to one skill — and it is tempting to run them as one. They were
split because each targets a different skill with its own Learn page and
its own checks, and 05 carries an unresolved adjacent claim that must
not ride along with the others.

## Provenance

First `/drift-audit --sources skills-for-fabric` run, 2026-09-10, from a
0.3.11 `eventstream-cli` bullet. The resume body and the CI/CD reset are
confirmed on Learn. The bodyless pause and the endpoint order are
upstream's claims only.

## Execution log

- **Executed**: 2026-09-11 — applied
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in the session)
- **Files changed**: `skills/fabric/fabric-eventstream/SKILL.md`
- **Verification**: the constraint's fetches ran first. Pause Eventstream
  documents no request body, so bodyless pause is now Learn-confirmed.
  The Topology operation group lists source- and destination-level pause
  and resume too. All four pages fetched: pause bodyless, resume taking
  the same required `startType` body. No endpoint order is documented
  anywhere, and none was encoded. The CI/CD reset was re-confirmed by
  search. Steps 1–4 passed: `startType` at lines 106–123 with all three
  values, the CI/CD row in `## Gotchas` (line 177), the resume enum
  unchanged on re-fetch, lint clean. Step 5 runs once at the end of the
  run.
- **Behavioural confirmation**: 2026-09-12 via `/test-skill`, closing
  the deferral. Activation was already stamped current and the `paths:`
  glob is unchanged by this content-only edit, so Phase A re-ran its
  static half only: PASS on all 70 fabric fixtures, with the rules pass
  confirming `fabric-git-serialization` co-loads on the Eventstream
  files. Cold `-p` probe in a scratch directory outside this repo (the
  in-repo `name-only` collapse would have guaranteed a false negative),
  against a `--safe-mode` baseline. The payload run model-invoked the
  skill (`Skill` tool_use) and stated every fact this brief added:
  bodyless pause, resume requiring `startType` with all three values,
  `customStartDateTime` as UTC, the per-node restriction, and the CI/CD
  reset. Stamped `behaviour` in `tests/skills/.tested.json`.
- **The baseline got the REST detail wrong, specifically.** With the
  docs surface disabled it invented `startType: "LastStoppedTime"`,
  routed the per-node calls through a `/topology/` segment addressed by
  node *name* rather than GUID, and expected `202 Accepted` with
  operation polling instead of `200`. It flagged its own uncertainty on
  exactly those points. It *did* reach the CI/CD conclusion unaided, by
  inferring that pause state appears nowhere in the item definition —
  so that half of the brief is a weaker discriminator than the REST
  half, though the skill states it as documented fact rather than
  inference.
- **`--disallowedTools WebFetch,WebSearch` does not block Microsoft
  Learn on this machine.** The first payload probe fetched the four
  Learn pages this brief was drilled from through the user-scope
  `microsoft-learn-mcp` server, confounding the measurement; the run
  had to be repeated with the MCP surface disallowed and
  `--strict-mcp-config`. Cost separated once it was: 9 turns against
  18.
- **One imprecision surfaced in the skill's own text.** Deprived of the
  docs, the payload run read `Eventhouse (Direct Ingestion)` in the new
  section as covering the Eventhouse node outright and called it
  non-pausable, where the fixture is `ProcessedIngestion` and *is*
  pausable — the docs-fetched run drew that distinction correctly. The
  parenthetical is accurate but compresses enough to be read past. Not
  corrected here; recorded for a later `/learn`.
- **Deviations**: the section's REST table carries the source- and
  destination-level paths alongside the stream-level ones. The brief
  named only the resume endpoint, but its constraint anticipated those
  pages, and all four are Learn-confirmed. The section follows
  `## Workspace monitoring (preview)`. The description was left alone.
  The CDC-snapshot routing gap was left out, because the section does
  not plainly need it.
