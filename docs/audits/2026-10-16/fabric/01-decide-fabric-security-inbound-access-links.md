# Handoff: decide whether fabric-security links the inbound access pages

- **Audit run**: 2026-10-16
- **Source**: `fabric`
- **Window**: floor `7ff5f2b3` (2026-10-02, the 2026-10-06 run's head) →
  head `0cbcc6f71` (2026-10-15)
- **Covers recommended actions**: 1
- **Kind**: a **decision** on one reference bundle of a platform skill —
  whether it should list two Learn pages it lacks — then, on a yes, an
  additive link edit. No existing claim is wrong. The decision is the
  user's: `/drift-update` puts it back to the user rather than
  executing it.
- **Target**: `skills/fabric-core/fabric-security/references/REFERENCE.md`,
  § Network security (lines 42–52)

## The problem

`fabric-security`'s reference bundle lists Fabric's network-security
pages, but neither of the two that document **inbound** access by Azure
resource instance: OneLake's Resource Instance Rules page, for a feature
What's New lists as generally available in July 2026, and the Real-Time
hub's private-links page. On 2026-10-15 Microsoft's docs repo revised
the private-links pages to say that Azure event delivery, blocked by
tenant private links, can be restored through those rules without
turning the private links off.

Nothing the skill says is wrong. The bundle is silent on a GA feature
that now carries a documented workaround, and whether it should carry
the two pages is the user's call.

## Evidence

**What's New.** The window's only change to
`docs/fundamentals/whats-new.md` is one GA-table row's "For more
information" link text; its target stayed
`../onelake/onelake-manage-inbound-access-trusted-resources.md`. The
text went from "Resource Instance rules for Inbound access" to "Manage
workspace inbound access with Resource Instance Rules". The row at head
`0cbcc6f71`, verbatim (upstream's own "Azurfe" typo included):

```text
|July 2026|**Resource Instance Rules for OneLake Network Security for Azure Services (Generally Available)**|[Resource Instance Rules for OneLake](https://community.fabric.microsoft.com/t5/Fabric-Updates-Blog/Simplify-OneLake-network-security-for-Azurfe-Services-with/ba-p/5284830) let you allow specific Azure resource instances to access OneLake over the public endpoint while Fabric still evaluates data permissions. For more information, see [Manage workspace inbound access with Resource Instance Rules](../onelake/onelake-manage-inbound-access-trusted-resources.md).|
```

**The carried commit.** Sync merge `0cbcc6f71` (PR #3428, 2026-10-15)
carries one commit, `4118631219d16472cec761dfbfa6255429575523`,
"Document trusted resources for Azure event delivery (#16720)",
2026-10-15. Its `--stat` in a blobless clone of
`MicrosoftDocs/fabric-docs`, 101 insertions and 16 deletions:

| File | Lines changed |
| --- | --- |
| `docs/fundamentals/whats-new.md` | 2 |
| `docs/real-time-hub/includes/tenant-private-links-note.md` | 5 |
| `docs/real-time-hub/private-links-real-time-events.md` | 94 |
| `docs/real-time-hub/workspace-private-links-real-time-events.md` | 4 |
| `docs/security/security-inbound-overview.md` | 2 |
| `docs/security/security-private-links-overview.md` | 6 |
| `docs/security/security-workspace-level-private-links-support.md` | 4 |

The changed lines read from the clone, verbatim. The session printed
each changed line up to 600 characters; "…" marks where one was cut.

- `docs/security/security-private-links-overview.md`, `ms.date`
  08/26/2026 → 10/13/2026. Removed:

  > Azure events (such as Azure Blob Storage events) are affected by
  > both tenant-level and workspace-level private links. When the
  > **Block Public Internet Access** tenant setting is enabled, Azure
  > event sources outside the tenant are blocked from delivering events
  > into Fabric entirely:

  Added:

  > Azure events (such as Azure Blob Storage events) are affected by
  > both tenant-level and workspace-level private links. When you enable
  > the **Block Public Internet Access** tenant setting, Azure event
  > sources outside the tenant are blocked from delivering events into
  > Fabric by default:

  The bullet on existing configurations gained:

  > If the Event Grid system topic and Fabric workspace are in the same
  > Microsoft Entra tenant, you can restore delivery by adding the system
  > topic to the workspace's Resource Instance Rules. For instructions,
  > see [Allow Azure event sources through inbound trusted
  > resources](../real-time-hub/private-links-real-time-events.md#allow-azure-event-sources-through-inbound-trusted-resources).

- `docs/real-time-hub/includes/tenant-private-links-note.md`: "is
  blocked entirely" became "is blocked by default", and the note gained:

  > If the Azure Event Grid system topic and Fabric workspace are in the
  > same Microsoft Entra tenant, you can restore event delivery without
  > disabling tenant private links by adding the system topic to the
  > inbound trusted-resources allow list for the workspace that contains
  > the …

- `docs/security/security-inbound-overview.md`: the Resource Instance
  Rules bullet's link text, to "Manage workspace inbound access with
  Resource Instance Rules", same target.
- `docs/security/security-workspace-level-private-links-support.md`:
  `ms.date` → 10/13/2026, and one Azure-events line whose change falls
  past the cut, unread.
- `docs/real-time-hub/private-links-real-time-events.md` (94 lines,
  holding the new
  `#allow-azure-event-sources-through-inbound-trusted-resources`
  section) and
  `docs/real-time-hub/workspace-private-links-real-time-events.md`
  were not read.

**The skill on 2026-10-16.**

- `skills/fabric-core/fabric-security/references/REFERENCE.md:39`, the
  outbound direction, Fabric reaching a firewalled storage account:

  > - [Trusted workspace
  > access](https://learn.microsoft.com/fabric/security/security-trusted-workspace-access)
  > — accessing firewall-enabled ADLS Gen2 via workspace identity +
  > resource instance rules. Shortcuts, pipelines, COPY INTO, semantic
  > models, AzCopy. F SKU only; ARM templates required.

- § Network security, lines 42–52, lists Conditional Access, protecting
  inbound traffic, tenant private links (overview and setup),
  workspace-level private links, workspace IP firewall rules, managed
  private endpoints, managed virtual networks and the advanced
  networking tenant settings. Neither page above.
- `skills/fabric-core/fabric-security/SKILL.md` has no line matching
  "private link", "Block Public" or "inbound"; its line 105 sends
  network security to the bundle.
- Out of this brief, for orientation: `fabric-deploy`'s
  `references/deployment-pipelines-tables.md:116` and `:123` name
  workspace inbound access protection as a blocker for deployment
  pipelines, and `fabric-activator`'s `SKILL.md:178` and `:312` name
  Azure Blob Storage events as a source, with nothing on networking.
  The report put the latter under No-op.

## What to change

This brief's output is a decision. Put the question to the user:

> Should `fabric-security`'s reference bundle list the OneLake inbound
> Resource Instance Rules page and the Real-Time hub private-links page?

The answers the evidence supports:

1. **Both.** Two bullets under § Network security, after "Workspace IP
   firewall rules" (line 49), in the bundle's form: a linked title, an
   em dash, one line on what the page holds.
   - [Manage workspace inbound access with Resource Instance
     Rules](https://learn.microsoft.com/fabric/onelake/onelake-manage-inbound-access-trusted-resources)
     — admitting named Azure resource instances to a workspace's
     OneLake over the public endpoint, GA July 2026 per What's New.
   - [Tenant private links for Azure and Fabric
     events](https://learn.microsoft.com/fabric/real-time-hub/private-links-real-time-events)
     — Azure and Fabric events under tenant and workspace private
     links, and restoring Azure event delivery through the workspace's
     Resource Instance Rules when the Event Grid system topic shares
     the tenant.
2. **The OneLake page only.** The Real-Time hub page is arguably an
   eventing concern; it is offered here because the security pages now
   link it as the procedure, and the report named no other skill.
3. **Neither.** Record the answer; nothing changes.

The titles, taken from the docs repo's own link text, and the summaries
are placeholders: write each from the page as fetched at execution, not
from this brief's quotes.

## Constraint on the fix

- **Fetch both pages through `microsoft-learn-mcp`
  (`microsoft_docs_fetch`) before writing a line.** The audit read the
  docs repo's source at `411863121`, not the published pages, so the
  Phase 3 drill this source's registry entry names, through
  `microsoft-learn-mcp`, never ran on them. If a page does not yet carry
  the 2026-10-15 text, link it for what it does say, and date the line.
- **Links only, in `references/REFERENCE.md`.** No networking guidance
  in `SKILL.md`, `fabric-activator` or `fabric-eventstream`: the report
  found no line wrong.
- **`REFERENCE.md:39` stays as it is.** It describes the outbound
  direction, and correctly.

## Verification

1. Both Learn fetches return the page, not a 404 or a redirect to
   another topic, and each new bullet's summary is true of the page as
   fetched.
2. `grep -n 'onelake-manage-inbound-access-trusted-resources\|real-time-hub/private-links-real-time-events' skills/fabric-core/fabric-security/references/REFERENCE.md`
   — one hit per page the answer admitted, none on "Neither".
3. `uv run --with pyyaml scripts/skill-status.py --stale` — no new
   entry for `fabric-security`: the stamps do not hash `references/`.
4. `pre-commit run --all-files`.

On "Neither", only the execution log changes; `git status` shows the
skill untouched.

## Sequencing note

Independent of brief 02, the ledger stamp. Neither waits on the other,
and they share no file.

## Provenance

Recommended action 1 of the 2026-10-16 `/drift-audit --sources fabric`
run (`00-audit-report.md`, § Drift / gap candidates). The window's one
change to `whats-new.md` was link text; the signal is the landing's
carried commit, whose other six files the audit read in its clone
because the landing touched the audited path. The report's audit-window
line names five of those six and calls the largest "+90"; the table
above is the `--stat` as printed. The changed lines came from the
repository, not the published Learn pages, and the 94-line Real-Time
hub page was not read at all.
