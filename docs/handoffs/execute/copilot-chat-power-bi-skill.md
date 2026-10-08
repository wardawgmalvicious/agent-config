---
status: open
priority: 3
needs: [user]
blocked-by: [platform-skill-portfolio.md]
written: 2026-10-08
---

# Handoff: decide where Fabric IQ in Microsoft 365 Copilot Chat over Power BI is covered

- **Written**: 2026-10-08, from one inbox note of 2026-10-07 by a session
  in a client Fabric repo, which was planning who may ask a semantic
  model questions from Microsoft 365 Copilot Chat. Re-measured against
  the payload at `fb9e38f`: no skill, brief or audit candidate covers
  the route.
- **Kind**: a decision, the user's, then an `/author-skill` run or an
  edit. Nothing is drafted.

## The route

Answering from Power BI content in Microsoft 365 Copilot Chat is GA, as
`fabric-semantic-model-ai-instructions` already quotes from Learn (read
2026-10-06), and it answers through Fabric IQ. `fabric-data-agent`
covers only the Agent Store route, for data agents. The model side
landed beside that quote on 2026-10-08: the model's Copilot access
setting, whose surfaces include "M365 Copilot Chat and Cowork".

## What the note gathered

From Learn's Copilot Chat overview, read 2026-10-07 by the note's
session and not re-read here:

- a report's share link is not supported; paste the address-bar URL;
- a pasted semantic-model URL answers without report visuals to ground
  it;
- data agents and ontologies answer there only through an explicitly
  published Microsoft 365 agent;
- answers reflect the last refresh;
- Embedded A and EM SKUs, paginated reports, dashboards and top-level
  apps are unsupported;
- the reader needs a Microsoft 365 Copilot licence and licensed access
  to the reports and models, but no access to Copilot in Fabric.

From a research pass in that session, **unverified**: three tenant
settings (the Microsoft 365 admin center's *Fabric data in Microsoft
Copilot*, with a specific-groups option; Fabric's *Share Fabric data
with your Microsoft 365 services*; cross-geo processing), and that
search indexes a report's name, description, page names, chart titles
and field names, and no models.

Verified answers return nothing while Fabric IQ is on (Learn, read
2026-10-08, landed in `fabric-semantic-model-ai-instructions`). That
Copilot Chat therefore returns none is the note's inference, not
observed.

## The decision

Whether this route gets a skill of its own, through `/author-skill`, or
a reference beside the AI-instructions guidance, which
`ai-instructions-into-fabric-tmdl.md` moves to
`fabric-tmdl/references/ai-instructions.md`.
`platform-skill-portfolio.md` decides first whether any new platform
skill is authored while the portfolio shrinks, and `fabric-data-agent`,
the other home for a Copilot surface, is one of its archive candidates.

## Not checked

The overview page itself, the three tenant settings and the search
fields: each needs a fresh Learn read, and the settings a tenant.

## Scrubbing

The note was raw. Its client and estate are cited by kind, and nothing
from it is quoted.

## Re-measure before acting

```bash
grep -rln -i "copilot chat" skills/fabric/   # fabric-semantic-model-ai-instructions alone on 2026-10-08
```
