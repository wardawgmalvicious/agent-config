---
status: deferred
priority: 3
needs: []
blocked-by: []
reopen-when: learnings from the client Container Apps worker's first deploy reach this inbox
written: 2026-10-15
---

# Handoff: an `azure-container-apps` skill, after a real deploy

- **Written**: 2026-10-15, from one inbox note of 2026-10-13 by a
  session in a client repo that runs a Python worker on Azure Container
  Apps. Re-measured against the payload at `f8abbed`, which holds
  nothing on Container Apps.
- **Kind**: a skill candidate for `/author-skill`, in the `azure`
  group `azure-access` opened on 2026-10-17. Nothing is drafted, and
  none of it is measured: that repo's `main.bicep` had never been
  deployed as of 2026-09-29.

## What it would cover

The note's list, each a claim to measure on that first deploy:

- revision health, and polling it from a deploy workflow;
- a liveness probe on a worker with no ingress, against the worker's own
  pass timeout;
- the `log-analytics` logs destination, which writes through the HTTP
  Data Collector API, whose support ended 2026-09-14 (Learn's migration
  guide, read 2026-09-29 by that repo's session), and its replacement,
  the `azure-monitor` destination plus a diagnostic setting;
- Key Vault secret references taking up to 30 minutes to see a new
  version;
- AcrPull with a user-assigned identity;
- no fixed egress IP on a consumption-plan app.

`azure-diagnostics/scripts/containerapp-diagnostics.sh` and its `.ps1`
twin, in `microsoft/azure-skills`, are a seed once their ingress
sections are dropped.

## Why it waits

Its learnings should come from that deploy, through `/learn` notes to
this inbox, not from documentation alone.

## Where it lands

A second skill in the `azure` group, by `/author-skill`.

## Scrubbing

The note was genericized at source; its repo is cited by kind.

## Re-measure before acting

```bash
ls ~/handoff-inbox/agent-config/   # the deploy's notes, when they come
ls skills/azure/                    # the group, opened 2026-10-17 with azure-access
```
