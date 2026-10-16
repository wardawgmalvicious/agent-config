---
status: open
priority: 3
needs: [user]
blocked-by: []
written: 2026-10-15
---

# Handoff: an `azure` platform group, opened by an `azure-access` skill

- **Written**: 2026-10-15, from one inbox note of 2026-10-13 by a
  session in a client repo that runs a Python worker on Azure Container
  Apps, the user's first Azure project. Re-measured against the payload
  at `f8abbed`, which holds no Azure skill, group or prefix.
- **Kind**: a decision, the user's: whether to open an `azure` platform
  group, then `/author-skill` for its first skill. Nothing is drafted.

## What was asked

The user asked whether the 28 Azure skills under `~/.agents/skills`,
written there by the GitHub Copilot for Azure extension from
`microsoft/azure-skills` (installed 2026-10-05, refreshing on their
own), could seed skills of their own, scoped to the work rather than
copied whole, and named `entra-app-registration` as a candidate. Nothing
in the note is decided beyond asking for this scoping.

## Why neither the plugin nor a copy

The note's session read the 28 local copies on 2026-10-13:

- **The deploy chain assumes azd.** `azure-validate` and `azure-deploy`
  stop without `.azure/deployment-plan.md` and send the agent to
  `azure-prepare` to make one; a repo deploying Bicep from GitHub
  Actions has none.
- **Its Container Apps guidance is for web apps**: ingress, target
  ports, a `/health` route, and image pulls by a system-assigned
  identity, where that worker has no ingress and pulls with a
  user-assigned one.
- **Thin where depth is needed, and duplicated.** Table Storage gets one
  row, `azure-kusto` is generic KQL, `azure-validate`'s Bicep recipe
  sits inside `coding-bicep`, and one auth reference is byte-identical
  in seven skills.
- **Tone and tools.** Several open with mandatory-compliance wording
  that competes with a repo's own instructions, and the plugin's own
  `azure` MCP server beside a repo's `azure-mcp` gives two overlapping
  tool sets, which `claude/mcp/README.md` § "Servers (project scope)"
  advises against.

`entra-app-registration` conflicts with the payload. Its "Configure API
Permissions" step runs against `fabric-rest-api/references/auth.md`,
which records Learn's advice to add none for a Fabric service principal;
its Bicep example hardcodes placeholder scope and role IDs and turns on
implicit-grant ID tokens; and it treats admin consent as the user's,
where the user holds Application Developer and admin consent goes to
their organization's identity team. Worth lifting, after a check against
Learn each: its AADSTS error index, the `az ad app credential list`
expiry check, and its comparison of secret, certificate and federated
credential.

The note's sort of the 28: lift a few reference files from
`entra-app-registration`, `azure-validate`, `azure-deploy`,
`azure-compliance` and `azure-diagnostics`; skip the rest as covered by
`coding-kql`, `coding-bicep` or `fabric-eventhouse`, as azd or
greenfield workflows, or as services not in use.

## The skill: give X access to Y, and find why X gets a 401 or 403

Working name `azure-access`; `/author-skill` settles it. None of this
was in `skills/` or `claude/` on 2026-10-13, by the note's grep.

- **Choosing the identity**: a managed identity first, user- or
  system-assigned; a federated credential for anything outside Azure;
  an app registration with a secret or certificate last. The Azure half
  of GitHub OIDC: the federated identity credential on a user-assigned
  identity, its issuer, the audience `api://AzureADTokenExchange` and an
  exact subject match. Link `coding-ci-workflows` for GitHub's half.
- **Data-plane against control-plane roles**: Contributor reads no
  secret and no table row; Key Vault Secrets User against Secrets
  Officer; Storage Table Data Contributor; AcrPull and AcrPush. Lift the
  mapping table in `azure-validate/references/role-verification.md` and
  the live check in `azure-deploy/references/live-role-verification.md`,
  `az role assignment list --scope <id> --assignee-object-id <oid>`.
- **An escalation path**, from that client repo's Key Vault decision
  record: Contributor on a resource group may add a federated credential
  to a user-assigned identity in it, so whatever acts as Contributor
  there can act as that identity.
- **Who can do what**: a template that assigns roles needs User Access
  Administrator or Owner active, and with Contributor alone it creates
  the resources, then fails on the first role assignment (that repo,
  2026-09-25). Under PIM, activate first. Registering a resource
  provider needs `/register/action` on the subscription, so a deploy
  identity with Contributor on one resource group fails with
  `MissingSubscriptionRegistration`, and Bicep has no resource type for
  the registration (that repo, 2026-09-29).
- **One variable, two identities**: `azure/login` reads
  `AZURE_CLIENT_ID` as the deploy identity, and the Azure Identity SDK
  inside the container reads it as the worker's user-assigned identity.
- **Credential expiry**: app credentials through
  `az ad app credential list`, and Key Vault secrets' `expires`
  attribute, adapted from
  `azure-compliance/references/azure-keyvault-expiration-audit.md`.
- **Tenant safety**: link `claude/CLAUDE.md` § "Azure CLI state is per
  tenant, and pinned by folder" rather than restating it.

The Fabric client repos use service principals, workspace identities and
Key Vault too, so they could link the group beside `fabric-core`.

Microsoft's skills are MIT (`license: MIT` in each frontmatter): cite
lifted text the way `pbir-report-workflow` cites skills-for-fabric.
Versions the note read: `entra-app-registration` 1.2.1,
`azure-validate` 1.2.3, `azure-deploy` 1.2.2, `azure-compliance` 1.2.3,
`azure-diagnostics` 1.2.7.

## A drift-audit source, once the group lifts text

Register `microsoft/azure-skills`, branch `main`, path
`.github/plugins/azure-skills/skills/`, beside `skills-for-fabric`,
filtered to the skills the group lifts from, so an upstream change is
reviewed against the group instead of drifting unseen in a copy.

## Where it lands

- A new group under `skills/`, its name in `PLATFORM_GROUPS` and an
  `azure-` prefix in `PLATFORM_PREFIXES` in
  `scripts/lint-skill-overrides.py`, and a section in `skills/README.md`
  § "Platform groups". `.claude/rules/editing-skills.md` and
  `/author-skill` hold the rest.
- The drift source in `.claude/skills/drift-audit/references/sources.md`
  and an entry file under its `references/sources/`.

## Not checked

- What the Claude Code plugin form installs: the note inferred its hook
  and its `azure` server from the local hook script's header.
- Anything in `microsoft/azure-skills` beyond the local copies.
- Every lifted claim, against Learn, which the note asks for before any
  lands.

## Scrubbing

The note was genericized at source, with no client, tenant, account or
resource name; its repo is cited here by kind.

## Re-measure before acting

```bash
ls ~/.agents/skills | wc -l                                     # 28 on 2026-10-13
grep -n "PLATFORM_PREFIXES = " scripts/lint-skill-overrides.py  # no azure- on 2026-10-15
ls skills/                                                      # no azure group on 2026-10-15
```
