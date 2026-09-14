# Handoff: fallout from the per-tenant Azure CLI model

- **Written**: 2026-09-14, out of the machine-config session that
  replaced `az account clear` with per-tenant `AZURE_CONFIG_DIR`
  directories. Both items below were found while deploying that
  change's CLAUDE.md edit, not while looking for them.
- **Kind**: one design decision on the deploy script, plus two prose
  corrections. Independent of each other — take either alone.
- **Status**: **open, written 2026-09-14.** Nothing is blocked on
  anything in this queue.
- **Run in**: any session here. Item 1 wants a decision before code;
  item 2 is an edit.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## What changed upstream, so the claims below can be checked

machine-config dropped `az account clear` from both shell profiles on
2026-09-14 (branch `feat/az-tenant-config-dirs`, `127b04d` and
`803d6cd`). Each tenant now gets its own Azure CLI config directory
under `~/.azure-tenants/<name>/`, selected through `AZURE_CONFIG_DIR`
and resolved at shell startup by folder scope first — a `repoRoot` in
`~/.config/az-tenants.json` — and the last `AzLogin` second.

This repo's authority on that is
[claude/CLAUDE.md](../../../claude/CLAUDE.md) § "Azure CLI state is per
tenant, and pinned by folder", landed 2026-09-14 in `97455f2`. Read it
first; everything below assumes it.

## Item 1: `-Force` overwrites live settings.json, and it is the flag you need

`scripts/link-claude.ps1` deploys `CLAUDE.md` and `settings.json` as
**copies**, and only `-Force` pushes them. So the single flag required
to deploy a CLAUDE.md edit is also the one that overwrites
`settings.json` — there is no way to do the first without risking the
second.

Measured 2026-09-14, `~/.claude/settings.json` against
`claude/settings.json`. The live file carries four keys the repo copy
does not:

```
theme, agentPushNotifEnabled, tui, model
```

Every one reads as a `/config` choice — per-machine runtime preference,
not payload. A `-Force` run would have silently discarded all four.
This session worked around it by copying `CLAUDE.md` alone with
`Copy-Item`, after first diffing the live file against `HEAD~1` to
confirm it was a verbatim copy with nothing local to lose. That
workaround is fine once and is not a fix: the documented default
invocation for this machine, in the script's own `.EXAMPLE` block, is
`-SkillGroups workflow,social -Force`.

**The script has no `-WhatIf`**, which is why this was only findable by
diffing first. Anyone following the documented example without that
instinct loses the keys and gets no warning, on a run whose visible
purpose was a docs edit.

### The decision to make before writing code

Three shapes, and the middle one is the recommendation:

1. **Merge the four keys into `claude/settings.json`.** Rejected here,
   recorded so it is not re-litigated: `/config` rewrites that file at
   runtime, so the repo would be claiming ownership of state it cannot
   hold, and the drift returns the first time the user changes a theme.
2. **Re-merge live values on deploy**, the way machine-config's
   `scripts/vscode-profiles.ps1` re-merges its `RedactedSettings` keys
   from the machine before writing a profile's settings. Same problem,
   same solution, and the precedent is already written down. Needs a
   list of which keys are runtime-owned — that is the actual decision,
   and it is a judgement about each key rather than a lookup.
3. **Split the flag** so `-Force` covers `CLAUDE.md` and a separate
   switch covers `settings.json`. Cheapest, and it only narrows the
   blast radius rather than removing it — the trap still fires for
   anyone who wants both.

Whichever lands, consider giving the script a `-WhatIf` in the same
pass. It writes to `$HOME` and prunes skill groups, and machine-config
treats dry-run as a maintained contract on exactly that kind of script.

## Item 2: two files still say the profiles clear the Azure account

**`docs/handoffs/execute/README.md`**, the row for the hosted-MCP
probes, tells a future session to "confirm the login survives, since an
interactive shell's profile runs `az account clear` and a cleared login
produces that same DCR error on a working config."

That is not merely stale. It instructs the reader to suspect a failure
mode that can no longer occur, on a probe whose entire difficulty was
separating credential absence from configuration error — so it costs
time in precisely the session least able to spare it. What replaces it:
a login now survives across shells, and `$env:AZURE_CONFIG_DIR` names
the tenant a shell is pinned to without running a command. The negative
control in that row is unaffected and should stay.

**`claude/mcp/README.md:180`** records a measurement whose third row was
an accident, explained in the present tense as "an interactive shell,
whose profile runs `az account clear`". The measurement itself still
stands; only the mechanism named in the aside is gone. Either put that
clause in the past tense or mark it as a record of behaviour that has
since been removed — do not delete the row, since it is the one that
established the finding.

### Deliberately not to be changed

Two dated audit records under
[docs/audits/2026-09-12/skills-for-fabric/](../../audits/2026-09-12/skills-for-fabric/)
also cite the clear. They are accurate history of what was true on that
date, and this repo keeps dated ledgers rather than rewriting them.
Leave both. If a reader needs the update, it belongs in this brief and
in `claude/CLAUDE.md`, not in a backdated record.

## Post-change checklist

- `grep -rn "az account clear" --include=*.md .` returns only the two
  audit records.
- For item 1, a deploy run leaves the four runtime keys in
  `~/.claude/settings.json` intact, verified by diffing before and
  after rather than by reading the code.
- `claude/CLAUDE.md` needs no further edit for either item; it already
  describes the current model.
