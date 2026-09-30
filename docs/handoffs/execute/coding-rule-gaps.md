---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-09-30
---

# Handoff: three coding rules miss what sessions elsewhere measured

- **Written**: 2026-09-30, from three inbox notes: a client repo's
  session of 2026-09-27, on Bicep; a personal machine-setup repo's of
  2026-09-29, on PowerShell; and a client Fabric repo's of the same day,
  on T-SQL. Each was checked against the payload at `0b1e82c`, and one
  PowerShell measurement was re-run here.
- **Kind**: edits to `claude/rules/coding-bicep.md`,
  `claude/rules/coding-powershell.md` and `claude/rules/coding-tsql.md`,
  the two ports that follow, and one clause of `claude/CLAUDE.md` with
  its ledger entry. The items are independent: land any alone and trim
  this brief to the rest. Nothing is drafted.

## Evidence status, per item

| Item | Status |
| --- | --- |
| 1, what-if's default-valued removals | Documented, read 2026-09-27 and 2026-09-30; measured once, on one resource type |
| 2, a secure prompt on redirected stdin | Measured 2026-09-29, several inputs each; its reach into the Bash tool inferred |
| 3, `$null` no longer deletes | Documented and measured 2026-09-29; Process scope re-run here 2026-09-30 |
| 4, no schema in an object's name | A client repo's convention, counted 2026-09-29; constraint names open |

## 1. Bicep: what-if lists an omitted property at its default as removed

**Problem.** A subscription-scope what-if, before a re-run of a
bootstrap template, listed this on a Basic-SKU container registry the
change did not touch:

```text
~ Microsoft.ContainerRegistry/registries/<name> [2023-11-01-preview]
  - properties.dataEndpointEnabled: false
  - properties.encryption:
      status: "disabled"
```

`coding-bicep.md` reads that as drift, twice. § "A redeploy replaces, it
does not merge" says "What-if shows the revert as a Modify wherever it
can evaluate the resource", and § "Checking a change" reads "a Modify on
a resource you did not touch" as "an out-of-band change about to be
reverted". It was neither.

**Cause.** The template sets neither property. The provider fills both
with defaults, which the live resource holds too: data endpoints and
customer-managed encryption are Premium-only, so a Basic registry is
always `false` and `disabled`. What-if compares the template's payload
with the live one and reports the omitted properties as deleted, though
a deploy sets them to the values they already have.

**Reading it.** The value after the `-`, not the symbol. A removed
property whose value is already the provider's default for that resource
and SKU changes nothing; a removed value that differs from the default
is the revert the rule warns of. **Re-running what-if cannot tell the
two apart**, unlike the rule's `reference()` case: after a real revert,
the next run shows the same line with the default value.

**Documented.** Learn, "Bicep What-If: Preview Changes Before
Deployment", § "Running the what-if operation": "Properties can be
incorrectly reported as deleted when they aren't in the Bicep file, but
are automatically set during deployment as default values. This result
is considered "noise" in the what-if response." Read 2026-09-27 by the
note's session and again here 2026-09-30.

**Measured**, 2026-09-27, Azure CLI with Bicep CLI 0.47.16: the lines
above; a registry module setting only `adminUserEnabled` and
`publicNetworkAccess` on SKU `Basic`; and `az acr show` after the
deployment, both properties unchanged.

**Edit.**

- § "A redeploy replaces, it does not merge", the bullet ending "What-if
  shows the revert as a Modify wherever it can evaluate the resource": a
  property listed as removed at its default is noise, and a removed
  value that is not the default is the revert.
- § "Checking a change", the second of its three reads: qualify "a
  Modify on a resource you did not touch" with each changed value not
  already being the default.
- Optional, beside § "Removing a resource from the template deletes
  nothing", which already names deployment stacks. That what-if run
  printed a pointer to deployment stacks' what-if, and Learn's "Preview
  deployment stack changes by using what-if", § "Noise reduction", says
  a stack keeps its deploy-time result as a baseline and drops what is
  unchanged since, though it "doesn't remove every one" (read
  2026-09-30).

