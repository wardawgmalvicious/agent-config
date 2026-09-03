# Handoff: is a `.platform` `logicalId` a byte-reversed runtime item ID?

- **Written**: 2026-09-02, during wave 11, from evidence that arrived
  while checking step 3d of the `item-type-skill-operationsagent.md`
  decision brief. That brief was deleted when wave 11 closed — recover
  it with
  `git log --diff-filter=D -- 'docs/**/item-type-skill-operationsagent.md'`
  then `git show <sha>^:<path>`.
- **Kind**: verification, then a small edit to two existing skills.
  **Not** a new-skill decision.
- **Status**: **RESOLVED 2026-09-03 — the claim holds.** Steps 1 and 2
  both ran. `rev(logicalId)` **is** the runtime item ID, with one
  precondition the brief did not anticipate: it holds for
  **portal-created** items, not for items authored git-first. All three
  skills named below have been edited. **This brief is spent and should
  be deleted** once that lands — see the [lifecycle](README.md#lifecycle).
- **Run in**: done. Step 1 ran against a live `az login`; step 2 needed
  no credential.
- **Queue**: [README.md](README.md) has the execution order.

## The claim to test

**`reverse_bytes(logicalId) == the item's runtime ID`.**

Where `reverse_bytes` is a full 16-byte reversal of the GUID, and is its
own inverse:

```python
import uuid
rev = lambda g: str(uuid.UUID(bytes_le=uuid.UUID(g).bytes_le[::-1]))

rev("7c4d1e88-93af-4b02-9d61-2fa50c7e3b14")
# -> '0c7e3b14-2fa5-9d61-4b02-93af7c4d1e88'
rev(rev("7c4d1e88-93af-4b02-9d61-2fa50c7e3b14"))
# -> '7c4d1e88-93af-4b02-9d61-2fa50c7e3b14'
```

*(Synthetic pair. The real values are in a private work repo and this
repo is public — see Redaction below.)*

## Why it matters

`fabric-gotchas` carries a `PowerBIEntityNotFound` row and a
MUST/PREFER/AVOID line saying `.platform` `logicalId` and the runtime
item ID "are NOT interchangeable", and `fabric-rest-api` carries the
detail. Both are **correct and stay correct either way** — the two are
different strings and substituting one for the other still 404s.

What changes if the claim holds is the *explanation*, and explanations
are what stop the mistake recurring:

- It tells you a logicalId is not an independent identifier the service
  assigns, but a re-encoding of one you can already obtain.
- It gives a **local, offline** way to map a committed item to its
  runtime ID with no API call, which is exactly the operation that
  currently forces "fetch the runtime ID from the portal URL or
  `GET /v1/workspaces/{wsId}/items`".
- It explains the cosmetic thing everyone notices and nobody explains:
  why a `logicalId` so often has a version nibble that is not `4`. A
  reversed v4 GUID does not look like a v4 GUID.

If it does **not** hold, that is equally worth a line — because the
byte-level relationship below is real regardless, and the next person to
notice it will draw the same inference unless the file says otherwise.

## The evidence, and its exact limit

All from one Git-synced repo (`C:\Repos\ACME\fabric-acme`), 2026-09-02.
**Kept as the wave-11 record; step 2 below supersedes its counts and
resolves the point-1 exceptions.** Points 2 and 3 are untouched by it.

1. **The encoding is systematic, not a one-off.** Reversing every
   `.platform` `logicalId` in the repo (35 files) yields a valid
   RFC-4122 **v4** GUID in **33** cases. The two exceptions are already
   v4 in their raw form — i.e. not reversed — which is itself worth a
   glance during the run.
2. **A cross-item reference confirmed the pair.** An `.OperationsAgent`
   item's `Configurations.json` names its Fabric-job target by
   `jobArtifactId`, and that value is the **exact byte-reversal** of the
   target pipeline's `.platform` `logicalId`. Verified as an equality,
   not a resemblance.
3. **The reversed form appears where runtime IDs live.** The monitored
   KQL database's `logicalId` reversed is the same string used as
   `itemId` in a Variable Library item-reference value set and as
   `databaseItemId` in an Eventstream definition. Both are places that
   hold runtime IDs.

**The limit is stated precisely because point 3 is suggestive and not
proof.** Nothing read was labelled "runtime item ID" by the service. No
`az login` was available during wave 11, so no API call was made. It is
also one repo, one tenant, and possibly one Fabric version — the
encoding could be an artifact of when those items were created.

## Step 1 — the call that settles it

```bash
az login
az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv
# GET https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items
```

Then, for each item in a Git-synced workspace, compare the returned `id`
against `rev(logicalId)` from that item's committed `.platform`.

**Step 2b changed what to expect here, and changed how to sample.**
A mixed result is now the *predicted* outcome, not a surprise — items
authored git-first should NOT match, because their `logicalId` is a
fresh client-side v4 that encodes nothing. So:

> **Do not sample only portal-created items.** Every item in a workspace
> that has only ever been portal-edited is in the class 2b says should
> match, so a sweep over those alone will come back 100% and look like a
> universal law. Deliberately include at least one item authored as
> files and synced *into* the workspace — in `fabric-acme` those are the
> two notebooks from PR #9 — and check that they come back **not**
> matching. A confirmation that cannot fail is not a confirmation.

Three outcomes, three different write-ups:

- **Every item matches, including a git-first one** → 2b is wrong and
  the relationship is universal. Add one line to `fabric-gotchas` (next
  to the existing logicalId row) and the detail to `fabric-rest-api`'s
  Item IDs section, with the snippet, the date, and the sample size.
  Keep the "not interchangeable" wording — it is still true and is the
  thing people get wrong.
- **Portal-origin items match and git-first ones do not** → the
  predicted result, and the most useful one: it confirms both the
  encoding *and* its boundary. Write it up as a rule with its
  precondition attached, since a reader who applies it to a git-first
  item gets a wrong ID with no error.
- **Some match and some do not, but not along that line** → find what
  actually separates them. Item age and creation path (portal vs API vs
  deployment pipeline) remain the hypotheses; 2b's classifier is the
  first thing to re-run.
- **None match** → the reversal relates logicalIds to something else.
  Record the negative in `fabric-gotchas` so the inference is closed
  rather than left for rediscovery, and note where `jobArtifactId`'s
  value actually comes from.

## Step 1 — DONE 2026-09-03: the claim holds, for portal-created items

Ran against a live `az login`, 19 workspaces visible to the identity,
296 distinct runtime item IDs collected. Read-only throughout.

**Result: of the local `logicalId`s whose reversal resolved to anything,
21 of 21 hit a real item carrying the same `displayName` and `type`.**
No reversal landed on a *different* item. No raw `logicalId` was itself
an item ID. The remaining 16 are absent from every visible workspace —
this repo accumulated items from five workspaces over its life, some now
deleted or inaccessible — so they neither confirm nor refute.

Both git-first items were in that unresolvable 16, so **step 2b's
negative prediction could not be tested.** It stays consistent with the
data and untested by it, and the skills say so rather than implying the
boundary was measured from both sides.

### The method note, because two earlier passes were wrong

Worth keeping, since the obvious approach fails quietly here:

- **Matching local items to API items by `(displayName, type)` is
  unsound.** This solution is deployed across four workspaces, so every
  name resolves four ways. The first pass compared against all 19
  workspaces and produced **120 comparisons from 37 items**, with a
  meaningless 91 "no match".
- **Scoping by name to one workspace is also unsound**, and worse
  because it looks right: pairing each item with the workspace named in
  its own newest sync commit produced a *spurious mixed result* (4 match,
  21 do not) by pairing items with the wrong copy of themselves.
- **The decisive test uses no names at all.** Collect every item ID
  visible to the identity, then ask whether `rev(logicalId)` is a
  **member** of that set. A 128-bit match is proof on its own, and
  checking `displayName`/`type` afterwards turns it into a
  self-validating test — a false positive would show up as a hit on an
  item with the wrong name, and there were none.

## Step 2 — DONE 2026-09-03: the structural half is confirmed

Ran first, as the brief allowed, because it needs no credential. It
confirmed the "reversed form is a valid v4" half well past the bar set
here, and it did something the brief did not expect: it **explained the
two exceptions**, offline.

### 2a — both local repos, not one

`fabric-acme` now holds 37 `.platform` files (was 35): **35 reverse to a
valid RFC-4122 v4, 2 are already v4 raw.** `fabric-acme-legacy` is a
**second workspace** the brief never sampled: **39 of 39 reverse.** So
74 of 76 locally, with the same 2 exceptions as wave 11 found.

### 2b — the exceptions are creation path, and the separation is perfect

Step 1 listed "item age or creation path" as the hypothesis to test *if*
the API call came back mixed. It was testable offline all along, by
asking git where each item came from. Classify every item by whether its
oldest commit (`git log --follow`, last line) is a Fabric portal Git-sync
commit — the portal writes `Committing N items from workspace <id>` —
or a human commit:

| Origin of the item | logicalId form | fabric-acme | fabric-acme-legacy |
| --- | --- | --- | --- |
| portal Git-sync commit | reverses to valid v4 | 35 | 39 |
| authored git-first in a human PR | already plain v4 | 2 | 0 |

**76 of 76, zero cross-cases.** The two exceptions are notebooks added
by a feature PR with no prior history — written as files and synced
*into* the workspace. A third notebook landed in that same commit and is
*not* an exception, which is what rules out "arrived in one commit" and
points at origin: `git log --follow` traces it back to a portal sync six
weeks earlier, so it had been portal-created and was merely moved.

Read plainly: **a portal-created item's `logicalId` is a re-encoding of
something the service assigned; a git-first item's is a fresh client-side
v4 that encodes nothing.** That is a sharper claim than the brief made,
and it predicts a *mixed* step 1 result rather than a clean sweep.

### 2c — cross-tenant, via public GitHub exports

37 unique `logicalId`s across ~20 unrelated public repos and tenants,
including `microsoft/fabric-racing-sim`. Every single one is a valid v4
in **exactly one** of the two forms — never both, never neither:

- **32 raw v4** (reversal is not RFC-4122) — overwhelmingly PBIP/Desktop
  authored projects, consistent with 2b's git-first class.
- **5 reverse to valid v4** (raw is not RFC-4122), across three
  independent repos.

Combined with the local sample: **79 reversals, zero failures.** The
encoding is not an artifact of one tenant, one repo, or one Fabric
version.

### The limit that remains

Two things this did **not** establish, stated so a later reader does not
over-claim:

- **The runtime-ID half is still unconfirmed.** Everything above is
  about GUID *shape*. Nothing here was labelled "runtime item ID" by the
  service, so step 1 is still the only thing that settles the actual
  claim.
- **The public sample cannot test 2b.** Those repos are manual exports —
  the `DataAIVIX2025` items all trace to a single "Initial commit" — so
  their history is flattened and carries no portal-sync provenance. The
  creation-path finding rests on the two local repos alone.

## Where the finding is already recorded

`skills/fabric/fabric-operations-agent/SKILL.md` §4 states only the two
halves that Git alone proves — `dataSource.id` equals the source's
`logicalId` verbatim, `jobArtifactId` equals the target's `logicalId`
byte-reversed — and explicitly declines the runtime-ID inference,
pointing at the missing API call. **If this brief resolves either way,
that section needs the same edit as `fabric-gotchas`**, and it is the
one place a wrong answer would already be doing damage.

## Redaction

This repo is public and the sample is a private work repo. No real
workspace ID, item ID, `logicalId` or UPN goes into any file here — use
the synthetic pair above, or generate another with the snippet. `docs/`
and `tests/` are gitleaks-allowlisted, so nothing mechanical will catch
a paste.

## If the answer turns out to be "not worth pursuing"

Then delete this brief and say why in the commit, per the
[lifecycle](README.md#lifecycle). But note what the "no" costs: the
byte-reversal in point 2 is already written into a shipped skill as an
unexplained fact, so a decision not to investigate should still leave
`fabric-gotchas` a sentence saying the relationship exists and has not
been chased. An unexplained fact in one skill is how the same
investigation gets started from scratch in six months.
