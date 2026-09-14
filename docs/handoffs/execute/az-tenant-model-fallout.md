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

## Item 2: two places still say the profiles clear the Azure account

**This item's original citation was wrong, corrected 2026-09-14.** It
named "the row for the hosted-MCP probes" in [README.md](README.md) and
quoted it as telling a future session to "confirm the login survives,
since an interactive shell's profile runs `az account clear`". No such
row exists. That file's only mention of the clear is this brief's own
summary row; the row immediately below it — which the summary calls the
hosted-MCP one — is the MSIX packaging brief; and the quoted sentence
appears nowhere in the repo. The forward-looking advice it describes is
real, but it lives in an audit record, named under "Deliberately not to
be changed" below. **Confirm each target below before editing it.**

### 2a. `README.md`, this brief's own summary row

The queue row for this brief carries both defects. It points at the
hosted-MCP probe row that is not there, and it restates the premise
item 2 was written on — that the stale text "would send a probe session
chasing a failure mode that no longer exists", which 2c corrects. Edit
those two clauses; the row is long and the rest of it still holds.

### 2b. `claude/mcp/README.md:185`

Records a measurement whose third row was an accident, explained in the
present tense as "an interactive shell, whose profile runs `az account
clear`". The measurement itself still stands; only the mechanism named
in the aside is gone. Either put that clause in the past tense or mark
it as a record of behaviour that has since been removed — do not delete
the row, since it is the one that established the finding. (Cited here
as `:180` until 2026-09-14; the line had drifted by five.)

### 2c. What replaces the premise, wherever it is restated

The mechanism is gone, but **do not replace it with "the login now
survives"** — a functionally identical failure is still reachable by a
different route, and on a probe whose entire difficulty was separating
credential absence from configuration error, getting that wrong costs
time in precisely the session least able to spare it.

What actually holds, measured 2026-09-14: a tool shell runs with **no
profile at all**, so it never receives the pin, and `az` in a tool call
reads the shared `~/.azure` rather than the tenant directory `AzLogin`
writes. The two stores had already diverged on this machine while both
still answered exit 0. So a session probing this should set
`AZURE_CONFIG_DIR` explicitly first, and read an empty
`$env:AZURE_CONFIG_DIR` as "the profile never ran" rather than as "no
tenant selected".

### Deliberately not to be changed

Two dated audit records under
[docs/audits/2026-09-12/skills-for-fabric/](../../audits/2026-09-12/skills-for-fabric/)
also cite the clear. They are accurate history of what was true on that
date, and this repo keeps dated ledgers rather than rewriting them.
Leave both. If a reader needs the update, it belongs in this brief and
in `claude/CLAUDE.md`, not in a backdated record.

**Know what that costs, because one of them is not a record.**
`01-resite-the-hosted-fabric-mcp-placement-rule.md:182-184` is step 1 of
a re-probe procedure — "Both shell profiles skip `az account clear` when
`CLAUDECODE` is set, so an existing `az login` survives across tool
calls" — and it is the forward-looking advice item 2 was reaching for.
It is now wrong twice: the `CLAUDECODE` carve-out is gone, and a tool
shell gets no pin either way. Leaving it stands, because the ledger rule
is the stronger convention and `claude/CLAUDE.md` now carries the
correct statement — but this is the judgement call in item 2, and a
future reader re-probing from that record alone gets bad advice. Flip it
only deliberately.

## Post-change checklist

- No file outside `docs/audits/` states in the **present tense** that a
  shell profile runs `az account clear`. The bare
  `grep -rn "az account clear" --include=*.md .` is not that check and
  never was: it legitimately matches `claude/CLAUDE.md` twice — the
  past-tense opener and the tenant-scoped note — and this brief five
  times. Read the matches rather than counting them.
- For item 1, a deploy run leaves the four runtime keys in
  `~/.claude/settings.json` intact, verified by diffing before and
  after rather than by reading the code.
- `claude/CLAUDE.md` **did** need an edit, made 2026-09-14 and not
  outstanding. Its description of the tenant model was accurate, but the
  "**An agent shell inherits the pin**" claim beneath it was false: tool
  shells load no profile, so they get no pin. That sentence now says the
  opposite, and the file's opening "Both profiles print a two-line
  banner" claim — older than this change, same root cause — was corrected
  with it. The deployed `~/.claude/CLAUDE.md` was refreshed by copying
  that one file, per item 1.