**Not checked.** How widespread it is across resource types. Only the
registry showed it; a storage account and a Key Vault in the same
what-if showed no such lines.

## 2. PowerShell: a secure prompt hangs where a plain one returns

**Problem.** A setup script gained a `Read-Host -AsSecureString` prompt.
Run from an agent shell it would have hung the whole run: with stdin
redirected and no `-NonInteractive`, the prompt blocked until the
process was killed, printing nothing.

**Measured** 2026-09-29, pwsh 7.6.6 on .NET 10.0.12, Windows 11:

| Session | plain `Read-Host` | `Read-Host -AsSecureString` |
| --- | --- | --- |
| stdin redirected, no `-NonInteractive` | reads stdin: `$null` at EOF, else the line; exit 0 | ignores stdin and reads console keys: blocks until killed |
| `-NonInteractive` | throws `PSInvalidOperationException` | the same |

- The throw reads "PowerShell is in NonInteractive mode. Read and
  Prompt functionality is not available.", and its exit code follows
  the error preference. Under `Continue` the error prints, `Read-Host`
  returns `$null` and the script exits 0; under `Stop`, `pwsh -File`
  exits 1. A `&`-invoked child script's throw reaches the caller's
  `catch`.
- `[Environment]::UserInteractive` was `True` in every session. It
  reports the window station, not the console, so it sees neither case.
- Both agent tool shells redirect stdin. `[Console]::IsInputRedirected`
  is `True` under the PowerShell tool, which also passes
  `-NonInteractive`, so a prompt there throws. It is `True` under the
  Bash tool too, which does not, so **a secure prompt reached from the
  Bash tool would block to the tool's timeout**. That step is inferred:
  nothing was hung inside the Bash tool itself. Re-read here 2026-09-30
  under the PowerShell tool: `IsInputRedirected` and `UserInteractive`
  both `True`.
- `Read-Host`'s Notes on Learn say "This cmdlet only reads from the
  stdin stream of the host process". The secure form contradicts that.
  `-MaskInput` probably shares its read path, and was not measured.

How: child `pwsh` processes with redirected stdin, an empty file and
then a line of text, the secure form killed at 20 s each time;
`-NonInteractive` and `-noni` in a child `pwsh -File` and in a hidden
real console, where `IsInputRedirected` was `False`; and the guard below
end to end in that console, with key events written into its input
buffer by `WriteConsoleInputW`. Enter alone skipped, and a token plus
Enter was accepted.

**The guard.** Refuse to prompt where nobody can answer, and catch the
throw the check cannot see:

```powershell
if (-not [Environment]::UserInteractive -or [Console]::IsInputRedirected) {
    # No keyboard: skip with a warning, or take the value from a parameter.
}
else {
    try {
        $secret = Read-Host -Prompt 'Token (Enter to skip)' -AsSecureString
    }
    catch [System.Management.Automation.PSInvalidOperationException] {
        # -NonInteractive on a real console: IsInputRedirected is False there.
    }
}
```

In a `SupportsShouldProcess` script the check runs before
`ShouldProcess`, so a dry run reports the skip a real run would make.
The `UserInteractive` half is for a scheduled task with no desktop:
reasoned, not measured.

**Edit.**

- `coding-powershell.md` § "Windows and system operations": a bullet
  saying to check that a prompt can be answered before asking, with the
  three behaviours and the guard. The `Read-Host` line in
  § "Anti-patterns" points at it.
- `claude/CLAUDE.md` § Python, the prompts bullet, whose "`Read-Host`
  under `-NonInteractive` exits 0" is incomplete: it throws, exiting 0
  only under `Continue`, and the secure form on redirected stdin blocks.
  The file stood at 189 of its 200 lines on 2026-09-30, so reword the
  clause or cut it to a pointer at the rule.
- `docs/evidence/user-claude-md.md` § Python, whose paragraph opening
  "The same stdin reaches anything that prompts" counts `Read-Host`
  among prompts that block to the timeout and repeats the exit-0 claim.
  **The note asked for a correction in place. A ledger takes a new
  dated entry at the end of its heading instead**
  (`.claude/rules/editing-claude-md.md`).

