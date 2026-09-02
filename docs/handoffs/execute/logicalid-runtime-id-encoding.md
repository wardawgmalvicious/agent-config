# Handoff: is a `.platform` `logicalId` a byte-reversed runtime item ID?

- **Written**: 2026-09-02, during wave 11
  ([item-type-skill-operationsagent.md](item-type-skill-operationsagent.md)),
  from evidence that arrived while checking that brief's step 3d.
- **Kind**: verification, then a small edit to two existing skills.
  **Not** a new-skill decision.
- **Status**: open. **Recommendation: make the one API call, then
  either add a line to `fabric-gotchas` and `fabric-rest-api` or record
  the negative.** Either outcome is worth the call; the current state —
  a strong pattern with no confirmation — is the only bad one.
- **Run in**: any session with a working `az login` against a tenant
  that has a Git-synced Fabric workspace. That is the whole blocker.
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

Three outcomes, three different write-ups:

- **Every item matches** → the claim holds. Add one line to
  `fabric-gotchas` (next to the existing logicalId row) and the detail
  to `fabric-rest-api`'s Item IDs section, with the snippet, the date,
  and the sample size. Keep the "not interchangeable" wording — it is
  still true and is the thing people get wrong.
- **Some match and some do not** → find what separates them. The obvious
  hypothesis is item age or creation path (portal vs API vs deployment
  pipeline), and the two raw-v4 exceptions in point 1 are the first
  place to look.
- **None match** → the reversal relates logicalIds to something else.
  Record the negative in `fabric-gotchas` so the inference is closed
  rather than left for rediscovery, and note where `jobArtifactId`'s
  value actually comes from.

## Step 2 — widen the sample before generalising

One tenant is not enough for a claim this mechanical. Cheap widening,
in order of cost:

- Any other Git-synced Fabric repo on this machine or a client's.
- Public Git-synced Fabric exports on GitHub — `tests/skills/fabric-triggers/README.md`
  already pins a set of these for fixtures, and their `.platform` files
  can be reversed offline with no credentials at all. **This costs
  nothing and does not need step 1**, so it can run first; it cannot
  confirm the runtime-ID half, but it can confirm or kill the
  "reversed form is a valid v4" half across tenants.

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