## 3. PowerShell: `$null` stopped deleting an environment variable in 7.5

**Problem.** A script's remove switch printed that a token variable was
removed from User scope and exited 0, leaving the name in
`HKCU:\Environment` with an empty value. A profile function did the same
at Process scope, under a comment asserting the reverse.

**Cause.** Two documented behaviours compose:

- PowerShell converts `$null` to `''` when binding it to a .NET `string`
  parameter. `[NullString]::Value` exists to pass a real null
  (`NullString` class docs; language spec § 6.8).
- .NET 9's breaking change "Support for empty environment variables":
  `SetEnvironmentVariable` with an empty string now sets an empty
  value, and only null deletes. Before .NET 9 both deleted. PowerShell
  7.5 is built on .NET 9, and 7.4 on .NET 8.

So the `$null` form deleted on Windows PowerShell 5.1 and pwsh 7.4. On
7.5 and later it writes an empty value, silently, and exits 0.

**Measured** 2026-09-29, pwsh 7.6.6 on .NET 10.0.12:

| Call | User scope | Process scope |
| --- | --- | --- |
| `SetEnvironmentVariable($n, $null, $s)` | empty value left, name still in `GetValueNames()` | empty variable left, `Test-Path env:` True |
| `SetEnvironmentVariable($n, '', $s)` | empty value left | not measured |
| `SetEnvironmentVariable($n, [NullString]::Value, $s)` | deleted | deleted |
| `$env:X = $null` | n/a | deleted |
| `$env:X = ''` | n/a | empty variable left |
| `Remove-Item env:X` | n/a | deleted |

**Re-run here** 2026-09-30, the same versions, Process scope only,
through the PowerShell tool: `$null` left the variable,
`[NullString]::Value` deleted it, and `Set-Item env:` deleted with
`$null` and left an empty variable with `''`.

**The remedy.** Delete with `[NullString]::Value`; in the current
process `Remove-Item env:NAME` works too. Then check that the name is
gone, with `(Get-Item 'HKCU:\Environment').GetValueNames()` or
`Test-Path env:NAME`, not that the value is falsy. An empty leftover
reads as `$false`: a cleanup check written as `[bool]$value` reported
"not set" over exactly that leftover.

**Generalization.** `$null` passed to a .NET `string` parameter is `''`.
Wherever the callee treats the two differently, the call changes
meaning with no error.

**Edit.** `coding-powershell.md` § "Windows and system operations", a
bullet, and a line in § "Anti-patterns". `git grep` finds `NullString`
and `SetEnvironmentVariable` nowhere in the payload (2026-09-30), so the
rule is new and no script here is affected.

**Docs**, read 2026-09-29 by the note's session and not re-read here,
each under learn.microsoft.com:

- `dotnet/core/compatibility/core-libraries/9.0/empty-env-variable`,
  the change and its "Previous behavior";
- `powershell/scripting/whats-new/differences-from-windows-powershell`,
  which .NET each release is built on;
- `dotnet/api/system.management.automation.language.nullstring`;
- `powershell/module/microsoft.powershell.utility/read-host`, for
  item 2.

**Not measured.** That the `$null` form deleted before 7.5. It rests on
the .NET page's "Previous behavior".

## 4. T-SQL: an object's name never repeats its schema

**The rule.** A client Fabric repo's root instruction file carried four
T-SQL conventions. Three are in `coding-tsql.md` already, which that
repo takes as a managed port: leading commas, `usp_` procedures, and
`TRY`/`CATCH` with a transaction for a multi-statement write. The fourth
is the repo's own, that an object's name does not repeat its schema.

**In use.** Counted 2026-09-29 from that repo's warehouse folder: three
schemas each hold a parallel set of control-plane objects, and none of
the 29 tables, views and procedures carries its schema in its name. Five
names therefore recur in all three: a control table, a run log, a
latest-run view and two procedures.

**Edit.** § "Object naming", a bullet ahead of **Tables**, and the same
in `copilot/instructions/coding-tsql.instructions.md`. For example:

> - **Schemas**: an object's name never repeats its schema:
>   `sales.Order`, not `sales.SalesOrder`. Every reference is
>   schema-qualified already (§ Identifier quoting), so schemas holding
>   parallel objects can share names.

Illustrate it with invented names, never the client's.

**Constraint names are the open part.** Four of that warehouse's five
primary keys do carry their schema, as `PK_<Schema><Table>`; the fifth
is `PK_<Table>`, and nothing in the repo says why. That matches neither
the new bullet nor the existing `PK_<Table>` one.

- SQL Server scopes a constraint name to the schema: "Constraint names
  must be unique within the schema to which the table belongs" (Learn,
  "CREATE TABLE (Transact-SQL)", Arguments, read 2026-09-30). There,
  `PK_<Table>` repeats across schemas as table names do.
- For a Fabric Warehouse nothing read here says. Its table-constraints
  page adds a `PK_<Table>` with `ALTER TABLE … ADD CONSTRAINT` and
  names no scope, while Synapse dedicated SQL pool's `CREATE TABLE`
  page says a default constraint's name "is unique within the
  database".
- **All five of the client's names are unique across the warehouse**,
  which is what a database-wide scope would force, and would explain
  the prefix. A reading, not a finding.

Two statements on any warehouse settle it: add a `PK_X` to a table in
each of two schemas. Without a tenant, land the bullet for tables,
views, procedures and functions, leave `PK_<Table>` as it is, and say
that constraint names are not covered. Put that choice in the diff.

Once it lands and the client repo re-syncs its port, that repo drops
its own line. Nothing returns to it from here.

## The ports, and the deploy

- `coding-bicep` and `coding-tsql` are ported, and `coding-powershell`
  is deferred (`copilot/.source-hashes.json`). While `lint-instructions`
  gates the ports, items 1 and 4 each redo theirs by hand, then
  `uv run --with pyyaml scripts/lint-instructions.py --stamp`
  (`.claude/rules/editing-rules.md`). Both stamps write one manifest.
- Those ports may be frozen or retired first:
  [copilot-client-repo-findings.md](copilot-client-repo-findings.md)
  holds what that waits on. If it lands first, the port steps go.
- After the merge, from the main checkout:
  `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`,
  never bare. `-Force` is for item 2's `claude/CLAUDE.md`. Then
  `./scripts/copy-copilot.ps1 -CopilotDir ~/.copilot -SkillGroups
  workflow`, which re-copies the ports (`.claude/rules/copilot-payload.md`).
- A split of `coding-tsql.md` by glob was proposed on 2026-09-30, in an
  exploration that edited nothing (transcript `230c3b1b`): it measured
  the rule's two Fabric Warehouse sections at 28% of the file. It is
  undecided and has no brief. § "Object naming" is generic T-SQL and
  stays with `**/*.sql` either way.

## Verification

- `uv run --with pyyaml scripts/lint-frontmatter.py` on the three rules.
- `uv run --with pyyaml scripts/lint-instructions.py` clean after the
  stamp.
- `uv run scripts/lint-claude-md.py`: `claude/CLAUDE.md` inside its cap.
- `cmp` each deployed rule, and `~/.claude/CLAUDE.md`, against the
  repo's copy.
- Item 3's table at Process scope, before quoting it. Item 2's hang only
  in a child process with redirected stdin and a kill timer, never
  inline in a tool shell.
- `pre-commit run --all-files`.

## Scrubbing

This repo is public. The client org, its repos and its Azure resources
are cited by kind, "a Basic-SKU container registry". The warehouse's
schema and object names stay out of the rule, the port and the commit
messages; their shape is all the rule needs. The machine-setup repo's
script names were examples and are dropped.

## Re-measure before acting

- `git log -1 --format=%h` on each rule: `c8da308` for Bicep, `70efba3`
  for PowerShell and `5aa8095` for T-SQL on 2026-09-30.
- The two Learn passages quoted above. Item 1's page says the noise
  "will be filtered out" as what-if matures, so it can stop being true.
- `pwsh --version`: 7.6.6 on 2026-09-30.
- `wc -l claude/CLAUDE.md`.
